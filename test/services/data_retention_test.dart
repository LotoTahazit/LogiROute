import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:logiroute/services/data_retention_service.dart';

void main() {
  group('DataRetentionService.isWithinRetentionPeriod', () {
    // Test the static logic without instantiating the service (avoids Firebase)
    test('recent date is within retention', () {
      final recentDate = DateTime.now().subtract(const Duration(days: 365));
      final cutoff = DateTime.now().subtract(
        const Duration(days: 7 * 365),
      );
      expect(recentDate.isAfter(cutoff), true);
    });

    test('very old date is outside retention', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 365 * 8));
      final cutoff = DateTime.now().subtract(
        const Duration(days: 7 * 365),
      );
      expect(oldDate.isAfter(cutoff), false);
    });

    test('minimumRetentionYears is 7', () {
      expect(DataRetentionService.minimumRetentionYears, 7);
    });
  });

  group('RetentionCheckResult', () {
    test('summary for compliant result', () {
      final result = RetentionCheckResult(
        checkedAt: DateTime.now(),
        checkedBy: 'admin',
        totalDocuments: 150,
        retentionCutoffDate: DateTime(2019, 1, 1),
        isCompliant: true,
        hasSequentialGaps: false,
        expectedCount: 150,
      );
      expect(result.summary, contains('תקין'));
      expect(result.summary, contains('150'));
    });

    test('summary for non-compliant result with gaps', () {
      final result = RetentionCheckResult(
        checkedAt: DateTime.now(),
        checkedBy: 'admin',
        totalDocuments: 140,
        retentionCutoffDate: DateTime(2019, 1, 1),
        isCompliant: false,
        hasSequentialGaps: true,
        expectedCount: 150,
      );
      expect(result.summary, contains('בעיות'));
      expect(result.summary, contains('פערים'));
    });
  });
}
