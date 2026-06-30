import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../services/company_remote_config_validator.dart';

/// Company-scoped pilot tunables (Firestore: settings/remote_config).
class CompanyRemoteConfig {
  final double autoCloseRadiusMeters;
  final double autoCloseResetRadiusMeters;
  final int autoCloseWaitSeconds;
  final int closeUndoSeconds;
  final int gpsStaleMinutes;

  /// UI-порог «GPS устарел» для баннера водителя (секунды). Отдельно от
  /// [gpsStaleMinutes] (48 ч — для Customer Health диспетчера/owner).
  final int driverGpsUiStaleSeconds;
  final int driverSessionHeartbeatSeconds;
  final int driverSessionStaleMinutes;
  final bool backgroundAutoCloseEnabled;
  final bool driverDeviceSessionLockEnabled;
  final bool navigationPreferWaze;
  final int importPreviewRows;

  const CompanyRemoteConfig({
    required this.autoCloseRadiusMeters,
    required this.autoCloseResetRadiusMeters,
    required this.autoCloseWaitSeconds,
    required this.closeUndoSeconds,
    required this.gpsStaleMinutes,
    this.driverGpsUiStaleSeconds = 180,
    required this.driverSessionHeartbeatSeconds,
    required this.driverSessionStaleMinutes,
    required this.backgroundAutoCloseEnabled,
    required this.driverDeviceSessionLockEnabled,
    required this.navigationPreferWaze,
    required this.importPreviewRows,
  });

  static CompanyRemoteConfig get defaults => CompanyRemoteConfig(
        autoCloseRadiusMeters: AppConfig.autoCompleteRadius,
        autoCloseResetRadiusMeters: AppConfig.autoCompleteResetRadius,
        autoCloseWaitSeconds: AppConfig.autoCompleteDuration.inSeconds,
        closeUndoSeconds: AppConfig.closeUndoUiDuration.inSeconds,
        gpsStaleMinutes: 48 * 60,
        driverGpsUiStaleSeconds: 180,
        driverSessionHeartbeatSeconds:
            AppConfig.driverSessionHeartbeatInterval.inSeconds,
        driverSessionStaleMinutes:
            AppConfig.driverSessionStaleThreshold.inMinutes,
        backgroundAutoCloseEnabled: true,
        driverDeviceSessionLockEnabled: true,
        navigationPreferWaze: true,
        importPreviewRows: 20,
      );

  Duration get autoCloseWait => Duration(seconds: autoCloseWaitSeconds);
  Duration get closeUndo => Duration(seconds: closeUndoSeconds);
  Duration get gpsStaleAfter => Duration(minutes: gpsStaleMinutes);
  Duration get driverGpsUiStale => Duration(seconds: driverGpsUiStaleSeconds);
  Duration get sessionHeartbeat =>
      Duration(seconds: driverSessionHeartbeatSeconds);
  Duration get sessionStale => Duration(minutes: driverSessionStaleMinutes);

  static CompanyRemoteConfig get withDefaults => defaults;

  /// Alias for [defaults].
  static CompanyRemoteConfig mergeWithDefaults(Map<String, dynamic>? raw) =>
      CompanyRemoteConfigValidator.mergeRaw(raw).config;

  factory CompanyRemoteConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) =>
      mergeWithDefaults(snap.data());

  Map<String, dynamic> toFirestore() => toMap();

  String? validate() => CompanyRemoteConfigValidator.validateForSave(this);

  factory CompanyRemoteConfig.fromMap(Map<String, dynamic>? raw) =>
      mergeWithDefaults(raw);

  Map<String, dynamic> toMap() => {
        'autoCloseRadiusMeters': autoCloseRadiusMeters,
        'autoCloseResetRadiusMeters': autoCloseResetRadiusMeters,
        'autoCloseWaitSeconds': autoCloseWaitSeconds,
        'closeUndoSeconds': closeUndoSeconds,
        'gpsStaleMinutes': gpsStaleMinutes,
        'driverGpsUiStaleSeconds': driverGpsUiStaleSeconds,
        'driverSessionHeartbeatSeconds': driverSessionHeartbeatSeconds,
        'driverSessionStaleMinutes': driverSessionStaleMinutes,
        'backgroundAutoCloseEnabled': backgroundAutoCloseEnabled,
        'driverDeviceSessionLockEnabled': driverDeviceSessionLockEnabled,
        'navigationPreferWaze': navigationPreferWaze,
        'importPreviewRows': importPreviewRows,
      };
}
