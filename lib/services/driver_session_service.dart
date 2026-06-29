import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/correlation/correlation_context.dart';
import '../models/driver_session.dart';
import '../../models/company_remote_config.dart';
import 'driver_session_logic.dart';
import 'firestore_paths.dart';

enum DriverSessionClaimOutcome {
  verified,
  started,
  takenOver,
  blocked,
}

class DriverSessionClaimResult {
  final DriverSessionClaimOutcome outcome;
  final DriverSession? remote;

  const DriverSessionClaimResult(this.outcome, [this.remote]);

  bool get isBlocked => outcome == DriverSessionClaimOutcome.blocked;
  bool get isActive => !isBlocked;
}

/// Управление device session lock для водителей.
class DriverSessionService {
  static const deviceIdPrefKey = 'driver_device_id';
  static const bgDeviceIdPrefKey = 'bg_device_id';
  static const sessionLostPrefKey = 'driver_session_lost';

  final String companyId;
  final FirebaseFirestore _firestore;
  final Duration _sessionStale;

  DriverSessionService({
    required this.companyId,
    FirebaseFirestore? firestore,
    Duration? sessionStale,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sessionStale = sessionStale ?? CompanyRemoteConfig.defaults.sessionStale;

  static const _uuid = Uuid();

  DocumentReference<Map<String, dynamic>> _sessionRef(String driverId) =>
      FirestorePaths(firestore: _firestore).driverSessions(companyId).doc(driverId);

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(deviceIdPrefKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await prefs.setString(deviceIdPrefKey, id);
    await prefs.setString(bgDeviceIdPrefKey, id);
    return id;
  }

  static Future<String> resolveDeviceLabel() async {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (_) {
      return 'Device';
    }
  }

  static Future<void> markSessionLostFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionLostPrefKey, true);
  }

  static Future<bool> consumeSessionLostFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final lost = prefs.getBool(sessionLostPrefKey) ?? false;
    if (lost) await prefs.setBool(sessionLostPrefKey, false);
    return lost;
  }

  Future<DriverSession?> fetchSession(String driverId) async {
    final snap = await _sessionRef(driverId).get();
    if (!snap.exists) return null;
    return DriverSession.fromMap(snap.data()!);
  }

  Stream<DriverSession?> watchSession(String driverId) {
    return _sessionRef(driverId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return DriverSession.fromMap(snap.data()!);
    });
  }

  Future<DriverSessionClaimResult> tryClaimOrVerify({
    required String driverId,
    required String userId,
    String? correlationId,
  }) async {
    final deviceId = await getOrCreateDeviceId();
    final deviceLabel = await resolveDeviceLabel();
    final ref = _sessionRef(driverId);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final now = Timestamp.now();
      DriverSession? existing;
      if (snap.exists) {
        existing = DriverSession.fromMap(snap.data()!);
      }

      final access = evaluateDriverSessionAccess(
        localDeviceId: deviceId,
        session: existing,
        now: now.toDate(),
        staleThreshold: _sessionStale,
      );

      if (access == DriverSessionAccess.blocked) {
        return DriverSessionClaimResult(
          DriverSessionClaimOutcome.blocked,
          existing,
        );
      }

      final wasTakeover = existing != null &&
          existing.active &&
          existing.deviceId != deviceId;
      final wasNew = existing == null || !existing.active;

      final data = <String, dynamic>{
        'driverId': driverId,
        'userId': userId,
        'deviceId': deviceId,
        'deviceLabel': deviceLabel,
        'active': true,
        'lastSeenAt': now,
        'startedAt': wasNew || wasTakeover
            ? now
            : (existing.startedAt != null
                ? Timestamp.fromDate(existing.startedAt!)
                : now),
      };
      if (wasTakeover) {
        data['takeoverAt'] = now;
        data['takeoverByDeviceId'] = deviceId;
      }
      tx.set(ref, data, SetOptions(merge: true));

      if (wasTakeover) {
        return DriverSessionClaimResult(
          DriverSessionClaimOutcome.takenOver,
          existing,
        );
      }
      if (wasNew) {
        return const DriverSessionClaimResult(DriverSessionClaimOutcome.started);
      }
      return const DriverSessionClaimResult(DriverSessionClaimOutcome.verified);
    }).then((result) async {
      await _auditClaim(
        driverId: driverId,
        userId: userId,
        outcome: result.outcome,
        previous: result.remote,
        correlationId: correlationId,
      );
      return result;
    });
  }

  Future<DriverSessionClaimResult> forceTakeover({
    required String driverId,
    required String userId,
    String? correlationId,
  }) async {
    final deviceId = await getOrCreateDeviceId();
    final deviceLabel = await resolveDeviceLabel();
    final ref = _sessionRef(driverId);
    final previous = await fetchSession(driverId);
    final now = FieldValue.serverTimestamp();

    await ref.set({
      'driverId': driverId,
      'userId': userId,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
      'active': true,
      'lastSeenAt': now,
      'startedAt': now,
      'takeoverAt': now,
      'takeoverByDeviceId': deviceId,
    }, SetOptions(merge: true));

    await _auditClaim(
      driverId: driverId,
      userId: userId,
      outcome: DriverSessionClaimOutcome.takenOver,
      previous: previous,
      correlationId: correlationId,
    );

    return DriverSessionClaimResult(
      DriverSessionClaimOutcome.takenOver,
      previous,
    );
  }

  /// Heartbeat: обновляет lastSeenAt только если deviceId совпадает.
  Future<bool> heartbeat({
    required String driverId,
    required String userId,
    String? correlationId,
  }) async {
    final deviceId = await getOrCreateDeviceId();
    final ref = _sessionRef(driverId);

    try {
      return await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final session = DriverSession.fromMap(snap.data()!);
        if (!driverSessionOwnedByDevice(session, deviceId)) return false;
        tx.update(ref, {
          'lastSeenAt': FieldValue.serverTimestamp(),
          'active': true,
        });
        return true;
      });
    } catch (e) {
      debugPrint('⚠️ [DriverSession] heartbeat failed: $e');
      await _audit(
        type: 'driver_session_heartbeat_failed',
        driverId: driverId,
        userId: userId,
        correlationId: correlationId,
        extra: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Проверка владения сессией (foreground / BG).
  static Future<bool> verifyOwnership({
    required String companyId,
    required String driverId,
    FirebaseFirestore? firestore,
  }) async {
    final deviceId = await getOrCreateDeviceId();
    final ref = FirestorePaths.driverSessionsOf(companyId).doc(driverId);
    final snap = await ref.get();
    if (!snap.exists) return false;
    final session = DriverSession.fromMap(snap.data()!);
    return driverSessionOwnedByDevice(session, deviceId);
  }

  Future<void> releaseSession(String driverId) async {
    final deviceId = await getOrCreateDeviceId();
    final ref = _sessionRef(driverId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final session = DriverSession.fromMap(snap.data()!);
    if (session.deviceId != deviceId) return;
    await ref.set({'active': false}, SetOptions(merge: true));
  }

  Future<void> auditSessionLost({
    required String driverId,
    required String userId,
    String? correlationId,
    DriverSession? remote,
  }) =>
      _audit(
        type: 'driver_session_lost',
        driverId: driverId,
        userId: userId,
        correlationId: correlationId,
        extra: {
          if (remote != null) 'newDeviceId': remote.deviceId,
          if (remote != null) 'newDeviceLabel': remote.deviceLabel,
        },
      );

  Future<void> _auditClaim({
    required String driverId,
    required String userId,
    required DriverSessionClaimOutcome outcome,
    DriverSession? previous,
    String? correlationId,
  }) async {
    final type = switch (outcome) {
      DriverSessionClaimOutcome.started => 'driver_session_started',
      DriverSessionClaimOutcome.takenOver => 'driver_session_taken_over',
      _ => null,
    };
    if (type == null) return;
    await _audit(
      type: type,
      driverId: driverId,
      userId: userId,
      correlationId: correlationId,
      extra: {
        if (previous != null) 'previousDeviceId': previous.deviceId,
        if (previous != null) 'previousDeviceLabel': previous.deviceLabel,
      },
    );
  }

  Future<void> _audit({
    required String type,
    required String driverId,
    required String userId,
    String? correlationId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final trace = correlationIf(
        operation: CorrelatedOperation.driverSession,
        companyId: companyId,
        userId: userId,
        correlationId: correlationId,
      );
      await trace?.audit(
        moduleKey: 'dispatcher',
        type: type,
        entityCollection: 'driver_sessions',
        entityDocId: driverId,
        extra: extra,
      );
    } catch (e) {
      debugPrint('⚠️ [DriverSession] audit $type failed: $e');
    }
  }
}
