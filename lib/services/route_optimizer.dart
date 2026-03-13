import 'dart:math' as math;
import '../models/delivery_point.dart';
import '../config/app_config.dart';

/// Route optimization algorithms: nearest-neighbor with urgency priority,
/// distance calculation (Haversine), alternative route generation.
class RouteOptimizer {
  /// Nearest-neighbor optimization with urgency priority
  static List<DeliveryPoint> optimizeRouteOrder(
      List<DeliveryPoint> points, Map<String, double>? driverLocation) {
    if (points.length <= 1) return points;

    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
      print('📍 [RouteOptimizer] Using driver location: ($baseLat, $baseLng)');
    } else {
      print(
          '📍 [RouteOptimizer] Using warehouse location: ($baseLat, $baseLng)');
    }

    // Split by priority
    final urgentPoints = points.where((p) => p.urgency == 'urgent').toList();
    final normalPoints = points.where((p) => p.urgency != 'urgent').toList();

    // Sort urgent by opening time then distance
    urgentPoints.sort((a, b) {
      if (a.openingTime != null && b.openingTime != null) {
        final timeCompare = a.openingTime!.compareTo(b.openingTime!);
        if (timeCompare != 0) return timeCompare;
      }
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    normalPoints.sort((a, b) {
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    // Nearest-neighbor with 20% urgency bonus
    final optimizedOrder = <DeliveryPoint>[];
    final remainingPoints =
        List<DeliveryPoint>.from([...urgentPoints, ...normalPoints]);

    double currentLat = baseLat;
    double currentLng = baseLng;

    while (remainingPoints.isNotEmpty) {
      DeliveryPoint? nextPoint;
      double minScore = double.infinity;
      int nextIndex = -1;

      for (int i = 0; i < remainingPoints.length; i++) {
        final p = remainingPoints[i];
        final dist =
            calculateDistance(currentLat, currentLng, p.latitude, p.longitude);
        final score = p.urgency == 'urgent' ? dist * 0.8 : dist;

        if (score < minScore) {
          minScore = score;
          nextPoint = p;
          nextIndex = i;
        }
      }

      if (nextPoint != null) {
        optimizedOrder.add(nextPoint);
        currentLat = nextPoint.latitude;
        currentLng = nextPoint.longitude;
        remainingPoints.removeAt(nextIndex);
      } else {
        break;
      }
    }

    print('🎯 [RouteOptimizer] Route optimization complete:');
    for (int i = 0; i < optimizedOrder.length; i++) {
      final point = optimizedOrder[i];
      print(
          '  ${i + 1}. ${point.clientName} (${point.urgency == 'urgent' ? 'URGENT' : 'normal'})');
    }

    return optimizedOrder;
  }

  /// Alternative route: simple distance sort from base
  static List<DeliveryPoint> createAlternativeRoute(
      List<DeliveryPoint> points, Map<String, double>? driverLocation) {
    if (points.length <= 1) return points;

    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
    }

    final sortedPoints = List<DeliveryPoint>.from(points);
    sortedPoints.sort((a, b) {
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    print(
        '🔄 [RouteOptimizer] Alternative route created from ($baseLat, $baseLng)');
    return sortedPoints;
  }

  /// Haversine distance between two points (km)
  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return AppConfig.earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
