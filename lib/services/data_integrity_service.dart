import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/correlation/correlation_context.dart';
import '../models/integrity_issue.dart';
import 'cross_module_audit_service.dart';
import 'firestore_paths.dart';

/// Data Integrity Checker — запуск проверки + чтение/изменение статуса проблем.
class DataIntegrityService {
  DataIntegrityService({required this.companyId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final FirebaseFirestore _firestore;

  static const auditIssueIgnored = 'integrity_issue_ignored';
  static const auditIssueResolved = 'integrity_issue_resolved';

  CollectionReference<Map<String, dynamic>> get _issues =>
      FirestorePaths(firestore: _firestore).integrityIssues(companyId);

  CollectionReference<Map<String, dynamic>> get _checks =>
      FirestorePaths(firestore: _firestore).integrityChecks(companyId);

  /// Запускает callable generateIntegrityCheck. Возвращает данные прогона.
  Future<Map<String, dynamic>> runCheck({String? correlationId}) async {
    final cid = correlationId ?? CorrelationContext.resolveId();
    final res = await FirebaseFunctions.instance
        .httpsCallable('generateIntegrityCheck')
        .call({'companyId': companyId, 'correlationId': cid});
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Последний прогон проверки.
  Stream<IntegrityCheck?> watchLastCheck() {
    return _checks
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : IntegrityCheck.fromFirestore(
                snap.docs.first.id, snap.docs.first.data()));
  }

  /// Проблемы (по умолчанию open), отсортированы по severity на клиенте.
  Stream<List<IntegrityIssue>> watchIssues({
    IntegrityIssueStatus status = IntegrityIssueStatus.open,
    int limit = 500,
  }) {
    return _issues
        .where('status', isEqualTo: status.name)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => IntegrityIssue.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final cmp = severityRank(a.severity).compareTo(severityRank(b.severity));
        if (cmp != 0) return cmp;
        return (b.lastSeenAt ?? DateTime(1970))
            .compareTo(a.lastSeenAt ?? DateTime(1970));
      });
      return list;
    });
  }

  Future<void> markIgnored(IntegrityIssue issue, String uid) async {
    await _issues.doc(issue.id).update({
      'status': 'ignored',
      'ignoredAt': FieldValue.serverTimestamp(),
      'ignoredBy': uid,
    });
    await _audit(auditIssueIgnored, issue, uid);
  }

  Future<void> markResolved(IntegrityIssue issue, String uid) async {
    await _issues.doc(issue.id).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': uid,
    });
    await _audit(auditIssueResolved, issue, uid);
  }

  Future<void> reopen(IntegrityIssue issue) async {
    await _issues.doc(issue.id).update({
      'status': 'open',
      'ignoredAt': FieldValue.delete(),
      'resolvedAt': FieldValue.delete(),
    });
  }

  Future<void> _audit(String type, IntegrityIssue issue, String uid) async {
    await CrossModuleAuditService(companyId: companyId).log(
      moduleKey: 'logistics',
      type: type,
      entityCollection: 'integrity_issues',
      entityDocId: issue.id,
      uid: uid,
      extra: {
        'issueCode': issue.issueCode,
        'entityType': issue.entityType,
        'entityId': issue.entityId,
        'severity': issue.severity.name,
      },
    );
  }
}
