import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restore_drill_record.dart';

/// Журнал бэкапов и restore drill (audit trail, не сам GCP backup).
class BackupService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BackupService({required this.companyId});

  bool isQuarterlyBackupDue() {
    final now = DateTime.now();
    const quarterStartMonths = [1, 4, 7, 10];
    return quarterStartMonths.contains(now.month) && now.day <= 7;
  }

  /// Запись о бэкапе (журнал аудита).
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
      'type': 'backup_record',
      'performedBy': performedBy,
      'backupLocation': backupLocation,
      'timestamp': FieldValue.serverTimestamp(),
      'quarter': _currentQuarter(),
      'year': DateTime.now().year,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

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

  /// Restore drill с обязательным evidence.
  Future<void> recordRestoreDrill(RestoreDrillRecord drill) async {
    final err = drill.validationError();
    if (err != null) {
      throw ArgumentError('Restore drill incomplete: $err');
    }
    if (drill.isSuccess && !drill.hasCompleteEvidence) {
      throw ArgumentError('Restore drill success requires complete evidence');
    }

    final payload = drill.toFirestoreMap(
      quarter: _currentQuarter(),
      year: DateTime.now().year,
    );
    payload['testDate'] = Timestamp.fromDate(drill.testDate);
    payload['timestamp'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('restore_tests')
        .add(payload);
  }

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

  static bool drillHasEvidence(Map<String, dynamic> t) {
    final notes = (t['evidenceNotes'] as String?)?.trim() ?? '';
    final collections = t['restoredCollections'];
    final hasCollections = collections is List && collections.isNotEmpty;
    final duration = (t['durationMinutes'] as num?)?.toInt() ?? 0;
    final env = (t['targetEnvironment'] as String?)?.trim() ?? '';
    return notes.length >= 20 &&
        hasCollections &&
        duration > 0 &&
        env.length >= 3;
  }

  static bool drillSucceeded(Map<String, dynamic> t) {
    final result = t['result'] as String?;
    if (result != null) return result == 'success';
    return t['success'] == true;
  }

  Future<Map<String, dynamic>> getBackupComplianceReport() async {
    final isBackedUp = await isCurrentQuarterBackedUp();
    final backups = await getBackupHistory(limit: 4);
    final restoreTests = await getRestoreTestHistory(limit: 10);

    final verifiedDrills = restoreTests.where(drillHasEvidence).toList();
    final lastVerified = verifiedDrills.isNotEmpty ? verifiedDrills.first : null;
    final lastRestoreSuccess = lastVerified != null &&
        drillSucceeded(lastVerified) &&
        drillHasEvidence(lastVerified);

    return {
      'currentQuarter': _currentQuarter(),
      'year': DateTime.now().year,
      'isCurrentQuarterBackedUp': isBackedUp,
      'backupsDue': isQuarterlyBackupDue(),
      'totalBackupsRecorded': backups.length,
      'lastRestoreTestSuccess': lastRestoreSuccess,
      'lastRestoreDrillVerified': lastVerified != null,
      'totalRestoreTests': restoreTests.length,
      'totalVerifiedRestoreDrills': verifiedDrills.length,
      'compliant': isBackedUp && lastRestoreSuccess,
    };
  }
}
