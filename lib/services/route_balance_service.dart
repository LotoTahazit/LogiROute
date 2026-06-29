import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_point.dart';
import '../utils/time_formatter.dart';
import 'route_optimizer.dart';
import 'osrm_navigation_service.dart';
import '../config/app_config.dart';
import 'firestore_paths.dart';

/// Service for balancing delivery routes across drivers.
/// Moves points from overloaded routes to underloaded ones.
class RouteBalanceService {
  final String companyId;

  RouteBalanceService({required this.companyId});

  CollectionReference<Map<String, dynamic>> get _pointsRef =>
      FirestorePaths.deliveryPointsOf(companyId);

  DateTime _pointSortTime(DeliveryPoint point) =>
      point.updatedAt ??
      point.completedAt ??
      point.arrivedAt ??
      point.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String? _selectLatestRouteId(List<DeliveryPoint> points) {
    final byRoute = <String, List<DeliveryPoint>>{};
    for (final point in points) {
      final routeId = point.routeId;
      if (routeId == null || routeId.isEmpty) continue;
      byRoute.putIfAbsent(routeId, () => []).add(point);
    }
    if (byRoute.isEmpty) return null;

    String? bestRouteId;
    DateTime? bestTime;
    for (final entry in byRoute.entries) {
      final latest = entry.value
          .map(_pointSortTime)
          .fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0), (a, b) {
        return a.isAfter(b) ? a : b;
      });
      if (bestTime == null || latest.isAfter(bestTime)) {
        bestTime = latest;
        bestRouteId = entry.key;
      }
    }
    return bestRouteId;
  }

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
        final targetRouteId = _selectLatestRouteId(targetPoints);
        if (targetRouteId == null) continue;

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

    // Re-read from Firestore so recalculation follows actual routeId groups.
    await _recalculateActiveRoutes();

    return movedCount;
  }

  /// Объединяет маршруты одного водителя: активные точки из [sourceRouteIds]
  /// переносятся в [targetRouteId]. Завершённые точки не трогаем.
  Future<int> mergeRoutes({
    required String targetRouteId,
    required Set<String> sourceRouteIds,
  }) async {
    final sources = sourceRouteIds.where((id) => id != targetRouteId).toSet();
    if (sources.isEmpty) return 0;

    final targetSample = await _pointsRef
        .where('routeId', isEqualTo: targetRouteId)
        .limit(1)
        .get();
    if (targetSample.docs.isEmpty) return 0;
    final targetData = targetSample.docs.first.data();
    final driverId = targetData['driverId'] as String? ?? '';
    final driverName = targetData['driverName'] as String? ?? '';
    final driverCapacity = targetData['driverCapacity'];

    final maxOrderQuery = await _pointsRef
        .where('routeId', isEqualTo: targetRouteId)
        .orderBy('orderInRoute', descending: true)
        .limit(1)
        .get();
    var nextOrder = maxOrderQuery.docs.isNotEmpty
        ? ((maxOrderQuery.docs.first.data()['orderInRoute'] as num?)?.toInt() ??
                0) +
            1
        : 0;

    int moved = 0;
    var batch = FirebaseFirestore.instance.batch();
    var batchOps = 0;

    Future<void> flushBatch() async {
      if (batchOps == 0) return;
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      batchOps = 0;
    }

    for (final sourceId in sources) {
      final srcSnap = await _pointsRef
          .where('routeId', isEqualTo: sourceId)
          .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
          .get();

      for (final doc in srcSnap.docs) {
        final data = doc.data();
        if ((data['driverId'] as String? ?? '') != driverId) {
          throw StateError('merge_routes_driver_mismatch');
        }
        batch.update(doc.reference, {
          'routeId': targetRouteId,
          'driverId': driverId,
          'driverName': driverName,
          if (driverCapacity != null) 'driverCapacity': driverCapacity,
          'orderInRoute': nextOrder++,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        moved++;
        batchOps++;
        if (batchOps >= 400) await flushBatch();
      }
    }

    await flushBatch();
    if (moved > 0) await _recalculateActiveRoutes();
    return moved;
  }

  /// Пересчитывает ETA и orderInRoute для списка точек.
  /// [polyline] — если передан, сохраняется в routes документ (без OSRM запроса).
  Future<void> recalculateETAsForPoints(
    List<DeliveryPoint> points, {
    String? polyline,
  }) async {
    const planLat = AppConfig.defaultWarehouseLat;
    const planLng = AppConfig.defaultWarehouseLng;

    double originLat = planLat;
    double originLng = planLng;

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
          originLat,
          originLng,
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Расчёт ETA возврата на склад
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final returnDistKm = RouteOptimizer.calculateDistance(
          lastPoint.latitude, lastPoint.longitude, planLat, planLng);
      final returnTravelMin = (returnDistKm / avgSpeedKmh) * 60;
      cumulativeTimeMinutes += returnTravelMin;
      final returnEta = TimeFormatter.formatArrivalTime(cumulativeTimeMinutes);
      debugPrint('🏭 [RouteBalance] Return ETA: $returnEta');

      // Сохраняем returnEta в routes документ
      final routeId = points.first.routeId;
      if (routeId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('logistics')
              .doc('_root')
              .collection('routes')
              .doc(routeId)
              .set({'returnEta': returnEta}, SetOptions(merge: true));
        } catch (_) {}
      }
    }

    // Сохраняем polyline в routes документ
    final routeId = points.first.routeId;
    if (routeId == null) return;

    String? polylineToSave = polyline;

    // Если polyline не передан — запрашиваем OSRM (для ручной перестановки)
    if (polylineToSave == null || polylineToSave.isEmpty) {
      try {
        final osrm = OsrmNavigationService();
        final waypoints =
            points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
        OsrmRoute? osrmRoute;
        if (waypoints.length <= 1) {
          osrmRoute = await osrm.getRoute(
            startLat: planLat,
            startLng: planLng,
            endLat: waypoints.first['lat']!,
            endLng: waypoints.first['lng']!,
          );
        } else {
          osrmRoute = await osrm.getOptimizedRoute(
            startLat: planLat,
            startLng: planLng,
            waypoints: waypoints,
            endLat: planLat,
            endLng: planLng,
          );
        }
        polylineToSave = osrmRoute?.polyline;
      } catch (e) {
        debugPrint('⚠️ [RouteBalance] OSRM polyline failed: $e');
      }
    }

    if (polylineToSave != null && polylineToSave.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('logistics')
            .doc('_root')
            .collection('routes')
            .doc(routeId)
            .set({'polyline': polylineToSave}, SetOptions(merge: true));
        debugPrint('✅ [RouteBalance] Polyline saved to routes/$routeId');
      } catch (e) {
        debugPrint('⚠️ [RouteBalance] Failed to save polyline: $e');
      }
    }
  }

  Future<void> _recalculateActiveRoutes() async {
    final snapshot = await _pointsRef
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    final byRoute = <String, List<DeliveryPoint>>{};
    for (final doc in snapshot.docs) {
      final point = DeliveryPoint.fromMap(doc.data(), doc.id);
      final routeKey = point.routeId?.isNotEmpty == true
          ? point.routeId!
          : '${point.driverId ?? 'unknown'}:${point.id}';
      byRoute.putIfAbsent(routeKey, () => []).add(point);
    }

    for (final points in byRoute.values) {
      points.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
      await recalculateETAsForPoints(points);
    }
  }
}
