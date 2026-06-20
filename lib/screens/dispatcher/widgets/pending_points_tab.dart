import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../services/print_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/zone_utils.dart';
import '../../../theme/app_theme.dart';

/// Вкладка с ожидающими точками доставки
class PendingPointsTab extends StatefulWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool isLoadingMap;
  final VoidCallback onCreateRoute;
  final Function(List<DeliveryPoint> selectedPoints)?
      onCreateRouteFromSelection;
  final VoidCallback onAutoDistribute;
  final Function(String pointId, String clientName) onDeletePoint;
  final Function(DeliveryPoint point) onEditPoint;
  final Function(DeliveryPoint point) onAssignDriver;
  final Function(DeliveryPoint point) onAddProduct;
  final Function(List<DeliveryPoint> sortedPoints)? onCreateRouteByZone;

  const PendingPointsTab({
    super.key,
    required this.points,
    required this.companyId,
    required this.isLoadingMap,
    required this.onCreateRoute,
    this.onCreateRouteFromSelection,
    required this.onAutoDistribute,
    required this.onDeletePoint,
    required this.onEditPoint,
    required this.onAssignDriver,
    required this.onAddProduct,
    this.onCreateRouteByZone,
  });

  @override
  State<PendingPointsTab> createState() => _PendingPointsTabState();
}

class _PendingPointsTabState extends State<PendingPointsTab> {
  String? selectedZone;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedPointIds = {};

  @override
  void didUpdateWidget(covariant PendingPointsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final liveIds = widget.points.map((p) => p.id).toSet();
    _selectedPointIds.removeWhere((id) => !liveIds.contains(id));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getDisplayAddress(DeliveryPoint point) {
    if (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) {
      return point.temporaryAddress!;
    }
    return point.address;
  }

  int _calculateTotalPallets() {
    return widget.points.fold(0, (sum, p) => sum + p.pallets);
  }

  int _calculateTotalBoxes() {
    return widget.points.fold(0, (sum, p) => sum + p.boxes);
  }

  bool _isSelected(DeliveryPoint point) => _selectedPointIds.contains(point.id);

  void _toggleSelection(DeliveryPoint point) {
    setState(() {
      if (!_selectedPointIds.add(point.id)) {
        _selectedPointIds.remove(point.id);
      }
    });
  }

  List<DeliveryPoint> _selectedPoints() => widget.points
      .where((point) => _selectedPointIds.contains(point.id))
      .toList();

  String _zoneNameForDialog(BuildContext context, String? zone) {
    if (zone == null || zone.isEmpty) {
      return AppLocalizations.of(context)!.noZoneLabel;
    }
    return ZoneUtils.getZoneName(
        zone, Localizations.localeOf(context).languageCode);
  }

  Future<void> _createRouteFromSelection(BuildContext context) async {
    final selectedPoints = _selectedPoints();
    if (selectedPoints.isEmpty || widget.onCreateRouteFromSelection == null)
      return;

    final selectedZones =
        selectedPoints.map((p) => _zoneNameForDialog(context, p.zone)).toSet();
    if (selectedZones.length > 1) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.warning),
              content: Text(
                AppLocalizations.of(context)!
                    .selectedClientsDifferentZonesWarning(
                  selectedZones.join(', '),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.continueAnyway),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    widget.onCreateRouteFromSelection!(selectedPoints);
  }

  Widget _buildZoneButton(
      String? zoneId, String text, String tooltip, int count) {
    final isSelected = selectedZone == zoneId;
    final Color zoneColor =
        zoneId != null ? ZoneUtils.getZoneColor(zoneId) : Colors.grey;

    return FilterChip(
      label: Text(
        '$text ($count)',
        style: TextStyle(
          color: isSelected ? Colors.white : zoneColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: zoneColor,
      checkmarkColor: Colors.white,
      backgroundColor:
          zoneColor.withValues(alpha: (zoneColor.a * 0.1).clamp(0.0, 1.0)),
      side: BorderSide(color: zoneColor, width: 1.5),
      onSelected: (val) {
        setState(() {
          selectedZone = val ? zoneId : null;
        });

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const zoneOrder = {
      'north': 1,
      'sharon': 2,
      'center': 3,
      'jerusalem': 4,
      'south': 5,
    };
    final List<DeliveryPoint> filteredPoints;
    if (selectedZone == null) {
      filteredPoints = List<DeliveryPoint>.from(widget.points);
      filteredPoints.sort((a, b) {
        final za = zoneOrder[a.zone ?? ''] ?? 999;
        final zb = zoneOrder[b.zone ?? ''] ?? 999;
        return za.compareTo(zb);
      });
    } else {
      filteredPoints = widget.points.where((p) {
        if (p.zone == null) return false;
        return p.zone!.split(',').map((z) => z.trim()).contains(selectedZone);
      }).toList();
    }
    final zoneCounts = <String, int>{};
    for (final p in widget.points) {
      if (p.zone != null) {
        for (final z in p.zone!.split(',')) {
          final zoneId = z.trim();
          if (zoneId.isNotEmpty) {
            zoneCounts[zoneId] = (zoneCounts[zoneId] ?? 0) + 1;
          }
        }
      }
    }

    return Column(
      children: [
        if (widget.points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                final firstButton = ElevatedButton.icon(
                  icon: const Icon(Icons.route),
                  label: Text(l10n.createRoute),
                  onPressed: widget.onCreateRoute,
                );
                final selectedButton = ElevatedButton.icon(
                  icon: const Icon(Icons.checklist),
                  label: Text(
                      l10n.createRouteFromSelected(_selectedPointIds.length)),
                  onPressed: _selectedPointIds.isEmpty
                      ? null
                      : () => _createRouteFromSelection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                );
                final clearSelectionButton = OutlinedButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: Text(l10n.clearSelection),
                  onPressed: _selectedPointIds.isEmpty
                      ? null
                      : () => setState(() => _selectedPointIds.clear()),
                );
                final secondButton = ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.autoDistributePallets),
                  onPressed:
                      widget.isLoadingMap ? null : widget.onAutoDistribute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                );
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_selectedPointIds.isEmpty) ...[
                        firstButton,
                        const SizedBox(height: 8),
                        secondButton,
                      ] else ...[
                        selectedButton,
                        const SizedBox(height: 8),
                        clearSelectionButton,
                        const SizedBox(height: 8),
                        secondButton,
                      ],
                    ],
                  );
                }
                if (_selectedPointIds.isEmpty) {
                  return Row(
                    children: [
                      Expanded(child: firstButton),
                      const SizedBox(width: 12),
                      Expanded(child: secondButton),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: selectedButton),
                    const SizedBox(width: 12),
                    Expanded(child: clearSelectionButton),
                    const SizedBox(width: 12),
                    Expanded(child: secondButton),
                  ],
                );
              },
            ),
          ),
        if (widget.points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '${widget.points.length} ${l10n.points}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_calculateTotalBoxes()} ${l10n.boxes}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_calculateTotalPallets()} ${l10n.pallets}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                      fontSize: 16,
                    ),
                  ),
                  if (_selectedPointIds.isNotEmpty)
                    Text(
                      l10n.selectedCount(_selectedPointIds.length),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.deepPurple),
                    tooltip: 'תעודת ליקוט',
                    onPressed: () => PrintService.printPickingList(
                      points: widget.points,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.points.isNotEmpty)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildZoneButton(null, 'הכל', l10n.all, widget.points.length),
                  const SizedBox(width: 8),
                  ...ZoneUtils.allZones.map((zone) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildZoneButton(zone.id, zone.nameHe, zone.nameHe,
                          zoneCounts[zone.id] ?? 0),
                    );
                  }),
                  const SizedBox(width: 16),
                  if (selectedZone != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.route, size: 16),
                      label: Text(l10n.createRouteByZone,
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZoneUtils.getZoneColor(selectedZone!),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        if (widget.onCreateRouteByZone != null) {
                          widget.onCreateRouteByZone!(
                            List<DeliveryPoint>.from(filteredPoints),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: filteredPoints.isEmpty
              ? Center(
                  child: Text(
                    selectedZone == null
                        ? l10n.noDeliveryPoints
                        : 'אין נקודות באזור הנבחר',
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredPoints.length,
                  itemBuilder: (context, index) {
                    final point = filteredPoints[index];
                    final isSelected = _isSelected(point);

                    final showZoneHeader = index == 0 ||
                        point.zone != filteredPoints[index - 1].zone;

                    final zoneFill = ZoneUtils.getZoneColor(point.zone ?? '');
                    final actionButtons = <Widget>[
                      IconButton(
                        icon: const Icon(Icons.person_add,
                            color: Colors.blue, size: 20),
                        tooltip: l10n.assignDriver,
                        onPressed: () => widget.onAssignDriver(point),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.green, size: 20),
                        tooltip: l10n.addProduct,
                        onPressed: () => widget.onAddProduct(point),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.orange, size: 20),
                        tooltip: 'Edit Point',
                        onPressed: () => widget.onEditPoint(point),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.list_alt,
                            color: Colors.teal, size: 20),
                        tooltip: 'תעודת ליקוט',
                        onPressed: () => PrintService.printPickingList(
                          points: [point],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        tooltip: l10n.delete,
                        onPressed: () =>
                            widget.onDeletePoint(point.id, point.clientName),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ];

                    final card = Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: isSelected
                          ? Colors.green.shade50
                          : zoneFill.withValues(
                              alpha: (zoneFill.a * 0.15).clamp(0.0, 1.0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleSelection(point),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;
                              final titleBlock = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          point.clientName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade700,
                                            size: 20,
                                          ),
                                        ),
                                      if (point.zone != null &&
                                          point.zone!.isNotEmpty)
                                        ...point.zone!.split(',').map((z) {
                                          final zoneId = z.trim();
                                          if (zoneId.isEmpty)
                                            return const SizedBox.shrink();
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            margin:
                                                const EdgeInsets.only(right: 2),
                                            decoration: BoxDecoration(
                                              color: ZoneUtils.getZoneColor(
                                                  zoneId),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ZoneUtils.getZoneName(
                                                  zoneId,
                                                  Localizations.localeOf(
                                                          context)
                                                      .languageCode),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getDisplayAddress(point),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.muted,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isNarrow) ...[
                                    titleBlock,
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${point.pallets} ${l10n.pallets}',
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Row(
                                      children: [
                                        Expanded(child: titleBlock),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${point.pallets} ${l10n.pallets}',
                                            style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (point.boxTypes != null &&
                                      point.boxTypes!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: point.boxTypes!.map((bt) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green.shade200),
                                          ),
                                          child: Text(
                                            bt.toShortString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: actionButtons,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );

                    if (!showZoneHeader ||
                        point.zone == null ||
                        point.zone!.isEmpty) {
                      return card;
                    }

                    final zoneId = point.zone!;
                    final localeCode =
                        Localizations.localeOf(context).languageCode;

                    final zoneName = ZoneUtils.getZoneName(zoneId, localeCode);

                    final zoneCount = zoneCounts[zoneId] ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8),
                          child: Text(
                            '$zoneName ($zoneCount)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        card,
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
