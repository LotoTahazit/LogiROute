// lib/services/web_geocoding_service_mobile.dart
// Заглушка для мобильных платформ (Android/iOS)

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Результат геокодинга
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String? formattedAddress;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });
}

/// Сервис геокодинга (заглушка для мобильных платформ)
class WebGeocodingService {
  /// Геокодирование адреса (не поддерживается на мобильных)
  static Future<GeocodingResult?> geocode(String address) async {
    debugPrint('❌ [WebGeocoding] Not supported on mobile platforms');
    return null;
  }
}
