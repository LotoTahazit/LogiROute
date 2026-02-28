import 'package:cloud_firestore/cloud_firestore.dart';

/// Cross-module audit log — пишет в companies/{companyId}/audit/{eventId}
/// Append-only: create only, update/delete запрещены правилами.
///
/// Обязательные поля (по Firestore rules):
/// - moduleKey: dispatcher | logistics | warehouse | accounting
/// - type: один из allowlist (invoice_issued, receipt_created, etc.)
/// - entity: { collection: string, docId: string }
/// - createdBy: request.auth.uid
/// - createdAt: serverTimestamp
class CrossModuleAuditService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CrossModuleAuditService({required this.companyId});

  CollectionReference<Map<String, dynamic>> get _auditRef =>
      _firestore.collection('companies').doc(companyId).collection('audit');

  /// Записать событие в cross-module audit log.
  /// [uid] — текущий auth uid (createdBy == request.auth.uid в rules).
  Future<void> log({
    required String moduleKey,
    required String type,
    required String entityCollection,
    required String entityDocId,
    required String uid,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final data = <String, dynamic>{
        'moduleKey': moduleKey,
        'type': type,
        'entity': {
          'collection': entityCollection,
          'docId': entityDocId,
        },
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        if (extra != null) ...extra,
      };
      await _auditRef.add(data);
    } catch (e) {
      // Audit не должен блокировать основной flow
      print('⚠️ [CrossModuleAudit] Failed to log: $e');
    }
  }
}
