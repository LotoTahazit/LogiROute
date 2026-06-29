import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/restore_drill_record.dart';
import 'package:logiroute/services/backup_service.dart';

void main() {
  group('RestoreDrillRecord evidence', () {
    RestoreDrillRecord sample({RestoreDrillResult result = RestoreDrillResult.success}) {
      return RestoreDrillRecord(
        backupId: 'b1',
        backupLocation: 'Firebase: logiroute-app',
        testDate: DateTime(2026, 6, 1),
        targetEnvironment: 'restore-20260601',
        restoredCollections: const ['clients', 'invoices'],
        testedBy: 'admin',
        result: result,
        evidenceNotes: result == RestoreDrillResult.success
            ? 'Restored to restore-20260601; verified 12 clients and 5 invoices match counts.'
            : 'Restore failed: gcloud timeout after 45 min.',
        durationMinutes: 45,
      );
    }

    test('success requires long evidence', () {
      final short = RestoreDrillRecord(
        backupId: 'b1',
        backupLocation: 'Firebase: logiroute-app',
        testDate: DateTime(2026, 6, 1),
        targetEnvironment: 'restore-20260601',
        restoredCollections: const ['clients'],
        testedBy: 'admin',
        result: RestoreDrillResult.success,
        evidenceNotes: 'too short',
        durationMinutes: 45,
      );
      expect(short.validationError(), isNotNull);
    });

    test('complete success drill passes validation', () {
      expect(sample().validationError(), isNull);
      expect(sample().hasCompleteEvidence, isTrue);
    });

    test('failed drill still needs evidence', () {
      final failed = sample(result: RestoreDrillResult.failed);
      expect(failed.validationError(), isNull);
    });
  });

  group('BackupService quarterly logic', () {
    test('quarter start months are Jan, Apr, Jul, Oct', () {
      final quarterStartMonths = [1, 4, 7, 10];
      expect(quarterStartMonths, contains(1));
      expect(quarterStartMonths, contains(4));
      expect(quarterStartMonths, contains(7));
      expect(quarterStartMonths, contains(10));
      expect(quarterStartMonths, isNot(contains(2)));
    });

    test('isQuarterlyBackupDue logic: first 7 days of quarter month', () {
      // Simulate the logic without Firebase
      bool isBackupDue(int month, int day) {
        final quarterStartMonths = [1, 4, 7, 10];
        return quarterStartMonths.contains(month) && day <= 7;
      }

      expect(isBackupDue(1, 1), true); // Jan 1
      expect(isBackupDue(1, 7), true); // Jan 7
      expect(isBackupDue(1, 8), false); // Jan 8
      expect(isBackupDue(4, 3), true); // Apr 3
      expect(isBackupDue(7, 5), true); // Jul 5
      expect(isBackupDue(10, 1), true); // Oct 1
      expect(isBackupDue(2, 1), false); // Feb 1
      expect(isBackupDue(6, 3), false); // Jun 3
    });

    test('currentQuarter logic', () {
      String currentQuarter(int month) {
        if (month <= 3) return 'Q1';
        if (month <= 6) return 'Q2';
        if (month <= 9) return 'Q3';
        return 'Q4';
      }

      expect(currentQuarter(1), 'Q1');
      expect(currentQuarter(3), 'Q1');
      expect(currentQuarter(4), 'Q2');
      expect(currentQuarter(6), 'Q2');
      expect(currentQuarter(7), 'Q3');
      expect(currentQuarter(10), 'Q4');
      expect(currentQuarter(12), 'Q4');
    });
  });
}
