import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../services/print_service.dart';
import '../../../services/route_service.dart';
import '../../../l10n/app_localizations.dart';

/// Вкладка с активными маршрутами
class ActiveRoutesTab extends StatelessWidget {
  final String companyId;
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
  final void Function(DeliveryPoint point)? onCompletePointManually;
  final VoidCallback? onBalanceRoutes;
  final Function(String driverId, String? routeId, List<DeliveryPoint> points)?
      onOptimizeRoute;

  const ActiveRoutesTab({
    super.key,
    required this.companyId,
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
    this.onCompletePointManually,
    this.onBalanceRoutes,
    this.onOptimizeRoute,
  });

  bool _isAssignedOrInProgress(DeliveryPoint p) {
    final s = DeliveryPoint.normalizeStatus(p.status);
    return s == DeliveryPoint.statusAssigned ||
        s == DeliveryPoint.statusInProgress;
  }

  bool _isClosed(DeliveryPoint p) {
    final s = DeliveryPoint.normalizeStatus(p.status);
    return s == DeliveryPoint.statusCompleted ||
        s == DeliveryPoint.statusCancelled;
  }

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

    // Use live routes; fallback to cached only if live is empty.
    // Cache keeps completed points too, so the route does not visually shrink.
    final allRoutes = routes.isNotEmpty ? routes : lastNonEmptyRoutes;

    // Группируем по routeId, чтобы новый маршрут того же водителя не склеивался со старым.
    final Map<String, List<DeliveryPoint>> routesByRouteId = {};
    for (final route in allRoutes) {
      final routeKey = route.routeId ?? route.driverId ?? 'unknown';
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
      final allClosed = routePoints.every(_isClosed);
      final routeStatus = allClosed
          ? DeliveryPoint.statusCompleted
          : hasInProgressPoints
              ? 'in_progress'
              : 'assigned';

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
            '${routePoints.length} ${l10n.points} • $palletText$kmText • ${routeStatus == DeliveryPoint.statusCompleted ? l10n.statusCompleted : routeStatus == 'in_progress' ? l10n.active : l10n.assigned}',
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (onOptimizeRoute != null &&
                    routePoints
                            .where((p) =>
                                p.status != 'completed' &&
                                p.status != 'cancelled')
                            .length >=
                        2)
                  _OptimizeTimeButton(
                    companyId: companyId,
                    routePoints: routePoints,
                    driverId: driverId,
                    routeId: routeId,
                    onOptimizeRoute: onOptimizeRoute!,
                    l10n: l10n,
                  ),
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
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) async {
                await onReorderPoints(routePoints, oldIndex, newIndex);
              },
              children: routePoints.asMap().entries.map(
                (entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isClosed = _isClosed(r);
                  final actionButtons = <Widget>[
                    if (!isClosed &&
                        onCompletePointManually != null &&
                        _isAssignedOrInProgress(r))
                      IconButton(
                        icon: const Icon(Icons.task_alt, color: Colors.green),
                        tooltip: l10n.dispatcherManualCompleteTooltip,
                        onPressed: () => onCompletePointManually!(r),
                      ),
                    if (!isClosed) ...[
                      IconButton(
                        icon: const Icon(Icons.receipt, color: Colors.green),
                        tooltip: l10n.createInvoiceTooltip,
                        onPressed: () => onCreateInvoice(r),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.local_shipping, color: Colors.blue),
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
                  ];

                  final pointText = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.clientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isClosed ? Colors.grey.shade700 : null,
                          decoration: isClosed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.pallets} ${l10n.pallets}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getDisplayAddress(r),
                        style: TextStyle(
                          color: isClosed
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (r.eta != null && r.eta!.isNotEmpty ||
                          r.distanceKm != null && r.distanceKm! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (r.distanceKm != null && r.distanceKm! > 0)
                                '${r.distanceKm!.toStringAsFixed(1)} ${l10n.km}',
                              if (r.eta != null && r.eta!.isNotEmpty)
                                'ETA: ${r.eta}',
                            ].join(' • '),
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                    ],
                  );

                  return Opacity(
                    key: ValueKey(r.id),
                    opacity: isClosed ? 0.38 : 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 640;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isClosed)
                                    ReorderableDragStartListener(
                                      index: idx,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.grab,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 8),
                                          child: Icon(Icons.drag_handle,
                                              color: Colors.grey.shade400,
                                              size: 24),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 32),
                                  CircleAvatar(
                                    backgroundColor: isClosed
                                        ? Colors.grey.shade500
                                        : Colors.blue,
                                    child: Text(
                                      '${r.orderInRoute + 1}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: pointText),
                                  if (!isNarrow && actionButtons.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: actionButtons,
                                    ),
                                ],
                              ),
                              if (isNarrow && actionButtons.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: actionButtons,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ).toList(),
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

/// Кнопка «Оптимизировать время»: подсвечивается только при неоптимальном порядке.
class _OptimizeTimeButton extends StatefulWidget {
  final String companyId;
  final List<DeliveryPoint> routePoints;
  final String driverId;
  final String? routeId;
  final void Function(String, String?, List<DeliveryPoint>) onOptimizeRoute;
  final AppLocalizations l10n;

  const _OptimizeTimeButton({
    required this.companyId,
    required this.routePoints,
    required this.driverId,
    required this.routeId,
    required this.onOptimizeRoute,
    required this.l10n,
  });

  @override
  State<_OptimizeTimeButton> createState() => _OptimizeTimeButtonState();
}

class _OptimizeTimeButtonState extends State<_OptimizeTimeButton> {
  bool? _isSuboptimal;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(_OptimizeTimeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isSuboptimal = null;
    _check();
  }

  Future<void> _check() async {
    final suboptimal = await RouteService(companyId: widget.companyId)
        .isRouteOrderSuboptimal(widget.routePoints);
    if (mounted) setState(() => _isSuboptimal = suboptimal);
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _isSuboptimal == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (highlight)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.l10n.routeTimeNotOptimal,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        Material(
          color: highlight ? Colors.orange.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onOptimizeRoute(
                widget.driverId, widget.routeId, widget.routePoints),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: highlight
                        ? Colors.orange.shade800
                        : Colors.grey.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.l10n.optimizeTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? Colors.orange.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
