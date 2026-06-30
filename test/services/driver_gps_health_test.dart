import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_remote_config.dart';
import 'package:logiroute/models/driver_gps_status.dart';
import 'package:logiroute/services/company_remote_config_validator.dart';
import 'package:logiroute/services/gps_health.dart';

void main() {
  // UI-порог по умолчанию (driverGpsUiStaleSeconds = 180).
  const ui = Duration(seconds: 180);

  group('GpsHealth.evaluateDriverGpsStatus', () {
    test('свежий локальный fix + старый Firestore (uploadOk) → Active, не Stale',
        () {
      // localFixAge свежий; «старый Firestore timestamp» НЕ участвует в решении.
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: const Duration(seconds: 20),
        sinceTrackingStart: const Duration(minutes: 10),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.active);
    });

    test('свежий локальный fix + Firestore upload failed → Upload Warning', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: const Duration(seconds: 20),
        sinceTrackingStart: const Duration(minutes: 10),
        uploadOk: false,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.uploadError);
    });

    test('нет локального fix дольше UI threshold → Stale', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: const Duration(seconds: 240),
        sinceTrackingStart: const Duration(minutes: 10),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.stale);
    });

    test('первый fix ещё не пришёл, в пределах грейса → Waiting', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: null,
        sinceTrackingStart: const Duration(seconds: 30),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.waiting);
    });

    test('первого fix нет дольше грейса → Stale', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: null,
        sinceTrackingStart: const Duration(minutes: 5),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.stale);
    });

    test('служба геолокации выключена → Disabled (приоритет)', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: false,
        permissionGranted: true,
        localFixAge: const Duration(seconds: 5),
        sinceTrackingStart: const Duration(minutes: 1),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.disabled);
    });

    test('нет разрешения → Permission Required', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: false,
        localFixAge: const Duration(seconds: 5),
        sinceTrackingStart: const Duration(minutes: 1),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.permissionRequired);
    });

    test('manual check с текущей позицией (age=0) → Active', () {
      final s = GpsHealth.evaluateDriverGpsStatus(
        serviceEnabled: true,
        permissionGranted: true,
        localFixAge: Duration.zero,
        sinceTrackingStart: const Duration(minutes: 30),
        uploadOk: true,
        uiStaleThreshold: ui,
      );
      expect(s, DriverGpsStatus.active);
    });

    test('применяется UI threshold из Remote Config (а не gpsStaleMinutes)', () {
      const rc = CompanyRemoteConfig(
        autoCloseRadiusMeters: 100,
        autoCloseResetRadiusMeters: 120,
        autoCloseWaitSeconds: 180,
        closeUndoSeconds: 15,
        gpsStaleMinutes: 2880, // 48 ч — НЕ должно влиять на UI
        driverGpsUiStaleSeconds: 300,
        driverSessionHeartbeatSeconds: 45,
        driverSessionStaleMinutes: 5,
        backgroundAutoCloseEnabled: true,
        driverDeviceSessionLockEnabled: true,
        navigationPreferWaze: true,
        importPreviewRows: 20,
      );
      // 240 с: при пороге 180 → stale, при 300 (из RC) → active.
      expect(
        GpsHealth.evaluateDriverGpsStatus(
          serviceEnabled: true,
          permissionGranted: true,
          localFixAge: const Duration(seconds: 240),
          sinceTrackingStart: const Duration(minutes: 10),
          uploadOk: true,
          uiStaleThreshold: ui,
        ),
        DriverGpsStatus.stale,
      );
      expect(
        GpsHealth.evaluateDriverGpsStatus(
          serviceEnabled: true,
          permissionGranted: true,
          localFixAge: const Duration(seconds: 240),
          sinceTrackingStart: const Duration(minutes: 10),
          uploadOk: true,
          uiStaleThreshold: rc.driverGpsUiStale,
        ),
        DriverGpsStatus.active,
      );
    });
  });

  group('GpsHealth debounce (shouldApplyDriverStatus)', () {
    final t0 = DateTime(2026, 6, 30, 12, 0, 0);

    test('тот же статус → не применять', () {
      expect(
        GpsHealth.shouldApplyDriverStatus(
          current: DriverGpsStatus.active,
          next: DriverGpsStatus.active,
          lastFlipAt: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('цвет-флип active→stale в пределах 30 с после флипа → подавляется', () {
      expect(
        GpsHealth.shouldApplyDriverStatus(
          current: DriverGpsStatus.active,
          next: DriverGpsStatus.stale,
          lastFlipAt: t0.subtract(const Duration(seconds: 10)),
          now: t0,
        ),
        isFalse,
      );
    });

    test('цвет-флип active→stale спустя 30 с → применяется', () {
      expect(
        GpsHealth.shouldApplyDriverStatus(
          current: DriverGpsStatus.active,
          next: DriverGpsStatus.stale,
          lastFlipAt: t0.subtract(const Duration(seconds: 31)),
          now: t0,
        ),
        isTrue,
      );
    });

    test('первый флип (lastFlipAt == null) → применяется', () {
      expect(
        GpsHealth.shouldApplyDriverStatus(
          current: DriverGpsStatus.active,
          next: DriverGpsStatus.stale,
          lastFlipAt: null,
          now: t0,
        ),
        isTrue,
      );
    });

    test('не цвет-флип (active→uploadError) → применяется сразу', () {
      expect(
        GpsHealth.shouldApplyDriverStatus(
          current: DriverGpsStatus.active,
          next: DriverGpsStatus.uploadError,
          lastFlipAt: t0,
          now: t0,
        ),
        isTrue,
      );
    });

    test('isDriverColorFlip: только active↔stale', () {
      expect(
        GpsHealth.isDriverColorFlip(
            DriverGpsStatus.active, DriverGpsStatus.stale),
        isTrue,
      );
      expect(
        GpsHealth.isDriverColorFlip(
            DriverGpsStatus.stale, DriverGpsStatus.active),
        isTrue,
      );
      expect(
        GpsHealth.isDriverColorFlip(
            DriverGpsStatus.active, DriverGpsStatus.uploadError),
        isFalse,
      );
    });
  });

  group('Remote Config driverGpsUiStaleSeconds', () {
    test('default = 180, getter = 180 с', () {
      final d = CompanyRemoteConfig.defaults;
      expect(d.driverGpsUiStaleSeconds, 180);
      expect(d.driverGpsUiStale.inSeconds, 180);
    });

    test('валидное значение принимается', () {
      final r = CompanyRemoteConfigValidator.mergeRaw(
          {'driverGpsUiStaleSeconds': 300});
      expect(r.config.driverGpsUiStaleSeconds, 300);
      expect(r.invalidFields, isEmpty);
    });

    test('ниже минимума (60) → игнор, default, поле в invalid', () {
      final r = CompanyRemoteConfigValidator.mergeRaw(
          {'driverGpsUiStaleSeconds': 30});
      expect(r.invalidFields, contains('driverGpsUiStaleSeconds'));
      expect(r.config.driverGpsUiStaleSeconds, 180);
    });

    test('выше максимума (900) → игнор', () {
      final r = CompanyRemoteConfigValidator.mergeRaw(
          {'driverGpsUiStaleSeconds': 1200});
      expect(r.invalidFields, contains('driverGpsUiStaleSeconds'));
    });

    test('validateForSave: вне диапазона → ключ ошибки', () {
      final cfg = CompanyRemoteConfig.defaults;
      final bad = CompanyRemoteConfig(
        autoCloseRadiusMeters: cfg.autoCloseRadiusMeters,
        autoCloseResetRadiusMeters: cfg.autoCloseResetRadiusMeters,
        autoCloseWaitSeconds: cfg.autoCloseWaitSeconds,
        closeUndoSeconds: cfg.closeUndoSeconds,
        gpsStaleMinutes: cfg.gpsStaleMinutes,
        driverGpsUiStaleSeconds: 10,
        driverSessionHeartbeatSeconds: cfg.driverSessionHeartbeatSeconds,
        driverSessionStaleMinutes: cfg.driverSessionStaleMinutes,
        backgroundAutoCloseEnabled: cfg.backgroundAutoCloseEnabled,
        driverDeviceSessionLockEnabled: cfg.driverDeviceSessionLockEnabled,
        navigationPreferWaze: cfg.navigationPreferWaze,
        importPreviewRows: cfg.importPreviewRows,
      );
      expect(
        CompanyRemoteConfigValidator.validateForSave(bad),
        'invalid_driver_gps_ui_stale',
      );
    });

    test('toMap/fromMap round-trip сохраняет поле', () {
      final r =
          CompanyRemoteConfig.fromMap(CompanyRemoteConfig.defaults.toMap());
      expect(r.driverGpsUiStaleSeconds, 180);
    });
  });
}
