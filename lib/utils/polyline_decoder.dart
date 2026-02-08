// lib/utils/polyline_decoder.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

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
    debugPrint('🔍 [PolylineDecoder] Decoding: ${encoded.length} chars, precision=$precision');
    debugPrint('🔍 [PolylineDecoder] First 50 chars: ${encoded.substring(0, encoded.length > 50 ? 50 : encoded.length)}');

    try {
      // Используем готовую библиотеку для декодирования
      final List<List<num>> decoded = decodePolyline(encoded, accuracyExponent: precision);
      
      final List<LatLng> points = decoded.map((point) {
        return LatLng(point[0].toDouble(), point[1].toDouble());
      }).toList();
      
      debugPrint('✅ [PolylineDecoder] Decoded ${points.length} points');
      if (points.isNotEmpty) {
        debugPrint('📍 [PolylineDecoder] First: ${points.first}');
        if (points.length > 1) {
          debugPrint('📍 [PolylineDecoder] Second: ${points[1]}');
        }
        debugPrint('📍 [PolylineDecoder] Last: ${points.last}');
      }
      
      return points;
    } catch (e, stackTrace) {
      debugPrint('❌ [PolylineDecoder] Error: $e');
      debugPrint('❌ [PolylineDecoder] Stack: $stackTrace');
      return [];
    }
  }

  /// Проверяет валидность декодированных точек
  static bool isValid(List<LatLng> points, {int minPoints = 10}) {
    debugPrint('🔍 [PolylineDecoder] Validating ${points.length} points (min: $minPoints)');
    
    if (points.length < minPoints) {
      debugPrint('❌ [PolylineDecoder] Too few points: ${points.length} < $minPoints');
      return false;
    }
    
    // Проверяем только первые и последние точки на NaN
    if (points.first.latitude.isNaN || points.first.longitude.isNaN ||
        points.last.latitude.isNaN || points.last.longitude.isNaN) {
      debugPrint('❌ [PolylineDecoder] First or last point is NaN');
      return false;
    }
    
    debugPrint('✅ [PolylineDecoder] Polyline is valid: ${points.length} points');
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
