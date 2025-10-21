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
        '❌ Google Maps Web API key not configured.\n'
        'Please check your environment configuration.',
      );
    }
    // Валидация формата API ключа
    if (!_isValidApiKey(key)) {
      throw Exception(
        '❌ Invalid Google Maps Web API key format.\n'
        'Please verify your API key configuration.',
      );
    }
    return key;
  }
  
  static String get _googleMapsAndroidKey {
    final key = dotenv.env['GOOGLE_MAPS_ANDROID_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        '❌ Google Maps Android API key not configured.\n'
        'Please check your environment configuration.',
      );
    }
    // Валидация формата API ключа
    if (!_isValidApiKey(key)) {
      throw Exception(
        '❌ Invalid Google Maps Android API key format.\n'
        'Please verify your API key configuration.',
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
  
  /// Валидация формата API ключа Google Maps
  /// Проверяет базовую структуру ключа без раскрытия его содержимого
  static bool _isValidApiKey(String key) {
    if (key.length < 20 || key.length > 100) return false;
    // Проверяем, что ключ содержит только допустимые символы
    final validPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    return validPattern.hasMatch(key);
  }
}

