import '../models/company_remote_config.dart';

class CompanyRemoteConfigValidation {
  final CompanyRemoteConfig config;
  final List<String> invalidFields;
  final List<String> warnings;

  const CompanyRemoteConfigValidation({
    required this.config,
    this.invalidFields = const [],
    this.warnings = const [],
  });

  bool get isValid => invalidFields.isEmpty;
}

class CompanyRemoteConfigValidator {
  static const radiusMin = 20.0;
  static const radiusMax = 300.0;
  static const waitMin = 30;
  static const waitMax = 600;
  static const undoMin = 5;
  static const undoMax = 60;
  static const gpsStaleMin = 10;
  static const gpsStaleMax = 2880;
  static const heartbeatMin = 15;
  static const heartbeatMax = 120;
  static const sessionStaleMin = 2;
  static const sessionStaleMax = 30;
  static const previewMin = 5;
  static const previewMax = 100;

  /// UI save: returns null if ok, else error key.
  static String? validateForSave(CompanyRemoteConfig c) {
    if (c.autoCloseRadiusMeters < radiusMin ||
        c.autoCloseRadiusMeters > radiusMax) {
      return 'invalid_auto_close_radius';
    }
    if (c.autoCloseResetRadiusMeters < c.autoCloseRadiusMeters) {
      return 'reset_radius_below_enter';
    }
    if (c.autoCloseResetRadiusMeters > radiusMax) {
      return 'invalid_reset_radius';
    }
    if (c.autoCloseWaitSeconds < waitMin || c.autoCloseWaitSeconds > waitMax) {
      return 'invalid_auto_close_wait';
    }
    if (c.closeUndoSeconds < undoMin || c.closeUndoSeconds > undoMax) {
      return 'invalid_close_undo';
    }
    if (c.gpsStaleMinutes < gpsStaleMin || c.gpsStaleMinutes > gpsStaleMax) {
      return 'invalid_gps_stale';
    }
    if (c.driverSessionHeartbeatSeconds < heartbeatMin ||
        c.driverSessionHeartbeatSeconds > heartbeatMax) {
      return 'invalid_heartbeat';
    }
    if (c.driverSessionStaleMinutes < sessionStaleMin ||
        c.driverSessionStaleMinutes > sessionStaleMax) {
      return 'invalid_session_stale';
    }
    if (c.importPreviewRows < previewMin || c.importPreviewRows > previewMax) {
      return 'invalid_preview_rows';
    }
    return null;
  }

  /// Merge Firestore raw → safe runtime config (invalid fields → defaults).
  static CompanyRemoteConfigValidation mergeRaw(Map<String, dynamic>? raw) {
    final d = CompanyRemoteConfig.defaults;
    if (raw == null || raw.isEmpty) {
      return CompanyRemoteConfigValidation(config: d);
    }

    final invalid = <String>[];
    final warnings = <String>[];

    double radius = d.autoCloseRadiusMeters;
    if (raw.containsKey('autoCloseRadiusMeters')) {
      final v = (raw['autoCloseRadiusMeters'] as num?)?.toDouble();
      if (v != null && v >= radiusMin && v <= radiusMax) {
        radius = v;
      } else {
        invalid.add('autoCloseRadiusMeters');
      }
    }

    double resetRadius = d.autoCloseResetRadiusMeters;
    if (raw.containsKey('autoCloseResetRadiusMeters')) {
      final v = (raw['autoCloseResetRadiusMeters'] as num?)?.toDouble();
      if (v != null && v >= radiusMin && v <= radiusMax) {
        resetRadius = v;
      } else {
        invalid.add('autoCloseResetRadiusMeters');
      }
    }
    if (resetRadius < radius) {
      resetRadius = radius;
      warnings.add('autoCloseResetRadiusMeters_corrected');
    }

    int wait = d.autoCloseWaitSeconds;
    if (raw.containsKey('autoCloseWaitSeconds')) {
      final v = (raw['autoCloseWaitSeconds'] as num?)?.toInt();
      if (v != null && v >= waitMin && v <= waitMax) {
        wait = v;
      } else {
        invalid.add('autoCloseWaitSeconds');
      }
    }

    int undo = d.closeUndoSeconds;
    if (raw.containsKey('closeUndoSeconds')) {
      final v = (raw['closeUndoSeconds'] as num?)?.toInt();
      if (v != null && v >= undoMin && v <= undoMax) {
        undo = v;
      } else {
        invalid.add('closeUndoSeconds');
      }
    }

    int gpsStale = d.gpsStaleMinutes;
    if (raw.containsKey('gpsStaleMinutes')) {
      final v = (raw['gpsStaleMinutes'] as num?)?.toInt();
      if (v != null && v >= gpsStaleMin && v <= gpsStaleMax) {
        gpsStale = v;
      } else {
        invalid.add('gpsStaleMinutes');
      }
    }

    int heartbeat = d.driverSessionHeartbeatSeconds;
    if (raw.containsKey('driverSessionHeartbeatSeconds')) {
      final v = (raw['driverSessionHeartbeatSeconds'] as num?)?.toInt();
      if (v != null && v >= heartbeatMin && v <= heartbeatMax) {
        heartbeat = v;
      } else {
        invalid.add('driverSessionHeartbeatSeconds');
      }
    }

    int sessionStale = d.driverSessionStaleMinutes;
    if (raw.containsKey('driverSessionStaleMinutes')) {
      final v = (raw['driverSessionStaleMinutes'] as num?)?.toInt();
      if (v != null && v >= sessionStaleMin && v <= sessionStaleMax) {
        sessionStale = v;
      } else {
        invalid.add('driverSessionStaleMinutes');
      }
    }

    bool bgAuto = d.backgroundAutoCloseEnabled;
    if (raw.containsKey('backgroundAutoCloseEnabled')) {
      final v = raw['backgroundAutoCloseEnabled'];
      if (v is bool) {
        bgAuto = v;
      } else {
        invalid.add('backgroundAutoCloseEnabled');
      }
    }

    bool sessionLock = d.driverDeviceSessionLockEnabled;
    if (raw.containsKey('driverDeviceSessionLockEnabled')) {
      final v = raw['driverDeviceSessionLockEnabled'];
      if (v is bool) {
        sessionLock = v;
      } else {
        invalid.add('driverDeviceSessionLockEnabled');
      }
    }

    bool preferWaze = d.navigationPreferWaze;
    if (raw.containsKey('navigationPreferWaze')) {
      final v = raw['navigationPreferWaze'];
      if (v is bool) {
        preferWaze = v;
      } else {
        invalid.add('navigationPreferWaze');
      }
    }

    int preview = d.importPreviewRows;
    if (raw.containsKey('importPreviewRows')) {
      final v = (raw['importPreviewRows'] as num?)?.toInt();
      if (v != null && v >= previewMin && v <= previewMax) {
        preview = v;
      } else {
        invalid.add('importPreviewRows');
      }
    }

    return CompanyRemoteConfigValidation(
      config: CompanyRemoteConfig(
        autoCloseRadiusMeters: radius,
        autoCloseResetRadiusMeters: resetRadius,
        autoCloseWaitSeconds: wait,
        closeUndoSeconds: undo,
        gpsStaleMinutes: gpsStale,
        driverSessionHeartbeatSeconds: heartbeat,
        driverSessionStaleMinutes: sessionStale,
        backgroundAutoCloseEnabled: bgAuto,
        driverDeviceSessionLockEnabled: sessionLock,
        navigationPreferWaze: preferWaze,
        importPreviewRows: preview,
      ),
      invalidFields: invalid,
      warnings: warnings,
    );
  }
}
