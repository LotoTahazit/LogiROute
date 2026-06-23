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

  /// Город из адреса = последний сегмент после запятой (без страны).
  /// "יהודה הנשיא 15, בית שמש, ישראל" → "בית שמש". null, если города нет.
  static String? _extractCity(String address) {
    final parts = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    while (parts.isNotEmpty &&
        (parts.last == 'ישראל' || parts.last.toLowerCase() == 'israel')) {
      parts.removeLast();
    }
    if (parts.length < 2) return null;
    return parts.last;
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
      // Привязка к Израилю и к ГОРОДУ из адреса. Имена улиц повторяются в
      // разных городах: без locality «יהודה הנשיא 15, בית שמש» мог попасть на
      // одноимённую улицу в Тель-Авиве. С componentRestrictions Google вернёт
      // результат именно в этом городе либо ZERO_RESULTS.
      final comp = JSObject();
      comp['country'] = 'IL'.toJS;
      final reqCity = _extractCity(address);
      if (reqCity != null) comp['locality'] = reqCity.toJS;
      request['componentRestrictions'] = comp;

      void onGeocode(JSAny? results, JSAny? status) {
        try {
          final statusStr = status != null ? (status as JSString).toDart : '';

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
            debugPrint('⚠️ [WebGeocoding] Error parsing formatted_address: $e');
          }

          // Бэкстоп: результат должен быть в том же городе, что в адресе
          // (для ЛЮБОГО города, не только списка). Иначе — отклоняем.
          final reqCity = _extractCity(address);
          if (reqCity != null &&
              formattedAddress != null &&
              !formattedAddress.contains(reqCity)) {
            debugPrint(
                '⚠️ [WebGeocoding] city mismatch: ждали "$reqCity", получили "$formattedAddress" — отклонено');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            return;
          }

          // 🛡️ GUARD: отклоняем координаты за пределами Израиля
          if (lat < 29.0 || lat > 34.0 || lng < 34.0 || lng > 36.5) {
            debugPrint(
                '⚠️ [WebGeocoding] REJECTED — coords outside Israel: ($lat, $lng) for "$address"');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            return;
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
