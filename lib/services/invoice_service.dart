import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/audit_event.dart';
import '../models/document_link.dart';
import 'summary_service.dart';
import 'audit_log_service.dart';
import 'document_link_service.dart';

/// Invoice Service with Israeli Tax Law Compliance
/// תואם לדרישות רשות המסים הישראלית
class InvoiceService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SummaryService _summaryService;
  late final AuditLogService _auditLogService;
  late final DocumentLinkService _documentLinkService;

  InvoiceService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
    _summaryService = SummaryService(companyId: companyId);
    _auditLogService = AuditLogService(companyId: companyId);
    _documentLinkService = DocumentLinkService(companyId: companyId);
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию счетов компании
  CollectionReference<Map<String, dynamic>> _invoicesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices');
  }

  /// Create חשבונית as draft (без номера).
  /// Номер выдаётся сервером через issueInvoice callable.
  /// יצירת חשבונית כטיוטה — מספר רץ יוקצה בשרת
  Future<String> createInvoice(Invoice invoice, String createdByUid) async {
    try {
      // Проверяем companyId
      if (invoice.companyId.isEmpty || invoice.companyId != companyId) {
        throw Exception('Invalid companyId in invoice');
      }

      // Проверка дубликата: если deliveryPointId задан, ищем существующий документ
      if (invoice.deliveryPointId != null &&
          invoice.deliveryPointId!.isNotEmpty) {
        final existing = await _invoicesCollection()
            .where('deliveryPointId', isEqualTo: invoice.deliveryPointId)
            .where('documentType', isEqualTo: invoice.documentType.name)
            .where('status',
                whereIn: [InvoiceStatus.active.name, 'issued', 'draft'])
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          final existingDoc = existing.docs.first;
          final existingStatus = existingDoc.data()['status'] as String? ?? '';
          // Если уже выдан — возвращаем как есть (idempotent)
          if (existingStatus == 'issued' ||
              existingStatus == InvoiceStatus.active.name) {
            print(
                '⚠️ [Invoice] Duplicate prevented (already issued): ${invoice.documentType.name} for deliveryPoint ${invoice.deliveryPointId}');
            return existingDoc.id;
          }
          // Если draft — возвращаем ID для повторной попытки выдачи
          print(
              '⚠️ [Invoice] Found existing draft for deliveryPoint ${invoice.deliveryPointId} — returning for re-issuance');
          return existingDoc.id;
        }
      }

      // Создаём как draft — sequentialNumber=0, status=draft
      final draftInvoice = invoice.copyWith(
        sequentialNumber: 0,
        status: InvoiceStatus.draft,
      );

      final docRef = _invoicesCollection().doc();

      // רישום ביומן ביקורת ПЕРЕД созданием — log-before-action
      await _auditLogService.logEvent(
        entityId: docRef.id,
        entityType: draftInvoice.documentType.name,
        eventType: AuditEventType.created,
        actorUid: createdByUid,
        metadata: {'status': 'draft'},
      );

      await docRef.set(draftInvoice.toMap());

      // ⚡ OPTIMIZATION: Update daily summary
      try {
        await _summaryService.updateInvoiceSummary(draftInvoice);
      } catch (e) {
        print('⚠️ [Invoice] Failed to update summary (non-critical): $e');
      }

      return docRef.id;
    } catch (e) {
      print('❌ [Invoice] Error creating invoice: $e');
      rethrow;
    }
  }

  /// Cancel חשבונית (NOT delete - deletion is illegal)
  /// ביטול חשבונית - מחיקה אסורה לפי חוק!
  Future<void> cancelInvoice(
    String id,
    String cancelledByUid,
    String reason, {
    String? cancelledByName,
  }) async {
    try {
      final invoice = await getInvoice(id);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      if (!invoice.canBeCancelled) {
        throw Exception(
            'Invoice cannot be cancelled (status: ${invoice.status})');
      }

      // רישום ביומן ביקורת (תת-אוסף) — log-before-action
      await _auditLogService.logEvent(
        entityId: id,
        entityType: 'invoice',
        eventType: AuditEventType.cancelled,
        actorUid: cancelledByUid,
        actorName: cancelledByName,
        metadata: {'reason': reason},
      );

      // Update invoice status — serverTimestamp для clock integrity
      await _invoicesCollection().doc(id).update({
        'status': InvoiceStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledByUid,
        'cancellationReason': reason,
      });

      // ⚡ OPTIMIZATION: Update daily summary
      try {
        final updatedInvoice = invoice.copyWith(
          status: InvoiceStatus.cancelled,
          cancelledAt: DateTime.now(),
          cancelledBy: cancelledByUid,
          cancellationReason: reason,
        );
        await _summaryService.updateInvoiceSummary(updatedInvoice);
      } catch (e) {
        print('⚠️ [Invoice] Failed to update summary (non-critical): $e');
      }
    } catch (e) {
      print('❌ [Invoice] Error cancelling invoice: $e');
      rethrow;
    }
  }

  /// ⚠️ DEPRECATED - Use cancelInvoice instead
  /// מחיקה אסורה לפי חוק ניהול ספרים!
  @Deprecated('Use cancelInvoice instead. Deletion violates Israeli tax law.')
  Future<void> deleteInvoice(String id) async {
    throw UnsupportedError(
      'Invoice deletion is not allowed per Israeli tax law. Use cancelInvoice instead.',
    );
  }

  /// Soft-void issued document.
  /// ביטול מסמך שהונפק — status=voided, לא מחיקה.
  /// Only issued documents can be voided. Voided docs are frozen in rules.
  Future<void> voidInvoice(
    String id,
    String voidedByUid,
    String reason, {
    String? voidedByName,
  }) async {
    try {
      final invoice = await getInvoice(id);
      if (invoice == null) throw Exception('Invoice not found');

      // Only issued docs can be voided
      if (invoice.status != InvoiceStatus.issued) {
        throw Exception(
            'רק מסמך שהונפק ניתן לביטול (סטטוס נוכחי: ${invoice.status.name})');
      }

      // Audit log before action
      await _auditLogService.logEvent(
        entityId: id,
        entityType: invoice.documentType.name,
        eventType: AuditEventType.cancelled,
        actorUid: voidedByUid,
        actorName: voidedByName,
        metadata: {'reason': reason, 'action': 'voided'},
      );

      await _invoicesCollection().doc(id).update({
        'status': InvoiceStatus.voided.name,
        'voidedAt': FieldValue.serverTimestamp(),
        'voidedBy': voidedByUid,
        'voidReason': reason,
      });

      // Cross-module audit: invoice_voided
      try {
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('audit')
            .add({
          'moduleKey': 'accounting',
          'type': 'invoice_voided',
          'entity': {'collection': 'invoices', 'docId': id},
          'createdBy': voidedByUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ [Invoice] Audit write failed (non-blocking): $e');
      }
    } catch (e) {
      print('❌ [Invoice] Error voiding invoice: $e');
      rethrow;
    }
  }

  /// Add audit log entry to invoice
  /// הוספת רשומה ליומן שינויים
  Future<void> addAuditEntry(
    String invoiceId,
    String action,
    String performedBy, {
    String? details,
  }) async {
    try {
      final auditEntry = InvoiceAuditEntry(
        timestamp: DateTime.now(),
        action: action,
        performedBy: performedBy,
        details: details,
      );

      await _invoicesCollection().doc(invoiceId).update({
        'auditLog': FieldValue.arrayUnion([auditEntry.toMap()]),
      });
    } catch (e) {
      print('❌ [Invoice] Error adding audit entry: $e');
      rethrow;
    }
  }

  /// Get all חשבוניות with pagination and filters
  /// קבלת חשבוניות עם עימוד וסינון
  ///
  /// ⚡ OPTIMIZED: Uses limit and date filters to reduce reads
  Future<List<Invoice>> getAllInvoices({
    bool includeCancelled = true,
    int limit = 50,
    DocumentSnapshot? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _invoicesCollection();

      // Filter by status
      if (!includeCancelled) {
        query = query.where('status', isEqualTo: InvoiceStatus.active.name);
      }

      // Filter by date range
      if (fromDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      // Order and limit
      query = query.orderBy('createdAt', descending: true).limit(limit);

      // Pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      print(
          '📊 [Invoice] Loaded ${snapshot.docs.length} invoices (limit: $limit)');

      return snapshot.docs
          .map((doc) =>
              Invoice.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ [Invoice] Error getting invoices: $e');
      return [];
    }
  }

  /// Get recent invoices (today, this week, this month)
  /// חשבוניות אחרונות
  Future<List<Invoice>> getRecentInvoices({
    String period = 'today', // 'today', 'week', 'month'
    int limit = 50,
  }) async {
    DateTime fromDate;
    final now = DateTime.now();

    switch (period) {
      case 'today':
        fromDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        fromDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        fromDate = DateTime(now.year, now.month, 1);
        break;
      default:
        fromDate = DateTime(now.year, now.month, now.day);
    }

    return getAllInvoices(
      fromDate: fromDate,
      limit: limit,
      includeCancelled: false,
    );
  }

  /// Get חשבונית by ID
  Future<Invoice?> getInvoice(String id) async {
    try {
      final doc = await _invoicesCollection().doc(id).get();

      if (doc.exists) {
        return Invoice.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ [Invoice] Error getting invoice: $e');
      return null;
    }
  }

  /// Get חשבוניות for client
  Future<List<Invoice>> getInvoicesForClient(
    String clientNumber, {
    bool includeCancelled = false,
  }) async {
    try {
      Query query = _invoicesCollection()
          .where('clientNumber', isEqualTo: clientNumber)
          .orderBy('sequentialNumber', descending: true);

      if (!includeCancelled) {
        query = query.where('status', isEqualTo: InvoiceStatus.active.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              Invoice.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ [Invoice] Error getting invoices for client: $e');
      return [];
    }
  }

  /// Get invoice by sequential number
  /// חיפוש לפי מספר רץ
  Future<Invoice?> getInvoiceBySequentialNumber(int sequentialNumber) async {
    try {
      final snapshot = await _invoicesCollection()
          .where('sequentialNumber', isEqualTo: sequentialNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Invoice.fromMap(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print('❌ [Invoice] Error getting invoice by sequential number: $e');
      return null;
    }
  }

  /// יצירת זיכוי (credit note) — מסמך חדש עם סכומים שליליים
  /// המסמך המקורי לא נמחק ולא משתנה
  /// Создаётся как draft — номер выдаёт сервер через issueInvoice callable.
  Future<String> createCreditNote({
    required Invoice originalInvoice,
    required String reason,
    required String createdBy,
  }) async {
    try {
      if (originalInvoice.status != InvoiceStatus.active &&
          originalInvoice.status != InvoiceStatus.draft) {
        // Разрешаем issued тоже (после миграции на серверную выдачу)
        if (originalInvoice.sequentialNumber == 0) {
          throw Exception('ניתן ליצור זיכוי רק למסמך שהונפק');
        }
      }
      if (originalInvoice.documentType == InvoiceDocumentType.creditNote) {
        throw Exception('לא ניתן ליצור זיכוי לזיכוי');
      }
      if (reason.isEmpty) {
        throw Exception('חובה לציין סיבה');
      }

      // פריטים עם מחיר שלילי (סטורנו)
      final creditItems = originalInvoice.items
          .map((item) => InvoiceItem(
                productCode: item.productCode,
                type: item.type,
                number: item.number,
                quantity: item.quantity,
                pricePerUnit: -item.pricePerUnit,
              ))
          .toList();

      final creditNote = Invoice(
        id: '',
        companyId: companyId,
        sequentialNumber: 0, // Draft — номер выдаст сервер
        clientName: originalInvoice.clientName,
        clientNumber: originalInvoice.clientNumber,
        address: originalInvoice.address,
        driverName: originalInvoice.driverName,
        truckNumber: originalInvoice.truckNumber,
        deliveryDate: originalInvoice.deliveryDate,
        paymentDueDate: originalInvoice.paymentDueDate,
        departureTime: originalInvoice.departureTime,
        items: creditItems,
        discount: originalInvoice.discount,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        documentType: InvoiceDocumentType.creditNote,
        linkedInvoiceId: originalInvoice.id,
        status: InvoiceStatus.draft,
      );

      // Резервируем ID для log-before-action
      final docRef = _invoicesCollection().doc();

      // רישום ביומן ביקורת ПЕРЕД созданием — log-before-action
      await _auditLogService.logEvent(
        entityId: originalInvoice.id,
        entityType: originalInvoice.documentType.name,
        eventType: AuditEventType.creditNoteCreated,
        actorUid: createdBy,
        metadata: {'creditNoteId': docRef.id, 'reason': reason},
      );

      await _auditLogService.logEvent(
        entityId: docRef.id,
        entityType: 'creditNote',
        eventType: AuditEventType.created,
        actorUid: createdBy,
        metadata: {'linkedTo': originalInvoice.id, 'reason': reason},
      );

      // Создаём документ
      await docRef.set(creditNote.toMap());

      // יצירת קישור רשמי בין מסמכים
      await _documentLinkService.createLink(DocumentLink(
        id: '',
        companyId: companyId,
        sourceDocumentId: docRef.id,
        sourceDocumentType: 'creditNote',
        sourceSequentialNumber: 0, // Будет обновлён после issuance
        targetDocumentId: originalInvoice.id,
        targetDocumentType: originalInvoice.documentType.name,
        targetSequentialNumber: originalInvoice.sequentialNumber,
        linkType: DocumentLinkType.creditToInvoice,
        createdBy: createdBy,
        reason: reason,
      ));

      return docRef.id;
    } catch (e) {
      print('❌ [Invoice] Error creating credit note: $e');
      rethrow;
    }
  }

  /// Verify sequential numbering integrity per document type
  /// בדיקת תקינות המספור הרץ לפי סוג מסמך
  /// כולל: התראה, רישום ביומן ביקורת, חסימת הדפסה בפער
  Future<Map<InvoiceDocumentType, SequentialIntegrityResult>>
      verifySequentialIntegrity({
    String? verifiedBy,
  }) async {
    final results = <InvoiceDocumentType, SequentialIntegrityResult>{};

    for (final docType in InvoiceDocumentType.values) {
      try {
        final snapshot = await _invoicesCollection()
            .where('documentType', isEqualTo: docType.name)
            .orderBy('sequentialNumber')
            .get();

        if (snapshot.docs.isEmpty) {
          results[docType] =
              SequentialIntegrityResult(valid: true, checkedCount: 0);
          continue;
        }

        int expectedNumber = 1;
        bool valid = true;
        int? gapAt;
        int? gapExpected;
        for (final doc in snapshot.docs) {
          final invoice = Invoice.fromMap(doc.data(), doc.id);
          if (invoice.sequentialNumber != expectedNumber) {
            print(
                '❌ [Invoice] Gap in ${docType.name}: expected $expectedNumber, got ${invoice.sequentialNumber}');
            valid = false;
            gapAt = invoice.sequentialNumber;
            gapExpected = expectedNumber;
            break;
          }
          expectedNumber++;
        }

        final result = SequentialIntegrityResult(
          valid: valid,
          checkedCount: snapshot.docs.length,
          gapAtNumber: gapAt,
          expectedNumber: gapExpected,
        );
        results[docType] = result;

        // רישום ביומן ביקורת אם נמצא פער
        if (!valid && verifiedBy != null) {
          await _auditLogService.logEvent(
            entityId: 'integrity_check_${docType.name}',
            entityType: docType.name,
            eventType: AuditEventType.technicalUpdate,
            actorUid: verifiedBy,
            metadata: {
              'action': 'sequential_integrity_gap_detected',
              'severity': 'HIGH',
              'docType': docType.name,
              'gapAt': gapAt,
              'expected': gapExpected,
              'totalChecked': snapshot.docs.length,
            },
          );
        }
      } catch (e) {
        print('❌ [Invoice] Error verifying ${docType.name} integrity: $e');
        results[docType] = SequentialIntegrityResult(
          valid: false,
          checkedCount: 0,
          error: e.toString(),
        );
      }
    }

    return results;
  }
}

/// תוצאת בדיקת שלמות מספור
class SequentialIntegrityResult {
  final bool valid;
  final int checkedCount;
  final int? gapAtNumber;
  final int? expectedNumber;
  final String? error;

  SequentialIntegrityResult({
    required this.valid,
    required this.checkedCount,
    this.gapAtNumber,
    this.expectedNumber,
    this.error,
  });

  /// תיאור בעברית
  String get summary {
    if (valid) return 'תקין — $checkedCount מסמכים נבדקו';
    if (error != null) return 'שגיאה: $error';
    return 'פער במספור: צפוי $expectedNumber, נמצא $gapAtNumber';
  }
}
