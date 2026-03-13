import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/import_result.dart';

void main() {
  group('ImportResult', () {
    group('summaryString', () {
      test('formats correctly with mixed counts', () {
        final result = ImportResult(
          addedCount: 5,
          skippedCount: 2,
          errorCount: 1,
          errorProductNames: ['כוס 8oz'],
        );

        expect(
          result.summaryString,
          'נוספו 5 | דולגו 2 כפילויות | שגיאות 1',
        );
      });

      test('formats correctly with all zeros', () {
        final result = ImportResult(
          addedCount: 0,
          skippedCount: 0,
          errorCount: 0,
        );

        expect(
          result.summaryString,
          'נוספו 0 | דולגו 0 כפילויות | שגיאות 0',
        );
      });
    });

    group('total getter', () {
      test('returns sum of addedCount + skippedCount + errorCount', () {
        final result = ImportResult(
          addedCount: 5,
          skippedCount: 2,
          errorCount: 1,
        );

        expect(result.total, 8);
      });

      test('all zeros → total == 0', () {
        final result = ImportResult(
          addedCount: 0,
          skippedCount: 0,
          errorCount: 0,
        );

        expect(result.total, 0);
      });
    });

    group('errorProductNames', () {
      test('0 errors → errorProductNames is empty', () {
        final result = ImportResult(
          addedCount: 3,
          skippedCount: 1,
          errorCount: 0,
        );

        expect(result.errorProductNames, isEmpty);
      });

      test('errors > 0 → errorProductNames populated', () {
        final result = ImportResult(
          addedCount: 2,
          skippedCount: 0,
          errorCount: 2,
          errorProductNames: ['כוס 8oz', 'מכסה שטוח'],
        );

        expect(result.errorProductNames, hasLength(2));
        expect(result.errorProductNames, ['כוס 8oz', 'מכסה שטוח']);
      });
    });

    group('equality', () {
      test('equal objects are equal', () {
        final a = ImportResult(
          addedCount: 3,
          skippedCount: 1,
          errorCount: 1,
          errorProductNames: ['כוס 8oz'],
        );
        final b = ImportResult(
          addedCount: 3,
          skippedCount: 1,
          errorCount: 1,
          errorProductNames: ['כוס 8oz'],
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different counts are not equal', () {
        final a = ImportResult(
          addedCount: 3,
          skippedCount: 1,
          errorCount: 0,
        );
        final b = ImportResult(
          addedCount: 3,
          skippedCount: 2,
          errorCount: 0,
        );

        expect(a, isNot(equals(b)));
      });

      test('different errorProductNames are not equal', () {
        final a = ImportResult(
          addedCount: 1,
          skippedCount: 0,
          errorCount: 1,
          errorProductNames: ['כוס 8oz'],
        );
        final b = ImportResult(
          addedCount: 1,
          skippedCount: 0,
          errorCount: 1,
          errorProductNames: ['מכסה שטוח'],
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('formats correctly', () {
        final result = ImportResult(
          addedCount: 5,
          skippedCount: 2,
          errorCount: 1,
        );

        expect(
          result.toString(),
          'ImportResult(added: 5, skipped: 2, errors: 1)',
        );
      });
    });
  });
}
