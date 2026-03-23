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

  // OSRM: все URL маршрутизации — [ApiConstants] (osrmBaseUrl / osrmRouteUrl / fallback).
  // Переменные окружения: OSRM_HOST, OSRM_FALLBACK_HOST или OSRM_BASE_URL (legacy, origin).

  // 🗺️ Google APIs URLs (публичные URL, не требуют защиты)
  static const String googleRoadsApiUrl = 'https://roads.googleapis.com/v1/snapToRoads';
  static const String googlePlacesApiUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleDirectionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String googleGeocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}