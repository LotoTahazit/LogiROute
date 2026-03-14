import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../services/print_service.dart';
import '../../../l10n/app_localizations.dart';

/// Вкладка с ожидающими точками доставки
class PendingPointsTab extends StatelessWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool isLoadingMap;
  final VoidCallback onCreateRoute;
  final VoidCallback onAutoDistribute;
  final Function(String pointId, String clientName) onDeletePoint;
  final Function(DeliveryPoint point) onEditPoint;
  final Function(DeliveryPoint point) onAssignDriver;
  final Function(DeliveryPoint point) onAddProduct;

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
  });

  String _getDisplayAddress(DeliveryPoint point) {
    if (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) {
      return point.temporaryAddress!;
    }
    return point.address;
  }

  /// Суммарные миштахи по всем точкам (простая сумма, диспетчер корректирует)
  int _calculateTotalPallets() {
    return points.fold(0, (sum, p) => sum + p.pallets);
  }

  /// Суммарные коробки по всем точкам
  int _calculateTotalBoxes() {
    return points.fold(0, (sum, p) => sum + p.boxes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.route),
                    label: Text(l10n.createRoute),
                    onPressed: onCreateRoute,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.autoDistributePallets),
                    onPressed: isLoadingMap ? null : onAutoDistribute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (points.isNotEmpty)
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
                    '${points.length} ${l10n.points}',
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
                      points: points,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: points.isEmpty
              ? Center(child: Text(l10n.noDeliveryPoints))
              : ListView.builder(
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                      Text(
                                        point.clientName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                            // Товары (boxTypes)
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
                                      borderRadius: BorderRadius.circular(8),
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
                                  onPressed: () => onAssignDriver(point),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart,
                                      color: Colors.green, size: 20),
                                  tooltip: l10n.addProduct,
                                  onPressed: () => onAddProduct(point),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange, size: 20),
                                  tooltip: 'Edit Point',
                                  onPressed: () => onEditPoint(point),
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
                                  onPressed: () =>
                                      onDeletePoint(point.id, point.clientName),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
