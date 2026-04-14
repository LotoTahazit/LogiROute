import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/delivery_map_widget.dart';

/// Вкладка с картой
/// ✅ AutomaticKeepAliveClientMixin — карта НЕ пересоздаётся при переключении табов
class MapTab extends StatefulWidget {
  final List<DeliveryPoint> routes;
  final List<DeliveryPoint> lastNonEmptyRoutes;
  final List<UserModel> drivers;
  final String? selectedDriverId;
  final Function(String? driverId) onDriverFilterChanged;
  final Map<String, String> routePolylines;
  final String companyId;
  final double warehouseLat;
  final double warehouseLng;
  final void Function(String pointId, String driverId, String driverName)?
      onPointDragToDriver;

  /// סיור מלא מהדשבורד — מפעיל דמו במפה בלי ללחוץ על כפתור המפה.
  final bool demoModeFromTour;

  /// כשסיום דמו המפה (סוף התרחיש) — לנקות שיוך מההורה.
  final VoidCallback? onTourDemoFinished;

  const MapTab({
    super.key,
    required this.routes,
    required this.lastNonEmptyRoutes,
    required this.drivers,
    required this.selectedDriverId,
    required this.onDriverFilterChanged,
    this.routePolylines = const {},
    required this.companyId,
    required this.warehouseLat,
    required this.warehouseLng,
    this.onPointDragToDriver,
    this.demoModeFromTour = false,
    this.onTourDemoFinished,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  bool _showDriverTracks = false;
  bool _showPreviousRoutes = false;
  bool _clearMap = false;

  /// Демо-сценарий на карте (только UI; prod — false).
  bool _demoMode = false;

  bool get _effectiveDemoMode => widget.demoModeFromTour || _demoMode;

  @override
  bool get wantKeepAlive => true;

  bool _isMobileWeb(BuildContext context) {
    if (!kIsWeb) return false;
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  Widget _buildMobileWebFallback(
      List<DeliveryPoint> points, AppLocalizations l10n) {
    // Группируем по водителям
    final byDriver = <String, List<DeliveryPoint>>{};
    for (final p in points) {
      final key = p.driverName ?? p.driverId ?? l10n.noDriverAssigned;
      byDriver.putIfAbsent(key, () => []).add(p);
    }

    final totalCount = points.length;
    final completedCount = points.where((p) {
      final s = DeliveryPoint.normalizeStatus(p.status);
      return s == DeliveryPoint.statusCompleted ||
          s == DeliveryPoint.statusCancelled;
    }).length;
    final remainingCount = totalCount - completedCount;

    if (points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noActivePoints,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Статистика
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(l10n.totalLabel, totalCount, Colors.blue),
                  _statChip(l10n.completedLabel, completedCount, Colors.green),
                  _statChip(l10n.remainingLabel, remainingCount, Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),
        // Список по водителям
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: byDriver.entries.map((entry) {
              final driverName = entry.key;
              final driverPoints = entry.value
                ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
              final done = driverPoints.where((p) {
                final s = DeliveryPoint.normalizeStatus(p.status);
                return s == DeliveryPoint.statusCompleted;
              }).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: done == driverPoints.length
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    child: Text(
                      '$done/${driverPoints.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: done == driverPoints.length
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  title: Text(
                    driverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  children: driverPoints.map((p) {
                    final s = DeliveryPoint.normalizeStatus(p.status);
                    final isDone = s == DeliveryPoint.statusCompleted;
                    final isCancelled = s == DeliveryPoint.statusCancelled;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isDone
                            ? Icons.check_circle
                            : isCancelled
                                ? Icons.cancel
                                : Icons.circle_outlined,
                        color: isDone
                            ? Colors.green
                            : isCancelled
                                ? Colors.red
                                : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        p.clientName,
                        style: TextStyle(
                          fontSize: 13,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        p.address,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: p.pallets > 0
                          ? Text(
                              '${p.pallets}P',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    final hasCurrentRoutes = widget.routes.isNotEmpty;
    final currentRouteIds = widget.routes
        .where((p) {
          final s = DeliveryPoint.normalizeStatus(p.status);
          return s != DeliveryPoint.statusCompleted &&
              s != DeliveryPoint.statusCancelled;
        })
        .where((p) => p.routeId != null && p.routeId!.isNotEmpty)
        .map((p) => p.routeId!)
        .toSet();
    final inlinePreviousRoutes = widget.routes.where((point) {
      final routeId = point.routeId;
      if (routeId == null || routeId.isEmpty) return false;
      return !currentRouteIds.contains(routeId);
    }).toList();
    final previousRoutes = inlinePreviousRoutes.isNotEmpty
        ? inlinePreviousRoutes
        : widget.lastNonEmptyRoutes.where((point) {
            final routeId = point.routeId;
            if (routeId == null || routeId.isEmpty) return true;
            return !currentRouteIds.contains(routeId);
          }).toList();
    final hasPreviousRoutes = previousRoutes.isNotEmpty;

    // Если нет текущих маршрутов и есть предыдущие — показываем предыдущие
    // Если есть текущие — показываем текущие, предыдущие по кнопке
    final List<DeliveryPoint> displayPoints;
    if (!hasCurrentRoutes && hasPreviousRoutes) {
      // Нет активных — показываем предыдущие
      displayPoints = previousRoutes;
    } else if (_showPreviousRoutes && hasPreviousRoutes) {
      displayPoints = previousRoutes;
    } else {
      displayPoints = widget.routes;
    }

    final activeDriverIds = displayPoints
        .where((p) => p.driverId != null)
        .map((p) => p.driverId!)
        .toSet()
        .toList();

    final driverPointCounts = <String, int>{};
    for (final point in displayPoints) {
      if (point.driverId != null) {
        driverPointCounts[point.driverId!] =
            (driverPointCounts[point.driverId!] ?? 0) + 1;
      }
    }

    var filteredPoints = displayPoints;
    if (widget.selectedDriverId != null) {
      filteredPoints = displayPoints
          .where((p) => p.driverId == widget.selectedDriverId)
          .toList();
    }

    return Column(
      children: [
        // Фильтр по водителям + toggle треков + toggle старых маршрутов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final driverFilter = DropdownButtonFormField<String?>(
                initialValue: widget.selectedDriverId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '${l10n.allDrivers} (${displayPoints.length})',
                    ),
                  ),
                  ...widget.drivers.map((driver) {
                    final isActive = activeDriverIds.contains(driver.uid);
                    final pointCount = driverPointCounts[driver.uid] ?? 0;

                    return DropdownMenuItem<String?>(
                      value: driver.uid,
                      enabled: isActive,
                      child: Text(
                        isActive
                            ? '${driver.name} ($pointCount)'
                            : '${driver.name} (0)',
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.grey,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: widget.onDriverFilterChanged,
              );

              final actions = <Widget>[
                if (hasCurrentRoutes && hasPreviousRoutes)
                  Tooltip(
                    message: _showPreviousRoutes
                        ? l10n.mapTooltipCurrentRoute
                        : l10n.mapTooltipPreviousRoute,
                    child: IconButton(
                      icon: Icon(
                        _showPreviousRoutes
                            ? Icons.history
                            : Icons.history_outlined,
                        color: _showPreviousRoutes
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPreviousRoutes = !_showPreviousRoutes;
                          _clearMap = false;
                        });
                      },
                    ),
                  ),
                Tooltip(
                  message: l10n.mapTooltipClearMap,
                  child: IconButton(
                    icon: Icon(
                      _clearMap ? Icons.layers : Icons.layers_clear,
                      color: _clearMap
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() => _clearMap = !_clearMap);
                    },
                  ),
                ),
                Tooltip(
                  message: _showDriverTracks
                      ? l10n.hideGpsTracks
                      : l10n.showGpsTracks,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showDriverTracks
                          ? Colors.blue.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _showDriverTracks
                          ? Border.all(color: Colors.blue.shade400)
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showDriverTracks ? Icons.route : Icons.route_outlined,
                        color: _showDriverTracks
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _showDriverTracks = !_showDriverTracks;
                          _clearMap = false;
                        });
                      },
                    ),
                  ),
                ),
                if (!widget.demoModeFromTour)
                  Tooltip(
                    message: _effectiveDemoMode
                        ? l10n.mapTooltipExitDemo
                        : l10n.mapTooltipDemoMode,
                    child: IconButton(
                      icon: Icon(
                        _effectiveDemoMode ? Icons.movie : Icons.movie_outlined,
                        color: _effectiveDemoMode
                            ? Colors.purple.shade700
                            : Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() => _demoMode = !_demoMode);
                      },
                    ),
                  ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    driverFilter,
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: actions,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: driverFilter),
                  const SizedBox(width: 4),
                  ...actions.expand((w) => [w, const SizedBox(width: 4)]),
                ]..removeLast(),
              );
            },
          ),
        ),
        // Индикатор "показан предыдущий маршрут"
        if (_showPreviousRoutes || (!hasCurrentRoutes && hasPreviousRoutes))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.mapBannerPreviousRouteShown,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isMobileWeb(context)
              ? _buildMobileWebFallback(filteredPoints, l10n)
              : DeliveryMapWidget(
                  points: _clearMap ? [] : filteredPoints,
                  companyId: widget.companyId,
                  demoMode: _effectiveDemoMode,
                  onDemoFinished: widget.onTourDemoFinished,
                  clearMapMode: _clearMap,
                  showDriverTracks: _clearMap ? false : _showDriverTracks,
                  routePolylines: _clearMap ? {} : widget.routePolylines,
                  warehouseLat: widget.warehouseLat,
                  warehouseLng: widget.warehouseLng,
                  enableDragDrop: widget.onPointDragToDriver != null,
                  onPointDragToDriver: widget.onPointDragToDriver,
                ),
        ),
      ],
    );
  }
}
