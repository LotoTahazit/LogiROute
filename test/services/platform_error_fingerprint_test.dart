import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/platform_system_error.dart';
import 'package:logiroute/services/platform_error_fingerprint.dart';

void main() {
  test('fingerprint is stable for same inputs', () {
    final a = computePlatformErrorFingerprint(
      errorType: 'FirebaseException',
      stackTrace: 'Error\n  at foo.dart:10\n  at bar.dart:20',
      operation: 'import_excel',
    );
    final b = computePlatformErrorFingerprint(
      errorType: 'FirebaseException',
      stackTrace: 'Error\n  at foo.dart:10\n  at bar.dart:99',
      operation: 'import_excel',
    );
    expect(a, b);
  });

  test('fingerprint changes when operation differs', () {
    final a = computePlatformErrorFingerprint(
      errorType: 'Error',
      stackTrace: 'x\n  at a.dart:1',
      operation: 'op_a',
    );
    final b = computePlatformErrorFingerprint(
      errorType: 'Error',
      stackTrace: 'x\n  at a.dart:1',
      operation: 'op_b',
    );
    expect(a, isNot(b));
  });

  test('permission denied severity is high', () {
    expect(
      inferPlatformErrorSeverity(
        errorType: 'permission-denied',
        errorMessage: 'Firestore permission denied',
      ),
      PlatformErrorSeverity.high,
    );
  });

  test('unhandled crash severity is critical', () {
    expect(
      inferPlatformErrorSeverity(
        errorType: 'unhandled',
        errorMessage: 'Unhandled exception in billing',
      ),
      PlatformErrorSeverity.critical,
    );
  });

  test('sanitize removes jwt and email', () {
    final out = sanitizePlatformErrorText(
      'user@test.com token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhIjoiYiJ9.sig',
    );
    expect(out, contains('[email]'));
    expect(out, contains('[jwt]'));
    expect(out, isNot(contains('user@test.com')));
  });
}
