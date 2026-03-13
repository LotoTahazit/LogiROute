import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_point.dart';
import '../utils/time_formatter.dart';
import 'route_optimizer.dart';
import 'osrm_navigation_service.dart';
import '../config/app_config.dart';

/// Service for balancing delivery routes across drivers.
/// Moves points from overloaded routes to underloaded ones.
class RouteBalanceService {
  final String companyId;

  RouteBalanceService({required this.companyId});

  CollectionReference<Map<String, dynamic>> get _pointsRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('delivery_points');

  /// Balances routes by moving points from overloaded to underloaded drivers.
  /// Returns the number of moved points.
  Future<int> balanceRoutes() async {
    final snapshot = await _pointsRef
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    final allPoints = snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();

    final Map<String, List<DeliveryPoint>> byDriver = {};
    for (final p in allPoints) {
      final key = p.driverId ?? 'unknown';
      byDriver.putIfAbsent(key, () => []).add(p);
    }

    if (byDriver.length < 2) return -1; // Signal: already balanced

    final totalPoints = allPoints.length;
    final avgPoints = totalPoints / byDriver.length;

    final overloaded = <String, List<DeliveryPoint>>{};
    final underloaded = <String, List<DeliveryPoint>>{};

    for (final entry in byDriver.entries) {
      if (entry.value.length > avgPoints + 1) {
        overloaded[entry.key] = entry.value;
      } else if (entry.value.length < avgPoints - 1) {
        underloaded[entry.key] = entry.value;
      }
    }

    if (overloaded.isEmpty || underloaded.isEmpty) return -1;

    int movedCount = 0;

    for (final overEntry in overloaded.entries) {
      final overPoints = overEntry.value
        ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

      final excess = overPoints.length - avgPoints.ceil();
      if (excess <= 0) continue;

      final toMove = overPoints.reversed.take(excess.clamp(1, 4)).toList();

      for (final point in toMove) {
        String? targetDriver;
        int minPoints = 999;
        for (final underEntry in byDriver.entries) {
          if (underEntry.key == overEntry.key) continue;
          if (underEntry.value.length < minPoints) {
            minPoints = underEntry.value.length;
            targetDriver = underEntry.key;
          }
        }

        if (targetDriver == null) continue;

        final targetPoints = byDriver[targetDriver]!;
        final targetDriverName = targetPoints.first.driverName ?? '';
        final targetCapacity = targetPoints.first.driverCapacity;
        final targetRouteId = targetPoints.first.routeId;

        // Транзакция для атомарного перемещения точки
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final maxOrderQuery = await _pointsRef
              .where('routeId', isEqualTo: targetRouteId)
              .orderBy('orderInRoute', descending: true)
              .limit(1)
              .get();

          final newOrder = maxOrderQuery.docs.isNotEmpty
              ? ((maxOrderQuery.docs.first.data()['orderInRoute'] as num?)
                          ?.toInt() ??
                      0) +
                  1
              : 0;

          transaction.update(_pointsRef.doc(point.id), {
            'driverId': targetDriver,
            'driverName': targetDriverName,
            'driverCapacity': targetCapacity,
            'routeId': targetRouteId,
            'orderInRoute': newOrder,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        byDriver[overEntry.key]!.remove(point);
        byDriver[targetDriver]!.add(point);
        movedCount++;
      }
    }

    // Recalculate orderInRoute and ETA for all affected routes
    await _recalculateETAs(byDriver);

    return movedCount;
  }

  /// Recalculates order and ETA for a set of reordered points
  Future<void> recalculateETAsForPoints(List<DeliveryPoint> points) async {
    double cumulativeTimeMinutes = 0;
    const double avgSpeedKmh = 38.0;
    const double serviceTimeMinutes = 7.0;
    const double parkingTimeMinutes = 2.0;

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      double distanceKm = 0;
      if (i == 0) {
        distanceKm = RouteOptimizer.calculateDistance(
          32.48698,
          34.982121,
          point.latitude,
          point.longitude,
        );
      } else {
        final prev = points[i - 1];
        distanceKm = RouteOptimizer.calculateDistance(
          prev.latitude,
          prev.longitude,
          point.latitude,
          point.longitude,
        );
      }

      final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
      cumulativeTimeMinutes +=
          travelTimeMinutes + serviceTimeMinutes + parkingTimeMinutes;
      final eta = TimeFormatter.formatArrivalTime(cumulativeTimeMinutes);

      batch.update(_pointsRef.doc(point.id), {
        'orderInRoute': i,
        'eta': eta,
        'distanceKm': double.parse(distanceKm.toStringAsFixed(1)),
      });
    }

    await batch.commit();

    // 🗺️ Обновляем кешированную полилинию после перестановки
    try {
      final warehouseLat = AppConfig.defaultWarehouseLat;
      final warehouseLng = AppConfig.defaultWarehouseLng;
      final osrm = OsrmNavigationService();

      final waypoints =
          points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

      OsrmRoute? osrmRoute;
      if (waypoints.length <= 1) {
        osrmRoute = await osrm.getRoute(
          startLat: warehouseLat,
          startLng: warehouseLng,
          endLat: waypoints.first['lat']!,
          endLng: waypoints.first['lng']!,
        );
      } else {
        final endWp = waypoints.removeLast();
        osrmRoute = await osrm.getOptimizedRoute(
          startLat: warehouseLat,
          startLng: warehouseLng,
          waypoints: waypoints,
          endLat: endWp['lat']!,
          endLng: endWp['lng']!,
        );
      }

      if (osrmRoute != null && osrmRoute.polyline.isNotEmpty) {
        // Сохраняем polyline в routes документ
        final routeId = points.first.routeId;
        if (routeId != null) {
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('logistics')
              .doc('_root')
              .collection('routes')
              .doc(routeId)
              .set({'polyline': osrmRoute.polyline}, SetOptions(merge: true));
        }
        debugPrint('✅ [RouteBalance] Polyline saved to routes/$routeId');
      }
    } catch (e) {
      debugPrint('⚠️ [RouteBalance] Failed to update polyline cache: $e');
    }
  }

  Future<void> _recalculateETAs(
      Map<String, List<DeliveryPoint>> byDriver) async {
    for (final entry in byDriver.entries) {
      final points = entry.value
        ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
      await recalculateETAsForPoints(points);
    }
  }
}
