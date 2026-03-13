import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../services/print_service.dart';
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
  final Function(DeliveryPoint point) onRemovePoint;
  final Function(DeliveryPoint point)? onReopenPoint;
  final VoidCallback? onBalanceRoutes;

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
    required this.onRemovePoint,
    this.onReopenPoint,
    this.onBalanceRoutes,
  });

  String _getDisplayAddress(DeliveryPoint point) {
    if (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) {
      return point.temporaryAddress!;
    }
    return point.address;
  }

  /// Генерирует рекомендации по объединению миштахов
  /// Советы ТОЛЬКО когда totalPallets > driverCapacity (не влезает)
  Map<String, dynamic> _buildPalletAdvice(
      List<DeliveryPoint> routePoints, AppLocalizations l10n) {
    final totalPallets = routePoints.fold(0, (sum, r) => sum + r.pallets);
    final driverCapacity = routePoints.first.driverCapacity ?? 0;

    // Если вмещается или вместимость неизвестна — не даём советов
    if (driverCapacity == 0 || totalPallets <= driverCapacity) {
      return {
        'advice': <String>[],
        'saved': 0,
        'total': totalPallets,
        'optimized': totalPallets,
      };
    }

    // Находим точки с неполными миштахами
    // Используем boxTypes для точного расчёта остатков
    final List<Map<String, dynamic>> pointsWithRemainder = [];
    for (int i = 0; i < routePoints.length; i++) {
      final p = routePoints[i];
      if (p.boxes > 0 && p.pallets > 0) {
        // Остаток = boxes - (fullPallets * среднее кол-во на миштах)
        // Но точнее: если pallets > 0 и boxes < pallets * 20, значит есть неполный
        // Простая эвристика: если boxes % 20 != 0 и boxes < pallets * 20
        final remainder = p.boxes % 20;
        if (remainder > 0 && remainder < 20) {
          pointsWithRemainder.add({
            'index': i,
            'point': p,
            'remainder': remainder,
          });
        }
      }
    }

    final List<String> advice = [];
    int savedPallets = 0;

    if (pointsWithRemainder.length < 2) {
      return {
        'advice': advice,
        'saved': 0,
        'total': totalPallets,
        'optimized': totalPallets,
      };
    }

    // Жадный алгоритм: объединяем остатки в группы по ≤20 коробок
    // Сначала сортируем по убыванию остатка (bin-packing first-fit decreasing)
    final sorted = List<Map<String, dynamic>>.from(pointsWithRemainder)
      ..sort(
          (a, b) => (b['remainder'] as int).compareTo(a['remainder'] as int));

    final List<List<Map<String, dynamic>>> combinedGroups = [];
    final List<int> groupTotals = [];
    final Set<int> assigned = {};

    for (final item in sorted) {
      final r = item['remainder'] as int;
      bool placed = false;
      // Пытаемся добавить в существующую группу
      for (int g = 0; g < combinedGroups.length; g++) {
        if (groupTotals[g] + r <= 20) {
          combinedGroups[g].add(item);
          groupTotals[g] += r;
          placed = true;
          break;
        }
      }
      if (!placed) {
        combinedGroups.add([item]);
        groupTotals.add(r);
      }
      assigned.add(item['index'] as int);
    }

    // Считаем экономию и формируем советы
    for (final group in combinedGroups) {
      if (group.length >= 2) {
        // Эта группа объединяет N точек в 1 миштах → экономия N-1
        final saved = group.length - 1;
        savedPallets += saved;

        // Проверяем соседние ли точки
        final indices = group.map((g) => g['index'] as int).toList()..sort();
        bool allAdjacent = true;
        for (int k = 1; k < indices.length; k++) {
          if (indices[k] - indices[k - 1] != 1) {
            allAdjacent = false;
            break;
          }
        }

        final names = group
            .map((g) =>
                '${(g['point'] as DeliveryPoint).clientName} (${g['remainder']})')
            .join(' + ');

        if (allAdjacent) {
          advice.add('✅ ${l10n.canCombineAdjacent(names)}');
        } else {
          advice.add('⚠️ ${l10n.canCombineDistant(names)}');
        }
      }
    }

    return {
      'advice': advice,
      'saved': savedPallets,
      'total': totalPallets,
      'optimized': totalPallets - savedPallets,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final allRoutes = routes.isNotEmpty ? routes : lastNonEmptyRoutes;

    // Группируем по driverId (один водитель = один маршрут)
    final Map<String, List<DeliveryPoint>> routesByRouteId = {};
    for (final route in allRoutes) {
      final routeKey = route.driverId ?? route.routeId ?? 'unknown';
      routesByRouteId.putIfAbsent(routeKey, () => []).add(route);
    }

    // Сортируем точки внутри каждого маршрута по orderInRoute
    for (final points in routesByRouteId.values) {
      points.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
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
      final driverCap = routePoints.first.driverCapacity ?? 0;

      final hasInProgressPoints =
          routePoints.any((r) => r.status == 'in_progress');
      final routeStatus = hasInProgressPoints ? 'in_progress' : 'assigned';

      // Цвет загрузки маршрута: 🟢 ≤80%  🟡 80–100%  🔴 >100%
      final loadRatio = driverCap > 0 ? totalPallets / driverCap : 0.0;
      final loadColor = loadRatio > 1.0
          ? Colors.red
          : loadRatio > 0.8
              ? Colors.orange
              : Colors.green;

      // Рассчитываем совет один раз для subtitle и body
      final adviceData = _buildPalletAdvice(routePoints, l10n);
      final saved = adviceData['saved'] as int;
      final optimized = adviceData['optimized'] as int;
      final adviceList = adviceData['advice'] as List<String>;
      final overCapacity = driverCap > 0 && totalPallets > driverCap;

      // Subtitle: показываем экономию только если есть советы
      final palletText = saved > 0
          ? '$totalPallets → $optimized ${l10n.pallets} (${l10n.savingPallets(saved.toString())})'
          : '$totalPallets ${l10n.pallets}';

      // Общий километраж маршрута
      final totalKm = routePoints.fold<double>(
          0.0, (sum, r) => sum + (r.distanceKm ?? 0.0));
      final kmText =
          totalKm > 0 ? ' • ${totalKm.toStringAsFixed(1)} ${l10n.km}' : '';

      return Card(
        margin: const EdgeInsets.all(8),
        child: ExpansionTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loadColor,
            ),
          ),
          title: Text(
            driverName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${routePoints.length} ${l10n.points} • $palletText$kmText • ${routeStatus == 'in_progress' ? l10n.active : l10n.assigned}',
          ),
          children: [
            // Совет по укладке — когда не влезает в грузовик
            if (overCapacity)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: optimized > driverCap
                      ? Colors.red.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: optimized > driverCap
                        ? Colors.red.shade200
                        : Colors.amber.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18,
                            color: optimized > driverCap
                                ? Colors.red
                                : Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          l10n.loadingAdvice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: optimized > driverCap
                                ? Colors.red.shade800
                                : Colors.amber.shade900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.capacityLabel(driverCap.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: optimized > driverCap
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (optimized > driverCap)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⛔ ${l10n.overCapacity(optimized.toString(), driverCap.toString())}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...adviceList.map((a) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(a, style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                ),
              ),
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
                  tooltip: l10n.printAllInvoicesTooltip,
                  onPressed: () => onPrintAllInvoices(routePoints),
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.teal),
                  tooltip: l10n.pickingListTooltip,
                  onPressed: () => PrintService.printPickingList(
                    points: routePoints,
                    driverName: driverName,
                  ),
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
                          if (r.eta != null && r.eta!.isNotEmpty ||
                              r.distanceKm != null && r.distanceKm! > 0)
                            Text(
                              [
                                if (r.distanceKm != null && r.distanceKm! > 0)
                                  '${r.distanceKm!.toStringAsFixed(1)} ${l10n.km}',
                                if (r.eta != null && r.eta!.isNotEmpty)
                                  'ETA: ${r.eta}',
                              ].join(' • '),
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                            tooltip: l10n.createInvoiceTooltip,
                            onPressed: () => onCreateInvoice(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.local_shipping,
                                color: Colors.blue),
                            tooltip: l10n.createDeliveryNoteTooltip,
                            onPressed: () => onCreateDeliveryNote(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: l10n.edit,
                            onPressed: () => onEditPoint(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            tooltip: l10n.removeFromRoute,
                            onPressed: () => onRemovePoint(r),
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
        // Кнопка балансировки маршрутов
        if (onBalanceRoutes != null && routesByRouteId.length >= 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: onBalanceRoutes,
              icon: const Icon(Icons.balance, size: 20),
              label: Text(l10n.balanceRoutes),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (autoCompletedPoints.isNotEmpty && onReopenPoint != null)
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.orange.shade50,
            child: ExpansionTile(
              leading: Icon(Icons.history, color: Colors.orange.shade700),
              title: Text(
                l10n.autoCompletedPointsTitle(autoCompletedPoints.length),
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
                        label: Text(l10n.reopenPoint),
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
