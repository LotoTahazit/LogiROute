// lib/services/smart_navigation_service.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'osrm_navigation_service.dart';
import 'navigation_service.dart';
import '../models/delivery_point.dart';

/// 🧠 Умный навигационный сервис
/// Использует OSRM как основной источник (бесплатно, без лимитов)
/// Google Directions API как fallback (с лимитами, но с пошаговыми инструкциями)
class SmartNavigationService {
  final OsrmNavigationService _osrm = OsrmNavigationService();
  final NavigationService _google = NavigationService();

  /// 🧭 Умный маршрут с несколькими точками
  /// - OSRM приоритетен
  /// - Google fallback
  /// - При ≤3 точках оптимизация отключается (OSRM теряет промежуточные)
  Future<NavigationRoute?> getMultiPointRoute({
    required double startLat,
    required double startLng,
    required List<DeliveryPoint> waypoints,
    required double endLat,
    required double endLng,
    String language = 'he',
    bool useOptimization = true,
  }) async {
    debugPrint('🧠 [SmartNavigation] Getting multi-point route with ${waypoints.length} waypoints');
    debugPrint('🔍 [SmartNavigation] Start: ($startLat, $startLng), End: ($endLat, $endLng)');

    // 🧹 Убираем дубликаты (но не теряем точки)
    final uniqueWaypoints = <Map<String, double>>[];
    for (var p in waypoints) {
      final exists = uniqueWaypoints.any((w) =>
          (w['lat']! - p.latitude).abs() < 0.00005 &&
          (w['lng']! - p.longitude).abs() < 0.00005);
      if (!exists) {
        uniqueWaypoints.add({'lat': p.latitude, 'lng': p.longitude});
      } else {
        debugPrint('⚠️ [SmartNavigation] Skipping near-duplicate waypoint: ${p.clientName}');
      }
    }

    // ⚙️ Если ≤3 точек — отключаем оптимизацию, OSRM их теряет
    final shouldOptimize = useOptimization && uniqueWaypoints.length > 3;

    try {
      final osrmRoute = shouldOptimize
          ? await _osrm.getOptimizedTrip(
              startLat: startLat,
              startLng: startLng,
              waypoints: uniqueWaypoints,
              endLat: endLat,
              endLng: endLng,
              language: language,
            )
          : await _osrm.getRoute(
              startLat: startLat,
              startLng: startLng,
              endLat: endLat,
              endLng: endLng,
              language: language,
            );

      if (osrmRoute != null) {
        debugPrint('✅ [SmartNavigation] OSRM route OK (${shouldOptimize ? "optimized" : "simple"}): ${osrmRoute.formattedDistance}, ${osrmRoute.formattedDuration}');
        debugPrint('🔍 [SmartNavigation] Polyline preview: ${osrmRoute.polyline.substring(0, math.min(50, osrmRoute.polyline.length))}...');
        
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
      debugPrint('⚠️ [SmartNavigation] OSRM multi-point failed: $e');
    }

    // 🪣 fallback → Google
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

        if (googleRoute != null) {
          debugPrint('✅ [SmartNavigation] Google fallback route: ${googleRoute.distance}, ${googleRoute.duration}');
          return googleRoute;
        }
      } catch (e) {
        debugPrint('❌ [SmartNavigation] Google multi-point failed: $e');
      }
    }

    debugPrint('❌ [SmartNavigation] All multi-point services failed');
    return null;
  }

  /// Получает обычный маршрут между двумя точками (с fallback)
  Future<NavigationRoute?> getNavigationRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    debugPrint('🧠 [SmartNav] Single route ($startLat,$startLng) → ($endLat,$endLng)');
    
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

      debugPrint('⚠️ [SmartNav] OSRM failed → Google fallback');
      
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

  /// Получает маршрут (автоматически выбирает лучший источник)
  Future<NavigationRoute?> getAutoRoute({
    required double startLat,
    required double startLng,
    required List<DeliveryPoint> points,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    debugPrint('🧠 [SmartNav] Auto route: ${points.length} points');
    
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

  /// Принудительно OSRM (без fallback)
  Future<NavigationRoute?> getOsrmOnlyRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    debugPrint('🧩 [SmartNav] OSRM-only route');
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

  /// Принудительно Google Directions (для инструкций)
  Future<NavigationRoute?> getGoogleOnlyRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    debugPrint('🧭 [SmartNav] Google-only route');
    return await _google.getNavigationRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      language: language,
    );
  }
}
