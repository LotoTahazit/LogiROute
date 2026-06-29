import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/config/app_config.dart';
import 'package:logiroute/models/driver_session.dart';
import 'package:logiroute/services/driver_session_logic.dart';

void main() {
  const deviceA = 'device-a';
  const deviceB = 'device-b';
  final fresh = DateTime(2026, 6, 21, 12, 0);
  final staleTime = fresh.subtract(const Duration(minutes: 6));

  test('нет сессии — доступ none', () {
    expect(
      evaluateDriverSessionAccess(localDeviceId: deviceA, session: null),
      DriverSessionAccess.none,
    );
  });

  test('первый вход — своё устройство active', () {
    final session = DriverSession(
      driverId: 'd1',
      userId: 'd1',
      deviceId: deviceA,
      active: true,
      lastSeenAt: fresh,
    );
    expect(
      evaluateDriverSessionAccess(
        localDeviceId: deviceA,
        session: session,
        now: fresh,
      ),
      DriverSessionAccess.active,
    );
  });

  test('второе устройство — blocked при свежей сессии', () {
    final session = DriverSession(
      driverId: 'd1',
      userId: 'd1',
      deviceId: deviceA,
      active: true,
      lastSeenAt: fresh,
    );
    expect(
      evaluateDriverSessionAccess(
        localDeviceId: deviceB,
        session: session,
        now: fresh,
      ),
      DriverSessionAccess.blocked,
    );
  });

  test('stale >5 мин — takeover разрешён', () {
    final session = DriverSession(
      driverId: 'd1',
      userId: 'd1',
      deviceId: deviceA,
      active: true,
      lastSeenAt: staleTime,
    );
    expect(
      evaluateDriverSessionAccess(
        localDeviceId: deviceB,
        session: session,
        now: fresh,
      ),
      DriverSessionAccess.stale,
    );
    expect(
      isDriverSessionStale(
        staleTime,
        now: fresh,
        staleThreshold: AppConfig.driverSessionStaleThreshold,
      ),
      isTrue,
    );
  });

  test('takeover — второе устройство владеет сессией', () {
    final session = DriverSession(
      driverId: 'd1',
      userId: 'd1',
      deviceId: deviceB,
      active: true,
      lastSeenAt: fresh,
    );
    expect(driverSessionOwnedByDevice(session, deviceB), isTrue);
    expect(driverSessionOwnedByDevice(session, deviceA), isFalse);
  });

  test('после takeover первое устройство — lost', () {
    final session = DriverSession(
      driverId: 'd1',
      userId: 'd1',
      deviceId: deviceB,
      active: true,
      lastSeenAt: fresh,
    );
    expect(driverSessionOwnedByDevice(session, deviceA), isFalse);
  });

  test('non-driver — bypass (логика не ограничивает без session)', () {
    expect(
      evaluateDriverSessionAccess(localDeviceId: deviceA, session: null),
      DriverSessionAccess.none,
    );
  });
}
