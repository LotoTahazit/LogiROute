import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Сервис управления API ключами
/// 
/// ⚠️ ВАЖНО: Все секретные ключи должны быть в .env файле!
/// Никогда не коммитьте .env файл в репозиторий!
class ApiConfigService {
  // 🔑 Google Maps API Keys
  static String get googleMapsApiKey {
    if (kIsWeb) {
      return dotenv.env['GOOGLE_MAPS_WEB_KEY'] ?? '';
    } else {
      return dotenv.env['GOOGLE_MAPS_ANDROID_KEY'] ?? '';
    }
  }
  
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