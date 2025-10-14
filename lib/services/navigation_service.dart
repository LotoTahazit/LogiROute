// lib/services/navigation_service.dart
import 'dart:convert';
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
      
      debugPrint('🧭 [Navigation] Requesting route from ($startLat, $startLng) to ($endLat, $endLng)');
      
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
      final String origin = '$startLat,$startLng';
      final String destination = '$endLat,$endLng';
      final String waypointStr = waypoints
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');
      
      final String url = '${ApiConfigService.googleDirectionsApiUrl}'
          '?origin=$origin'
          '&destination=$destination'
          '&waypoints=$waypointStr'
          '&language=$language'
          '&mode=driving'
          '&avoid=tolls'
          '&traffic_model=best_guess'
          '&departure_time=now'
          '&key=${ApiConfigService.googleMapsApiKey}';
      
      debugPrint('🧭 [Navigation] Requesting multi-point route with ${waypoints.length} waypoints');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final allSteps = <NavigationStep>[];
          
          // Объединяем шаги из всех участков маршрута
          for (final leg in route['legs']) {
            for (final stepData in leg['steps']) {
              allSteps.add(NavigationStep(
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
          }
          
          // Подсчитываем общее расстояние и время
          int totalDistance = 0;
          int totalDuration = 0;
          for (final leg in route['legs']) {
            totalDistance += (leg['distance']['value'] as num).toInt();
            totalDuration += (leg['duration']['value'] as num).toInt();
          }
          
          return NavigationRoute(
            distance: _formatDistance(totalDistance),
            duration: _formatDuration(totalDuration),
            durationInTraffic: _formatDuration(totalDuration),
            steps: allSteps,
            polyline: route['overview_polyline']['points'],
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [Navigation] Multi-point route error: $e');
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
      return '${meters}м';
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
      return '${hours}ч ${minutes}м';
    } else {
      return '${minutes}м';
    }
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
