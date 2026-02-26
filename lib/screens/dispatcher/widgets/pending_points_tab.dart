import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
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
  });

  String _getDisplayAddress(DeliveryPoint point) {
    if (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) {
      return point.temporaryAddress!;
    }
    return point.address;
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
                      child: ListTile(
                        title: Text(point.clientName),
                        subtitle: Text(_getDisplayAddress(point)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${point.pallets} ${l10n.pallets}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: l10n.delete,
                              onPressed: () =>
                                  onDeletePoint(point.id, point.clientName),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Edit Point',
                              onPressed: () => onEditPoint(point),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add,
                                  color: Colors.blue),
                              tooltip: l10n.assignDriver,
                              onPressed: () => onAssignDriver(point),
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
