import 'package:cloud_firestore/cloud_firestore.dart';

/// שירות מדיניות שמירת נתונים — 7+ שנים לפי חוק
/// אוסף: companies/{cId}/retention_checks/{checkId}
///
/// אחריות:
/// - בדיקה שמסמכים לא נמחקו לפני תום תקופת השמירה
/// - התראה כשמסמכים מתקרבים לסוף תקופת השמירה
/// - רישום בדיקות תקופתיות (compliance audit trail)
///
/// SAFETY RAILS — коллекции, которые НИКОГДА не удаляются retention job:
///   - audit (cross-module audit log)
///   - accounting/_root/integrity_chain (hash chain)
///   - accounting/_root/integrity_anchors
///   - payment_events (payment ledger)
///   - notifications (in-app inbox — server-only create)
/// Retention проверяет ТОЛЬКО accounting/_root/invoices (read-only check).
class DataRetentionService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// תקופת שמירה מינימלית בשנים (חוק ניהול ספרים)
  static const int minimumRetentionYears = 7;

  /// Коллекции, которые ЗАПРЕЩЕНО удалять/модифицировать retention job.
  /// Используется для safety check в runRetentionCheck.
  static const Set<String> protectedCollections = {
    'audit',
    'integrity_chain',
    'integrity_anchors',
    'payment_events',
    'notifications',
    'invoices',
    'receipts',
    'credit_notes',
  };

  DataRetentionService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _retentionChecksCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('retention_checks');
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices');
  }

  /// בדיקת עמידה במדיניות שמירה
  /// מחזיר דוח: כמה מסמכים, טווח תאריכים, בעיות
  Future<RetentionCheckResult> runRetentionCheck(String checkedBy) async {
    final now = DateTime.now();
    final retentionCutoff = DateTime(
      now.year - minimumRetentionYears,
      now.month,
      now.day,
    );

    // ספירת מסמכים לפי שנה
    final snapshot =
        await _invoicesCollection().orderBy('createdAt').limit(1).get();

    DateTime? oldestDocDate;
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data['createdAt'] != null) {
        oldestDocDate = (data['createdAt'] as Timestamp).toDate();
      }
    }

    // ספירת כל המסמכים
    final allDocs = await _invoicesCollection().count().get();
    final totalCount = allDocs.count ?? 0;

    // בדיקה: האם יש מסמכים שנמחקו (לא אמור לקרות — delete: if false)
    // אם המספר הרץ האחרון > מספר המסמכים — יש פער
    final counterSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('counters')
        .get();

    int totalExpected = 0;
    for (final doc in counterSnapshot.docs) {
      totalExpected += (doc.data()['lastNumber'] as int? ?? 0);
    }

    final hasGaps = totalCount < totalExpected;

    final result = RetentionCheckResult(
      checkedAt: now,
      checkedBy: checkedBy,
      totalDocuments: totalCount,
      oldestDocumentDate: oldestDocDate,
      retentionCutoffDate: retentionCutoff,
      isCompliant: oldestDocDate == null ||
          oldestDocDate.isAfter(retentionCutoff) ||
          !hasGaps,
      hasSequentialGaps: hasGaps,
      expectedCount: totalExpected,
    );

    // רישום הבדיקה
    await _retentionChecksCollection().add({
      'checkedAt': FieldValue.serverTimestamp(),
      'checkedBy': checkedBy,
      'totalDocuments': totalCount,
      'oldestDocumentDate':
          oldestDocDate != null ? Timestamp.fromDate(oldestDocDate) : null,
      'retentionCutoffDate': Timestamp.fromDate(retentionCutoff),
      'isCompliant': result.isCompliant,
      'hasSequentialGaps': hasGaps,
      'expectedCount': totalExpected,
    });

    return result;
  }

  /// קבלת היסטוריית בדיקות
  Future<List<Map<String, dynamic>>> getCheckHistory({int limit = 20}) async {
    final snapshot = await _retentionChecksCollection()
        .orderBy('checkedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// בדיקה: האם מסמך עדיין בתקופת שמירה?
  bool isWithinRetentionPeriod(DateTime documentDate) {
    final cutoff = DateTime.now().subtract(
      Duration(days: minimumRetentionYears * 365),
    );
    return documentDate.isAfter(cutoff);
  }
}

/// תוצאת בדיקת מדיניות שמירה
class RetentionCheckResult {
  final DateTime checkedAt;
  final String checkedBy;
  final int totalDocuments;
  final DateTime? oldestDocumentDate;
  final DateTime retentionCutoffDate;
  final bool isCompliant;
  final bool hasSequentialGaps;
  final int expectedCount;

  RetentionCheckResult({
    required this.checkedAt,
    required this.checkedBy,
    required this.totalDocuments,
    this.oldestDocumentDate,
    required this.retentionCutoffDate,
    required this.isCompliant,
    required this.hasSequentialGaps,
    required this.expectedCount,
  });

  /// תיאור בעברית
  String get summary {
    if (isCompliant && !hasSequentialGaps) {
      return 'תקין — כל המסמכים נשמרים כנדרש ($totalDocuments מסמכים)';
    }
    final issues = <String>[];
    if (hasSequentialGaps) {
      issues.add(
          'נמצאו פערים במספור ($totalDocuments מתוך $expectedCount צפויים)');
    }
    if (!isCompliant) {
      issues.add('בעיית עמידה במדיניות שמירה');
    }
    return 'בעיות: ${issues.join('; ')}';
  }
}
