import 'package:cloud_firestore/cloud_firestore.dart';

/// סוגי אירועי גישה
enum AccessEventType {
  login, // כניסה למערכת
  logout, // יציאה
  viewDocument, // צפייה במסמך
  printDocument, // הדפסה
  exportData, // ייצוא נתונים
  createDocument, // יצירת מסמך
  cancelDocument, // ביטול מסמך
  viewAuditLog, // צפייה ביומן ביקורת
  viewReport, // צפייה בדוח
  adminAction, // פעולת מנהל
}

/// שירות יומן גישה — SaaS compliance
/// אוסף: companies/{cId}/access_log/{logId}
/// רושם: מי, מתי, מאיפה, מה עשה
/// append-only — לעולם לא מתעדכן ולא נמחק
class AccessLogService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AccessLogService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _accessLogCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('access_log');
  }

  /// רישום אירוע גישה
  Future<void> logAccess({
    required String actorUid,
    required AccessEventType eventType,
    String? actorName,
    String? targetEntityId,
    String? targetEntityType,
    String? ipAddress,
    String? userAgent,
    String? platform,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _accessLogCollection().add({
        'actorUid': actorUid,
        'actorName': actorName,
        'eventType': eventType.name,
        'timestamp': FieldValue.serverTimestamp(),
        if (targetEntityId != null) 'targetEntityId': targetEntityId,
        if (targetEntityType != null) 'targetEntityType': targetEntityType,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (userAgent != null) 'userAgent': userAgent,
        'platform': platform ?? 'web',
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      print('❌ [AccessLog] Error logging access: $e');
    }
  }

  /// קבלת יומן גישה לתקופה
  Future<List<Map<String, dynamic>>> getAccessLog({
    DateTime? fromDate,
    DateTime? toDate,
    String? actorUid,
    AccessEventType? eventType,
    int limit = 100,
  }) async {
    Query query = _accessLogCollection();

    if (fromDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// ספירת אירועי גישה לפי סוג (לדוחות)
  Future<Map<String, int>> getAccessCounts({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final logs =
        await getAccessLog(fromDate: fromDate, toDate: toDate, limit: 1000);
    final counts = <String, int>{};
    for (final log in logs) {
      final type = log['eventType'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
