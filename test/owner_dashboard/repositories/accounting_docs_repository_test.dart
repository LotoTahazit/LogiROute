import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/accounting_doc.dart';
import 'package:logiroute/features/owner_dashboard/models/credit_note_data.dart';
import 'package:logiroute/features/owner_dashboard/repositories/accounting_docs_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All possible document statuses.
const _allStatuses = AccountingDocStatus.values;

/// Non-draft statuses — updates should be rejected for these.
final _nonDraftStatuses =
    _allStatuses.where((s) => s != AccountingDocStatus.draft).toList();

/// All document types.
const _allDocTypes = AccountingDocType.values;

String _randomString(Random rng, {int minLen = 3, int maxLen = 12}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => 97 + rng.nextInt(26)),
  );
}

AccountingDocType _randomDocType(Random rng) =>
    _allDocTypes[rng.nextInt(_allDocTypes.length)];

AccountingDocStatus _randomNonDraftStatus(Random rng) =>
    _nonDraftStatuses[rng.nextInt(_nonDraftStatuses.length)];

/// Creates a document directly in Firestore with the given status.
/// Returns the document ID.
Future<String> _createDocInFirestore(
  FakeFirebaseFirestore firestore,
  String companyId, {
  required AccountingDocStatus status,
  required AccountingDocType type,
  required String customerId,
  required String createdBy,
}) async {
  final docRef = firestore
      .collection('companies')
      .doc(companyId)
      .collection('accountingDocs')
      .doc();

  await docRef.set({
    'type': type.value,
    'status': status.value,
    'customerId': customerId,
    'customerName': 'Customer $customerId',
    'lines': [],
    'totals': {'net': 100.0, 'vat': 17.0, 'gross': 117.0},
    'createdAt': Timestamp.now(),
    'createdBy': createdBy,
    'companyId': companyId,
  });

  return docRef.id;
}

// ===========================================================================
// Property-Based Tests — Property 27: Accountant может редактировать только
// draft-документы
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 27: Accountant может редактировать только draft-документы
  //
  // Для любого документа и роли accountant:
  // - если status == draft — обновление разрешено
  // - если status != draft — обновление отклонено (StateError)
  // **Validates: Requirements 15.2, 15.4, 15.5, 19.2**
  // -------------------------------------------------------------------------

  test(
    'Property 27a: updateDoc succeeds for draft documents (150 iterations)',
    () async {
      final rng = Random(2700);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final customerId = 'cust-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);

        // Create a draft document directly in Firestore
        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: AccountingDocStatus.draft,
          type: docType,
          customerId: customerId,
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Random update field
        final newNotes = 'updated-notes-${_randomString(rng)}';

        // updateDoc should succeed for draft documents
        await expectLater(
          repo.updateDoc(docId, {'notes': newNotes}),
          completes,
          reason: 'Iteration $i: updateDoc should succeed for draft '
              '(type=${docType.value})',
        );
      }
    },
  );

  test(
    'Property 27b: updateDoc throws StateError for non-draft documents (150 iterations)',
    () async {
      final rng = Random(2701);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final customerId = 'cust-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);
        final nonDraftStatus = _randomNonDraftStatus(rng);

        // Create a document with non-draft status directly in Firestore
        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: nonDraftStatus,
          type: docType,
          customerId: customerId,
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Random update field
        final newNotes = 'updated-notes-${_randomString(rng)}';

        // updateDoc should throw StateError for non-draft documents
        await expectLater(
          repo.updateDoc(docId, {'notes': newNotes}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updateDoc should throw StateError for '
              'status=${nonDraftStatus.value} (type=${docType.value})',
        );
      }
    },
  );

  test(
    'Property 27c: updateDoc rejects each specific non-draft status (150 iterations)',
    () async {
      final rng = Random(2702);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);

        // Cycle through all non-draft statuses deterministically
        final statusIndex = i % _nonDraftStatuses.length;
        final nonDraftStatus = _nonDraftStatuses[statusIndex];

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: nonDraftStatus,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Attempt update with random data
        final updates = <String, dynamic>{
          'customerName': 'New Name ${_randomString(rng)}',
          'notes': 'note-${_randomString(rng)}',
        };

        await expectLater(
          repo.updateDoc(docId, updates),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(nonDraftStatus.value),
            ),
          ),
          reason: 'Iteration $i: updateDoc should throw StateError '
              'mentioning "${nonDraftStatus.value}"',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 28: Issued-документы — неизменяемость ключевых полей
  //
  // Для любого документа со статусом issued/locked/credited, поля docNumber,
  // issuedAt, customerId, lines, totals, immutableSnapshotHash не могут быть
  // изменены. updateDoc отклоняет ВСЕ обновления для не-draft документов
  // (throws StateError), что автоматически защищает ключевые поля.
  // **Validates: Requirements 15.3, 17.3, 19.6**
  // -------------------------------------------------------------------------

  test(
    'Property 28a: updating docNumber on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2800);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        await expectLater(
          repo.updateDoc(docId, {'docNumber': rng.nextInt(9999) + 1}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating docNumber should throw for '
              'status=${status.value}',
        );
      }
    },
  );

  test(
    'Property 28b: updating issuedAt on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2801);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        await expectLater(
          repo.updateDoc(docId, {'issuedAt': Timestamp.now()}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating issuedAt should throw for '
              'status=${status.value}',
        );
      }
    },
  );

  test(
    'Property 28c: updating customerId on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2802);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        await expectLater(
          repo.updateDoc(docId, {'customerId': 'new-${_randomString(rng)}'}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating customerId should throw for '
              'status=${status.value}',
        );
      }
    },
  );

  test(
    'Property 28d: updating lines on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2803);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final newLines = [
          {
            'description': 'item-${_randomString(rng)}',
            'quantity': rng.nextDouble() * 10,
            'unitPrice': rng.nextDouble() * 100,
            'totalBeforeVat': rng.nextDouble() * 1000,
            'vatRate': 0.17,
            'vatAmount': rng.nextDouble() * 170,
            'totalWithVat': rng.nextDouble() * 1170,
          }
        ];

        await expectLater(
          repo.updateDoc(docId, {'lines': newLines}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating lines should throw for '
              'status=${status.value}',
        );
      }
    },
  );

  test(
    'Property 28e: updating totals on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2804);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final newTotals = {
          'net': rng.nextDouble() * 1000,
          'vat': rng.nextDouble() * 170,
          'gross': rng.nextDouble() * 1170,
        };

        await expectLater(
          repo.updateDoc(docId, {'totals': newTotals}),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating totals should throw for '
              'status=${status.value}',
        );
      }
    },
  );

  test(
    'Property 28f: updating immutableSnapshotHash on issued/locked/credited throws StateError (150 iterations)',
    () async {
      final rng = Random(2805);
      final immutableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
        AccountingDocStatus.credited,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final status = immutableStatuses[i % immutableStatuses.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 6)}',
          createdBy: 'uid-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        await expectLater(
          repo.updateDoc(docId, {
            'immutableSnapshotHash': 'fake-hash-${_randomString(rng)}',
          }),
          throwsA(isA<StateError>()),
          reason: 'Iteration $i: updating immutableSnapshotHash should throw '
              'for status=${status.value}',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 29: Credit Note требует originalDocId и reason
  //
  // Для любого документа типа credit_note: обязательны непустые
  // references.originalDocId и reason; без любого из них — отклонение
  // (ArgumentError).
  // **Validates: Requirements 16.1, 19.7**
  // -------------------------------------------------------------------------

  test(
    'Property 29a: createCreditNote throws ArgumentError for empty originalDocId (150 iterations)',
    () async {
      final rng = Random(2900);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final data = CreditNoteData(
          originalDocId: '', // empty — should be rejected
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: 'Valid reason ${_randomString(rng)}',
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        await expectLater(
          repo.createCreditNote(data),
          throwsA(isA<ArgumentError>()),
          reason:
              'Iteration $i: empty originalDocId should throw ArgumentError',
        );
      }
    },
  );

  test(
    'Property 29b: createCreditNote throws ArgumentError for empty reason (150 iterations)',
    () async {
      final rng = Random(2901);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final data = CreditNoteData(
          originalDocId: 'doc-${_randomString(rng, maxLen: 8)}',
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: '', // empty — should be rejected
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        await expectLater(
          repo.createCreditNote(data),
          throwsA(isA<ArgumentError>()),
          reason: 'Iteration $i: empty reason should throw ArgumentError',
        );
      }
    },
  );

  test(
    'Property 29c: createCreditNote throws ArgumentError for whitespace-only originalDocId (150 iterations)',
    () async {
      final rng = Random(2902);
      const whitespaceVariants = ['   ', ' \t ', '\t\t', '  \n  ', ' '];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final wsOriginalDocId =
            whitespaceVariants[i % whitespaceVariants.length];

        final data = CreditNoteData(
          originalDocId:
              wsOriginalDocId, // whitespace-only — should be rejected
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: 'Valid reason ${_randomString(rng)}',
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        await expectLater(
          repo.createCreditNote(data),
          throwsA(isA<ArgumentError>()),
          reason:
              'Iteration $i: whitespace-only originalDocId "${wsOriginalDocId.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}" '
              'should throw ArgumentError',
        );
      }
    },
  );

  test(
    'Property 29d: createCreditNote throws ArgumentError for whitespace-only reason (150 iterations)',
    () async {
      final rng = Random(2903);
      const whitespaceVariants = ['   ', ' \t ', '\t\t', '  \n  ', ' '];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final wsReason = whitespaceVariants[i % whitespaceVariants.length];

        final data = CreditNoteData(
          originalDocId: 'doc-${_randomString(rng, maxLen: 8)}',
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: wsReason, // whitespace-only — should be rejected
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        await expectLater(
          repo.createCreditNote(data),
          throwsA(isA<ArgumentError>()),
          reason:
              'Iteration $i: whitespace-only reason "${wsReason.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}" '
              'should throw ArgumentError',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 30: Создание Credit Note обновляет статус оригинала
  //
  // Для любого документа со статусом issued/locked: после создания credit_note
  // статус оригинала == credited, references.creditNoteIds содержит ID нового
  // credit_note.
  // **Validates: Requirements 16.2, 16.3**
  // -------------------------------------------------------------------------

  test(
    'Property 30a: createCreditNote changes original issued document status to credited (150 iterations)',
    () async {
      final rng = Random(3000);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final customerId = 'cust-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);

        // Create an issued document directly in Firestore
        final originalDocId = await _createDocInFirestore(
          firestore,
          companyId,
          status: AccountingDocStatus.issued,
          type: docType,
          customerId: customerId,
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final creditNoteData = CreditNoteData(
          originalDocId: originalDocId,
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: 'Correction reason ${_randomString(rng)}',
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: customerId,
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        final creditNoteId = await repo.createCreditNote(creditNoteData);

        // Read the original document from Firestore to verify status
        final originalSnapshot = await firestore
            .collection('companies')
            .doc(companyId)
            .collection('accountingDocs')
            .doc(originalDocId)
            .get();

        expect(
          originalSnapshot.data()!['status'],
          equals(AccountingDocStatus.credited.value),
          reason: 'Iteration $i: original issued doc status should be '
              '"credited" after createCreditNote',
        );

        // Verify references.creditNoteIds contains the new credit note ID
        final refs = originalSnapshot.data()!['references'] as Map?;
        final creditNoteIds = refs != null
            ? List<String>.from(refs['creditNoteIds'] ?? [])
            : <String>[];

        expect(
          creditNoteIds,
          contains(creditNoteId),
          reason: 'Iteration $i: original doc references.creditNoteIds '
              'should contain "$creditNoteId"',
        );
      }
    },
  );

  test(
    'Property 30b: createCreditNote changes original locked document status to credited (150 iterations)',
    () async {
      final rng = Random(3001);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final customerId = 'cust-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);

        // Create a locked document directly in Firestore
        final originalDocId = await _createDocInFirestore(
          firestore,
          companyId,
          status: AccountingDocStatus.locked,
          type: docType,
          customerId: customerId,
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final creditNoteData = CreditNoteData(
          originalDocId: originalDocId,
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: 'Locked doc correction ${_randomString(rng)}',
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: customerId,
          lines: [
            AccountingDocLine(
              description: 'item-${_randomString(rng)}',
              quantity: 1,
              unitPrice: 100,
              totalBeforeVat: 100,
              vatAmount: 17,
              totalWithVat: 117,
            ),
          ],
          totals: AccountingDocTotals(net: 100, vat: 17, gross: 117),
        );

        final creditNoteId = await repo.createCreditNote(creditNoteData);

        // Read the original document from Firestore to verify status
        final originalSnapshot = await firestore
            .collection('companies')
            .doc(companyId)
            .collection('accountingDocs')
            .doc(originalDocId)
            .get();

        expect(
          originalSnapshot.data()!['status'],
          equals(AccountingDocStatus.credited.value),
          reason: 'Iteration $i: original locked doc status should be '
              '"credited" after createCreditNote',
        );

        // Verify references.creditNoteIds contains the new credit note ID
        final refs = originalSnapshot.data()!['references'] as Map?;
        final creditNoteIds = refs != null
            ? List<String>.from(refs['creditNoteIds'] ?? [])
            : <String>[];

        expect(
          creditNoteIds,
          contains(creditNoteId),
          reason: 'Iteration $i: original locked doc references.creditNoteIds '
              'should contain "$creditNoteId"',
        );
      }
    },
  );

  test(
    'Property 30c: createCreditNote for random issued/locked status updates original correctly (150 iterations)',
    () async {
      final rng = Random(3002);
      final creditableStatuses = [
        AccountingDocStatus.issued,
        AccountingDocStatus.locked,
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final customerId = 'cust-${_randomString(rng, maxLen: 8)}';
        final createdBy = 'uid-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng);
        final status =
            creditableStatuses[rng.nextInt(creditableStatuses.length)];

        // Create a document with issued or locked status
        final originalDocId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: customerId,
          createdBy: createdBy,
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        final creditNoteData = CreditNoteData(
          originalDocId: originalDocId,
          originalDocNumber: rng.nextInt(9999) + 1,
          reason: 'Reason ${_randomString(rng)}',
          correctionType: rng.nextBool() ? 'full' : 'partial',
          customerId: customerId,
          lines: [
            AccountingDocLine(
              description: 'line-${_randomString(rng)}',
              quantity: (rng.nextInt(10) + 1).toDouble(),
              unitPrice: (rng.nextInt(1000) + 1).toDouble(),
              totalBeforeVat: (rng.nextInt(1000) + 1).toDouble(),
              vatAmount: (rng.nextInt(170) + 1).toDouble(),
              totalWithVat: (rng.nextInt(1170) + 1).toDouble(),
            ),
          ],
          totals: AccountingDocTotals(
            net: (rng.nextInt(10000) + 1).toDouble(),
            vat: (rng.nextInt(1700) + 1).toDouble(),
            gross: (rng.nextInt(11700) + 1).toDouble(),
          ),
        );

        final creditNoteId = await repo.createCreditNote(creditNoteData);

        // Read the original document from Firestore
        final originalSnapshot = await firestore
            .collection('companies')
            .doc(companyId)
            .collection('accountingDocs')
            .doc(originalDocId)
            .get();

        // Verify status changed to credited
        expect(
          originalSnapshot.data()!['status'],
          equals(AccountingDocStatus.credited.value),
          reason: 'Iteration $i: original ${status.value} doc status should '
              'become "credited" after createCreditNote',
        );

        // Verify creditNoteIds contains the new credit note ID
        final refs = originalSnapshot.data()!['references'] as Map?;
        final creditNoteIds = refs != null
            ? List<String>.from(refs['creditNoteIds'] ?? [])
            : <String>[];

        expect(
          creditNoteIds,
          contains(creditNoteId),
          reason: 'Iteration $i: references.creditNoteIds should contain '
              'the new credit note ID',
        );

        // Verify the credit note ID is a non-empty string
        expect(
          creditNoteId,
          isNotEmpty,
          reason: 'Iteration $i: createCreditNote should return a non-empty ID',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 31: Последовательная нумерация без пропусков
  //
  // Для любой последовательности issued-документов одного типа:
  // d[i+1].docNumber == d[i].docNumber + 1
  // Нумерация начинается с 1 и идёт без пропусков: 1, 2, 3, ..., N
  // **Validates: Requirements 17.1**
  // -------------------------------------------------------------------------

  test(
    'Property 31a: getNextSequentialNumber returns 1, 2, ..., N without gaps (150 iterations)',
    () async {
      final rng = Random(3100);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final docType = _randomDocType(rng).value;

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Random N between 2 and 10
        final n = 2 + rng.nextInt(9); // 2..10

        final numbers = <int>[];
        for (var j = 0; j < n; j++) {
          final num = await repo.getNextSequentialNumber(docType);
          numbers.add(num);
        }

        // Verify the sequence is exactly 1, 2, 3, ..., N
        final expected = List.generate(n, (idx) => idx + 1);
        expect(
          numbers,
          equals(expected),
          reason: 'Iteration $i: getNextSequentialNumber should return '
              '$expected for $n calls (docType=$docType), got $numbers',
        );

        // Verify consecutive pairs: d[i+1] == d[i] + 1
        for (var k = 0; k < numbers.length - 1; k++) {
          expect(
            numbers[k + 1],
            equals(numbers[k] + 1),
            reason: 'Iteration $i: numbers[$k]=${numbers[k]} → '
                'numbers[${k + 1}]=${numbers[k + 1]} should differ by 1',
          );
        }
      }
    },
  );

  test(
    'Property 31b: different docTypes have independent sequential counters (150 iterations)',
    () async {
      final rng = Random(3101);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Pick two distinct docTypes
        final allTypes = _allDocTypes.map((t) => t.value).toList()
          ..shuffle(rng);
        final typeA = allTypes[0];
        final typeB = allTypes[1];

        final nA = 2 + rng.nextInt(9); // 2..10
        final nB = 2 + rng.nextInt(9); // 2..10

        // Interleave calls to typeA and typeB
        final numbersA = <int>[];
        final numbersB = <int>[];
        var doneA = 0;
        var doneB = 0;

        while (doneA < nA || doneB < nB) {
          // Randomly pick which type to call next
          final pickA = doneB >= nB || (doneA < nA && rng.nextBool());
          if (pickA) {
            numbersA.add(await repo.getNextSequentialNumber(typeA));
            doneA++;
          } else {
            numbersB.add(await repo.getNextSequentialNumber(typeB));
            doneB++;
          }
        }

        // Each type should have its own independent sequence 1, 2, ..., N
        final expectedA = List.generate(nA, (idx) => idx + 1);
        final expectedB = List.generate(nB, (idx) => idx + 1);

        expect(
          numbersA,
          equals(expectedA),
          reason: 'Iteration $i: typeA=$typeA should have sequence '
              '$expectedA, got $numbersA',
        );
        expect(
          numbersB,
          equals(expectedB),
          reason: 'Iteration $i: typeB=$typeB should have sequence '
              '$expectedB, got $numbersB',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 32: Запрет удаления бухгалтерских документов
  //
  // Для любого пользователя (включая owner, admin, super_admin, accountant)
  // и любого документа независимо от статуса — удаление отклоняется
  // (UnsupportedError).
  // **Validates: Requirements 14.9, 17.2, 17.5, 19.3**
  // -------------------------------------------------------------------------

  test(
    'Property 32a: deleteDoc throws UnsupportedError for any status and any role (150 iterations)',
    () async {
      final rng = Random(3200);
      const allRoles = [
        'owner',
        'admin',
        'super_admin',
        'accountant',
        'dispatcher',
        'driver',
        'warehouse_keeper',
        'viewer',
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        final role = allRoles[rng.nextInt(allRoles.length)];
        final status = _allStatuses[rng.nextInt(_allStatuses.length)];
        final docType = _randomDocType(rng);

        // Create a document with random status
        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          createdBy: 'uid-$role-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // deleteDoc should always throw UnsupportedError
        await expectLater(
          repo.deleteDoc(docId),
          throwsA(isA<UnsupportedError>()),
          reason: 'Iteration $i: deleteDoc should throw UnsupportedError '
              'for role=$role, status=${status.value}, type=${docType.value}',
        );
      }
    },
  );

  test(
    'Property 32b: deleteDoc throws UnsupportedError for each specific status (150 iterations)',
    () async {
      final rng = Random(3201);
      const privilegedRoles = [
        'owner',
        'admin',
        'super_admin',
        'accountant',
      ];

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';
        // Cycle through all statuses deterministically
        final status = _allStatuses[i % _allStatuses.length];
        // Cycle through privileged roles
        final role = privilegedRoles[i % privilegedRoles.length];
        final docType = _randomDocType(rng);

        final docId = await _createDocInFirestore(
          firestore,
          companyId,
          status: status,
          type: docType,
          customerId: 'cust-${_randomString(rng, maxLen: 8)}',
          createdBy: 'uid-$role-${_randomString(rng, maxLen: 6)}',
        );

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        await expectLater(
          repo.deleteDoc(docId),
          throwsA(isA<UnsupportedError>()),
          reason: 'Iteration $i: deleteDoc should throw UnsupportedError '
              'for role=$role, status=${status.value}',
        );

        // Verify the document still exists in Firestore after failed deletion
        final snapshot = await firestore
            .collection('companies')
            .doc(companyId)
            .collection('accountingDocs')
            .doc(docId)
            .get();

        expect(
          snapshot.exists,
          isTrue,
          reason: 'Iteration $i: document should still exist after '
              'rejected deleteDoc (role=$role, status=${status.value})',
        );
      }
    },
  );

  test(
    'Property 32c: deleteDoc throws UnsupportedError even for non-existent documents (150 iterations)',
    () async {
      final rng = Random(3202);

      for (var i = 0; i < 150; i++) {
        final firestore = FakeFirebaseFirestore();
        final companyId = 'company-${_randomString(rng, maxLen: 8)}';

        final repo = AccountingDocsRepository(
          companyId: companyId,
          firestore: firestore,
        );

        // Generate a random non-existent document ID
        final fakeDocId = 'nonexistent-${_randomString(rng, maxLen: 12)}';

        // deleteDoc should throw UnsupportedError regardless of document existence
        await expectLater(
          repo.deleteDoc(fakeDocId),
          throwsA(isA<UnsupportedError>()),
          reason: 'Iteration $i: deleteDoc should throw UnsupportedError '
              'even for non-existent document "$fakeDocId"',
        );
      }
    },
  );
}
