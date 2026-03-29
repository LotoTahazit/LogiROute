import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';

/// Панель загрузки водителей — показывает capacity %, палеты, ETA, статус
/// Используется в диспетчерской для быстрого обзора всех водителей
class DriverWorkloadPanel extends StatelessWidget {
  final List<DeliveryPoint> routes;
  final List<UserModel> drivers;

  const DriverWorkloadPanel({
    super.key,
    required this.routes,
    required this.drivers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Группируем по routeId, чтобы completed старого маршрута не смешивались
    // с active точками нового маршрута того же водителя.
    final Map<String, List<DeliveryPoint>> byRoute = {};
    for (final point in routes) {
      if (point.driverId == null || point.driverId!.isEmpty) continue;
      final routeKey = point.routeId ?? point.driverId!;
      byRoute.putIfAbsent(routeKey, () => []).add(point);
    }

    final routeGroups = byRoute.values.toList()
      ..sort((a, b) {
        final ao = a.map((p) => p.orderInRoute).fold<int>(0, (x, y) => x + y);
        final bo = b.map((p) => p.orderInRoute).fold<int>(0, (x, y) => x + y);
        return ao.compareTo(bo);
      });

    if (routeGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.noActivePoints,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: routeGroups.length,
        itemBuilder: (context, index) {
          final points = List<DeliveryPoint>.from(routeGroups[index])
            ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
          final driver = drivers.firstWhere(
            (d) => d.uid == (points.first.driverId ?? ''),
            orElse: () => UserModel(
              uid: points.first.driverId ?? '',
              email: '',
              name: points.first.driverName ?? l10n.unknownDriver,
              role: 'driver',
              vehicleNumber: '',
            ),
          );
          return _DriverCard(driver: driver, points: points, l10n: l10n);
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final UserModel driver;
  final List<DeliveryPoint> points;
  final AppLocalizations l10n;

  const _DriverCard({
    required this.driver,
    required this.points,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final capacity = driver.palletCapacity ?? 0;
    final totalPallets = points.fold(0, (sum, p) => sum + p.pallets);
    final completedCount = points
        .where(
          (p) =>
              p.status == DeliveryPoint.statusCompleted ||
              p.status == DeliveryPoint.statusCancelled,
        )
        .length;
    final totalCount = points.length;
    final ratio = capacity > 0 ? totalPallets / capacity : 0.0;

    // Цвет по загрузке
    final Color loadColor;
    if (ratio > 1.0) {
      loadColor = Colors.red;
    } else if (ratio > 0.8) {
      loadColor = Colors.orange;
    } else {
      loadColor = Colors.green;
    }

    // Ближайший ETA
    final nextEta = _getNextEta();

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: loadColor.withValues(alpha: (loadColor.a * 0.4).clamp(0.0, 1.0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Имя + статус
          Row(
            children: [
              Icon(Icons.local_shipping, size: 16, color: loadColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(loadColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalPallets${capacity > 0 ? "/$capacity" : ""} ${l10n.pallets}',
                style: TextStyle(
                  fontSize: 10,
                  color: loadColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completedCount/$totalCount ✓',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          // ETA
          if (nextEta != null)
            Text(
              'ETA: $nextEta',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String? _getNextEta() {
    try {
      final nextActive = points.firstWhere(
        (p) =>
            p.status != DeliveryPoint.statusCompleted &&
            p.status != DeliveryPoint.statusCancelled,
      );
      return nextActive.eta;
    } catch (_) {
      return null;
    }
  }
}
