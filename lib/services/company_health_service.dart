import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../features/owner_dashboard/services/metrics_service.dart';
import '../models/company_settings.dart';
import '../models/company_setup_wizard.dart';
import '../models/onboarding_section.dart';
import 'firestore_paths.dart';
import 'company_remote_config_service.dart';
import 'gps_health.dart';
import 'onboarding_step_signals.dart';

enum HealthCheckStatus { ok, warn, fail }

class CompanyHealthSnapshot {
  final String companyName;
  final HealthCheckStatus billing;
  final HealthCheckStatus gps;
  final HealthCheckStatus firestore;
  final int driverCount;
  final int activeRoutes;
  final HealthCheckStatus fcm;
  final HealthCheckStatus accounting;
  final String? lastError;
  final int problems;
  final DateTime syncedAt;

  const CompanyHealthSnapshot({
    required this.companyName,
    required this.billing,
    required this.gps,
    required this.firestore,
    required this.driverCount,
    required this.activeRoutes,
    required this.fcm,
    required this.accounting,
    this.lastError,
    required this.problems,
    required this.syncedAt,
  });
}

/// Bounded snapshot для Customer Health Dashboard.
class CompanyHealthTenantSnapshot {
  final String companyId;
  final String companyName;
  final String plan;
  final String billingStatus;
  final int setupPercent;
  final int driverCount;
  final int activeRoutes;
  final int failedSyncCount;
  final int staleGpsDrivers;
  final DateTime? lastActivity;
  final int problemsCount;
  final HealthCheckStatus accounting;
  final String? lastSyncError;
  final bool fetchOk;

  const CompanyHealthTenantSnapshot({
    required this.companyId,
    required this.companyName,
    required this.plan,
    required this.billingStatus,
    required this.setupPercent,
    required this.driverCount,
    required this.activeRoutes,
    required this.failedSyncCount,
    required this.staleGpsDrivers,
    this.lastActivity,
    required this.problemsCount,
    required this.accounting,
    this.lastSyncError,
    required this.fetchOk,
  });
}

/// Операционный снимок здоровья компании (Owner strip / tenant dashboard).
class CompanyHealthService {
  CompanyHealthService({
    required this.companyId,
    CompanySettings? companySettings,
    FirebaseFirestore? firestore,
  })  : _settings = companySettings,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final CompanySettings? _settings;
  final FirebaseFirestore _firestore;

  FirestorePaths get _paths => FirestorePaths(firestore: _firestore);

  /// Полоска одной компании (Owner Overview) — может включать FCM устройства.
  Future<CompanyHealthSnapshot> fetch({bool includeDeviceChecks = true}) async {
    CompanySettings settings;
    var firestoreStatus = HealthCheckStatus.ok;
    try {
      settings = _settings ??
          CompanySettings.fromFirestore(
            await _firestore.collection('companies').doc(companyId).get(),
          );
    } catch (_) {
      if (_settings == null) rethrow;
      settings = _settings!;
      firestoreStatus = HealthCheckStatus.fail;
    }

    final signals = await OnboardingStepSignals(
      companyId: companyId,
      companySettings: settings,
      firestore: _firestore,
    ).checkAll();

    final driverCount = await _countDrivers();
    final activeRoutes = await _countActiveRoutes();
    final fcm =
        includeDeviceChecks ? await _checkFcm() : HealthCheckStatus.ok;
    final (accounting, lastError) = await _checkAccounting(settings);

    final billing = _billingStatus(settings.billingStatus);
    final gps = _status(signals[SetupWizardStepId.gpsCheck] == true);

    var problems = 0;
    for (final s in [
      billing,
      gps,
      firestoreStatus,
      accounting,
      if (includeDeviceChecks) fcm,
    ]) {
      if (s == HealthCheckStatus.fail) problems++;
    }

    return CompanyHealthSnapshot(
      companyName: settings.nameHebrew.isNotEmpty
          ? settings.nameHebrew
          : settings.nameEnglish,
      billing: billing,
      gps: gps,
      firestore: firestoreStatus,
      driverCount: driverCount,
      activeRoutes: activeRoutes,
      fcm: fcm,
      accounting: accounting,
      lastError: lastError,
      problems: problems,
      syncedAt: DateTime.now(),
    );
  }

  /// Tenant dashboard — без OnboardingStepSignals / invoices / delivery_points.
  Future<CompanyHealthTenantSnapshot> fetchTenantSnapshot({
    required CompanySettings settings,
  }) async {
    final results = await Future.wait([
      _setupPercent(),
      _countDrivers(),
      _countActiveRoutes(),
      _countFailedSyncs(),
      _countStaleGps(),
      _lastAuditActivity(),
      _checkAccounting(settings),
      MetricsService(companyId: companyId).getTodayMetrics(),
    ]);

    final setupPercent = results[0] as int;
    final driverCount = results[1] as int;
    final activeRoutes = results[2] as int;
    final failedSyncCount = results[3] as int;
    final staleGpsDrivers = results[4] as int;
    final lastActivity = results[5] as DateTime?;
    final (accounting, lastSyncError) =
        results[6] as (HealthCheckStatus, String?);

    final billing = _billingStatus(settings.billingStatus);

    var problems = 0;
    if (billing == HealthCheckStatus.fail) problems++;
    if (accounting == HealthCheckStatus.fail) problems++;
    if (staleGpsDrivers > 0) problems++;
    if (failedSyncCount > 0) problems++;

    return CompanyHealthTenantSnapshot(
      companyId: companyId,
      companyName: settings.nameHebrew.isNotEmpty
          ? settings.nameHebrew
          : settings.nameEnglish,
      plan: settings.plan,
      billingStatus: settings.billingStatus,
      setupPercent: setupPercent,
      driverCount: driverCount,
      activeRoutes: activeRoutes,
      failedSyncCount: failedSyncCount,
      staleGpsDrivers: staleGpsDrivers,
      lastActivity: lastActivity,
      problemsCount: problems,
      accounting: accounting,
      lastSyncError: lastSyncError,
      fetchOk: true,
    );
  }

  Future<int> _countDrivers() async {
    final snap = await _paths
        .members(companyId)
        .where('role', isEqualTo: 'driver')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> _countActiveRoutes() async {
    final snap = await _paths
        .routes(companyId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<HealthCheckStatus> _checkFcm() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token != null && token.isNotEmpty
          ? HealthCheckStatus.ok
          : HealthCheckStatus.warn;
    } catch (_) {
      return HealthCheckStatus.warn;
    }
  }

  Future<(HealthCheckStatus, String?)> _checkAccounting(
    CompanySettings settings,
  ) async {
    if (settings.accountingProvider == 'none' ||
        settings.accountingProvider.isEmpty) {
      return (HealthCheckStatus.ok, null);
    }

    try {
      final snap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('accounting')
          .doc('_root')
          .collection('sync_ledger')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return (HealthCheckStatus.ok, null);

      final data = snap.docs.first.data();
      final status = data['status'] as String? ?? '';
      final lastError = data['lastError'] as String?;

      if (status == 'failed') {
        return (HealthCheckStatus.fail, lastError);
      }
      if (status == 'processing') {
        return (HealthCheckStatus.warn, null);
      }
      return (HealthCheckStatus.ok, null);
    } catch (e) {
      return (HealthCheckStatus.fail, e.toString());
    }
  }

  HealthCheckStatus _billingStatus(String status) {
    switch (status) {
      case 'active':
      case 'trial':
        return HealthCheckStatus.ok;
      case 'grace':
        return HealthCheckStatus.warn;
      case 'suspended':
      case 'cancelled':
        return HealthCheckStatus.fail;
      default:
        return HealthCheckStatus.warn;
    }
  }

  HealthCheckStatus _status(bool ok) =>
      ok ? HealthCheckStatus.ok : HealthCheckStatus.fail;

  Future<int> _setupPercent() async {
    try {
      final snap = await _paths
          .companySettings(companyId)
          .doc('setup_wizard')
          .get();
      if (!snap.exists) return 0;
      final state = CompanySetupWizardState.fromMap(snap.data());
      final done = OnboardingSectionId.ordered
          .where((s) => _sectionDone(s, state))
          .length;
      return ((done / OnboardingSectionId.ordered.length) * 100).round();
    } catch (_) {
      return 0;
    }
  }

  bool _sectionDone(OnboardingSectionId section, CompanySetupWizardState state) {
    if (section == OnboardingSectionId.goLive) return state.wizardCompleted;
    for (final id in section.wizardSteps) {
      final st = state.statusOf(id);
      if (st != SetupWizardStepStatus.completed &&
          st != SetupWizardStepStatus.skipped) {
        return false;
      }
    }
    return true;
  }

  Future<int> _countFailedSyncs() async {
    try {
      final snap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('accounting')
          .doc('_root')
          .collection('sync_ledger')
          .where('status', isEqualTo: 'failed')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countStaleGps() async {
    try {
      final rc = await CompanyRemoteConfigService().get(companyId);
      final snap = await _paths.driverLocations(companyId).limit(200).get();
      return GpsHealth.summarizeDocs(
        snap.docs.map((d) => d.data()),
        staleAfter: rc.gpsStaleAfter,
      ).stale;
    } catch (_) {
      return 0;
    }
  }

  Future<DateTime?> _lastAuditActivity() async {
    try {
      final snap = await _paths
          .audit(companyId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final ts = snap.docs.first.data()['createdAt'];
      if (ts is Timestamp) return ts.toDate();
      return null;
    } catch (_) {
      return null;
    }
  }
}
