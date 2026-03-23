// lib/services/smart_navigation_service.dart
import 'package:flutter/foundation.dart';
import '../config/api_constants.dart';
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
    debugPrint(
        '[OSRM_INPUT] start=$startLat,$startLng end=$endLat,$endLng waypoints=${waypoints.length}');
    // 🐞 DEBUG: Входные данные
    debugPrint('🔍 [SmartNavigation] getMultiPointRoute called');
    debugPrint('📍 [SmartNavigation] Start: ($startLat, $startLng)');
    debugPrint('📍 [SmartNavigation] End: ($endLat, $endLng)');
    debugPrint('📍 [SmartNavigation] Waypoints: ${waypoints.length} points');
    if (waypoints.isNotEmpty) {
      debugPrint(
          '📍 [SmartNavigation] First waypoint: (${waypoints.first.latitude}, ${waypoints.first.longitude})');
      debugPrint(
          '📍 [SmartNavigation] Last waypoint: (${waypoints.last.latitude}, ${waypoints.last.longitude})');
    }

    final uniqueWaypoints = <Map<String, double>>[];
    for (var p in waypoints) {
      final exists = uniqueWaypoints.any((w) =>
          (w['lat']! - p.latitude).abs() < 0.00005 &&
          (w['lng']! - p.longitude).abs() < 0.00005);
      if (!exists) {
        uniqueWaypoints.add({'lat': p.latitude, 'lng': p.longitude});
      }
    }

    debugPrint(
        '📍 [SmartNavigation] Unique waypoints: ${uniqueWaypoints.length} points');
    final shouldOptimize = useOptimization && uniqueWaypoints.length > 3;
    debugPrint('📍 [SmartNavigation] Should optimize: $shouldOptimize');

    try {
      debugPrint('[OSRM_CALL_START]');
      // Тот же URL, что уйдёт в OsrmNavigationService (до http.get) — для диагностики web.
      final debugOsrmUrl = () {
        if (uniqueWaypoints.isEmpty) {
          final coords = '$startLng,$startLat;$endLng,$endLat';
          return '${ApiConstants.osrmRouteUrl}/$coords?${ApiConstants.osrmRouteParams}';
        }
        final buf = StringBuffer()
          ..write('$startLng,$startLat');
        for (final w in uniqueWaypoints) {
          buf.write(';${w['lng']},${w['lat']}');
        }
        buf.write(';$endLng,$endLat');
        final coords = buf.toString();
        if (shouldOptimize) {
          return '${ApiConstants.osrmTripUrl}/$coords?${ApiConstants.osrmTripParams}';
        }
        return '${ApiConstants.osrmRouteUrl}/$coords?${ApiConstants.osrmRouteParams}';
      }();
      debugPrint('[OSRM_HTTP_URL] $debugOsrmUrl');

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
      debugPrint('[OSRM_CALL_END] result=$osrmRoute');

      if (osrmRoute != null) {
        if (osrmRoute.polyline.isEmpty) {
          debugPrint('❌ [SmartNavigation] OSRM returned empty polyline');
          debugPrint(
              '🐞 [SmartNavigation] Returning null due to empty polyline');
          return null;
        }
        debugPrint(
            '✅ [SmartNavigation] OSRM success: polyline length ${osrmRoute.polyline.length}');
        return NavigationRoute(
          distance: osrmRoute.formattedDistance,
          duration: osrmRoute.formattedDuration,
          durationInTraffic: osrmRoute.formattedDuration,
          steps: [],
          polyline: osrmRoute.polyline,
        );
      } else {
        debugPrint('❌ [SmartNavigation] OSRM returned null route');
        debugPrint('🐞 [SmartNavigation] OSRM result was null');
      }
    } catch (e) {
      debugPrint('❌ [SmartNavigation] OSRM multi-point failed: $e');
      debugPrint('🐞 [SmartNavigation] Exception in OSRM: $e');
    }

    if (!kIsWeb) {
      try {
        debugPrint('🔍 [SmartNavigation] Trying Google Navigation service');
        final googleRoute = await _google.getMultiPointRoute(
          startLat: startLat,
          startLng: startLng,
          waypoints: waypoints,
          endLat: endLat,
          endLng: endLng,
          language: language,
        );
        if (googleRoute != null) {
          debugPrint(
              '✅ [SmartNavigation] Google success: polyline length ${googleRoute.polyline.length}');
          return googleRoute;
        } else {
          debugPrint('❌ [SmartNavigation] Google returned null route');
        }
      } catch (e) {
        debugPrint('❌ [SmartNavigation] Google multi-point failed: $e');
        debugPrint('🐞 [SmartNavigation] Exception in Google: $e');
      }
    }

    debugPrint('❌ [SmartNavigation] All multi-point services failed');
    debugPrint('🐞 [SmartNavigation] Final return null - no route available');
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
