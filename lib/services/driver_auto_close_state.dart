import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_point.dart';
import 'firestore_paths.dart';

/// Персистентное состояние автозакрытия (SharedPreferences) — общее для UI и BG isolate.
class DriverAutoCloseState {
  static const _pendingPointId = 'ac_pending_point_id';
  static const _pendingStartedAtMs = 'ac_pending_started_at_ms';
  static const _lastLat = 'ac_last_lat';
  static const _lastLng = 'ac_last_lng';
  static const _systemStoppedBg = 'bg_system_stopped';

  static Future<void> savePending({
    required String pointId,
    required DateTime startedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPointId, pointId);
    await prefs.setInt(_pendingStartedAtMs, startedAt.millisecondsSinceEpoch);
  }

  static Future<({String pointId, DateTime startedAt})?> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pointId = prefs.getString(_pendingPointId);
    final ms = prefs.getInt(_pendingStartedAtMs);
    if (pointId == null || ms == null) return null;
    return (pointId: pointId, startedAt: DateTime.fromMillisecondsSinceEpoch(ms));
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPointId);
    await prefs.remove(_pendingStartedAtMs);
  }

  static Future<void> saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLat, lat);
    await prefs.setDouble(_lastLng, lng);
  }

  static Future<({double lat, double lng})?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastLat);
    final lng = prefs.getDouble(_lastLng);
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  static Future<void> markSystemStoppedBg(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemStoppedBg, value);
  }

  static Future<bool> wasSystemStoppedBg() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_systemStoppedBg) ?? false;
  }

  static Future<void> clearSystemStoppedBg() async {
    await markSystemStoppedBg(false);
  }

  /// Закрывает точку один раз (транзакция + visit_logs). Возвращает true если закрыли.
  static Future<bool> tryCompletePoint({
    required String companyId,
    required String pointId,
    required String driverId,
    required double lat,
    required double lng,
    required double distanceMeters,
    required String correlationId,
  }) async {
    final pointRef = FirestorePaths.deliveryPointsOf(companyId).doc(pointId);
    final closed = await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(pointRef);
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final status = DeliveryPoint.normalizeStatus(data['status'] as String?);
      if (status == DeliveryPoint.statusCompleted ||
          status == DeliveryPoint.statusCancelled) {
        return false;
      }
      tx.update(pointRef, {
        'status': DeliveryPoint.statusCompleted,
        'completedAt': FieldValue.serverTimestamp(),
        'autoCompleted': true,
        'updatedByUid': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!closed) return false;

    try {
      await pointRef.collection('visit_logs').add({
        'lat': lat,
        'lng': lng,
        'driverId': driverId,
        'autoCompleted': true,
        'distanceM': distanceMeters.round(),
        'correlationId': correlationId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await clearPending();
    return true;
  }

  /// in_progress при первом входе в радиус (идемпотентно).
  static Future<void> markInProgressIfNeeded({
    required String companyId,
    required String pointId,
    required String driverId,
    required String currentStatus,
  }) async {
    if (DeliveryPoint.normalizeStatus(currentStatus) !=
        DeliveryPoint.statusAssigned) {
      return;
    }
    await FirestorePaths.deliveryPointsOf(companyId).doc(pointId).update({
      'status': DeliveryPoint.statusInProgress,
      'arrivedAt': FieldValue.serverTimestamp(),
      'updatedByUid': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
