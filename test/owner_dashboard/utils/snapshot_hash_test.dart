import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/accounting_doc.dart';
import 'package:logiroute/features/owner_dashboard/utils/snapshot_hash.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AccountingDoc _makeDoc({
  int? docNumber,
  DateTime? issuedAt,
  String customerId = 'cust-1',
  List<AccountingDocLine>? lines,
  AccountingDocTotals? totals,
}) {
  return AccountingDoc(
    type: AccountingDocType.taxInvoice,
    status: AccountingDocStatus.issued,
    docNumber: docNumber,
    issuedAt: issuedAt,
    customerId: customerId,
    customerName: 'Test Customer',
    lines: lines ??
        [
          AccountingDocLine(
            description: 'Item 1',
            quantity: 2,
            unitPrice: 100,
            totalBeforeVat: 200,
            vatAmount: 34,
            totalWithVat: 234,
          ),
        ],
    totals: totals ?? AccountingDocTotals(net: 200, vat: 34, gross: 234),
    createdBy: 'user-1',
    companyId: 'company-1',
  );
}

String _manualHash(AccountingDoc doc) {
  final payload = {
    'docNumber': doc.docNumber,
    'issuedAt': doc.issuedAt?.toIso8601String(),
    'customerId': doc.customerId,
    'lines': doc.lines.map((l) => l.toMap()).toList(),
    'totals': doc.totals.toMap(),
  };
  final jsonString = jsonEncode(payload);
  final bytes = utf8.encode(jsonString);
  return sha256.convert(bytes).toString();
}

// ===========================================================================
// Tests — SnapshotHash utility
// ===========================================================================

void main() {
  group('SnapshotHash.compute', () {
    test('returns a 64-character hex string (SHA-256)', () {
      final doc = _makeDoc(docNumber: 1, issuedAt: DateTime(2025, 1, 15));
      final hash = SnapshotHash.compute(doc);

      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('matches manual SHA-256 computation', () {
      final doc = _makeDoc(
        docNumber: 42,
        issuedAt: DateTime(2025, 6, 1),
        customerId: 'cust-abc',
      );

      expect(SnapshotHash.compute(doc), _manualHash(doc));
    });

    test('same document produces same hash (deterministic)', () {
      final doc = _makeDoc(docNumber: 10, issuedAt: DateTime(2025, 3, 20));

      expect(SnapshotHash.compute(doc), SnapshotHash.compute(doc));
    });

    test('different docNumber produces different hash', () {
      final doc1 = _makeDoc(docNumber: 1, issuedAt: DateTime(2025, 1, 1));
      final doc2 = _makeDoc(docNumber: 2, issuedAt: DateTime(2025, 1, 1));

      expect(SnapshotHash.compute(doc1), isNot(SnapshotHash.compute(doc2)));
    });

    test('different customerId produces different hash', () {
      final doc1 = _makeDoc(
          docNumber: 1, issuedAt: DateTime(2025, 1, 1), customerId: 'a');
      final doc2 = _makeDoc(
          docNumber: 1, issuedAt: DateTime(2025, 1, 1), customerId: 'b');

      expect(SnapshotHash.compute(doc1), isNot(SnapshotHash.compute(doc2)));
    });

    test('different totals produces different hash', () {
      final doc1 = _makeDoc(
        docNumber: 1,
        issuedAt: DateTime(2025, 1, 1),
        totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
      );
      final doc2 = _makeDoc(
        docNumber: 1,
        issuedAt: DateTime(2025, 1, 1),
        totals: AccountingDocTotals(net: 200, vat: 34, gross: 234),
      );

      expect(SnapshotHash.compute(doc1), isNot(SnapshotHash.compute(doc2)));
    });

    test('different lines produces different hash', () {
      final doc1 = _makeDoc(
        docNumber: 1,
        issuedAt: DateTime(2025, 1, 1),
        lines: [
          AccountingDocLine(
            description: 'A',
            quantity: 1,
            unitPrice: 50,
            totalBeforeVat: 50,
            vatAmount: 8.5,
            totalWithVat: 58.5,
          ),
        ],
      );
      final doc2 = _makeDoc(
        docNumber: 1,
        issuedAt: DateTime(2025, 1, 1),
        lines: [
          AccountingDocLine(
            description: 'B',
            quantity: 2,
            unitPrice: 50,
            totalBeforeVat: 100,
            vatAmount: 17,
            totalWithVat: 117,
          ),
        ],
      );

      expect(SnapshotHash.compute(doc1), isNot(SnapshotHash.compute(doc2)));
    });

    test('non-key fields (notes, status, type) do not affect hash', () {
      final base = _makeDoc(docNumber: 5, issuedAt: DateTime(2025, 2, 1));
      final withNotes = AccountingDoc(
        type: AccountingDocType.receipt,
        status: AccountingDocStatus.locked,
        docNumber: 5,
        issuedAt: DateTime(2025, 2, 1),
        customerId: base.customerId,
        customerName: 'Different Name',
        lines: base.lines,
        totals: base.totals,
        createdBy: 'other-user',
        companyId: 'other-company',
        notes: 'some notes',
      );

      expect(SnapshotHash.compute(base), SnapshotHash.compute(withNotes));
    });

    test('handles null docNumber and issuedAt', () {
      final doc = _makeDoc(docNumber: null, issuedAt: null);
      final hash = SnapshotHash.compute(doc);

      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('deterministic across 100 random documents', () {
      final rng = Random(42);

      for (var i = 0; i < 100; i++) {
        final doc = _makeDoc(
          docNumber: rng.nextInt(10000),
          issuedAt: DateTime(
              2020 + rng.nextInt(10), 1 + rng.nextInt(12), 1 + rng.nextInt(28)),
          customerId: 'cust-${rng.nextInt(1000)}',
          totals: AccountingDocTotals(
            net: rng.nextDouble() * 10000,
            vat: rng.nextDouble() * 2000,
            gross: rng.nextDouble() * 12000,
          ),
        );

        final h1 = SnapshotHash.compute(doc);
        final h2 = SnapshotHash.compute(doc);
        expect(h1, h2, reason: 'Iteration $i: hash should be deterministic');
        expect(h1, _manualHash(doc),
            reason: 'Iteration $i: should match manual computation');
      }
    });
  });
}
