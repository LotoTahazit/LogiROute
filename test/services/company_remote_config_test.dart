import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_remote_config.dart';
import 'package:logiroute/services/company_remote_config_validator.dart';
import 'package:logiroute/services/driver_auto_close_logic.dart';
import 'package:logiroute/services/driver_close_undo_state.dart';
import 'package:logiroute/services/driver_session_logic.dart';

void main() {
  group('CompanyRemoteConfig.defaults', () {
    test('returns valid config from AppConfig', () {
      final d = CompanyRemoteConfig.defaults;
      expect(d.autoCloseRadiusMeters, greaterThan(0));
      expect(d.autoCloseResetRadiusMeters, greaterThanOrEqualTo(d.autoCloseRadiusMeters));
      expect(d.autoCloseWaitSeconds, greaterThan(0));
      expect(d.closeUndoSeconds, greaterThan(0));
      expect(d.gpsStaleMinutes, greaterThan(0));
      expect(d.driverSessionHeartbeatSeconds, greaterThan(0));
      expect(d.driverSessionStaleMinutes, greaterThan(0));
      expect(d.backgroundAutoCloseEnabled, isTrue);
      expect(d.driverDeviceSessionLockEnabled, isTrue);
      expect(d.navigationPreferWaze, isTrue);
      expect(d.importPreviewRows, equals(20));
    });

    test('Duration getters match seconds/minutes', () {
      final d = CompanyRemoteConfig.defaults;
      expect(d.autoCloseWait.inSeconds, equals(d.autoCloseWaitSeconds));
      expect(d.closeUndo.inSeconds, equals(d.closeUndoSeconds));
      expect(d.gpsStaleAfter.inMinutes, equals(d.gpsStaleMinutes));
      expect(d.sessionHeartbeat.inSeconds, equals(d.driverSessionHeartbeatSeconds));
      expect(d.sessionStale.inMinutes, equals(d.driverSessionStaleMinutes));
    });
  });

  group('CompanyRemoteConfig.fromMap', () {
    test('missing doc → defaults', () {
      final cfg = CompanyRemoteConfig.fromMap(null);
      final d = CompanyRemoteConfig.defaults;
      expect(cfg.autoCloseRadiusMeters, equals(d.autoCloseRadiusMeters));
      expect(cfg.importPreviewRows, equals(d.importPreviewRows));
    });

    test('partial map merges with defaults', () {
      final cfg = CompanyRemoteConfig.fromMap({'autoCloseRadiusMeters': 75.0});
      expect(cfg.autoCloseRadiusMeters, equals(75.0));
      expect(cfg.importPreviewRows, equals(CompanyRemoteConfig.defaults.importPreviewRows));
    });

    test('empty map → defaults', () {
      final cfg = CompanyRemoteConfig.fromMap({});
      expect(cfg.autoCloseRadiusMeters,
          equals(CompanyRemoteConfig.defaults.autoCloseRadiusMeters));
    });
  });

  group('CompanyRemoteConfigValidator.mergeRaw', () {
    test('null doc → defaults, no invalid fields', () {
      final result = CompanyRemoteConfigValidator.mergeRaw(null);
      expect(result.isValid, isTrue);
      expect(result.invalidFields, isEmpty);
    });

    test('empty map → defaults, no invalid fields', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({});
      expect(result.isValid, isTrue);
    });

    test('valid values are accepted', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'autoCloseRadiusMeters': 80.0,
        'autoCloseWaitSeconds': 120,
        'closeUndoSeconds': 30,
        'gpsStaleMinutes': 60,
        'driverSessionHeartbeatSeconds': 45,
        'driverSessionStaleMinutes': 5,
        'backgroundAutoCloseEnabled': false,
        'navigationPreferWaze': false,
        'importPreviewRows': 50,
      });
      expect(result.isValid, isTrue);
      expect(result.config.autoCloseRadiusMeters, equals(80.0));
      expect(result.config.autoCloseWaitSeconds, equals(120));
      expect(result.config.backgroundAutoCloseEnabled, isFalse);
      expect(result.config.navigationPreferWaze, isFalse);
      expect(result.config.importPreviewRows, equals(50));
    });

    test('invalid radius → ignored, defaults used, field listed', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'autoCloseRadiusMeters': 5.0, // below min 20
      });
      expect(result.invalidFields, contains('autoCloseRadiusMeters'));
      expect(result.config.autoCloseRadiusMeters,
          equals(CompanyRemoteConfig.defaults.autoCloseRadiusMeters));
    });

    test('invalid wait → ignored, defaults used', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'autoCloseWaitSeconds': 10, // below min 30
      });
      expect(result.invalidFields, contains('autoCloseWaitSeconds'));
    });

    test('reset radius below enter radius → corrected to enter radius', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'autoCloseRadiusMeters': 100.0,
        'autoCloseResetRadiusMeters': 80.0, // below enter radius
      });
      expect(result.warnings, contains('autoCloseResetRadiusMeters_corrected'));
      expect(result.config.autoCloseResetRadiusMeters,
          greaterThanOrEqualTo(result.config.autoCloseRadiusMeters));
    });

    test('invalid bool → ignored, default used', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'backgroundAutoCloseEnabled': 'yes', // not a bool
      });
      expect(result.invalidFields, contains('backgroundAutoCloseEnabled'));
      expect(result.config.backgroundAutoCloseEnabled,
          equals(CompanyRemoteConfig.defaults.backgroundAutoCloseEnabled));
    });

    test('invalid preview rows → ignored', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'importPreviewRows': 200, // above max 100
      });
      expect(result.invalidFields, contains('importPreviewRows'));
      expect(result.config.importPreviewRows,
          equals(CompanyRemoteConfig.defaults.importPreviewRows));
    });

    test('multiple invalid fields all listed', () {
      final result = CompanyRemoteConfigValidator.mergeRaw({
        'autoCloseRadiusMeters': 1.0,
        'autoCloseWaitSeconds': 700,
        'gpsStaleMinutes': 0,
      });
      expect(result.invalidFields.length, equals(3));
    });
  });

  group('CompanyRemoteConfigValidator.validateForSave', () {
    CompanyRemoteConfig _cfg({
      double radius = 100,
      double resetRadius = 120,
      int wait = 180,
      int undo = 15,
      int gpsStale = 2880,
      int heartbeat = 45,
      int sessionStale = 5,
      int previewRows = 20,
      bool bgAutoClose = true,
      bool sessionLock = true,
      bool preferWaze = true,
    }) {
      return CompanyRemoteConfig(
        autoCloseRadiusMeters: radius,
        autoCloseResetRadiusMeters: resetRadius,
        autoCloseWaitSeconds: wait,
        closeUndoSeconds: undo,
        gpsStaleMinutes: gpsStale,
        driverSessionHeartbeatSeconds: heartbeat,
        driverSessionStaleMinutes: sessionStale,
        backgroundAutoCloseEnabled: bgAutoClose,
        driverDeviceSessionLockEnabled: sessionLock,
        navigationPreferWaze: preferWaze,
        importPreviewRows: previewRows,
      );
    }

    test('valid config → null (no error)', () {
      expect(CompanyRemoteConfigValidator.validateForSave(_cfg()), isNull);
    });

    test('radius below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(radius: 10)),
        equals('invalid_auto_close_radius'),
      );
    });

    test('radius above max → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(radius: 500)),
        equals('invalid_auto_close_radius'),
      );
    });

    test('reset radius below enter radius → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(radius: 100, resetRadius: 90)),
        equals('reset_radius_below_enter'),
      );
    });

    test('wait below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(wait: 10)),
        equals('invalid_auto_close_wait'),
      );
    });

    test('wait above max → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(wait: 700)),
        equals('invalid_auto_close_wait'),
      );
    });

    test('undo below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(undo: 2)),
        equals('invalid_close_undo'),
      );
    });

    test('undo above max → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(undo: 120)),
        equals('invalid_close_undo'),
      );
    });

    test('gps stale below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(gpsStale: 5)),
        equals('invalid_gps_stale'),
      );
    });

    test('heartbeat below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(heartbeat: 5)),
        equals('invalid_heartbeat'),
      );
    });

    test('session stale above max → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(sessionStale: 60)),
        equals('invalid_session_stale'),
      );
    });

    test('preview rows below min → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(previewRows: 2)),
        equals('invalid_preview_rows'),
      );
    });

    test('preview rows above max → error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(_cfg(previewRows: 200)),
        equals('invalid_preview_rows'),
      );
    });

    test('bool flags can be false without error', () {
      expect(
        CompanyRemoteConfigValidator.validateForSave(
          _cfg(bgAutoClose: false, sessionLock: false, preferWaze: false),
        ),
        isNull,
      );
    });
  });

  group('CompanyRemoteConfig.toMap / fromMap round-trip', () {
    test('toMap then fromMap preserves all values', () {
      const orig = CompanyRemoteConfig(
        autoCloseRadiusMeters: 75.0,
        autoCloseResetRadiusMeters: 90.0,
        autoCloseWaitSeconds: 120,
        closeUndoSeconds: 30,
        gpsStaleMinutes: 60,
        driverSessionHeartbeatSeconds: 45,
        driverSessionStaleMinutes: 5,
        backgroundAutoCloseEnabled: false,
        driverDeviceSessionLockEnabled: false,
        navigationPreferWaze: false,
        importPreviewRows: 50,
      );
      final map = orig.toMap();
      final restored = CompanyRemoteConfig.fromMap(map);
      expect(restored.autoCloseRadiusMeters, equals(75.0));
      expect(restored.autoCloseResetRadiusMeters, equals(90.0));
      expect(restored.autoCloseWaitSeconds, equals(120));
      expect(restored.closeUndoSeconds, equals(30));
      expect(restored.gpsStaleMinutes, equals(60));
      expect(restored.driverSessionHeartbeatSeconds, equals(45));
      expect(restored.driverSessionStaleMinutes, equals(5));
      expect(restored.backgroundAutoCloseEnabled, isFalse);
      expect(restored.driverDeviceSessionLockEnabled, isFalse);
      expect(restored.navigationPreferWaze, isFalse);
      expect(restored.importPreviewRows, equals(50));
    });
  });

  group('runtime integration', () {
    test('auto-close uses remote radius', () {
      const rc = CompanyRemoteConfig(
        autoCloseRadiusMeters: 150,
        autoCloseResetRadiusMeters: 180,
        autoCloseWaitSeconds: 120,
        closeUndoSeconds: 20,
        gpsStaleMinutes: 60,
        driverSessionHeartbeatSeconds: 30,
        driverSessionStaleMinutes: 10,
        backgroundAutoCloseEnabled: true,
        driverDeviceSessionLockEnabled: true,
        navigationPreferWaze: true,
        importPreviewRows: 30,
      );
      expect(
        selectNearestDriverAutoCloseTarget(
          driverLat: 0,
          driverLng: 0,
          points: [],
          driverId: 'd1',
          enterRadiusM: rc.autoCloseRadiusMeters,
        ),
        isNull,
      );
      expect(
        shouldResetDriverAutoCloseTimer(
          distanceMeters: 160,
          resetRadiusM: rc.autoCloseResetRadiusMeters,
        ),
        isFalse,
      );
    });

    test('undo uses remote duration', () {
      const undoSec = 25;
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      final remaining = closeUndoRemainingUi(
        t0,
        t0.add(const Duration(seconds: 10)),
        maxUi: Duration(seconds: undoSec),
      );
      expect(remaining.inSeconds, equals(15));
    });

    test('session stale uses remote value', () {
      expect(
        isDriverSessionStale(
          DateTime.now().subtract(const Duration(minutes: 11)),
          staleThreshold: const Duration(minutes: 10),
        ),
        isTrue,
      );
    });

    test('import preview rows from config', () {
      const rc = CompanyRemoteConfig(
        autoCloseRadiusMeters: 100,
        autoCloseResetRadiusMeters: 120,
        autoCloseWaitSeconds: 180,
        closeUndoSeconds: 15,
        gpsStaleMinutes: 2880,
        driverSessionHeartbeatSeconds: 45,
        driverSessionStaleMinutes: 5,
        backgroundAutoCloseEnabled: true,
        driverDeviceSessionLockEnabled: true,
        navigationPreferWaze: true,
        importPreviewRows: 42,
      );
      expect(rc.importPreviewRows, equals(42));
    });
  });
}
