// lib/utils/polyline_decoder.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class PolylineDecoder {
  static List<LatLng> decode(String encoded, {int precision = 5}) {
    try {
      final List<List<num>> decoded =
          decodePolyline(encoded, accuracyExponent: precision);
      return decoded
          .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
          .toList();
    } catch (e) {
      debugPrint('❌ [PolylineDecoder] Error: $e');
      return [];
    }
  }

  static bool isValid(List<LatLng> points, {int minPoints = 10}) {
    if (points.length < minPoints) return false;
    if (points.first.latitude.isNaN ||
        points.first.longitude.isNaN ||
        points.last.latitude.isNaN ||
        points.last.longitude.isNaN) return false;
    return true;
  }

  static String sanitize(String raw) {
    var s = raw.trim();
    if (s.length >= 2) {
      if ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'"))) {
        s = s.substring(1, s.length - 1);
      }
    }
    while (s.startsWith(r'\')) {
      s = s.substring(1);
    }
    s = s.replaceAll(RegExp(r'[\r\n\t]'), '');
    return s;
  }
}
