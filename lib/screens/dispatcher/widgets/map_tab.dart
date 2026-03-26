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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    final hasCurrentRoutes = widget.routes.isNotEmpty;
    final hasPreviousRoutes = widget.lastNonEmptyRoutes.isNotEmpty;

    // Если нет текущих маршрутов и есть предыдущие — показываем предыдущие
    // Если есть текущие — показываем текущие, предыдущие по кнопке
    final List<DeliveryPoint> displayPoints;
    if (!hasCurrentRoutes && hasPreviousRoutes) {
      // Нет активных — показываем предыдущие
      displayPoints = widget.lastNonEmptyRoutes;
    } else if (_showPreviousRoutes && hasPreviousRoutes) {
      displayPoints = widget.lastNonEmptyRoutes;
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
          child: DeliveryMapWidget(
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
