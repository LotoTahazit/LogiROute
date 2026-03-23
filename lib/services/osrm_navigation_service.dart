// lib/services/osrm_navigation_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class OsrmNavigationService {
  static const Duration _routeHttpTimeout = Duration(seconds: 12);
  /// Trip — тяжёлый запрос; прокси/публичный OSRM часто >8s.
  static const Duration _tripHttpTimeout = Duration(seconds: 25);

  /// Общий метод: пробует список OSRM-серверов для route endpoint
  Future<OsrmRoute?> _tryRouteUrls(String coordinates, String params) async {
    for (final baseUrl in ApiConstants.osrmRouteUrls) {
      final url = '$baseUrl/$coordinates?$params';
      try {
        debugPrint('[OSRM_HTTP_URL] $url');
        debugPrint('🧭 [OSRM] Trying: $url');
        final response =
            await http.get(Uri.parse(url)).timeout(_routeHttpTimeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0];
            final distance = (route['distance'] as num) / 1000;
            final duration = (route['duration'] as num) / 60;
            final polyline = route['geometry'] as String;
            debugPrint('✅ [OSRM] Route found: ${distance.toStringAsFixed(1)}km, ${duration.toStringAsFixed(1)}min (${polyline.length} chars)');
            return OsrmRoute(
              distance: distance,
              duration: duration,
              polyline: polyline,
              summary: route['summary'],
            );
          }
          debugPrint('❌ [OSRM] API Error from $baseUrl: ${data['code']}');
        } else {
          debugPrint('❌ [OSRM] HTTP ${response.statusCode} from $baseUrl');
        }
      } catch (e) {
        debugPrint('⚠️ [OSRM] Server $baseUrl failed: $e');
      }
    }
    return null;
  }

  /// Общий метод: пробует список OSRM-серверов для trip endpoint
  Future<OsrmRoute?> _tryTripUrls(String coordinates, String params, List<Map<String, double>> waypoints) async {
    for (final baseUrl in ApiConstants.osrmTripUrls) {
      final url = '$baseUrl/$coordinates?$params';
      try {
        debugPrint('[OSRM_HTTP_URL] $url');
        debugPrint('🧭 [OSRM] Trying trip: $url');
        final response =
            await http.get(Uri.parse(url)).timeout(_tripHttpTimeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 'Ok' && data['trips'] != null && (data['trips'] as List).isNotEmpty) {
            final trip = data['trips'][0];
            final distance = (trip['distance'] as num) / 1000;
            final duration = (trip['duration'] as num) / 60;
            debugPrint('✅ [OSRM] Trip found: ${distance.toStringAsFixed(1)}km');
            return OsrmRoute(
              distance: distance,
              duration: duration,
              polyline: trip['geometry'] as String,
              summary: trip['summary'],
              waypoints: waypoints,
              isOptimized: true,
            );
          }
          debugPrint('❌ [OSRM] Trip API Error from $baseUrl: ${data['code']}');
        } else {
          debugPrint('❌ [OSRM] Trip HTTP ${response.statusCode} from $baseUrl');
        }
      } catch (e) {
        debugPrint('⚠️ [OSRM] Trip server $baseUrl failed: $e');
      }
    }
    return null;
  }

  /// Получает маршрут через OSRM (с fallback на запасной сервер)
  Future<OsrmRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    debugPrint('[OSRM_BUILD_URL_START]');
    final coordinates = '$startLng,$startLat;$endLng,$endLat';
    final params = ApiConstants.osrmRouteParams;
    final url = '${ApiConstants.osrmRouteUrl}/$coordinates?$params';
    debugPrint('[OSRM_BUILD_URL_DONE] $url');
    return _tryRouteUrls(coordinates, params);
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

    final coordinates = StringBuffer();
    coordinates.write('$startLng,$startLat');
    for (final waypoint in waypoints) {
      coordinates.write(';${waypoint['lng']},${waypoint['lat']}');
    }
    coordinates.write(';$endLng,$endLat');

    final result = await _tryRouteUrls(coordinates.toString(), ApiConstants.osrmRouteParams);
    if (result != null) {
      return OsrmRoute(
        distance: result.distance,
        duration: result.duration,
        polyline: result.polyline,
        summary: result.summary,
        waypoints: waypoints,
      );
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

    final coordinates = StringBuffer();
    coordinates.write('$startLng,$startLat');
    for (final waypoint in waypoints) {
      coordinates.write(';${waypoint['lng']},${waypoint['lat']}');
    }
    coordinates.write(';$endLng,$endLat');

    return _tryTripUrls(coordinates.toString(), ApiConstants.osrmTripParams, waypoints);
  }

  /// Оптимизирует порядок точек через OSRM Trip API (кольцевой маршрут).
  /// Возвращает оптимальный порядок waypoint-индексов и общее время.
  Future<TripOptimizationResult?> getOptimizedTripOrder({
    required double warehouseLat,
    required double warehouseLng,
    required List<Map<String, double>> waypoints,
  }) async {
    if (waypoints.length < 2) return null;

    final coordinates = StringBuffer();
    coordinates.write('$warehouseLng,$warehouseLat');
    for (final wp in waypoints) {
      coordinates.write(';${wp['lng']},${wp['lat']}');
    }

    for (final baseUrl in ApiConstants.osrmTripUrls) {
      final url =
          '$baseUrl/${coordinates.toString()}?${ApiConstants.osrmTripRoundtripParams}';
      try {
        debugPrint('[OSRM_HTTP_URL] $url');
        debugPrint('🧭 [OSRM] Trip optimize: $url');
        final response =
            await http.get(Uri.parse(url)).timeout(_tripHttpTimeout);
        if (response.statusCode != 200) continue;

        final data = json.decode(response.body);
        if (data['code'] != 'Ok') continue;

        final trips = data['trips'] as List?;
        final wpData = data['waypoints'] as List?;
        if (trips == null || trips.isEmpty || wpData == null) continue;

        final trip = trips[0];
        final duration = (trip['duration'] as num) / 60;
        final distance = (trip['distance'] as num) / 1000;
        final polyline = trip['geometry'] as String? ?? '';

        // waypoint_index: оптимальный порядок посещения
        // Индекс 0 — склад, пропускаем его; остальные сдвигаем на -1
        final order = <int>[];
        for (final wp in wpData) {
          final idx = wp['waypoint_index'] as int;
          if (idx == 0) continue; // склад
          order.add(idx - 1); // индекс в исходном списке waypoints
        }

        debugPrint(
            '✅ [OSRM] Trip optimized: ${distance.toStringAsFixed(1)}km, '
            '${duration.toStringAsFixed(1)}min, order=$order');
        return TripOptimizationResult(
          waypointOrder: order,
          durationMinutes: duration,
          distanceKm: distance,
          polyline: polyline,
        );
      } catch (e) {
        debugPrint('⚠️ [OSRM] Trip optimize error: $e');
      }
    }
    return null;
  }

  /// Snap-to-road: привязывает GPS-точки к дорогам через OSRM Match API
  /// Возвращает список LatLng-пар (decoded), привязанных к дорожной сети.
  /// OSRM ограничивает ~100 координат за запрос, поэтому разбиваем на чанки.
  Future<List<List<double>>?> matchGpsPointsDecoded(
      List<Map<String, double>> points) async {
    if (points.length < 2) return null;

    try {
      const chunkSize = 100;
      final allDecodedPoints = <List<double>>[];

      for (var i = 0; i < points.length; i += chunkSize - 1) {
        final end =
            (i + chunkSize < points.length) ? i + chunkSize : points.length;
        final chunk = points.sublist(i, end);

        if (chunk.length < 2) continue;

        final coordinates =
            chunk.map((p) => '${p['lng']},${p['lat']}').join(';');
        // radiuses — допуск в метрах для каждой точки (GPS погрешность в городе до 40м)
        final radiuses = List.filled(chunk.length, '50').join(';');

        final url =
            '${ApiConstants.osrmMatchUrl}/$coordinates?${ApiConstants.osrmOverviewFull}&${ApiConstants.osrmGeometriesPolyline}&radiuses=$radiuses';

        debugPrint('[OSRM_HTTP_URL] $url');
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint(
              '🛤️ [OSRM Match] code=${data['code']}, matchings=${(data['matchings'] as List?)?.length ?? 0}');
          if (data['code'] == 'Ok' && data['matchings'] != null) {
            for (final matching in data['matchings']) {
              final geometry = matching['geometry'] as String?;
              if (geometry != null && geometry.isNotEmpty) {
                final decoded = _decodePolyline(geometry);
                allDecodedPoints.addAll(decoded);
              }
            }
          } else {
            debugPrint(
                '⚠️ [OSRM Match] Non-Ok response: ${data['code']} — ${data['message'] ?? ''}');
          }
        } else {
          debugPrint(
              '❌ [OSRM Match] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        }
      }

      if (allDecodedPoints.isEmpty) return null;
      return allDecodedPoints;
    } catch (e) {
      debugPrint('❌ [OSRM] Match exception: $e');
      return null;
    }
  }

  /// Декодирует encoded polyline (precision 5) в список [lat, lng]
  static List<List<double>> _decodePolyline(String encoded) {
    final points = <List<double>>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add([lat / 1e5, lng / 1e5]);
    }
    return points;
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
      return '${(distance * 1000).round()}מ'; // Hebrew: מ = מטר (meters)
    } else {
      return '${distance.toStringAsFixed(1)}ק"מ'; // Hebrew: ק"מ = קילומטר (kilometers)
    }
  }

  /// Форматирует время
  String get formattedDuration {
    if (duration < 60) {
      return '${duration.round()}ד'; // Hebrew: ד = דקות (minutes)
    } else {
      final hours = (duration / 60).floor();
      final minutes = (duration % 60).round();
      return '$hoursש $minutesד'; // Hebrew: ש = שעות (hours), ד = דקות (minutes)
    }
  }
}

/// Результат оптимизации порядка точек через OSRM Trip API
class TripOptimizationResult {
  final List<int> waypointOrder;
  final double durationMinutes;
  final double distanceKm;
  final String polyline;

  const TripOptimizationResult({
    required this.waypointOrder,
    required this.durationMinutes,
    required this.distanceKm,
    required this.polyline,
  });
}
