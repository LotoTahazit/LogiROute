import 'package:flutter/foundation.dart';

/// Сервис управления API ключами
class ApiConfigService {
  // 🔑 Google Maps API Keys
  static const String _googleMapsWebKey = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_KEY',
    defaultValue: 'AIzaSyC1FqbSw4TzGRO5FwQYo3_7iDFP2ynTlpQ',
  );
  
  static const String _googleMapsAndroidKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_KEY',
    defaultValue: 'AIzaSyDs_vewHuQ2DK5r8yqvJ4W2jvUAusC3SkY',
  );
  
  /// Получить правильный Google Maps API ключ для текущей платформы
  static String get googleMapsApiKey {
    return kIsWeb ? _googleMapsWebKey : _googleMapsAndroidKey;
  }
  
  /// Web API ключ (явно)
  static String get webApiKey => _googleMapsWebKey;
  
  /// Android API ключ (явно)
  static String get androidApiKey => _googleMapsAndroidKey;
  
  // 🌐 OSRM API
  static const String osrmBaseUrl = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org/route/v1/driving',
  );
  
  // 🗺️ Google APIs URLs
  static const String googleRoadsApiUrl = 'https://roads.googleapis.com/v1/snapToRoads';
  static const String googlePlacesApiUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleDirectionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String googleGeocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}

