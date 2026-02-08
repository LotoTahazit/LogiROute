// lib/services/osrm_navigation_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class OsrmNavigationService {
  /// Получает маршрут через OSRM (бесплатный, без лимитов)
  Future<OsrmRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    try {
      final coordinates = '$startLng,$startLat;$endLng,$endLat';
      final url =
          '${ApiConstants.osrmRouteUrl}/$coordinates?${ApiConstants.osrmRouteParams}';

      debugPrint('🧭 [OSRM] Requesting route: $url');

      final response = await http.get(Uri.parse(url));
      debugPrint('📡 [OSRM] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📊 [OSRM] API response code: ${data['code']}');

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distance = route['distance'] / 1000; // км
          final duration = route['duration'] / 60; // минуты
          final polyline = route['geometry'];

          debugPrint(
              '✅ [OSRM] Route found: ${distance.toStringAsFixed(1)}km, ${duration.toStringAsFixed(1)}min');
          debugPrint('📏 [OSRM] Polyline length: ${polyline.length} chars');
          debugPrint('🔍 [OSRM] Polyline type: ${polyline.runtimeType}');
          debugPrint(
              '🔍 [OSRM] Polyline preview (first 100 chars): ${polyline.toString().substring(0, polyline.length > 100 ? 100 : polyline.length)}');

          // Проверяем первые символы polyline
          if (polyline.length > 0) {
            final firstChar = polyline.codeUnitAt(0);
            debugPrint(
                '🔍 [OSRM] First char code: $firstChar (char: "${polyline[0]}")');
          }

          return OsrmRoute(
            distance: distance,
            duration: duration,
            polyline: polyline,
            summary: route['summary'],
          );
        } else {
          debugPrint('❌ [OSRM] API Error: ${data['code']}');
        }
      } else {
        debugPrint('❌ [OSRM] HTTP Error: ${response.statusCode}');
        debugPrint('📄 [OSRM] Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [OSRM] Exception: $e');
    }

    return null;
  }

  /// Получает оптимизированный маршрут с промежуточными точками
  Future<OsrmRoute?> getOptimizedRoute({
    required double startLat,
    required double startLng,
    required List<Map<String, double>> waypoints,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    if (waypoints.isEmpty) {
      return getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        language: language,
      );
    }

    try {
      // Формируем координаты: старт -> waypoints -> финиш
      final coordinates = StringBuffer();
      coordinates.write('$startLng,$startLat');

      for (final waypoint in waypoints) {
        coordinates.write(';${waypoint['lng']},${waypoint['lat']}');
      }

      coordinates.write(';$endLng,$endLat');

      final url =
          '${ApiConstants.osrmRouteUrl}/${coordinates.toString()}?${ApiConstants.osrmRouteParams}';

      debugPrint(
          '🧭 [OSRM] Requesting route with ${waypoints.length} waypoints');
      debugPrint('🔍 [OSRM] URL: $url');

      final response = await http.get(Uri.parse(url));
      debugPrint('📡 [OSRM] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📊 [OSRM] API response code: ${data['code']}');

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distance = route['distance'] / 1000; // км
          final duration = route['duration'] / 60; // минуты
          final polyline = route['geometry'];

          debugPrint(
              '✅ [OSRM] Route with waypoints found: ${distance.toStringAsFixed(1)}km, ${duration.toStringAsFixed(1)}min');
          debugPrint('📏 [OSRM] Polyline length: ${polyline.length} chars');

          return OsrmRoute(
            distance: distance,
            duration: duration,
            polyline: polyline,
            summary: route['summary'],
            waypoints: waypoints,
          );
        } else {
          debugPrint('❌ [OSRM] API Error: ${data['code']}');
        }
      } else {
        debugPrint('❌ [OSRM] HTTP Error: ${response.statusCode}');
        debugPrint('📄 [OSRM] Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [OSRM] Exception: $e');
    }

    return null;
  }

  /// Получает маршрут с оптимизацией порядка точек (trip optimization)
  Future<OsrmRoute?> getOptimizedTrip({
    required double startLat,
    required double startLng,
    required List<Map<String, double>> waypoints,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    if (waypoints.isEmpty) {
      return getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        language: language,
      );
    }

    try {
      // Формируем координаты для trip optimization
      final coordinates = StringBuffer();
      coordinates.write('$startLng,$startLat');

      for (final waypoint in waypoints) {
        coordinates.write(';${waypoint['lng']},${waypoint['lat']}');
      }

      coordinates.write(';$endLng,$endLat');

      // Используем trip endpoint для оптимизации порядка
      final tripUrl =
          '${ApiConstants.osrmTripUrl}/${coordinates.toString()}?${ApiConstants.osrmTripParams}';

      debugPrint(
          '🧭 [OSRM] Requesting optimized trip with ${waypoints.length} waypoints');
      debugPrint('🔍 [OSRM] Coordinates: ${coordinates.toString()}');

      final response = await http.get(Uri.parse(tripUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['trips'].isNotEmpty) {
          final trip = data['trips'][0];
          final distance = trip['distance'] / 1000; // км
          final duration = trip['duration'] / 60; // минуты

          return OsrmRoute(
            distance: distance,
            duration: duration,
            polyline: trip['geometry'],
            summary: trip['summary'],
            waypoints: waypoints,
            isOptimized: true,
          );
        } else {
          debugPrint('❌ [OSRM] Trip API Error: ${data['code']}');
        }
      } else {
        debugPrint('❌ [OSRM] Trip HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [OSRM] Trip Exception: $e');
    }

    return null;
  }
}

/// Модель маршрута OSRM
class OsrmRoute {
  final double distance; // в км
  final double duration; // в минутах
  final String polyline;
  final Map<String, dynamic>? summary;
  final List<Map<String, double>>? waypoints;
  final bool isOptimized;

  OsrmRoute({
    required this.distance,
    required this.duration,
    required this.polyline,
    this.summary,
    this.waypoints,
    this.isOptimized = false,
  });

  /// Форматирует расстояние
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()}м';
    } else {
      return '${distance.toStringAsFixed(1)}км';
    }
  }

  /// Форматирует время
  String get formattedDuration {
    if (duration < 60) {
      return '${duration.round()}м';
    } else {
      final hours = (duration / 60).floor();
      final minutes = (duration % 60).round();
      return '$hoursч $minutesм';
    }
  }
}
