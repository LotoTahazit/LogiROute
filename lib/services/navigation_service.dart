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
        desiredAccuracy: LocationAccuracy.high,
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
      return '$metersм';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}км';
    }
  }

  /// Форматирует время в секундах
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hoursч $minutesм';
    } else {
      return '$minutesм';
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

  /// Создает детальные навигационные шаги между двумя точками
  List<NavigationStep> _createDetailedSteps(double startLat, double startLng,
      double endLat, double endLng, String destination) {
    final steps = <NavigationStep>[];
    final distance = _calculateDistance(startLat, startLng, endLat, endLng);
    final duration =
        (distance / 50000 * 3600).round(); // ИСПРАВЛЕНО: 50 км/ч = 50000 м/ч

    // Определяем направление движения
    final bearing = _calculateBearing(startLat, startLng, endLat, endLng);
    final direction = _getDirectionFromBearing(bearing);

    // Создаем несколько шагов для более реалистичной навигации
    if (distance > 1000) {
      // Если расстояние больше 1км
      // Шаг 1: Начало движения
      steps.add(NavigationStep(
        instruction: 'התחל נסיעה לכיוון $direction',
        distance: '500м',
        duration: '1м',
        startLocation: LatLng(startLat, startLng),
        endLocation: LatLng(startLat + (endLat - startLat) * 0.1,
            startLng + (endLng - startLng) * 0.1),
      ));

      // Шаг 2: Продолжение движения
      steps.add(NavigationStep(
        instruction: 'המשך ישר לכיוון $destination',
        distance: _formatDistance((distance * 0.7).round()),
        duration: _formatDuration((duration * 0.7).round()),
        startLocation: LatLng(startLat + (endLat - startLat) * 0.1,
            startLng + (endLng - startLng) * 0.1),
        endLocation: LatLng(startLat + (endLat - startLat) * 0.8,
            startLng + (endLng - startLng) * 0.8),
      ));

      // Шаг 3: Приближение к цели
      steps.add(NavigationStep(
        instruction: 'הגע ל$destination',
        distance: _formatDistance((distance * 0.2).round()),
        duration: _formatDuration((duration * 0.2).round()),
        startLocation: LatLng(startLat + (endLat - startLat) * 0.8,
            startLng + (endLng - startLng) * 0.8),
        endLocation: LatLng(endLat, endLng),
      ));
    } else {
      // Короткое расстояние - один шаг
      steps.add(NavigationStep(
        instruction: 'נסיעה ל$destination',
        distance: _formatDistance(distance.round()),
        duration: _formatDuration(duration),
        startLocation: LatLng(startLat, startLng),
        endLocation: LatLng(endLat, endLng),
      ));
    }

    return steps;
  }

  /// Вычисляет азимут между двумя точками
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Получает направление по азимуту
  String _getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'צפון';
    if (bearing >= 22.5 && bearing < 67.5) return 'צפון-מזרח';
    if (bearing >= 67.5 && bearing < 112.5) return 'מזרח';
    if (bearing >= 112.5 && bearing < 157.5) return 'דרום-מזרח';
    if (bearing >= 157.5 && bearing < 202.5) return 'דרום';
    if (bearing >= 202.5 && bearing < 247.5) return 'דרום-מערב';
    if (bearing >= 247.5 && bearing < 292.5) return 'מערב';
    if (bearing >= 292.5 && bearing < 337.5) return 'צפון-מערב';
    return 'צפון';
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
