/// Restore drill — проверяемое восстановление (не галочка в журнале).
enum RestoreDrillResult { success, failed }

class RestoreDrillRecord {
  final String backupId;
  final String backupLocation;
  final DateTime testDate;
  final String targetEnvironment;
  final List<String> restoredCollections;
  final String testedBy;
  final RestoreDrillResult result;
  final String evidenceNotes;
  final int durationMinutes;

  const RestoreDrillRecord({
    required this.backupId,
    required this.backupLocation,
    required this.testDate,
    required this.targetEnvironment,
    required this.restoredCollections,
    required this.testedBy,
    required this.result,
    required this.evidenceNotes,
    required this.durationMinutes,
  });

  bool get isSuccess => result == RestoreDrillResult.success;

  /// Evidence заполнен — без этого success недопустим.
  bool get hasCompleteEvidence {
    if (backupId.trim().isEmpty || backupLocation.trim().isEmpty) return false;
    if (targetEnvironment.trim().length < 3) return false;
    if (restoredCollections.isEmpty) return false;
    if (testedBy.trim().isEmpty) return false;
    if (durationMinutes <= 0) return false;
    if (evidenceNotes.trim().length < 20) return false;
    if (isSuccess && evidenceNotes.trim().length < 40) return false;
    return true;
  }

  String? validationError() {
    if (backupId.trim().isEmpty) return 'backupId';
    if (backupLocation.trim().isEmpty) return 'backupLocation';
    if (targetEnvironment.trim().length < 3) return 'targetEnvironment';
    if (restoredCollections.isEmpty) return 'restoredCollections';
    if (testedBy.trim().isEmpty) return 'testedBy';
    if (durationMinutes <= 0) return 'durationMinutes';
    if (evidenceNotes.trim().length < 20) return 'evidenceNotes';
    if (isSuccess && evidenceNotes.trim().length < 40) {
      return 'evidenceNotesSuccess';
    }
    return null;
  }

  Map<String, dynamic> toFirestoreMap({required String quarter, required int year}) {
    return {
      'type': 'restore_drill',
      'backupId': backupId,
      'backupLocation': backupLocation,
      'testDate': testDate,
      'targetEnvironment': targetEnvironment.trim(),
      'restoredCollections': restoredCollections,
      'testedBy': testedBy,
      'performedBy': testedBy,
      'result': result.name,
      'success': isSuccess,
      'evidenceNotes': evidenceNotes.trim(),
      'durationMinutes': durationMinutes,
      'quarter': quarter,
      'year': year,
    };
  }
}
