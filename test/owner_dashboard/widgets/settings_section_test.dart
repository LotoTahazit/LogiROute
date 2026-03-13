import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_settings.dart';
import 'package:logiroute/features/owner_dashboard/utils/company_profile_validator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _hebrewChars = 'אבגדהוזחטיכלמנסעפצקרשת';
const _latinChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _digitChars = '0123456789';

String _randomHebrewString(Random rng, {int minLen = 1, int maxLen = 30}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return List.generate(
      len, (_) => _hebrewChars[rng.nextInt(_hebrewChars.length)]).join();
}

String _randomLatinString(Random rng, {int minLen = 0, int maxLen = 30}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  if (len == 0) return '';
  return List.generate(len, (_) => _latinChars[rng.nextInt(_latinChars.length)])
      .join();
}

String _randomDigitString(Random rng, {int minLen = 0, int maxLen = 10}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  if (len == 0) return '';
  return List.generate(len, (_) => _digitChars[rng.nextInt(_digitChars.length)])
      .join();
}

String _randomPhone(Random rng) {
  // Generate a phone like 05X-XXXXXXX
  return '05${rng.nextInt(10)}-${_randomDigitString(rng, minLen: 7, maxLen: 7)}';
}

String _randomEmail(Random rng) {
  final user = _randomLatinString(rng, minLen: 3, maxLen: 10).toLowerCase();
  final domain = _randomLatinString(rng, minLen: 3, maxLen: 8).toLowerCase();
  return '$user@$domain.co.il';
}

String _randomUrl(Random rng) {
  final domain = _randomLatinString(rng, minLen: 3, maxLen: 10).toLowerCase();
  return 'https://www.$domain.co.il';
}

/// Generate a valid 9-digit Israeli tax ID that passes Luhn.
String _randomValidTaxId(Random rng) {
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

/// A data class holding the profile fields that the owner can edit.
/// These are the fields saved in SettingsSection._saveProfile().
class _ProfileData {
  final String nameHebrew;
  final String nameEnglish;
  final String taxId;
  final String addressHebrew;
  final String addressEnglish;
  final String phone;
  final String city;
  final String zipCode;
  final String poBox;
  final String fax;
  final String email;
  final String website;

  const _ProfileData({
    required this.nameHebrew,
    required this.nameEnglish,
    required this.taxId,
    required this.addressHebrew,
    required this.addressEnglish,
    required this.phone,
    required this.city,
    required this.zipCode,
    required this.poBox,
    required this.fax,
    required this.email,
    required this.website,
  });

  /// The map that SettingsSection._saveProfile() writes to Firestore.
  Map<String, dynamic> toUpdateMap() => {
        'nameHebrew': nameHebrew,
        'nameEnglish': nameEnglish,
        'taxId': taxId,
        'addressHebrew': addressHebrew,
        'addressEnglish': addressEnglish,
        'phone': phone,
        'city': city,
        'zipCode': zipCode,
        'poBox': poBox,
        'fax': fax,
        'email': email,
        'website': website,
      };
}

/// Generate random valid profile data.
_ProfileData _randomProfileData(Random rng) {
  return _ProfileData(
    nameHebrew: _randomHebrewString(rng, minLen: 2, maxLen: 25),
    nameEnglish: _randomLatinString(rng, minLen: 2, maxLen: 25),
    taxId: _randomValidTaxId(rng),
    addressHebrew: _randomHebrewString(rng, minLen: 3, maxLen: 40),
    addressEnglish: _randomLatinString(rng, minLen: 3, maxLen: 40),
    phone: _randomPhone(rng),
    city: _randomHebrewString(rng, minLen: 2, maxLen: 15),
    zipCode: _randomDigitString(rng, minLen: 5, maxLen: 7),
    poBox: _randomDigitString(rng, minLen: 0, maxLen: 5),
    fax: _randomPhone(rng),
    email: _randomEmail(rng),
    website: _randomUrl(rng),
  );
}

// ===========================================================================
// Property-Based Tests — Property 15: Round-trip сохранения профиля компании
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 15: Round-trip сохранения профиля компании
  //
  // Для любых валидных данных профиля компании (nameHebrew, taxId,
  // addressHebrew, phone, city, zipCode), если owner сохраняет их,
  // то повторное чтение документа /companies/{companyId} должно вернуть
  // те же значения.
  // **Validates: Requirements 7.5**
  // -------------------------------------------------------------------------

  test(
    'Property 15a: round-trip save → read preserves all profile fields via FakeFirestore (150 iterations)',
    () async {
      final rng = Random(500);
      final fakeFirestore = FakeFirebaseFirestore();

      for (var i = 0; i < 150; i++) {
        final companyId = 'company-$i';
        final profile = _randomProfileData(rng);

        // Pre-validate: ensure the generated data passes validation
        final errors = CompanyProfileValidator.validate(
          nameHebrew: profile.nameHebrew,
          taxId: profile.taxId,
        );
        expect(errors.isEmpty, isTrue,
            reason:
                'Iteration $i: generated data should be valid, got: $errors');

        // Step 1: Create initial company document (simulates existing doc)
        final docRef = fakeFirestore.collection('companies').doc(companyId);
        await docRef.set({
          'nameHebrew': '',
          'nameEnglish': '',
          'taxId': '',
          'addressHebrew': '',
          'addressEnglish': '',
          'phone': '',
          'city': '',
          'zipCode': '',
          'poBox': '',
          'fax': '',
          'email': '',
          'website': '',
          // Non-profile fields that should not be affected
          'invoiceFooterText': 'footer-$i',
          'paymentTerms': 'net30',
          'bankDetails': 'bank-$i',
          'driverName': 'driver-$i',
          'driverPhone': '050-0000000',
          'departureTime': '7:00',
          'plan': 'full',
          'billingStatus': 'active',
          'gracePeriodDays': 7,
        });

        // Step 2: Save profile (same as SettingsSection._saveProfile)
        await docRef.update(profile.toUpdateMap());

        // Step 3: Read back via CompanySettings.fromFirestore
        final snapshot = await docRef.get();
        final restored = CompanySettings.fromFirestore(snapshot);

        // Step 4: Verify all profile fields match
        expect(restored.nameHebrew, equals(profile.nameHebrew),
            reason: 'Iteration $i: nameHebrew mismatch');
        expect(restored.nameEnglish, equals(profile.nameEnglish),
            reason: 'Iteration $i: nameEnglish mismatch');
        expect(restored.taxId, equals(profile.taxId),
            reason: 'Iteration $i: taxId mismatch');
        expect(restored.addressHebrew, equals(profile.addressHebrew),
            reason: 'Iteration $i: addressHebrew mismatch');
        expect(restored.addressEnglish, equals(profile.addressEnglish),
            reason: 'Iteration $i: addressEnglish mismatch');
        expect(restored.phone, equals(profile.phone),
            reason: 'Iteration $i: phone mismatch');
        expect(restored.city, equals(profile.city),
            reason: 'Iteration $i: city mismatch');
        expect(restored.zipCode, equals(profile.zipCode),
            reason: 'Iteration $i: zipCode mismatch');
        expect(restored.poBox, equals(profile.poBox),
            reason: 'Iteration $i: poBox mismatch');
        expect(restored.fax, equals(profile.fax),
            reason: 'Iteration $i: fax mismatch');
        expect(restored.email, equals(profile.email),
            reason: 'Iteration $i: email mismatch');
        expect(restored.website, equals(profile.website),
            reason: 'Iteration $i: website mismatch');
      }
    },
  );

  test(
    'Property 15b: profile update does not corrupt non-profile fields (150 iterations)',
    () async {
      final rng = Random(501);
      final fakeFirestore = FakeFirebaseFirestore();

      for (var i = 0; i < 150; i++) {
        final companyId = 'company-np-$i';
        final profile = _randomProfileData(rng);

        // Non-profile fields that must survive the profile update
        final nonProfileData = {
          'invoiceFooterText': 'footer-text-$i',
          'paymentTerms': 'net${rng.nextInt(90)}',
          'bankDetails': 'bank-details-$i',
          'driverName': 'driver-$i',
          'driverPhone': '050-${_randomDigitString(rng, minLen: 7, maxLen: 7)}',
          'departureTime':
              '${6 + rng.nextInt(4)}:${rng.nextBool() ? "00" : "30"}',
          'plan': ['warehouse_only', 'ops', 'full'][rng.nextInt(3)],
          'billingStatus': 'active',
          'gracePeriodDays': 7 + rng.nextInt(14),
        };

        final docRef = fakeFirestore.collection('companies').doc(companyId);

        // Create initial doc with non-profile data
        await docRef.set({
          ...nonProfileData,
          'nameHebrew': '',
          'nameEnglish': '',
          'taxId': '',
          'addressHebrew': '',
          'addressEnglish': '',
          'phone': '',
          'city': '',
          'zipCode': '',
          'poBox': '',
          'fax': '',
          'email': '',
          'website': '',
        });

        // Save profile (partial update — only profile fields)
        await docRef.update(profile.toUpdateMap());

        // Read back
        final snapshot = await docRef.get();
        final restored = CompanySettings.fromFirestore(snapshot);

        // Non-profile fields should be unchanged
        expect(restored.invoiceFooterText,
            equals(nonProfileData['invoiceFooterText']),
            reason: 'Iteration $i: invoiceFooterText corrupted');
        expect(restored.paymentTerms, equals(nonProfileData['paymentTerms']),
            reason: 'Iteration $i: paymentTerms corrupted');
        expect(restored.bankDetails, equals(nonProfileData['bankDetails']),
            reason: 'Iteration $i: bankDetails corrupted');
        expect(restored.plan, equals(nonProfileData['plan']),
            reason: 'Iteration $i: plan corrupted');
        expect(restored.billingStatus, equals(nonProfileData['billingStatus']),
            reason: 'Iteration $i: billingStatus corrupted');
      }
    },
  );

  test(
    'Property 15c: round-trip via CompanySettings toFirestore → fromFirestore preserves profile fields (150 iterations)',
    () async {
      final rng = Random(502);
      final fakeFirestore = FakeFirebaseFirestore();

      for (var i = 0; i < 150; i++) {
        final companyId = 'company-rt-$i';
        final profile = _randomProfileData(rng);

        // Build a full CompanySettings with the random profile data
        final original = CompanySettings(
          id: companyId,
          nameHebrew: profile.nameHebrew,
          nameEnglish: profile.nameEnglish,
          taxId: profile.taxId,
          addressHebrew: profile.addressHebrew,
          addressEnglish: profile.addressEnglish,
          phone: profile.phone,
          city: profile.city,
          zipCode: profile.zipCode,
          poBox: profile.poBox,
          fax: profile.fax,
          email: profile.email,
          website: profile.website,
          invoiceFooterText: 'footer',
          paymentTerms: 'net30',
          bankDetails: 'bank',
          driverName: 'driver',
          driverPhone: '050-0000000',
          departureTime: '7:00',
        );

        // Write full model to Firestore
        final docRef = fakeFirestore.collection('companies').doc(companyId);
        await docRef.set(original.toFirestore());

        // Read back
        final snapshot = await docRef.get();
        final restored = CompanySettings.fromFirestore(snapshot);

        // Verify all profile fields
        expect(restored.nameHebrew, equals(original.nameHebrew),
            reason: 'Iteration $i: nameHebrew mismatch');
        expect(restored.nameEnglish, equals(original.nameEnglish),
            reason: 'Iteration $i: nameEnglish mismatch');
        expect(restored.taxId, equals(original.taxId),
            reason: 'Iteration $i: taxId mismatch');
        expect(restored.addressHebrew, equals(original.addressHebrew),
            reason: 'Iteration $i: addressHebrew mismatch');
        expect(restored.addressEnglish, equals(original.addressEnglish),
            reason: 'Iteration $i: addressEnglish mismatch');
        expect(restored.phone, equals(original.phone),
            reason: 'Iteration $i: phone mismatch');
        expect(restored.city, equals(original.city),
            reason: 'Iteration $i: city mismatch');
        expect(restored.zipCode, equals(original.zipCode),
            reason: 'Iteration $i: zipCode mismatch');
        expect(restored.poBox, equals(original.poBox),
            reason: 'Iteration $i: poBox mismatch');
        expect(restored.fax, equals(original.fax),
            reason: 'Iteration $i: fax mismatch');
        expect(restored.email, equals(original.email),
            reason: 'Iteration $i: email mismatch');
        expect(restored.website, equals(original.website),
            reason: 'Iteration $i: website mismatch');
      }
    },
  );
}
