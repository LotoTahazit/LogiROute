// lib/services/web_geocoding_service.dart
// Условный экспорт для разных платформ

export 'web_geocoding_service_web.dart' if (dart.library.io) 'web_geocoding_service_mobile.dart';
