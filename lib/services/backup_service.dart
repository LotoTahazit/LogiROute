import 'package:cloud_firestore/cloud_firestore.dart';

/// שירות גיבוי — תואם לדרישות ניהול ספרים
/// גיבוי בשבוע הראשון של כל רבעון, אחסון במקום נפרד
class BackupService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BackupService({required this.companyId});

  /// בדיקה: האם נדרש גיבוי רבעוני?
  /// גיבוי נדרש בשבוע הראשון של ינואר, אפריל, יולי, אוקטובר
  bool isQuarterlyBackupDue() {
    final now = DateTime.now();
    final quarterStartMonths = [1, 4, 7, 10];
    return quarterStartMonths.contains(now.month) && now.day <= 7;
  }

  /// רישום גיבוי שבוצע
  Future<void> recordBackup({
    required String performedBy,
    required String backupLocation,
    String? notes,
  }) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('backups')
        .add({
      'performedBy': performedBy,
      'backupLocation': backupLocation,
      'timestamp': FieldValue.serverTimestamp(),
      'quarter': _currentQuarter(),
      'year': DateTime.now().year,
      if (notes != null) 'notes': notes,
    });
  }

  /// קבלת היסטוריית גיבויים
  Future<List<Map<String, dynamic>>> getBackupHistory({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('backups')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// בדיקה: האם הגיבוי האחרון עדכני לרבעון הנוכחי?
  Future<bool> isCurrentQuarterBackedUp() async {
    final quarter = _currentQuarter();
    final year = DateTime.now().year;

    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('backups')
        .where('quarter', isEqualTo: quarter)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  String _currentQuarter() {
    final month = DateTime.now().month;
    if (month <= 3) return 'Q1';
    if (month <= 6) return 'Q2';
    if (month <= 9) return 'Q3';
    return 'Q4';
  }

  /// רישום תוצאת בדיקת שחזור (restore test)
  /// נדרש להוכחת DR — אודיטור רוצה לראות שהשחזור עובד
  Future<void> recordRestoreTest({
    required String performedBy,
    required bool success,
    required String backupId,
    String? notes,
    int? documentsVerified,
    Duration? restoreDuration,
  }) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('restore_tests')
        .add({
      'performedBy': performedBy,
      'success': success,
      'backupId': backupId,
      'timestamp': FieldValue.serverTimestamp(),
      'quarter': _currentQuarter(),
      'year': DateTime.now().year,
      if (notes != null) 'notes': notes,
      if (documentsVerified != null) 'documentsVerified': documentsVerified,
      if (restoreDuration != null)
        'restoreDurationMs': restoreDuration.inMilliseconds,
    });
  }

  /// קבלת היסטוריית בדיקות שחזור
  Future<List<Map<String, dynamic>>> getRestoreTestHistory(
      {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('restore_tests')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// דוח מצב גיבויים — סיכום לאודיטור
  Future<Map<String, dynamic>> getBackupComplianceReport() async {
    final isBackedUp = await isCurrentQuarterBackedUp();
    final backups = await getBackupHistory(limit: 4);
    final restoreTests = await getRestoreTestHistory(limit: 4);

    final lastRestoreSuccess = restoreTests.isNotEmpty
        ? restoreTests.first['success'] as bool? ?? false
        : false;

    return {
      'currentQuarter': _currentQuarter(),
      'year': DateTime.now().year,
      'isCurrentQuarterBackedUp': isBackedUp,
      'backupsDue': isQuarterlyBackupDue(),
      'totalBackupsRecorded': backups.length,
      'lastRestoreTestSuccess': lastRestoreSuccess,
      'totalRestoreTests': restoreTests.length,
      'compliant': isBackedUp && lastRestoreSuccess,
    };
  }
}
