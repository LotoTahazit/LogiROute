// lib/services/smart_navigation_service.dart
import 'package:flutter/foundation.dart';
import 'osrm_navigation_service.dart';
import 'navigation_service.dart';
import '../models/delivery_point.dart';

class SmartNavigationService {
  final OsrmNavigationService _osrm = OsrmNavigationService();
  final NavigationService _google = NavigationService();

  Future<NavigationRoute?> getMultiPointRoute({
    required double startLat,
    required double startLng,
    required List<DeliveryPoint> waypoints,
    required double endLat,
    required double endLng,
    String language = 'he',
    bool useOptimization = true,
  }) async {
    final uniqueWaypoints = <Map<String, double>>[];
    for (var p in waypoints) {
      final exists = uniqueWaypoints.any((w) =>
          (w['lat']! - p.latitude).abs() < 0.00005 &&
          (w['lng']! - p.longitude).abs() < 0.00005);
      if (!exists) {
        uniqueWaypoints.add({'lat': p.latitude, 'lng': p.longitude});
      }
    }

    final shouldOptimize = useOptimization && uniqueWaypoints.length > 3;

    try {
      OsrmRoute? osrmRoute;

      if (uniqueWaypoints.isEmpty) {
        osrmRoute = await _osrm.getRoute(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
      } else if (shouldOptimize) {
        osrmRoute = await _osrm.getOptimizedTrip(
          startLat: startLat,
          startLng: startLng,
          waypoints: uniqueWaypoints,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
      } else {
        osrmRoute = await _osrm.getOptimizedRoute(
          startLat: startLat,
          startLng: startLng,
          waypoints: uniqueWaypoints,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
      }

      if (osrmRoute != null) {
        if (osrmRoute.polyline.isEmpty) {
          debugPrint('❌ [SmartNavigation] OSRM returned empty polyline');
          return null;
        }
        return NavigationRoute(
          distance: osrmRoute.formattedDistance,
          duration: osrmRoute.formattedDuration,
          durationInTraffic: osrmRoute.formattedDuration,
          steps: [],
          polyline: osrmRoute.polyline,
        );
      } else {
        debugPrint('❌ [SmartNavigation] OSRM returned null route');
      }
    } catch (e) {
      debugPrint('❌ [SmartNavigation] OSRM multi-point failed: $e');
    }

    if (!kIsWeb) {
      try {
        final googleRoute = await _google.getMultiPointRoute(
          startLat: startLat,
          startLng: startLng,
          waypoints: waypoints,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
        if (googleRoute != null) return googleRoute;
      } catch (e) {
        debugPrint('❌ [SmartNavigation] Google multi-point failed: $e');
      }
    }

    debugPrint('❌ [SmartNavigation] All multi-point services failed');
    return null;
  }

  Future<NavigationRoute?> getNavigationRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    try {
      final osrmRoute = await _osrm.getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        language: language,
      );
      if (osrmRoute != null) {
        return NavigationRoute(
          distance: osrmRoute.formattedDistance,
          duration: osrmRoute.formattedDuration,
          durationInTraffic: osrmRoute.formattedDuration,
          steps: [],
          polyline: osrmRoute.polyline,
        );
      }
      if (!kIsWeb) {
        return await _google.getNavigationRoute(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
      }
    } catch (e) {
      debugPrint('❌ [SmartNav] Error: $e');
    }
    return null;
  }

  Future<NavigationRoute?> getAutoRoute({
    required double startLat,
    required double startLng,
    required List<DeliveryPoint> points,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    if (points.isEmpty) {
      return getNavigationRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        language: language,
      );
    }
    return getMultiPointRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: points,
      endLat: endLat,
      endLng: endLng,
      language: language,
    );
  }

  Future<NavigationRoute?> getOsrmOnlyRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    final osrmRoute = await _osrm.getRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      language: language,
    );
    if (osrmRoute != null) {
      return NavigationRoute(
        distance: osrmRoute.formattedDistance,
        duration: osrmRoute.formattedDuration,
        durationInTraffic: osrmRoute.formattedDuration,
        steps: [],
        polyline: osrmRoute.polyline,
      );
    }
    return null;
  }

  Future<NavigationRoute?> getGoogleOnlyRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    return await _google.getNavigationRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      language: language,
    );
  }
}
