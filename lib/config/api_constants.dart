// lib/config/api_constants.dart

/// Константы для API endpoints и URL
class ApiConstants {
  // Приватный конструктор чтобы предотвратить создание экземпляров
  ApiConstants._();

  // ========== OSRM API ==========
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  static const String osrmRouteEndpoint = '/route/v1/driving';
  static const String osrmTripEndpoint = '/trip/v1/driving';
  
  /// Полный URL для OSRM route API
  static String get osrmRouteUrl => '$osrmBaseUrl$osrmRouteEndpoint';
  
  /// Полный URL для OSRM trip API
  static String get osrmTripUrl => '$osrmBaseUrl$osrmTripEndpoint';

  // ========== Google Maps API ==========
  static const String googleMapsBaseUrl = 'https://www.google.com/maps';
  static const String googleMapsApiBaseUrl = 'https://maps.googleapis.com/maps/api';
  
  /// URL для открытия навигации в Google Maps
  static String get googleMapsDirectionsUrl => '$googleMapsBaseUrl/dir/';
  
  /// URL для Google Directions API
  static String get googleDirectionsApiUrl => '$googleMapsApiBaseUrl/directions/json';
  
  /// URL для Google Geocoding API
  static String get googleGeocodingApiUrl => '$googleMapsApiBaseUrl/geocode/json';
  
  /// URL для Google Places API
  static String get googlePlacesApiUrl => '$googleMapsApiBaseUrl/place/details/json';
  
  /// URL для Google Roads API
  static String get googleRoadsApiUrl => 'https://roads.googleapis.com/v1/snapToRoads';

  // ========== Параметры запросов ==========
  
  /// Параметры для OSRM запросов
  static const String osrmOverviewFull = 'overview=full';
  static const String osrmGeometriesPolyline = 'geometries=polyline';
  static const String osrmAnnotations = 'annotations=duration,distance';
  
  /// Стандартные параметры для OSRM route
  static String get osrmRouteParams => '$osrmOverviewFull&$osrmGeometriesPolyline';
  
  /// Стандартные параметры для OSRM trip (с оптимизацией)
  static String get osrmTripParams => 
      'source=first&destination=last&roundtrip=false&$osrmOverviewFull&$osrmGeometriesPolyline';

  // ========== Precision для polyline ==========
  
  /// Precision для OSRM polyline (всегда 5)
  static const int osrmPolylinePrecision = 5;
  
  /// Precision для Google Maps polyline (обычно 5, но может быть 6)
  static const int googlePolylinePrecision = 5;
}
