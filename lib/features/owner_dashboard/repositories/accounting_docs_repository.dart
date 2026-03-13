import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/cross_module_audit_service.dart';
import '../models/accounting_doc.dart';
import '../models/credit_note_data.dart';
import '../models/document_status.dart';
import '../utils/snapshot_hash.dart';

/// Фильтр для списка бухгалтерских документов.
class AccountingDocFilter {
  final AccountingDocType? type;
  final AccountingDocStatus? status;
  final String? customerId;

  const AccountingDocFilter({this.type, this.status, this.customerId});
}

/// Репозиторий для управления бухгалтерскими документами.
///
/// Работает с коллекцией `/companies/{companyId}/accountingDocs/{docId}`.
/// Счётчик нумерации: `/companies/{companyId}/accounting/_root/counters/{docType}`.
///
/// Удаление документов запрещено для всех ролей (ניהול ספרים).
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class AccountingDocsRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  AccountingDocsRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию accountingDocs компании.
  CollectionReference<Map<String, dynamic>> get _docsCollection => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('accountingDocs');

  /// Ссылка на коллекцию счётчиков нумерации.
  CollectionReference<Map<String, dynamic>> get _countersCollection =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('accounting')
          .doc('_root')
          .collection('counters');

  /// Ссылка на коллекцию аудит-логов компании.
  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _firestore.collection('companies').doc(companyId).collection('audit');

  /// Создаёт новый бухгалтерский документ (статус draft).
  ///
  /// Возвращает ID созданного документа.
  Future<String> createDoc(AccountingDoc data) async {
    final doc = await _docsCollection.add(data.toMap());
    return doc.id;
  }

  /// Обновляет документ (только draft).
  ///
  /// Проверяет, что документ находится в статусе `draft` перед обновлением.
  /// Выбрасывает [StateError] если документ не в статусе draft.
  Future<void> updateDoc(String docId, Map<String, dynamic> updates) async {
    final docRef = _docsCollection.doc(docId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw ArgumentError('Document $docId not found');
    }

    final currentStatus =
        AccountingDocStatus.fromString(snapshot.data()!['status'] ?? 'draft');
    if (currentStatus != AccountingDocStatus.draft) {
      throw StateError(
        'Cannot update document with status "${currentStatus.value}". '
        'Only draft documents can be updated.',
      );
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.update(updates);
  }

  /// Читает один документ по ID.
  Future<AccountingDoc?> getDoc(String docId) async {
    final snapshot = await _docsCollection.doc(docId).get();
    if (!snapshot.exists) return null;
    return AccountingDoc.fromMap(snapshot.data()!);
  }

  /// Стрим документов компании с опциональным фильтром.
  Stream<List<AccountingDoc>> watchDocs({AccountingDocFilter? filter}) {
    Query<Map<String, dynamic>> query = _docsCollection;

    if (filter?.type != null) {
      query = query.where('type', isEqualTo: filter!.type!.value);
    }
    if (filter?.status != null) {
      query = query.where('status', isEqualTo: filter!.status!.value);
    }
    if (filter?.customerId != null) {
      query = query.where('customerId', isEqualTo: filter!.customerId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final accountingDoc = AccountingDoc.fromMap(data);
        return AccountingDoc(
          id: doc.id,
          type: accountingDoc.type,
          status: accountingDoc.status,
          docNumber: accountingDoc.docNumber,
          issuedAt: accountingDoc.issuedAt,
          customerId: accountingDoc.customerId,
          customerName: accountingDoc.customerName,
          customerTaxId: accountingDoc.customerTaxId,
          lines: accountingDoc.lines,
          totals: accountingDoc.totals,
          references: accountingDoc.references,
          reason: accountingDoc.reason,
          correctionType: accountingDoc.correctionType,
          createdAt: accountingDoc.createdAt,
          createdBy: accountingDoc.createdBy,
          companyId: accountingDoc.companyId,
          immutableSnapshotHash: accountingDoc.immutableSnapshotHash,
          updatedAt: accountingDoc.updatedAt,
          updatedBy: accountingDoc.updatedBy,
          notes: accountingDoc.notes,
        );
      }).toList();
    });
  }

  /// Переводит документ из draft → issued.
  ///
  /// В Firestore transaction:
  /// 1. Читает документ и проверяет status == draft
  /// 2. Получает следующий docNumber через счётчик
  /// 3. Вычисляет immutableSnapshotHash
  /// 4. Обновляет status → issued, устанавливает docNumber, issuedAt, hash
  ///
  /// Выбрасывает [StateError] если документ не в статусе draft.
  Future<void> issueDoc(String docId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _docsCollection.doc(docId);
      final docSnapshot = await transaction.get(docRef);

      if (!docSnapshot.exists) {
        throw ArgumentError('Document $docId not found');
      }

      final data = docSnapshot.data()!;
      final currentStatus =
          AccountingDocStatus.fromString(data['status'] ?? 'draft');

      if (currentStatus != AccountingDocStatus.draft) {
        throw StateError(
          'Cannot issue document with status "${currentStatus.value}". '
          'Only draft documents can be issued.',
        );
      }

      // Получаем следующий номер через счётчик
      final docType = data['type'] as String;
      final counterRef = _countersCollection.doc(docType);
      final counterSnapshot = await transaction.get(counterRef);

      int nextNumber;
      if (!counterSnapshot.exists) {
        nextNumber = 1;
        transaction.set(counterRef, {'lastNumber': 1});
      } else {
        final lastNumber =
            (counterSnapshot.data()!['lastNumber'] as num).toInt();
        nextNumber = lastNumber + 1;
        transaction.update(counterRef, {'lastNumber': nextNumber});
      }

      // Вычисляем snapshot hash
      final now = DateTime.now();
      final doc = AccountingDoc.fromMap({
        ...data,
        'docNumber': nextNumber,
        'issuedAt': Timestamp.fromDate(now),
      });
      final hash = SnapshotHash.compute(doc);

      // Обновляем документ
      transaction.update(docRef, {
        'status': AccountingDocStatus.issued.value,
        'docNumber': nextNumber,
        'issuedAt': Timestamp.fromDate(now),
        'immutableSnapshotHash': hash,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Создаёт Credit Note (תעודת זיכוי) с привязкой к оригинальному документу.
  ///
  /// В Firestore transaction:
  /// 1. Проверяет статус оригинала (issued или locked)
  /// 2. Создаёт credit_note документ
  /// 3. Обновляет оригинал: status → credited, добавляет creditNoteId
  /// 4. Записывает событие в аудит
  ///
  /// Возвращает ID созданного credit_note.
  ///
  /// Выбрасывает [ArgumentError] если данные невалидны.
  /// Выбрасывает [StateError] если оригинал не в статусе issued/locked.
  Future<String> createCreditNote(CreditNoteData data) async {
    // Валидация обязательных полей
    if (data.originalDocId.trim().isEmpty) {
      throw ArgumentError('originalDocId is required for credit note');
    }
    if (data.reason.trim().isEmpty) {
      throw ArgumentError('reason is required for credit note');
    }

    final creditNoteRef = _docsCollection.doc();
    final creditNoteId = creditNoteRef.id;

    await _firestore.runTransaction((transaction) async {
      // Читаем оригинальный документ
      final originalRef = _docsCollection.doc(data.originalDocId);
      final originalSnapshot = await transaction.get(originalRef);

      if (!originalSnapshot.exists) {
        throw ArgumentError(
          'Original document ${data.originalDocId} not found',
        );
      }

      final originalData = originalSnapshot.data()!;
      final originalStatus =
          AccountingDocStatus.fromString(originalData['status'] ?? 'draft');

      // Проверяем допустимость перехода: только issued или locked → credited
      if (originalStatus != AccountingDocStatus.issued &&
          originalStatus != AccountingDocStatus.locked) {
        throw StateError(
          'Cannot create credit note for document with status '
          '"${originalStatus.value}". '
          'Only issued or locked documents can be credited.',
        );
      }

      // Создаём credit_note документ
      final creditNoteMap = <String, dynamic>{
        'type': AccountingDocType.creditNote.value,
        'status': AccountingDocStatus.draft.value,
        'customerId': data.customerId,
        'customerName': originalData['customerName'] ?? '',
        'customerTaxId': originalData['customerTaxId'],
        'lines': data.lines.map((e) => e.toMap()).toList(),
        'totals': data.totals.toMap(),
        'references': {
          'originalDocId': data.originalDocId,
          'originalDocNumber': data.originalDocNumber,
        },
        'reason': data.reason,
        'correctionType': data.correctionType,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': originalData['createdBy'] ?? '',
        'companyId': companyId,
      };

      transaction.set(creditNoteRef, creditNoteMap);

      // Обновляем оригинал: status → credited, добавляем creditNoteId
      final existingCreditNoteIds =
          List<String>.from(originalData['references']?['creditNoteIds'] ?? []);
      existingCreditNoteIds.add(creditNoteId);

      transaction.update(originalRef, {
        'status': AccountingDocStatus.credited.value,
        'references.creditNoteIds': existingCreditNoteIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Записываем событие в аудит
      final auditRef = _auditCollection.doc();
      transaction.set(auditRef, {
        'moduleKey': 'accounting',
        'type': CrossModuleAuditService.typeCreditNoteCreated,
        'entity': {
          'collection': 'accountingDocs',
          'docId': creditNoteId,
        },
        'createdBy': originalData['createdBy'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'originalDocId': data.originalDocId,
        'originalDocNumber': data.originalDocNumber,
        'reason': data.reason,
        'correctionType': data.correctionType,
        'amount': data.totals.gross,
      });
    });

    return creditNoteId;
  }

  /// Отменяет документ до доставки клиенту (draft → voided_before_delivery).
  ///
  /// Проверяет status == draft, обновляет status, записывает событие в аудит.
  ///
  /// Выбрасывает [StateError] если документ не в статусе draft.
  Future<void> voidBeforeDelivery(String docId, String reason) async {
    final docRef = _docsCollection.doc(docId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw ArgumentError('Document $docId not found');
    }

    final data = snapshot.data()!;
    final currentStatus =
        AccountingDocStatus.fromString(data['status'] ?? 'draft');

    if (!canTransition(
        currentStatus, AccountingDocStatus.voidedBeforeDelivery)) {
      throw StateError(
        'Cannot void document with status "${currentStatus.value}". '
        'Only draft documents can be voided before delivery.',
      );
    }

    await docRef.update({
      'status': AccountingDocStatus.voidedBeforeDelivery.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Записываем событие в аудит
    await _auditCollection.add({
      'moduleKey': 'accounting',
      'type': CrossModuleAuditService.typeDocumentVoided,
      'entity': {
        'collection': 'accountingDocs',
        'docId': docId,
      },
      'createdBy': data['createdBy'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'reason': reason,
    });
  }

  /// Получает цепочку связанных документов (оригинал → credit notes).
  ///
  /// Возвращает список документов, начиная с указанного документа
  /// и включая все связанные credit notes.
  Future<List<AccountingDoc>> getDocumentChain(String docId) async {
    final result = <AccountingDoc>[];

    final rootDoc = await getDoc(docId);
    if (rootDoc == null) return result;
    result.add(rootDoc);

    // Если у документа есть credit notes — загружаем их
    final creditNoteIds = rootDoc.references?.creditNoteIds;
    if (creditNoteIds != null && creditNoteIds.isNotEmpty) {
      for (final cnId in creditNoteIds) {
        final cn = await getDoc(cnId);
        if (cn != null) result.add(cn);
      }
    }

    // Если это credit note — загружаем оригинал
    if (rootDoc.type == AccountingDocType.creditNote &&
        rootDoc.references?.originalDocId != null) {
      final originalId = rootDoc.references!.originalDocId!;
      final original = await getDoc(originalId);
      if (original != null) {
        result.insert(0, original);
      }
    }

    return result;
  }

  /// Удаление бухгалтерских документов запрещено для всех ролей.
  ///
  /// В соответствии с требованиями ניהול ספרים (ведение бухгалтерских книг),
  /// бухгалтерские документы не могут быть удалены. Для коррекции используйте
  /// [createCreditNote], для отмены до доставки — [voidBeforeDelivery].
  ///
  /// Всегда выбрасывает [UnsupportedError].
  Future<void> deleteDoc(String docId) async {
    throw UnsupportedError(
      'Deletion of accounting documents is forbidden (ניהול ספרים). '
      'Use createCreditNote() for corrections or voidBeforeDelivery() '
      'for cancellation before delivery.',
    );
  }

  /// Получает следующий последовательный номер для типа документа.
  ///
  /// Инкремент через Firestore transaction с правилом newValue == lastNumber + 1.
  Future<int> getNextSequentialNumber(String docType) async {
    int nextNumber = 0;

    await _firestore.runTransaction((transaction) async {
      final counterRef = _countersCollection.doc(docType);
      final counterSnapshot = await transaction.get(counterRef);

      if (!counterSnapshot.exists) {
        nextNumber = 1;
        transaction.set(counterRef, {'lastNumber': 1});
      } else {
        final lastNumber =
            (counterSnapshot.data()!['lastNumber'] as num).toInt();
        nextNumber = lastNumber + 1;
        transaction.update(counterRef, {'lastNumber': nextNumber});
      }
    });

    return nextNumber;
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for AccountingDocsRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
