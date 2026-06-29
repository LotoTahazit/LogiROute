import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/owner_dashboard/models/daily_metrics.dart';
import '../features/owner_dashboard/services/metrics_service.dart';
import '../models/company_settings.dart';
import '../models/company_setup_wizard.dart';
import '../models/delivery_point.dart';
import '../models/onboarding_section.dart';
import '../models/support_diagnostic_snapshot.dart';
import 'accounting_sync_service.dart';
import 'company_health_service.dart';
import 'firestore_paths.dart';

/// Bounded diagnostic load для Support Console (super_admin).
class SupportDiagnosticService {
  SupportDiagnosticService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _listLimit = 20;

  FirestorePaths get _paths => FirestorePaths(firestore: _firestore);

  Future<SupportDiagnosticSnapshot> load(String companyId) async {
    final companySnap = await _paths.companyDoc(companyId).get();
    final settings = CompanySettings.fromFirestore(companySnap);
    final health = CompanyHealthService(
      companyId: companyId,
      companySettings: settings,
      firestore: _firestore,
    );

    final results = await Future.wait([
      health.fetchTenantSnapshot(settings: settings),
      _nextMissingRequiredSection(companyId),
      _countUsers(companyId),
      _countFcmUsers(companyId),
      _countDeliveryByStatuses(companyId, DeliveryPoint.pendingStatuses),
      _countDeliveryByStatuses(companyId, _cancelledStatuses),
      _latestSyncEntry(companyId),
      _countUnreadNotifications(companyId),
      _paths
          .audit(companyId)
          .orderBy('createdAt', descending: true)
          .limit(_listLimit)
          .get(),
      _paths
          .paymentEvents(companyId)
          .orderBy('processedAt', descending: true)
          .limit(_listLimit)
          .get(),
      _paths
          .notifications(companyId)
          .orderBy('createdAt', descending: true)
          .limit(_listLimit)
          .get(),
      _paths
          .pushDeliveryLogs(companyId)
          .orderBy('timestamp', descending: true)
          .limit(_listLimit)
          .get(),
      _paths
          .emailDeliveryLogs(companyId)
          .orderBy('timestamp', descending: true)
          .limit(_listLimit)
          .get(),
      _paths
          .systemEvents(companyId)
          .orderBy('createdAt', descending: true)
          .limit(_listLimit)
          .get(),
      MetricsService(companyId: companyId, firestore: _firestore)
          .getTodayMetrics(),
    ]);

    final tenant = results[0] as CompanyHealthTenantSnapshot;
    final nextSection = results[1] as OnboardingSectionId?;
    final totalUsers = results[2] as int;
    final fcmTokenUsers = results[3] as int;
    final pendingDp = results[4] as int;
    final cancelledDp = results[5] as int;
    final latestSync = results[6] as AccountingSyncEntry?;
    final unread = results[7] as int;
    final auditSnap = results[8] as QuerySnapshot<Map<String, dynamic>>;
    final paySnap = results[9] as QuerySnapshot<Map<String, dynamic>>;
    final notifSnap = results[10] as QuerySnapshot<Map<String, dynamic>>;
    final pushSnap = results[11] as QuerySnapshot<Map<String, dynamic>>;
    final emailSnap = results[12] as QuerySnapshot<Map<String, dynamic>>;
    final sysSnap = results[13] as QuerySnapshot<Map<String, dynamic>>;
    final metrics = results[14] as DailyMetrics;

    final auditEvents = _mapDocs(auditSnap);
    final paymentEvents = _mapDocs(paySnap);
    final notifications = _mapDocs(notifSnap);
    final pushLogs = _mapDocs(pushSnap);
    final emailLogs = _mapDocs(emailSnap);

    final actorIds = auditEvents
        .map((e) => e['createdBy']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty && id != 'system')
        .toSet();
    final userNames = await _fetchUserNames(actorIds);

    final recentErrors = _mergeRecentErrors(auditEvents, sysSnap.docs);

    Map<String, dynamic>? lastOk;
    Map<String, dynamic>? lastFail;
    for (final p in paymentEvents) {
      if (lastOk == null && p['error'] == null) lastOk = p;
      if (lastFail == null && p['error'] != null) lastFail = p;
      if (lastOk != null && lastFail != null) break;
    }

    return SupportDiagnosticSnapshot(
      companyId: companyId,
      settings: settings,
      tenant: tenant,
      metrics: metrics,
      nextMissingRequiredSection: nextSection,
      totalUsers: totalUsers,
      fcmTokenUsers: fcmTokenUsers,
      pendingDeliveryPoints: pendingDp,
      cancelledDeliveryPoints: cancelledDp,
      latestSyncEntry: latestSync,
      unreadNotifications: unread,
      lastSuccessfulPayment: lastOk,
      lastFailedPayment: lastFail,
      recentErrors: recentErrors,
      auditEvents: auditEvents,
      paymentEvents: paymentEvents,
      notifications: notifications,
      pushLogs: pushLogs,
      emailLogs: emailLogs,
      userNames: userNames,
      loadedAt: DateTime.now(),
    );
  }

  static const _cancelledStatuses = [
    DeliveryPoint.statusCancelled,
    DeliveryPoint.statusCancelledHe,
    DeliveryPoint.statusCancelledRu,
    DeliveryPoint.statusCancelledRuAlt,
  ];

  List<Map<String, dynamic>> _mapDocs(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) =>
      snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();

  Future<OnboardingSectionId?> _nextMissingRequiredSection(
    String companyId,
  ) async {
    try {
      final snap = await _paths
          .companySettings(companyId)
          .doc('setup_wizard')
          .get();
      if (!snap.exists) return OnboardingSectionId.companyDetails;
      final state = CompanySetupWizardState.fromMap(snap.data());
      for (final section in OnboardingSectionId.ordered) {
        if (section == OnboardingSectionId.goLive) continue;
        if (!section.isRequired) continue;
        if (!_sectionDone(section, state)) return section;
      }
      return null;
    } catch (_) {
      return OnboardingSectionId.companyDetails;
    }
  }

  bool _sectionDone(
    OnboardingSectionId section,
    CompanySetupWizardState state,
  ) {
    if (section == OnboardingSectionId.goLive) return state.wizardCompleted;
    if (section.isSignalOnly) {
      // Support console без live signals — только persisted steps
      return false;
    }
    for (final id in section.wizardSteps) {
      final st = state.statusOf(id);
      if (st != SetupWizardStepStatus.completed &&
          st != SetupWizardStepStatus.skipped) {
        return false;
      }
    }
    return true;
  }

  Future<int> _countUsers(String companyId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countFcmUsers(String companyId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('fcmToken', isGreaterThan: '')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countDeliveryByStatuses(
    String companyId,
    List<String> statuses,
  ) async {
    if (statuses.isEmpty) return 0;
    try {
      final snap = await _paths
          .deliveryPoints(companyId)
          .where('status', whereIn: statuses)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<AccountingSyncEntry?> _latestSyncEntry(String companyId) async {
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
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return AccountingSyncEntry.fromFirestore(d.id, d.data());
    } catch (_) {
      return null;
    }
  }

  Future<int> _countUnreadNotifications(String companyId) async {
    try {
      final snap = await _paths
          .notifications(companyId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, String>> _fetchUserNames(Set<String> uids) async {
    if (uids.isEmpty) return {};
    final out = <String, String>{};
    final snaps = await Future.wait(
      uids.map((id) => _firestore.collection('users').doc(id).get()),
    );
    for (final d in snaps) {
      if (!d.exists) continue;
      final m = d.data()!;
      out[d.id] = (m['name'] ?? m['displayName'] ?? '') as String;
    }
    return out;
  }

  List<SupportErrorEntry> _mergeRecentErrors(
    List<Map<String, dynamic>> auditEvents,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> systemDocs,
  ) {
    final entries = <SupportErrorEntry>[];

    for (final e in auditEvents) {
      if (!_isAuditError(e)) continue;
      entries.add(
        SupportErrorEntry(
          source: 'audit',
          type: e['type']?.toString() ?? 'audit',
          message: (e['reason'] ?? e['message'] ?? e['type'] ?? '').toString(),
          correlationId: e['correlationId'] as String?,
          at: SupportDiagnosticSnapshot.ts(e['createdAt']),
          id: e['id'] as String?,
        ),
      );
    }

    for (final d in systemDocs) {
      final data = d.data();
      final status = data['status']?.toString() ?? '';
      if (status != 'error' && status != 'failed') continue;
      entries.add(
        SupportErrorEntry(
          source: 'system',
          type: data['type']?.toString() ?? 'system',
          message: (data['message'] ?? status).toString(),
          correlationId: data['correlationId'] as String?,
          at: SupportDiagnosticSnapshot.ts(data['createdAt']),
          id: d.id,
        ),
      );
    }

    entries.sort((a, b) {
      final ta = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    if (entries.length > _listLimit) {
      return entries.sublist(0, _listLimit);
    }
    return entries;
  }

  bool _isAuditError(Map<String, dynamic> e) {
    final severity = (e['severity'] ?? '').toString().toLowerCase();
    if (severity == 'error' || severity == 'critical') return true;
    final type = (e['type'] ?? '').toString().toLowerCase();
    return type.contains('error') || type.contains('failed');
  }
}
