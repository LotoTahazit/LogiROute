import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../services/print_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/zone_utils.dart';

/// Вкладка с ожидающими точками доставки
class PendingPointsTab extends StatefulWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool isLoadingMap;
  final VoidCallback onCreateRoute;
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

  Widget _buildZoneButton(String? zoneId, String text, String tooltip, int count) {
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
      filteredPoints = widget.points.where((p) => p.zone == selectedZone).toList();
    }
    final zoneCounts = <String, int>{};
    for (final p in widget.points) {
      if (p.zone != null) {
        zoneCounts[p.zone!] = (zoneCounts[p.zone!] ?? 0) + 1;
      }
    }

    return Column(
      children: [
        if (widget.points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.route),
                    label: Text(l10n.createRoute),
                    onPressed: widget.onCreateRoute,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.autoDistributePallets),
                    onPressed: widget.isLoadingMap
                        ? null
                        : widget.onAutoDistribute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      child: _buildZoneButton(
                          zone.id, zone.nameHe, zone.nameHe, zoneCounts[zone.id] ?? 0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                    final showZoneHeader = index == 0 ||
                        point.zone != filteredPoints[index - 1].zone;

                    final zoneFill =
                        ZoneUtils.getZoneColor(point.zone ?? '');
                    final card = Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: zoneFill.withValues(
                              alpha: (zoneFill.a * 0.15).clamp(0.0, 1.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                ),
                                              ),
                                              if (point.zone != null &&
                                                  point.zone!.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: ZoneUtils.getZoneColor(
                                                        point.zone ?? ''),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    ZoneUtils.getZoneName(
                                                        point.zone ?? '',
                                                        Localizations.localeOf(
                                                                context)
                                                            .languageCode),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getDisplayAddress(point),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(12),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person_add,
                                          color: Colors.blue, size: 20),
                                      tooltip: l10n.assignDriver,
                                      onPressed: () =>
                                          widget.onAssignDriver(point),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart,
                                          color: Colors.green, size: 20),
                                      tooltip: l10n.addProduct,
                                      onPressed: () => widget.onAddProduct(point),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.orange, size: 20),
                                      tooltip: 'Edit Point',
                                      onPressed: () => widget.onEditPoint(point),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.list_alt,
                                          color: Colors.teal, size: 20),
                                      tooltip: 'תעודת ליקוט',
                                      onPressed: () =>
                                          PrintService.printPickingList(
                                        points: [point],
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      tooltip: l10n.delete,
                                      onPressed: () => widget.onDeletePoint(
                                          point.id, point.clientName),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
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