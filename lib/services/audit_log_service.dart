import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_event.dart';

/// שירות יומן ביקורת — append-only
/// כל אירוע נרשם לתת-אוסף: companies/{cId}/invoices/{iId}/auditLog/{eId}
/// אירועים לעולם לא מתעדכנים ולא נמחקים
class AuditLogService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  AuditLogService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// הפניה לתת-אוסף auditLog של מסמך
  CollectionReference<Map<String, dynamic>> _auditCollection(String entityId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .doc(entityId)
        .collection('auditLog');
  }

  /// רושם אירוע ביקורת. זורק חריגה בשגיאה — הקורא לא ממשיך בפעולה.
  /// requestId — UUID לאידמפוטנטיות (נוצר אוטומטית אם לא סופק).
  Future<String> logEvent({
    required String entityId,
    required String entityType,
    required AuditEventType eventType,
    required String actorUid,
    String? actorName,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) async {
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(actorUid.isNotEmpty, 'actorUid cannot be empty');

    final rid = requestId ?? _uuid.v4();

    final event = AuditEvent(
      id: '',
      entityId: entityId,
      entityType: entityType,
      companyId: companyId,
      eventType: eventType,
      actorUid: actorUid,
      actorName: actorName,
      requestId: rid,
      metadata: metadata,
    );

    try {
      final docRef = await _auditCollection(entityId).add(event.toMap());
      return docRef.id;
    } catch (e) {
      print('❌ [AuditLog] Error logging event: $e');
      rethrow;
    }
  }

  /// קבלת יומן ביקורת ממוין לפי timestamp (סדר עולה)
  Future<List<AuditEvent>> getAuditLog(String entityId) async {
    try {
      final snapshot = await _auditCollection(entityId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => AuditEvent.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [AuditLog] Error getting audit log: $e');
      return [];
    }
  }

  /// סטרימינג של יומן ביקורת בזמן אמת
  Stream<List<AuditEvent>> watchAuditLog(String entityId) {
    return _auditCollection(entityId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditEvent.fromMap(doc.data(), doc.id))
            .toList());
  }
}
