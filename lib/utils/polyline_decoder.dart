// lib/utils/polyline_decoder.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

/// Утилита для декодирования encoded polyline в координаты
/// Поддерживает precision 5 (OSRM) и precision 6 (Google Maps)
class PolylineDecoder {
  /// Декодирует encoded polyline строку в список координат
  /// 
  /// [encoded] - закодированная polyline строка
  /// [precision] - точность кодирования (5 для OSRM, 6 для Google Maps)
  /// 
  /// Возвращает список LatLng координат
  static List<LatLng> decode(String encoded, {int precision = 5}) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    final int len = encoded.length;
    final double factor = (precision == 6) ? 1e6 : 1e5;

    debugPrint('🔍 [PolylineDecoder] Decoding: ${encoded.length} chars, precision=$precision, factor=$factor');

    try {
      while (index < len) {
        // Декодируем широту
        int shift = 0;
        int result = 0;
        int byte;
        
        do {
          if (index >= len) {
            if (kDebugMode) {
              debugPrint('⚠️ [PolylineDecoder] Unexpected end while decoding latitude');
            }
            return points;
          }
          byte = encoded.codeUnitAt(index++) - 63;
          if (byte < 0 || byte > 95) {
            if (kDebugMode) {
              debugPrint('⚠️ [PolylineDecoder] Invalid byte: $byte at index ${index-1}');
            }
            return points;
          }
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        
        final int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += deltaLat;

        if (index >= len) {
          if (kDebugMode) {
            debugPrint('⚠️ [PolylineDecoder] Unexpected end after latitude');
          }
          return points;
        }

        // Декодируем долготу
        shift = 0;
        result = 0;
        
        do {
          if (index >= len) {
            if (kDebugMode) {
              debugPrint('⚠️ [PolylineDecoder] Unexpected end while decoding longitude');
            }
            return points;
          }
          byte = encoded.codeUnitAt(index++) - 63;
          if (byte < 0 || byte > 95) {
            if (kDebugMode) {
              debugPrint('⚠️ [PolylineDecoder] Invalid byte: $byte at index ${index-1}');
            }
            return points;
          }
          result |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20);
        
        final int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += deltaLng;

        final double decodedLat = lat / factor;
        final double decodedLng = lng / factor;
        
        // Проверяем валидность координат
        if (decodedLat.abs() < 85 && decodedLng.abs() <= 180 && 
            !decodedLat.isNaN && !decodedLng.isNaN) {
          points.add(LatLng(decodedLat, decodedLng));
          
          // Логируем первые несколько точек для отладки
          if (points.length <= 3) {
            debugPrint('📍 [PolylineDecoder] Point ${points.length}: lat=$decodedLat, lng=$decodedLng');
          }
        } else {
          debugPrint('⚠️ [PolylineDecoder] Invalid point: lat=$decodedLat, lng=$decodedLng (raw: lat=$lat, lng=$lng)');
          // Если слишком много невалидных точек, прерываем
          if (points.isEmpty && index > 100) {
            debugPrint('❌ [PolylineDecoder] Too many invalid points, stopping');
            return [];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PolylineDecoder] Error: $e');
      }
      return points.isNotEmpty ? points : [];
    }

    debugPrint('✅ [PolylineDecoder] Decoded ${points.length} valid points');
    if (points.isNotEmpty) {
      debugPrint('📍 [PolylineDecoder] First: ${points.first}');
      debugPrint('📍 [PolylineDecoder] Last: ${points.last}');
    }
    
    return points;
  }

  /// Проверяет валидность декодированных точек
  static bool isValid(List<LatLng> points, {int minPoints = 2}) {
    debugPrint('🔍 [PolylineDecoder] Validating ${points.length} points (min: $minPoints)');
    
    if (points.length < minPoints) {
      debugPrint('❌ [PolylineDecoder] Too few points: ${points.length} < $minPoints');
      return false;
    }
    
    int invalidCount = 0;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.latitude.isNaN ||
          p.longitude.isNaN ||
          p.latitude.abs() >= 85 ||
          p.longitude.abs() > 180) {
        invalidCount++;
        if (invalidCount <= 3) {
          debugPrint('❌ [PolylineDecoder] Invalid point $i: lat=${p.latitude}, lng=${p.longitude}');
        }
      }
    }
    
    if (invalidCount > 0) {
      debugPrint('❌ [PolylineDecoder] Found $invalidCount invalid points out of ${points.length}');
      return false;
    }
    
    debugPrint('✅ [PolylineDecoder] All ${points.length} points are valid');
    return true;
  }

  /// Санитизирует polyline строку (убирает кавычки, escape-символы)
  static String sanitize(String raw) {
    var s = raw.trim();

    // Убираем кавычки
    if (s.length >= 2) {
      if ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'"))) {
        s = s.substring(1, s.length - 1);
      }
    }

    // Убираем ведущие обратные слэши
    while (s.startsWith(r'\')) {
      s = s.substring(1);
    }

    // Убираем управляющие символы
    s = s.replaceAll(RegExp(r'[\r\n\t]'), '');

    if (kDebugMode && s.length != raw.length) {
      debugPrint('🧹 [PolylineDecoder] Sanitized: ${s.length} chars (was ${raw.length})');
    }
    
    return s;
  }
}
