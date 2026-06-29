import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/delivery_point.dart';

/// Сводка GPS по документам `companies/{id}/driver_locations`.
class GpsDriverCounts {
  final int active;
  final int stale;
  final int offline;

  const GpsDriverCounts({
    required this.active,
    required this.stale,
    required this.offline,
  });
}

/// Единая логика GPS health / onboarding (C1).
class GpsHealth {
  GpsHealth._();

  static const staleAfter = Duration(hours: 48);

  static DateTime? locationTimestamp(Map<String, dynamic> data) {
    final raw = data['timestamp'] ?? data['updatedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  static bool hasValidFix(Map<String, dynamic> data) {
    final lat = (data['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 0;
    return DeliveryPoint.isValidCoordinates(lat, lng);
  }

  static bool hasFreshValidFix(
    Map<String, dynamic> data, {
    DateTime? now,
    Duration? staleAfter,
  }) {
    if (!hasValidFix(data)) return false;
    final ts = locationTimestamp(data);
    if (ts == null) return false;
    final clock = now ?? DateTime.now();
    final threshold = staleAfter ?? const Duration(hours: 48);
    return clock.difference(ts) <= threshold;
  }

  static bool isStale(
    Map<String, dynamic> data, {
    DateTime? now,
    Duration? staleAfter,
  }) {
    final ts = locationTimestamp(data);
    if (ts == null) return true;
    final threshold = staleAfter ?? const Duration(hours: 48);
    return (now ?? DateTime.now()).difference(ts) > threshold;
  }

  /// active = on shift + fresh valid fix; offline = isOnShift false; else stale.
  static GpsDriverCounts summarizeDocs(
    Iterable<Map<String, dynamic>> docs, {
    DateTime? now,
    Duration? staleAfter,
  }) {
    var active = 0;
    var stale = 0;
    var offline = 0;
    for (final data in docs) {
      if (data['isOnShift'] == false) {
        offline++;
        continue;
      }
      if (hasFreshValidFix(data, now: now, staleAfter: staleAfter)) {
        active++;
      } else {
        stale++;
      }
    }
    return GpsDriverCounts(active: active, stale: stale, offline: offline);
  }

  /// Onboarding GPS step: хотя бы один on-shift водитель с fresh valid fix.
  static bool onboardingGpsComplete(
    Iterable<Map<String, dynamic>> docs, {
    Duration? staleAfter,
  }) {
    for (final data in docs) {
      if (data['isOnShift'] == false) continue;
      if (hasFreshValidFix(data, staleAfter: staleAfter)) return true;
    }
    return false;
  }
}
