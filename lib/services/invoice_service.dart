import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/audit_event.dart';
import '../models/document_link.dart';
import 'summary_service.dart';
import 'audit_log_service.dart';
import 'integrity_chain_service.dart';
import 'document_link_service.dart';
import 'invoice_assignment_service.dart';

/// Invoice Service with Israeli Tax Law Compliance
/// תואם לדרישות רשות המסים הישראלית
class InvoiceService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SummaryService _summaryService;
  late final AuditLogService _auditLogService;
  late final IntegrityChainService _integrityChainService;
  late final DocumentLinkService _documentLinkService;
  late final InvoiceAssignmentService _assignmentService;

  InvoiceService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
    _summaryService = SummaryService(companyId: companyId);
    _auditLogService = AuditLogService(companyId: companyId);
    _integrityChainService = IntegrityChainService(companyId: companyId);
    _documentLinkService = DocumentLinkService(companyId: companyId);
    _assignmentService = InvoiceAssignmentService(companyId: companyId);
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

  /// Хелпер: возвращает ссылку на счетчик по типу документа
  DocumentReference<Map<String, dynamic>> _counterRef(
      InvoiceDocumentType docType) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('counters')
        .doc(docType.name);
  }

  /// הקצאת מספר רץ אטומית לפי סוג מסמך
  /// סדרות נפרדות: חשבונית מס, קבלה, תעודת משלוח, זיכוי
  Future<int> _getNextSequentialNumberForType(
      InvoiceDocumentType docType) async {
    try {
      final counterRef = _counterRef(docType);

      return await _firestore.runTransaction((transaction) async {
        final counterDoc = await transaction.get(counterRef);

        int nextNumber;
        if (!counterDoc.exists) {
          nextNumber = 1;
          transaction.set(counterRef, {'lastNumber': nextNumber});
        } else {
          nextNumber = (counterDoc.data()?['lastNumber'] ?? 0) + 1;
          transaction.update(counterRef, {'lastNumber': nextNumber});
        }

        return nextNumber;
      });
    } catch (e) {
      print(
          '❌ [Invoice] Error getting sequential number for ${docType.name}: $e');
      rethrow;
    }
  }

  /// Create חשבונית with sequential numbering and audit log
  /// יצירת חשבונית עם מספר רץ ויומן שינויים
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
            .where('status', isEqualTo: InvoiceStatus.active.name)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          // Документ уже существует — возвращаем его ID
          print(
              '⚠️ [Invoice] Duplicate prevented: ${invoice.documentType.name} for deliveryPoint ${invoice.deliveryPointId} already exists');
          return existing.docs.first.id;
        }
      }

      // Get sequential number per document type
      final sequentialNumber =
          await _getNextSequentialNumberForType(invoice.documentType);

      // Create invoice with sequential number
      final invoiceWithNumber = invoice.copyWith(
        sequentialNumber: sequentialNumber,
        status: InvoiceStatus.active,
      );

      // Резервируем ID документа заранее для log-before-action
      final docRef = _invoicesCollection().doc();

      // רישום ביומן ביקורת ПЕРЕД созданием — log-before-action
      await _auditLogService.logEvent(
        entityId: docRef.id,
        entityType: invoiceWithNumber.documentType.name,
        eventType: AuditEventType.created,
        actorUid: createdByUid,
        metadata: {'sequentialNumber': sequentialNumber},
      );

      // Создаём документ
      await docRef.set(invoiceWithNumber.toMap());

      // ⚡ OPTIMIZATION: Update daily summary
      try {
        await _summaryService.updateInvoiceSummary(invoiceWithNumber);
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

  /// סיום מסמך: מגדיר finalizedAt + מחשב immutableSnapshotHash
  /// לאחר סיום — שדות מוגנים לא ניתנים לשינוי (Firestore Rules)
  Future<void> finalizeInvoice(String invoiceId, String finalizedBy) async {
    try {
      final invoice = await getInvoice(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }
      if (invoice.isFinalized) {
        throw Exception('Invoice already finalized');
      }

      final hash = invoice.computeSnapshotHash();

      // רישום ביומן ביקורת ПЕРЕД финализацией — log-before-action
      await _auditLogService.logEvent(
        entityId: invoiceId,
        entityType: invoice.documentType.name,
        eventType: AuditEventType.finalized,
        actorUid: finalizedBy,
        metadata: {'snapshotHash': hash},
      );

      // Финализация с serverTimestamp для clock integrity
      await _invoicesCollection().doc(invoiceId).update({
        'finalizedAt': FieldValue.serverTimestamp(),
        'finalizedBy': finalizedBy,
        'immutableSnapshotHash': hash,
      });

      // הוספה לשרשרת שלמות
      await _integrityChainService.appendToChain(
        documentId: invoiceId,
        documentType: invoice.documentType.name,
        sequentialNumber: invoice.sequentialNumber,
        documentHash: hash,
      );

      // === בקשת מספר הקצאה אוטומטית אם נדרש ===
      if (_assignmentService.isAssignmentRequired(invoice)) {
        try {
          await _assignmentService.requestAssignmentNumber(invoiceId);
        } catch (e) {
          print('⚠️ [Invoice] Assignment request failed (non-blocking): $e');
        }
      }
    } catch (e) {
      print('❌ [Invoice] Error finalizing invoice: $e');
      rethrow;
    }
  }

  /// יצירת זיכוי (credit note) — מסמך חדש עם סכומים שליליים
  /// המסמך המקורי לא נמחק ולא משתנה
  Future<String> createCreditNote({
    required Invoice originalInvoice,
    required String reason,
    required String createdBy,
  }) async {
    try {
      if (originalInvoice.status != InvoiceStatus.active) {
        throw Exception('ניתן ליצור זיכוי רק למסמך פעיל');
      }
      if (originalInvoice.documentType == InvoiceDocumentType.creditNote) {
        throw Exception('לא ניתן ליצור זיכוי לזיכוי');
      }
      if (reason.isEmpty) {
        throw Exception('חובה לציין סיבה');
      }

      final sequentialNumber =
          await _getNextSequentialNumberForType(InvoiceDocumentType.creditNote);

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
        sequentialNumber: sequentialNumber,
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
        status: InvoiceStatus.active,
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
        sourceSequentialNumber: sequentialNumber,
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
