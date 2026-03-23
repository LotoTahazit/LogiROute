// lib/config/api_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Константы для API endpoints и URL
class ApiConstants {
  // Приватный конструктор чтобы предотвратить создание экземпляров
  ApiConstants._();

  // ========== OSRM API (единый источник; см. [ApiConfigService] только для ключей) ==========

  /// База без завершающего `/`: итог вида `{this}/route/v1/driving/...` (прокси Cloud Run + `/osrm`).
  static const String _osrmDefaultBase =
      'https://osrm-proxy-375119625021.europe-west1.run.app/osrm';

  /// Хост OSRM без пути (все запросы добавляют [osrmRouteEndpoint] и т.д.).
  /// Переопределение: `OSRM_HOST` или устаревший `OSRM_BASE_URL` (берётся [Uri.origin]).
  /// **Web:** публичный OSRM с другого origin часто режется CORS — укажите свой прокси
  /// (Cloud Run / Cloud Function), отдающий тот же API с `Access-Control-Allow-Origin`.
  static String get osrmBaseUrl {
    // Без dotenv.load() в main доступ к dotenv.env бросает NotInitializedError (web/release).
    if (!dotenv.isInitialized) return _osrmDefaultBase;
    final host = dotenv.env['OSRM_HOST']?.trim();
    if (host != null && host.isNotEmpty) return host;
    final legacy = dotenv.env['OSRM_BASE_URL']?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      final u = Uri.tryParse(legacy.split('#').first.trim());
      if (u != null && u.hasScheme && u.host.isNotEmpty) {
        // Старые .env указывали на публичный OSRM — тот же API через прокси (CORS на web).
        if (u.host == 'router.project-osrm.org') return _osrmDefaultBase;
        return u.origin;
      }
    }
    return _osrmDefaultBase;
  }

  /// Запасной сервер (тот же смысл, что у основного — только host + путь из констант ниже).
  static String get osrmFallbackBaseUrl {
    if (!dotenv.isInitialized) {
      return 'https://routing.openstreetmap.de/routed-car';
    }
    final h = dotenv.env['OSRM_FALLBACK_HOST']?.trim();
    if (h != null && h.isNotEmpty) return h;
    return 'https://routing.openstreetmap.de/routed-car';
  }
  static const String osrmRouteEndpoint = '/route/v1/driving';
  static const String osrmTripEndpoint = '/trip/v1/driving';
  static const String osrmMatchEndpoint = '/match/v1/driving';

  /// Полный URL для OSRM match API (snap-to-road)
  static String get osrmMatchUrl => '$osrmBaseUrl$osrmMatchEndpoint';

  /// Полный URL для OSRM route API
  static String get osrmRouteUrl => '$osrmBaseUrl$osrmRouteEndpoint';

  /// Полный URL для OSRM trip API
  static String get osrmTripUrl => '$osrmBaseUrl$osrmTripEndpoint';

  /// Fallback URLs
  static String get osrmFallbackRouteUrl => '$osrmFallbackBaseUrl$osrmRouteEndpoint';
  static String get osrmFallbackTripUrl => '$osrmFallbackBaseUrl$osrmTripEndpoint';

  /// Список всех OSRM route URL (основной + fallback)
  static List<String> get osrmRouteUrls => [osrmRouteUrl, osrmFallbackRouteUrl];
  static List<String> get osrmTripUrls => [osrmTripUrl, osrmFallbackTripUrl];

  // ========== Google Maps API ==========
  static const String googleMapsBaseUrl = 'https://www.google.com/maps';
  static const String googleMapsApiBaseUrl =
      'https://maps.googleapis.com/maps/api';

  /// URL для открытия навигации в Google Maps
  static String get googleMapsDirectionsUrl => '$googleMapsBaseUrl/dir/';

  /// URL для Google Directions API
  static String get googleDirectionsApiUrl =>
      '$googleMapsApiBaseUrl/directions/json';

  /// URL для Google Geocoding API
  static String get googleGeocodingApiUrl =>
      '$googleMapsApiBaseUrl/geocode/json';

  /// URL для Google Places API
  static String get googlePlacesApiUrl =>
      '$googleMapsApiBaseUrl/place/details/json';

  /// URL для Google Roads API
  static String get googleRoadsApiUrl =>
      'https://roads.googleapis.com/v1/snapToRoads';

  // ========== Параметры запросов ==========

  /// Параметры для OSRM запросов
  static const String osrmOverviewFull = 'overview=full';
  static const String osrmGeometriesPolyline = 'geometries=polyline';
  static const String osrmAnnotations = 'annotations=duration,distance';

  /// Стандартные параметры для OSRM route
  static String get osrmRouteParams =>
      '$osrmOverviewFull&$osrmGeometriesPolyline';

  /// Стандартные параметры для OSRM trip (с оптимизацией)
  static String get osrmTripParams =>
      'source=first&destination=last&roundtrip=false&$osrmOverviewFull&$osrmGeometriesPolyline';

  /// Параметры для OSRM trip с кольцевым маршрутом (склад→точки→склад)
  static String get osrmTripRoundtripParams =>
      'source=first&roundtrip=true&$osrmOverviewFull&$osrmGeometriesPolyline';

  // ========== Precision для polyline ==========

  /// Precision для OSRM polyline (всегда 5)
  static const int osrmPolylinePrecision = 5;

  /// Precision для Google Maps polyline (обычно 5, но может быть 6)
  static const int googlePolylinePrecision = 5;
}
