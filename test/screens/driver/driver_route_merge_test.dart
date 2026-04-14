import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/delivery_point.dart';

/// Regression tests for driver dashboard route merge logic.
///
/// BUG: When all points in a route are completed, the stats showed 0/0/0
/// because the merge pipeline lost all data. This happened through:
///   1) _filterDriverPointsToCurrentRoute set _visibleRouteKey = null
///   2) _mergeVisibleRoutePoints skipped all local points (routeKey != null)
///   3) _lastPoints was overwritten with empty list
///
/// FIX: Three layers of protection:
///   1) Don't reset _visibleRouteKey when incoming is empty
///   2) Preserve _lastPoints when incoming is empty but we have completed data
///   3) StreamBuilder guard: never wipe _lastPoints with empty when non-empty

// === Helpers that mirror driver_dashboard.dart logic ===

bool isClosedPoint(DeliveryPoint point) {
  final status = DeliveryPoint.normalizeStatus(point.status);
  return status == DeliveryPoint.statusCompleted ||
      status == DeliveryPoint.statusCancelled;
}

bool isActiveRoutePoint(DeliveryPoint point) {
  final status = DeliveryPoint.normalizeStatus(point.status);
  return status == DeliveryPoint.statusAssigned ||
      status == DeliveryPoint.statusInProgress;
}

String routeKeyForPoint(DeliveryPoint point) =>
    point.routeId?.isNotEmpty == true
        ? point.routeId!
        : '__driver__${point.driverId ?? ''}';

String? selectCurrentRouteKey(
  List<DeliveryPoint> points, {
  String? preferredRouteKey,
}) {
  if (points.isEmpty) return null;

  final byRoute = <String, List<DeliveryPoint>>{};
  for (final point in points) {
    byRoute.putIfAbsent(routeKeyForPoint(point), () => []).add(point);
  }

  if (preferredRouteKey != null && byRoute.containsKey(preferredRouteKey)) {
    return preferredRouteKey;
  }

  String? bestKey;
  DateTime? bestTime;

  void consider(String key, List<DeliveryPoint> group) {
    final latest = group
        .map((p) =>
            p.updatedAt ?? p.completedAt ?? p.createdAt ?? DateTime(1970))
        .fold<DateTime>(DateTime(1970), (a, b) => a.isAfter(b) ? a : b);
    if (bestTime == null || latest.isAfter(bestTime!)) {
      bestTime = latest;
      bestKey = key;
    }
  }

  for (final entry in byRoute.entries) {
    if (entry.value.any(isActiveRoutePoint)) {
      consider(entry.key, entry.value);
    }
  }
  if (bestKey != null) return bestKey;

  for (final entry in byRoute.entries) {
    consider(entry.key, entry.value);
  }
  return bestKey;
}

/// Mirrors _filterDriverPointsToCurrentRoute (FIXED version)
(List<DeliveryPoint>, String?) filterDriverPointsToCurrentRoute(
  List<DeliveryPoint> points,
  String? visibleRouteKey,
) {
  final currentRouteKey = selectCurrentRouteKey(
    points,
    preferredRouteKey: visibleRouteKey,
  );
  if (currentRouteKey == null) {
    // FIX: НЕ сбрасываем visibleRouteKey
    return ([], visibleRouteKey);
  }

  final filtered = points
      .where((point) => routeKeyForPoint(point) == currentRouteKey)
      .toList()
    ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
  return (filtered, currentRouteKey);
}

/// Mirrors _mergeVisibleRoutePoints (FIXED version)
List<DeliveryPoint> mergeVisibleRoutePoints(
  List<DeliveryPoint> incomingPoints,
  List<DeliveryPoint> lastPoints,
  String? visibleRouteKey,
) {
  if (lastPoints.isEmpty) return incomingPoints;

  // FIX: incoming пуст, но есть данные — сохраняем
  if (incomingPoints.isEmpty && visibleRouteKey != null) {
    return List.of(lastPoints);
  }

  final incomingById = {
    for (final point in incomingPoints) point.id: point,
  };
  final merged = <DeliveryPoint>[];

  for (final incoming in incomingPoints) {
    merged.add(incoming);
  }

  for (final local in lastPoints) {
    if (incomingById.containsKey(local.id)) continue;
    if (routeKeyForPoint(local) != visibleRouteKey) continue;
    if (isClosedPoint(local)) {
      merged.add(local);
    }
  }

  merged.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
  return merged;
}

/// Full pipeline: filter → merge → guard
List<DeliveryPoint> fullPipeline(
  List<DeliveryPoint> incomingPoints,
  List<DeliveryPoint> lastPoints,
  String? visibleRouteKey,
) {
  final (routePoints, updatedKey) =
      filterDriverPointsToCurrentRoute(incomingPoints, visibleRouteKey);
  var points = mergeVisibleRoutePoints(routePoints, lastPoints, updatedKey);

  // StreamBuilder guard
  if (points.isNotEmpty || lastPoints.isEmpty) {
    return points;
  } else {
    return lastPoints;
  }
}

// === Test data ===

DeliveryPoint _point(
  String id, {
  String status = 'assigned',
  String routeId = 'driver1_2026_4_12',
  int order = 0,
  DateTime? completedAt,
  DateTime? updatedAt,
}) {
  return DeliveryPoint(
    id: id,
    companyId: 'test_company',
    address: 'Test Address $id',
    latitude: 32.0 + order * 0.01,
    longitude: 34.0 + order * 0.01,
    clientName: 'Client $id',
    urgency: 'normal',
    pallets: 1,
    boxes: 0,
    status: status,
    routeId: routeId,
    orderInRoute: order,
    completedAt: completedAt,
    updatedAt: updatedAt,
    driverId: 'driver1',
  );
}

void main() {
  group('Driver route merge — 0/0/0 regression tests', () {
    final now = DateTime.now();

    test('Completed route keeps data when stream returns empty', () {
      // Setup: 3 completed points from a finished route
      final completedPoints = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2',
            status: 'completed', order: 1, completedAt: now, updatedAt: now),
        _point('p3',
            status: 'completed', order: 2, completedAt: now, updatedAt: now),
      ];

      // Stream returns empty (the bug trigger)
      final result = fullPipeline(
        [], // incoming: empty
        completedPoints, // lastPoints: completed route
        'driver1_2026_4_12', // visibleRouteKey: set
      );

      // MUST NOT be empty — this is the 0/0/0 bug
      expect(result, isNotEmpty,
          reason: 'Completed route data must be preserved');
      expect(result.length, 3);
      expect(result.every(isClosedPoint), true);
    });

    test('Completed route keeps data when stream returns completed points', () {
      final completedPoints = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2',
            status: 'completed', order: 1, completedAt: now, updatedAt: now),
        _point('p3',
            status: 'completed', order: 2, completedAt: now, updatedAt: now),
      ];

      // Stream returns same completed points (normal case)
      final result = fullPipeline(
        completedPoints,
        completedPoints,
        'driver1_2026_4_12',
      );

      expect(result.length, 3);
      expect(result.every(isClosedPoint), true);
    });

    test('Active route shows correct stats during delivery', () {
      final mixedPoints = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2', status: 'in_progress', order: 1, updatedAt: now),
        _point('p3', status: 'assigned', order: 2),
      ];

      final result = fullPipeline(
        mixedPoints,
        [],
        null,
      );

      expect(result.length, 3);
      final completed = result.where(isClosedPoint).length;
      final active = result.where(isActiveRoutePoint).length;
      expect(completed, 1);
      expect(active, 2);
    });

    test('Last point completed does not wipe stats', () {
      // Before: 2 completed, 1 active
      final lastPoints = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2',
            status: 'completed', order: 1, completedAt: now, updatedAt: now),
        _point('p3', status: 'in_progress', order: 2, updatedAt: now),
      ];

      // Stream fires: all 3 now completed
      final incoming = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2',
            status: 'completed', order: 1, completedAt: now, updatedAt: now),
        _point('p3',
            status: 'completed', order: 2, completedAt: now, updatedAt: now),
      ];

      final result = fullPipeline(
        incoming,
        lastPoints,
        'driver1_2026_4_12',
      );

      expect(result.length, 3, reason: 'All 3 completed points must show');
      expect(result.every(isClosedPoint), true);
    });

    test('Empty incoming + empty lastPoints = empty (new day, no routes)', () {
      final result = fullPipeline([], [], null);
      expect(result, isEmpty);
    });

    test('_visibleRouteKey preserved when incoming is empty', () {
      const routeKey = 'driver1_2026_4_12';
      final (_, updatedKey) = filterDriverPointsToCurrentRoute([], routeKey);
      expect(updatedKey, routeKey,
          reason: '_visibleRouteKey must NOT be reset to null');
    });

    test('Multiple stream emissions with empty data preserve route', () {
      final completedPoints = [
        _point('p1',
            status: 'completed', order: 0, completedAt: now, updatedAt: now),
        _point('p2',
            status: 'completed', order: 1, completedAt: now, updatedAt: now),
      ];

      // First emission: empty
      var result = fullPipeline([], completedPoints, 'driver1_2026_4_12');
      expect(result.length, 2, reason: 'First empty emission: data preserved');

      // Second emission: still empty
      result = fullPipeline([], result, 'driver1_2026_4_12');
      expect(result.length, 2, reason: 'Second empty emission: data preserved');

      // Third emission: still empty
      result = fullPipeline([], result, 'driver1_2026_4_12');
      expect(result.length, 2, reason: 'Third empty emission: data preserved');
    });
  });
}
