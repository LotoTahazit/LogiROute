import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config_service.dart';

/// Бесплатный сервис маршрутизации на основе OSRM (Open Source Routing Machine)
/// Не требует API-ключа и работает через открытый REST-интерфейс.
class OsrmDirectionsService {
  static String get _baseUrl => ApiConfigService.osrmBaseUrl;

  /// Получить маршрут между двумя точками
  Future<RouteInfo?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$originLng,$originLat;$destinationLng,$destinationLat'
        '?overview=full&geometries=polyline&annotations=duration,distance',
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
          ? 'https://router.project-osrm.org/trip/v1/driving/$coords?source=first&destination=last&roundtrip=false&overview=full&geometries=polyline'
          : '$_baseUrl/$coords?overview=full&geometries=polyline';

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
          waypointOrder: (trip['waypoint_order'] as List?)?.map((e) => e as int).toList(),
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
