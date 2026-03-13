import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/firestore_paths.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Generate a random non-empty companyId string (alphanumeric, 1..30 chars).
String _randomCompanyId(Random rng) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final len = 1 + rng.nextInt(30);
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}

// ===========================================================================
// Property-Based Tests — Property 22: Пути Firestore всегда содержат companyId
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 22: Пути Firestore всегда содержат companyId
  //
  // Для любого вызова метода репозитория с непустым companyId,
  // сгенерированный путь Firestore должен содержать
  // `/companies/{companyId}/` как префикс.
  // Для пустого или null companyId должно быть выброшено исключение.
  // **Validates: Requirements 10.5, 10.6**
  // -------------------------------------------------------------------------

  late FirestorePaths paths;

  setUp(() {
    paths = FirestorePaths(firestore: FakeFirebaseFirestore());
  });

  test(
    'Property 22a: validateCompanyId accepts any non-empty companyId (150 iterations)',
    () {
      final rng = Random(500);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);

        expect(
          () => paths.validateCompanyId(companyId),
          returnsNormally,
          reason:
              'Iteration $i: validateCompanyId should accept non-empty companyId "$companyId"',
        );
      }
    },
  );

  test(
    'Property 22b: validateCompanyId throws for empty or null companyId (150 iterations)',
    () {
      final rng = Random(501);

      for (var i = 0; i < 150; i++) {
        final isNull = rng.nextBool();

        expect(
          () => paths.validateCompanyId(isNull ? null : ''),
          throwsA(isA<Exception>()),
          reason:
              'Iteration $i: validateCompanyId should throw for ${isNull ? "null" : "empty"} companyId',
        );
      }
    },
  );

  test(
    'Property 22c: all Owner Dashboard path methods throw for empty companyId (150 iterations)',
    () {
      // Each method that belongs to the Owner Dashboard section
      // should throw when given an empty companyId.
      final ownerDashboardMethods = <String, void Function()>{
        'members': () => paths.members(''),
        'invites': () => paths.invites(''),
        'billingInvoices': () => paths.billingInvoices(''),
        'dailyMetrics': () => paths.dailyMetrics(''),
        'systemEvents': () => paths.systemEvents(''),
        'printEvents': () => paths.printEvents(''),
        'audit': () => paths.audit(''),
        'accountingDocs': () => paths.accountingDocs(''),
        'accountingCounters': () => paths.accountingCounters(''),
      };

      for (var i = 0; i < 150; i++) {
        for (final entry in ownerDashboardMethods.entries) {
          expect(
            entry.value,
            throwsA(isA<Exception>()),
            reason:
                'Iteration $i: ${entry.key}("") should throw for empty companyId',
          );
        }
      }
    },
  );

  test(
    'Property 22d: all Owner Dashboard path methods produce paths containing companies/{companyId} for non-empty companyId (150 iterations)',
    () {
      final rng = Random(502);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final expectedSegment = 'companies/$companyId';

        // Each Owner Dashboard method should produce a path containing
        // companies/{companyId} as a prefix segment.
        final methodResults = <String, String>{
          'members': paths.members(companyId).path,
          'invites': paths.invites(companyId).path,
          'billingInvoices': paths.billingInvoices(companyId).path,
          'dailyMetrics': paths.dailyMetrics(companyId).path,
          'systemEvents': paths.systemEvents(companyId).path,
          'printEvents': paths.printEvents(companyId).path,
          'audit': paths.audit(companyId).path,
          'accountingDocs': paths.accountingDocs(companyId).path,
          'accountingCounters': paths.accountingCounters(companyId).path,
        };

        for (final entry in methodResults.entries) {
          expect(
            entry.value.contains(expectedSegment),
            isTrue,
            reason:
                'Iteration $i: ${entry.key}("$companyId") path "${entry.value}" should contain "$expectedSegment"',
          );
        }
      }
    },
  );

  test(
    'Property 22e: paths start with companies/{companyId} prefix (150 iterations)',
    () {
      final rng = Random(503);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final expectedPrefix = 'companies/$companyId/';

        final methodResults = <String, String>{
          'members': paths.members(companyId).path,
          'invites': paths.invites(companyId).path,
          'billingInvoices': paths.billingInvoices(companyId).path,
          'dailyMetrics': paths.dailyMetrics(companyId).path,
          'systemEvents': paths.systemEvents(companyId).path,
          'printEvents': paths.printEvents(companyId).path,
          'audit': paths.audit(companyId).path,
          'accountingDocs': paths.accountingDocs(companyId).path,
          'accountingCounters': paths.accountingCounters(companyId).path,
        };

        for (final entry in methodResults.entries) {
          expect(
            entry.value.startsWith(expectedPrefix),
            isTrue,
            reason:
                'Iteration $i: ${entry.key}("$companyId") path "${entry.value}" should start with "$expectedPrefix"',
          );
        }
      }
    },
  );

  test(
    'Property 22f: exception message for empty/null companyId is descriptive (150 iterations)',
    () {
      final rng = Random(504);

      for (var i = 0; i < 150; i++) {
        final isNull = rng.nextBool();

        try {
          paths.validateCompanyId(isNull ? null : '');
          fail('Iteration $i: should have thrown');
        } on Exception catch (e) {
          final message = e.toString().toLowerCase();
          expect(
            message.contains('companyid'),
            isTrue,
            reason:
                'Iteration $i: exception message "$message" should mention companyId',
          );
        }
      }
    },
  );
}
