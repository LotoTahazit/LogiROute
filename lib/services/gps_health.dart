import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/delivery_point.dart';
import '../models/driver_gps_status.dart';

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

  // ───────────────────────── Driver UI health (P0) ─────────────────────────
  // Чистая логика статуса баннера водителя. Источник истины — ВОЗРАСТ ЛОКАЛЬНОГО
  // FIX, а не Firestore timestamp: на стоянке стрим молчит (distanceFilter), но
  // GPS исправен → старый Firestore-таймштамп НЕ должен давать красный «stale».

  /// Решение по статусу баннера. [uiStaleThreshold] — НЕ [staleAfter] (48 ч).
  static DriverGpsStatus evaluateDriverGpsStatus({
    required bool serviceEnabled,
    required bool permissionGranted,
    required Duration? localFixAge,
    required Duration sinceTrackingStart,
    required bool uploadOk,
    required Duration uiStaleThreshold,
  }) {
    if (!serviceEnabled) return DriverGpsStatus.disabled;
    if (!permissionGranted) return DriverGpsStatus.permissionRequired;
    if (localFixAge == null) {
      // Первого fix ещё не было: грейс-период = тот же UI-порог.
      return sinceTrackingStart <= uiStaleThreshold
          ? DriverGpsStatus.waiting
          : DriverGpsStatus.stale;
    }
    if (localFixAge <= uiStaleThreshold) {
      return uploadOk ? DriverGpsStatus.active : DriverGpsStatus.uploadError;
    }
    return DriverGpsStatus.stale;
  }

  static bool _isGreen(DriverGpsStatus s) => s == DriverGpsStatus.active;
  static bool _isRed(DriverGpsStatus s) => s == DriverGpsStatus.stale;

  /// Цвет-флип = переход зелёный↔красный (active↔stale) — его и дребезжим.
  static bool isDriverColorFlip(DriverGpsStatus a, DriverGpsStatus b) =>
      (_isGreen(a) && _isRed(b)) || (_isRed(a) && _isGreen(b));

  /// Антидребезг: цвет-флип не чаще раза в [debounce]. Прочие смены — сразу.
  static bool shouldApplyDriverStatus({
    required DriverGpsStatus current,
    required DriverGpsStatus next,
    required DateTime? lastFlipAt,
    required DateTime now,
    Duration debounce = const Duration(seconds: 30),
  }) {
    if (next == current) return false;
    if (!isDriverColorFlip(current, next)) return true;
    if (lastFlipAt == null) return true;
    return now.difference(lastFlipAt) >= debounce;
  }
}
