import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../l10n/app_localizations.dart';

/// Вкладка с активными маршрутами
class ActiveRoutesTab extends StatelessWidget {
  final List<DeliveryPoint> routes;
  final List<DeliveryPoint> lastNonEmptyRoutes;
  final List<DeliveryPoint> autoCompletedPoints;
  final Function(String driverId, String driverName, String? routeId)
      onChangeDriver;
  final Function(String driverId, String? routeId) onCancelRoute;
  final Function(List<DeliveryPoint> routes) onPrintRoute;
  final Function(List<DeliveryPoint> routes, int oldIndex, int newIndex)
      onReorderPoints;
  final Function(DeliveryPoint point) onCreateInvoice;
  final Function(DeliveryPoint point) onCreateDeliveryNote;
  final Function(List<DeliveryPoint> routePoints) onPrintAllInvoices;
  final Function(DeliveryPoint point) onEditPoint;
  final Function(DeliveryPoint point)? onReopenPoint;

  const ActiveRoutesTab({
    super.key,
    required this.routes,
    required this.lastNonEmptyRoutes,
    this.autoCompletedPoints = const [],
    required this.onChangeDriver,
    required this.onCancelRoute,
    required this.onPrintRoute,
    required this.onReorderPoints,
    required this.onCreateInvoice,
    required this.onCreateDeliveryNote,
    required this.onPrintAllInvoices,
    required this.onEditPoint,
    this.onReopenPoint,
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

    final allRoutes = routes.isNotEmpty ? routes : lastNonEmptyRoutes;

    // Группируем по routeId или driverId
    final Map<String, List<DeliveryPoint>> routesByRouteId = {};
    for (final route in allRoutes) {
      final routeKey = route.routeId ?? route.driverId ?? 'unknown';
      routesByRouteId.putIfAbsent(routeKey, () => []).add(route);
    }

    if (routesByRouteId.isEmpty) {
      return Center(child: Text(l10n.noRoutesYet));
    }

    final routeCards = routesByRouteId.entries.map((entry) {
      final routePoints = entry.value;
      final driverId = routePoints.first.driverId ?? '';
      final routeId = routePoints.first.routeId;
      final driverName = routePoints.first.driverName ?? l10n.unknownDriver;
      final totalPallets = routePoints.fold(0, (sum, r) => sum + r.pallets);

      final hasInProgressPoints =
          routePoints.any((r) => r.status == 'in_progress');
      final routeStatus = hasInProgressPoints ? 'in_progress' : 'assigned';

      return Card(
        margin: const EdgeInsets.all(8),
        child: ExpansionTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  routeStatus == 'in_progress' ? Colors.green : Colors.orange,
            ),
          ),
          title: Text(
            driverName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${routePoints.length} ${l10n.points} • $totalPallets ${l10n.pallets} • ${routeStatus == 'in_progress' ? l10n.active : l10n.assigned}',
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: l10n.changeDriver,
                  onPressed: () =>
                      onChangeDriver(driverId, driverName, routeId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  tooltip: l10n.cancelRoute,
                  onPressed: () => onCancelRoute(driverId, routeId),
                ),
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: l10n.printRoute,
                  onPressed: () => onPrintRoute(routePoints),
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long, color: Colors.green),
                  tooltip: 'הדפס כל החשבוניות',
                  onPressed: () => onPrintAllInvoices(routePoints),
                ),
              ],
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) async {
                await onReorderPoints(routePoints, oldIndex, newIndex);
              },
              children: routePoints
                  .map(
                    (r) => ListTile(
                      key: ValueKey(r.id),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          '${r.orderInRoute + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(r.clientName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.pallets} ${l10n.pallets} • ${_getDisplayAddress(r)}',
                          ),
                          if (r.eta != null && r.eta!.isNotEmpty)
                            Text(
                              'ETA: ${r.eta}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.receipt, color: Colors.green),
                            tooltip: 'צור חשבונית',
                            onPressed: () => onCreateInvoice(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.local_shipping,
                                color: Colors.blue),
                            tooltip: 'צור תעודת משלוח',
                            onPressed: () => onCreateDeliveryNote(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Edit Point',
                            onPressed: () => onEditPoint(r),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }).toList();

    return ListView(
      children: [
        // Автозакрытые точки — секция для переоткрытия
        if (autoCompletedPoints.isNotEmpty && onReopenPoint != null)
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.orange.shade50,
            child: ExpansionTile(
              leading: Icon(Icons.history, color: Colors.orange.shade700),
              title: Text(
                'נקודות שנסגרו אוטומטית (${autoCompletedPoints.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              children: autoCompletedPoints
                  .map(
                    (p) => ListTile(
                      leading:
                          Icon(Icons.check_circle, color: Colors.grey.shade400),
                      title: Text(p.clientName),
                      subtitle: Text(
                        '${p.driverName ?? ""} • ${_getDisplayAddress(p)}',
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('החזר'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                        ),
                        onPressed: () => onReopenPoint!(p),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ...routeCards,
      ],
    );
  }
}
