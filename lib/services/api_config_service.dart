import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Сервис управления API ключами
/// 
/// ⚠️ ВАЖНО: Все секретные ключи должны быть в .env файле!
/// Никогда не коммитьте .env файл в репозиторий!
class ApiConfigService {
  // 🔑 Google Maps API Keys
  static String get _googleMapsWebKey {
    final key = dotenv.env['GOOGLE_MAPS_WEB_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        '❌ GOOGLE_MAPS_WEB_KEY не найден в .env файле!\n'
        'Создайте файл .env в корне проекта и добавьте туда ключ.',
      );
    }
    return key;
  }
  
  static String get _googleMapsAndroidKey {
    final key = dotenv.env['GOOGLE_MAPS_ANDROID_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        '❌ GOOGLE_MAPS_ANDROID_KEY не найден в .env файле!\n'
        'Создайте файл .env в корне проекта и добавьте туда ключ.',
      );
    }
    return key;
  }
  
  /// Получить правильный Google Maps API ключ для текущей платформы
  static String get googleMapsApiKey {
    return kIsWeb ? _googleMapsWebKey : _googleMapsAndroidKey;
  }
  
  /// Web API ключ (явно)
  static String get webApiKey => _googleMapsWebKey;
  
  /// Android API ключ (явно)
  static String get androidApiKey => _googleMapsAndroidKey;
  
  // 🌐 OSRM API
  static String get osrmBaseUrl {
    return dotenv.env['OSRM_BASE_URL'] ?? 
           'https://router.project-osrm.org/route/v1/driving';
  }
  
  // 🗺️ Google APIs URLs (публичные URL, не требуют защиты)
  static const String googleRoadsApiUrl = 'https://roads.googleapis.com/v1/snapToRoads';
  static const String googlePlacesApiUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleDirectionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String googleGeocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}

