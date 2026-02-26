// lib/services/navigation_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/delivery_point.dart';
import 'api_config_service.dart';

class NavigationService {
  /// Получает пошаговые инструкции для навигации
  Future<NavigationRoute?> getNavigationRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String language = 'he', // Иврит для навигации
  }) async {
    try {
      final String origin = '$startLat,$startLng';
      final String destination = '$endLat,$endLng';

      final String url = '${ApiConfigService.googleDirectionsApiUrl}'
          '?origin=$origin'
          '&destination=$destination'
          '&language=$language'
          '&mode=driving'
          '&avoid=tolls'
          '&traffic_model=best_guess'
          '&departure_time=now'
          '&key=${ApiConfigService.googleMapsApiKey}';

      debugPrint(
          '🧭 [Navigation] Requesting route from ($startLat, $startLng) to ($endLat, $endLng)');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final steps = <NavigationStep>[];
          for (final stepData in leg['steps']) {
            steps.add(NavigationStep(
              instruction: _cleanHtml(stepData['html_instructions']),
              distance: stepData['distance']['text'],
              duration: stepData['duration']['text'],
              startLocation: LatLng(
                stepData['start_location']['lat'],
                stepData['start_location']['lng'],
              ),
              endLocation: LatLng(
                stepData['end_location']['lat'],
                stepData['end_location']['lng'],
              ),
            ));
          }

          return NavigationRoute(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            durationInTraffic: leg['duration_in_traffic']?['text'],
            steps: steps,
            polyline: route['overview_polyline']['points'],
          );
        } else {
          debugPrint('❌ [Navigation] API Error: ${data['status']}');
        }
      } else {
        debugPrint('❌ [Navigation] HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Navigation] Exception: $e');
    }

    return null;
  }

  /// Получает маршрут с промежуточными точками (waypoints)
  Future<NavigationRoute?> getMultiPointRoute({
    required double startLat,
    required double startLng,
    required List<DeliveryPoint> waypoints,
    required double endLat,
    required double endLng,
    String language = 'he',
  }) async {
    if (waypoints.isEmpty) {
      return getNavigationRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        language: language,
      );
    }

    try {
      // Создаем простой маршрут для карты без текстовых инструкций
      final allSteps = <NavigationStep>[];

      // Подсчитываем общее расстояние
      double totalDistance = 0;
      for (int i = 0; i < waypoints.length; i++) {
        final point = waypoints[i];
        final distance = _calculateDistance(
          i == 0 ? startLat : waypoints[i - 1].latitude,
          i == 0 ? startLng : waypoints[i - 1].longitude,
          point.latitude,
          point.longitude,
        );
        totalDistance += distance;
      }

      // Добавляем расстояние до финальной точки
      final finalDistance = _calculateDistance(
        waypoints.last.latitude,
        waypoints.last.longitude,
        endLat,
        endLng,
      );
      totalDistance += finalDistance;

      debugPrint(
          '🧭 [Navigation] Created map route: ${totalDistance.round()}м');

      return NavigationRoute(
        distance: _formatDistance(totalDistance.round()),
        duration: _formatDuration((totalDistance / 50000 * 3600)
            .round()), // ИСПРАВЛЕНО: 50 км/ч = 50000 м/ч
        durationInTraffic: null,
        steps: allSteps, // Пустые шаги - только карта
        polyline: '', // Будет создан на карте
      );
    } catch (e) {
      debugPrint('❌ [Navigation] Map route error: $e');
    }

    return null;
  }

  /// Получает текущую позицию водителя
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('❌ [Navigation] Error getting current position: $e');
      return null;
    }
  }

  /// Очищает HTML из инструкций
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Удаляем HTML теги
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Форматирует расстояние в метрах
  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$metersמ'; // Hebrew: מ = מטר (meters)
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}ק"מ'; // Hebrew: ק"מ = קילומטר (kilometers)
    }
  }

  /// Форматирует время в секундах
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hoursש $minutesד'; // Hebrew: ש = שעות (hours), ד = דקות (minutes)
    } else {
      return '$minutesד';
    }
  }

  /// Вычисляет расстояние между двумя точками (формула гаверсинуса)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Радиус Земли в метрах

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Конвертирует градусы в радианы
  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

/// Модель для навигационного маршрута
class NavigationRoute {
  final String distance;
  final String duration;
  final String? durationInTraffic;
  final List<NavigationStep> steps;
  final String polyline;

  NavigationRoute({
    required this.distance,
    required this.duration,
    this.durationInTraffic,
    required this.steps,
    required this.polyline,
  });
}

/// Модель для шага навигации
class NavigationStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}

/// Простая модель координат
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
