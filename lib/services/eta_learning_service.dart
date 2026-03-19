import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EtaLearningService {
  final String companyId;

  EtaLearningService(this.companyId);

  // === CONFIG ===
  static const int _minUpdateIntervalSec = 10;
  static const double _minSpeed = 3.0; // m/s (~10.8 km/h)
  static const double _maxSpeed = 25.0; // m/s (~90 km/h)

  DateTime? _lastUpdate;

  // === LOCAL CACHE ===
  final Map<String, double> _speedCache = {};
  DateTime? _lastCacheSync;
  static const int _cacheTtlSec = 60;
  static const double _fallbackSpeed = 10.0; // m/s (~36 km/h)

  // === SEGMENT ID ===
  String getSegmentId(double lat, double lng) {
    final rLat = (lat * 1000).round() / 1000;
    final rLng = (lng * 1000).round() / 1000;
    return '$rLat,$rLng';
  }

  // === MAIN LEARNING METHOD ===
  Future<void> updateLearning(Position pos) async {
    final now = DateTime.now();

    // Throttle: at most one write every 10 seconds
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inSeconds < _minUpdateIntervalSec) {
      return;
    }

    _lastUpdate = now;

    final speed = pos.speed.clamp(_minSpeed, _maxSpeed);

    // Protection from invalid values
    if (speed.isNaN || speed <= 0) return;

    final segmentId = getSegmentId(pos.latitude, pos.longitude);
    _speedCache[segmentId] = speed;

    final ref = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('analytics')
        .doc('road_segments')
        .collection('segments')
        .doc(segmentId);

    try {
      await ref.set({
        'avgSpeed': speed,
        'samples': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Learning must never break the app
    }
  }

  Future<double> getSpeedForSegment(String segmentId) async {
    if (_speedCache.containsKey(segmentId)) {
      return _speedCache[segmentId]!;
    }

    final now = DateTime.now();
    if (_lastCacheSync != null &&
        now.difference(_lastCacheSync!).inSeconds < _cacheTtlSec) {
      return _fallbackSpeed;
    }

    _lastCacheSync = now;

    try {
      final ref = FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('analytics')
          .doc('road_segments')
          .collection('segments')
          .doc(segmentId);

      final doc = await ref.get();

      if (doc.exists) {
        final speed = (doc.data()!['avgSpeed'] as num).toDouble();
        _speedCache[segmentId] = speed;
        return speed;
      }
    } catch (_) {
      // ignore
    }

    return _fallbackSpeed;
  }

  Future<int> calculateEtaSeconds({
    required List<LatLng> polyline,
    required LatLng driverPos,
    required double smoothedSpeed,
  }) async {
    if (polyline.length < 2) return 0;

    int nearestIndex = 0;
    double minDist = double.infinity;

    for (int i = 0; i < polyline.length; i++) {
      final p = polyline[i];
      final d = Geolocator.distanceBetween(
        driverPos.latitude,
        driverPos.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }

    double totalSeconds = 0;

    for (int i = nearestIndex; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];

      final dist = Geolocator.distanceBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );

      final segmentId = getSegmentId(p1.latitude, p1.longitude);
      final learnedSpeed = await getSpeedForSegment(segmentId);

      double speed = (learnedSpeed * 0.7) + (smoothedSpeed * 0.3);
      if (speed.isNaN || speed < 3) speed = 3;
      if (speed > 25) speed = 25;

      totalSeconds += dist / speed;
    }

    return totalSeconds.round();
  }
}
