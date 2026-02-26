// lib/services/web_geocoding_service_web.dart
// Геокодинг для web через Google Maps JavaScript API
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js' as js;
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

/// Сервис геокодинга для web через Google Maps JavaScript API
class WebGeocodingService {
  static js.JsObject? _geocoder;

  /// Инициализация геокодера
  static void _ensureInitialized() {
    if (_geocoder == null) {
      final google = js.context['google'];
      if (google != null) {
        final maps = google['maps'];
        if (maps != null) {
          final geocoderClass = maps['Geocoder'];
          if (geocoderClass != null) {
            _geocoder = js.JsObject(geocoderClass);
          }
        }
      }

      if (_geocoder == null) {
        debugPrint('❌ [WebGeocoding] Google Maps not loaded');
      }
      if (_geocoder == null) {
        debugPrint('❌ [WebGeocoding] Google Maps not loaded');
      }
    }
  }

  static Future<GeocodingResult?> geocode(String address) async {
    _ensureInitialized();

    if (_geocoder == null) {
      debugPrint('❌ [WebGeocoding] Geocoder not available');
      return null;
    }

    final completer = Completer<GeocodingResult?>();

    try {
      final request = js.JsObject.jsify({'address': address});

      final callback = js.JsFunction.withThis(
        (self, results, status) {
          try {
            if (status == 'OK' && results != null && results.length > 0) {
              final firstResult = results[0];
              final geometry = firstResult['geometry'];
              final location = geometry['location'];

              // Получаем lat/lng через методы
              final lat = location.callMethod('lat', []) as double;
              final lng = location.callMethod('lng', []) as double;

              // Получаем форматированный адрес
              String? formattedAddress;
              try {
                formattedAddress = firstResult['formatted_address'] as String?;
              } catch (_) {}

              // ✅ ПРОВЕРКА: Если в запросе был конкретный город, проверяем результат
              final cityChecks = {
                'חולון': ['חולון', 'Holon'],
                'Holon': ['חולון', 'Holon'],
                'ראשון לציון': ['ראשון לציון', 'Rishon'],
                'Rishon': ['ראשון לציון', 'Rishon'],
                'תל אביב': ['תל אביב', 'Tel Aviv'],
                'Tel Aviv': ['תל אביב', 'Tel Aviv'],
              };

              for (final entry in cityChecks.entries) {
                if (address.contains(entry.key)) {
                  final cityFound = entry.value.any(
                    (city) => formattedAddress?.contains(city) ?? false,
                  );
                  if (!cityFound) {
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                    return;
                  }
                }
              }

              if (!completer.isCompleted) {
                completer.complete(GeocodingResult(
                  latitude: lat,
                  longitude: lng,
                  formattedAddress: formattedAddress,
                ));
              }
            } else {
              debugPrint('❌ [WebGeocoding] Статус: $status');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            }
          } catch (e) {
            debugPrint('❌ [WebGeocoding] Ошибка парсинга: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [WebGeocoding] Ошибка: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('❌ [WebGeocoding] Таймаут');
        return null;
      },
    );
  }
}
