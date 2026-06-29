import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/driver_session_service.dart';
import 'package:logiroute/services/firestore_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const companyId = 'c1';
  const driverId = 'd1';
  const deviceA = 'device-a';
  const deviceB = 'device-b';

  Future<DriverSessionService> serviceWithDevice(
    FakeFirebaseFirestore db,
    String deviceId,
  ) async {
    SharedPreferences.setMockInitialValues({
      DriverSessionService.deviceIdPrefKey: deviceId,
    });
    return DriverSessionService(companyId: companyId, firestore: db);
  }

  Future<void> seedSession(
    FakeFirebaseFirestore db, {
    required String deviceId,
    DateTime? lastSeenAt,
  }) async {
    await FirestorePaths(firestore: db)
        .driverSessions(companyId)
        .doc(driverId)
        .set({
      'driverId': driverId,
      'userId': driverId,
      'deviceId': deviceId,
      'deviceLabel': 'Android',
      'active': true,
      'lastSeenAt': Timestamp.fromDate(
        lastSeenAt ?? DateTime(2026, 6, 21, 12, 0),
      ),
      'startedAt': Timestamp.fromDate(DateTime(2026, 6, 21, 11, 0)),
    });
  }

  test('первый вход водителя — сессия создаётся', () async {
    final db = FakeFirebaseFirestore();
    final svc = await serviceWithDevice(db, deviceA);
    final result = await svc.tryClaimOrVerify(driverId: driverId, userId: driverId);
    expect(result.outcome, DriverSessionClaimOutcome.started);
    final snap = await FirestorePaths(firestore: db)
        .driverSessions(companyId)
        .doc(driverId)
        .get();
    expect(snap.data()!['deviceId'], deviceA);
    expect(snap.data()!['active'], isTrue);
  });

  test('второе устройство — blocked при свежей сессии', () async {
    final db = FakeFirebaseFirestore();
    await seedSession(db, deviceId: deviceA, lastSeenAt: DateTime.now());
    final svc = await serviceWithDevice(db, deviceB);
    final result = await svc.tryClaimOrVerify(driverId: driverId, userId: driverId);
    expect(result.outcome, DriverSessionClaimOutcome.blocked);
  });

  test('takeover — второе устройство становится активным', () async {
    final db = FakeFirebaseFirestore();
    await seedSession(db, deviceId: deviceA, lastSeenAt: DateTime.now());
    final svc = await serviceWithDevice(db, deviceB);
    final result = await svc.forceTakeover(driverId: driverId, userId: driverId);
    expect(result.outcome, DriverSessionClaimOutcome.takenOver);
    final snap = await FirestorePaths(firestore: db)
        .driverSessions(companyId)
        .doc(driverId)
        .get();
    expect(snap.data()!['deviceId'], deviceB);
    expect(snap.data()!['takeoverByDeviceId'], deviceB);
  });

  test('после takeover первое устройство — heartbeat false', () async {
    final db = FakeFirebaseFirestore();
    await seedSession(db, deviceId: deviceB, lastSeenAt: DateTime.now());
    final svc = await serviceWithDevice(db, deviceA);
    final ok = await svc.heartbeat(driverId: driverId, userId: driverId);
    expect(ok, isFalse);
  });

  test('stale >5 мин — takeover без блокировки', () async {
    final db = FakeFirebaseFirestore();
    final stale = DateTime(2026, 6, 21, 11, 0);
    await seedSession(db, deviceId: deviceA, lastSeenAt: stale);
    final svc = await serviceWithDevice(db, deviceB);
    final result = await svc.tryClaimOrVerify(driverId: driverId, userId: driverId);
    expect(result.outcome, isNot(DriverSessionClaimOutcome.blocked));
    final snap = await FirestorePaths(firestore: db)
        .driverSessions(companyId)
        .doc(driverId)
        .get();
    expect(snap.data()!['deviceId'], deviceB);
  });
}
