import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_paths.dart';

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

  // ---------------------------------------------------------------------------
  // Стандартизированные типы событий
  // ---------------------------------------------------------------------------

  /// Accounting module
  static const String typeReceiptCreated = 'receipt_created';
  static const String typeCreditNoteCreated = 'credit_note_created';
  static const String typeDocumentVoided = 'document_voided_before_delivery';
  static const String typeInvoiceVoided = 'invoice_voided';

  /// Billing / admin module
  static const String typeBillingStatusChanged = 'billing_status_changed';
  static const String typeTrialUntilChanged = 'trial_until_changed';
  static const String typeAccountingLockedUntilChanged =
      'accounting_locked_until_changed';

  /// All known types — used for filter dropdowns
  static const List<String> allTypes = [
    typeReceiptCreated,
    typeCreditNoteCreated,
    typeDocumentVoided,
    typeInvoiceVoided,
    typeBillingStatusChanged,
    typeTrialUntilChanged,
    typeAccountingLockedUntilChanged,
  ];

  CollectionReference<Map<String, dynamic>> get _auditRef =>
      FirestorePaths(firestore: _firestore).audit(companyId);

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
