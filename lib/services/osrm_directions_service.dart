import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

/// Бесплатный сервис маршрутизации на основе OSRM (Open Source Routing Machine)
/// Не требует API-ключа и работает через открытый REST-интерфейс.
class OsrmDirectionsService {
  /// Получить маршрут между двумя точками
  Future<RouteInfo?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.osrmRouteUrl}/$originLng,$originLat;$destinationLng,$destinationLat'
        '?${ApiConstants.osrmRouteParams}&${ApiConstants.osrmAnnotations}',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('OSRM HTTP error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      // Безопасная проверка структуры ответа
      if (data == null || data['code'] != 'Ok') {
        if (kDebugMode) debugPrint('OSRM response error: ${data?['code']}');
        return null;
      }

      final routes = data['routes'];
      if (routes == null || routes is! List || routes.isEmpty) {
        if (kDebugMode) debugPrint('OSRM: No routes found');
        return null;
      }

      final route = routes[0];
      if (route['geometry'] == null) {
        if (kDebugMode) debugPrint('OSRM: No geometry in route');
        return null;
      }

      final distance = (route['distance'] as num).toInt(); // метры
      final duration = (route['duration'] as num).toInt(); // секунды
      final polyline = route['geometry'];

      return RouteInfo(
        distance: distance,
        duration: duration,
        durationInTraffic: duration, // OSRM не возвращает трафик
        polyline: polyline,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('OSRM route error: $e');
      return null;
    }
  }

  /// Привязать GPS-трек к дорогам (OSRM match / snap-to-road).
  ///
  /// [latLngs] — точки трека в порядке времени, формат [[lat, lng], ...].
  /// Возвращает список закодированных polyline-геометрий (по одной на каждый
  /// matching OSRM) или null при неудаче — тогда вызывающий рисует исходные
  /// прямые отрезки. [radiusMeters] — допуск поиска дороги для каждой точки
  /// (для разреженного GPS нужен запас).
  Future<List<String>?> matchToRoad(
    List<List<double>> latLngs, {
    double radiusMeters = 35,
  }) async {
    if (latLngs.length < 2) return null;
    // У OSRM match лимит ~100 координат на запрос — при необходимости прорежаем.
    var pts = latLngs;
    if (pts.length > 100) {
      final step = (pts.length / 100).ceil();
      final sampled = <List<double>>[];
      for (var i = 0; i < pts.length; i += step) {
        sampled.add(pts[i]);
      }
      if (sampled.isEmpty || sampled.last != pts.last) sampled.add(pts.last);
      pts = sampled;
    }
    final coords = pts.map((p) => '${p[1]},${p[0]}').join(';');
    final radiuses =
        List.filled(pts.length, radiusMeters.toStringAsFixed(0)).join(';');
    try {
      final url = Uri.parse(
        '${ApiConstants.osrmMatchUrl}/$coords'
        '?geometries=polyline&overview=full&tidy=true&radiuses=$radiuses',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('OSRM match HTTP error: ${response.statusCode}');
        return null;
      }
      final data = json.decode(response.body);
      if (data == null || data['code'] != 'Ok') {
        if (kDebugMode) debugPrint('OSRM match response: ${data?['code']}');
        return null;
      }
      final matchings = data['matchings'];
      if (matchings is! List || matchings.isEmpty) return null;
      final geoms = <String>[];
      for (final m in matchings) {
        final g = m['geometry'];
        if (g is String && g.isNotEmpty) geoms.add(g);
      }
      return geoms.isEmpty ? null : geoms;
    } catch (e) {
      if (kDebugMode) debugPrint('OSRM match error: $e');
      return null;
    }
  }

  /// Получить маршрут через несколько точек (waypoints)
  Future<RouteInfo?> getRouteWithWaypoints({
    required double originLat,
    required double originLng,
    required List<Map<String, double>> waypoints,
    required double destinationLat,
    required double destinationLng,
    bool optimize = true,
  }) async {
    try {
      final coords = [
        '$originLng,$originLat',
        ...waypoints.map((w) => '${w['lng']},${w['lat']}'),
        '$destinationLng,$destinationLat'
      ].join(';');

      final String url = optimize
          ? '${ApiConstants.osrmTripUrl}/$coords?${ApiConstants.osrmTripParams}'
          : '${ApiConstants.osrmRouteUrl}/$coords?${ApiConstants.osrmRouteParams}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('OSRM HTTP error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      // Проверка базовой структуры ответа
      if (data == null || data['code'] != 'Ok') {
        if (kDebugMode) debugPrint('OSRM response error: ${data?['code']}');
        return null;
      }

      // OSRM Trip API (если optimize = true)
      if (optimize) {
        final trips = data['trips'];
        if (trips == null || trips is! List || trips.isEmpty) {
          if (kDebugMode) debugPrint('OSRM: No trips found in response');
          return null;
        }

        final trip = trips[0];
        if (trip['geometry'] == null) {
          if (kDebugMode) debugPrint('OSRM: No geometry in trip');
          return null;
        }

        return RouteInfo(
          distance: (trip['distance'] as num).toInt(),
          duration: (trip['duration'] as num).toInt(),
          durationInTraffic: (trip['duration'] as num).toInt(),
          polyline: trip['geometry'],
          waypointOrder: (trip['waypoint_order'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList(),
        );
      }

      // OSRM Route API (если optimize = false)
      final routes = data['routes'];
      if (routes == null || routes is! List || routes.isEmpty) {
        if (kDebugMode) debugPrint('OSRM: No routes found in response');
        return null;
      }

      final route = routes[0];
      if (route['geometry'] == null) {
        if (kDebugMode) debugPrint('OSRM: No geometry in route');
        return null;
      }

      return RouteInfo(
        distance: (route['distance'] as num).toInt(),
        duration: (route['duration'] as num).toInt(),
        durationInTraffic: (route['duration'] as num).toInt(),
        polyline: route['geometry'],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('OSRM waypoints error: $e');
      return null;
    }
  }
}

/// Универсальная модель маршрута
class RouteInfo {
  final int distance; // метры
  final int duration; // секунды
  final int durationInTraffic; // секунды с учётом трафика
  final String polyline;
  final List<int>? waypointOrder;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.durationInTraffic,
    required this.polyline,
    this.waypointOrder,
  });

  double get distanceInKm => distance / 1000.0;
  double get durationInHours => duration / 3600.0;

  double get durationInTrafficHours {
    final trafficTime = durationInTraffic / 3600.0;
    final minTimeBySpeed = distanceInKm / 90.0;
    return math.max(trafficTime, minTimeBySpeed);
  }
}
