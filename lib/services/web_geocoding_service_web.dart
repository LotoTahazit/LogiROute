// lib/services/web_geocoding_service_web.dart
// Геокодинг для web через Google Maps JavaScript API
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
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
  static JSObject? _geocoder;

  /// Инициализация геокодера
  static void _ensureInitialized() {
    if (_geocoder != null) return;
    try {
      final googleAny = globalContext['google'];
      if (googleAny == null) {
        debugPrint('❌ [WebGeocoding] Google Maps not loaded');
        return;
      }
      final google = googleAny as JSObject;
      final mapsAny = google['maps'];
      if (mapsAny == null) return;
      final maps = mapsAny as JSObject;
      final geocoderCtorAny = maps['Geocoder'];
      if (geocoderCtorAny == null) return;
      final ctor = geocoderCtorAny as JSFunction;
      _geocoder = ctor.callAsConstructor<JSObject>();
    } catch (e) {
      debugPrint('❌ [WebGeocoding] Google Maps not loaded: $e');
      _geocoder = null;
    }

    if (_geocoder == null) {
      debugPrint('❌ [WebGeocoding] Google Maps not loaded');
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
      final request = JSObject();
      request['address'] = address.toJS;

      void onGeocode(JSAny? results, JSAny? status) {
        try {
          final statusStr =
              status != null ? (status as JSString).toDart : '';

          if (statusStr != 'OK' || results == null) {
            debugPrint('❌ [WebGeocoding] Статус: $statusStr');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            return;
          }

          final resultsObj = results as JSObject;
          final lenAny = resultsObj['length'];
          final len = lenAny != null ? (lenAny as JSNumber).toDartInt : 0;
          if (len <= 0) {
            debugPrint('❌ [WebGeocoding] Статус: $statusStr');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            return;
          }

          final firstResult = resultsObj['0'] as JSObject;
          final geometry = firstResult['geometry'] as JSObject;
          final location = geometry['location'] as JSObject;

          final latAny = location.callMethod('lat'.toJS);
          final lngAny = location.callMethod('lng'.toJS);
          final lat = (latAny as JSNumber).toDartDouble;
          final lng = (lngAny as JSNumber).toDartDouble;

          String? formattedAddress;
          try {
            final fa = firstResult['formatted_address'];
            if (fa != null) {
              formattedAddress = (fa as JSString).toDart;
            }
          } catch (e) {
            debugPrint(
                '⚠️ [WebGeocoding] Error parsing formatted_address: $e');
          }

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
        } catch (e) {
          debugPrint('❌ [WebGeocoding] Ошибка парсинга: $e');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      }

      final callback = onGeocode.toJS;
      _geocoder!.callMethod('geocode'.toJS, request, callback);
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
