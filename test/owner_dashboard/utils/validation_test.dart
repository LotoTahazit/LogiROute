import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/utils/company_profile_validator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Characters that are considered "blank" — spaces, tabs, newlines, etc.
const _whitespaceChars = [' ', '\t', '\n', '\r', '\u00A0'];

/// Generate a random whitespace-only string of length 0..maxLen.
String _randomWhitespace(Random rng, {int maxLen = 10}) {
  final len = rng.nextInt(maxLen + 1);
  return List.generate(
    len,
    (_) => _whitespaceChars[rng.nextInt(_whitespaceChars.length)],
  ).join();
}

/// Generate a random non-empty Hebrew-like string (at least 1 non-space char).
String _randomNonEmptyName(Random rng) {
  const chars = 'אבגדהוזחטיכלמנסעפצקרשת';
  final len = 1 + rng.nextInt(20);
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Compute a known-valid Israeli tax ID using the same Luhn algorithm.
String _computeValidTaxId() {
  // Start with 8 digits, compute check digit
  const base = [1, 0, 0, 0, 0, 0, 0, 0];
  var sum = 0;
  for (var i = 0; i < 8; i++) {
    var d = base[i];
    if (i % 2 != 0) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  final check = (10 - (sum % 10)) % 10;
  return '${base.join()}$check';
}

final _validTaxId = _computeValidTaxId();

/// Generate a random valid 9-digit Israeli tax ID that passes Luhn.
String _randomValidTaxId(Random rng) {
  // Generate first 8 digits, compute the 9th as check digit
  final digits = List.generate(8, (_) => rng.nextInt(10));

  var sum = 0;
  for (var i = 0; i < 8; i++) {
    var d = digits[i];
    if (i % 2 != 0) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }

  final checkDigit = (10 - (sum % 10)) % 10;
  digits.add(checkDigit);

  return digits.join();
}

// ===========================================================================
// Property-Based Tests — Property 16: Валидация обязательных полей
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 16: Валидация обязательных полей
  //
  // Если `nameHebrew` или `taxId` пусты/пробелы — ошибка валидации,
  // сохранение не происходит.
  // **Validates: Requirements 7.8, 7.9**
  // -------------------------------------------------------------------------

  test(
    'Property 16a: empty or whitespace-only nameHebrew always produces validation error (150 iterations)',
    () {
      final rng = Random(200);

      for (var i = 0; i < 150; i++) {
        final blankName = _randomWhitespace(rng);
        final validTaxId = _randomValidTaxId(rng);

        final errors = CompanyProfileValidator.validate(
          nameHebrew: blankName,
          taxId: validTaxId,
        );

        expect(errors.containsKey('nameHebrew'), isTrue,
            reason:
                'Iteration $i: blank nameHebrew "$blankName" should produce error');
        expect(errors['nameHebrew'], isNotEmpty,
            reason: 'Iteration $i: error message should not be empty');
      }
    },
  );

  test(
    'Property 16b: empty or whitespace-only taxId always produces validation error (150 iterations)',
    () {
      final rng = Random(201);

      for (var i = 0; i < 150; i++) {
        final validName = _randomNonEmptyName(rng);
        final blankTaxId = _randomWhitespace(rng);

        final errors = CompanyProfileValidator.validate(
          nameHebrew: validName,
          taxId: blankTaxId,
        );

        expect(errors.containsKey('taxId'), isTrue,
            reason:
                'Iteration $i: blank taxId "$blankTaxId" should produce error');
        expect(errors['taxId'], isNotEmpty,
            reason: 'Iteration $i: error message should not be empty');
      }
    },
  );

  test(
    'Property 16c: both fields blank produces errors for both (150 iterations)',
    () {
      final rng = Random(202);

      for (var i = 0; i < 150; i++) {
        final blankName = _randomWhitespace(rng);
        final blankTaxId = _randomWhitespace(rng);

        final errors = CompanyProfileValidator.validate(
          nameHebrew: blankName,
          taxId: blankTaxId,
        );

        expect(errors.containsKey('nameHebrew'), isTrue,
            reason: 'Iteration $i: blank nameHebrew should produce error');
        expect(errors.containsKey('taxId'), isTrue,
            reason: 'Iteration $i: blank taxId should produce error');
        expect(errors.length, greaterThanOrEqualTo(2),
            reason: 'Iteration $i: should have at least 2 errors');
      }
    },
  );

  test(
    'Property 16d: valid nameHebrew and valid taxId produces no errors (150 iterations)',
    () {
      final rng = Random(203);

      for (var i = 0; i < 150; i++) {
        final validName = _randomNonEmptyName(rng);
        final validTaxId = _randomValidTaxId(rng);

        final errors = CompanyProfileValidator.validate(
          nameHebrew: validName,
          taxId: validTaxId,
        );

        expect(errors.isEmpty, isTrue,
            reason:
                'Iteration $i: valid name "$validName" and taxId "$validTaxId" should pass validation, got errors: $errors');
      }
    },
  );

  test(
    'Property 16e: exactly empty string always fails for both fields',
    () {
      final errors = CompanyProfileValidator.validate(
        nameHebrew: '',
        taxId: '',
      );

      expect(errors.containsKey('nameHebrew'), isTrue);
      expect(errors.containsKey('taxId'), isTrue);
    },
  );

  test(
    'Property 16f: known valid taxId "$_validTaxId" with valid name passes',
    () {
      final errors = CompanyProfileValidator.validate(
        nameHebrew: 'חברה לדוגמה',
        taxId: _validTaxId,
      );

      expect(errors.isEmpty, isTrue, reason: 'Known valid inputs should pass');
    },
  );
}
