import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import 'summary_service.dart';

/// Invoice Service with Israeli Tax Law Compliance
/// תואם לדרישות רשות המסים הישראלית
class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SummaryService _summaryService = SummaryService();

  /// Get next sequential number for invoice
  /// מספר רץ - נדרש לפי חוק
  Future<int> _getNextSequentialNumber() async {
    try {
      // Use a counter document to ensure sequential numbering
      final counterRef = _firestore.collection('counters').doc('invoices');

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
      print('❌ [Invoice] Error getting sequential number: $e');
      rethrow;
    }
  }

  /// Create חשבונית with sequential numbering and audit log
  /// יצירת חשבונית עם מספר רץ ויומן שינויים
  Future<String> createInvoice(Invoice invoice, String createdBy) async {
    try {
      // Get sequential number
      final sequentialNumber = await _getNextSequentialNumber();

      // Create audit entry
      final auditEntry = InvoiceAuditEntry(
        timestamp: DateTime.now(),
        action: 'created',
        performedBy: createdBy,
        details: 'Invoice created with sequential number $sequentialNumber',
      );

      // Create invoice with sequential number and audit log
      final invoiceWithNumber = invoice.copyWith(
        sequentialNumber: sequentialNumber,
        status: InvoiceStatus.active,
        auditLog: [auditEntry],
      );

      final docRef = await _firestore
          .collection('invoices')
          .add(invoiceWithNumber.toMap());

      print(
          '✅ [Invoice] Created invoice: ${docRef.id} (Sequential #$sequentialNumber)');

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
    String cancelledBy,
    String reason,
  ) async {
    try {
      final invoice = await getInvoice(id);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      if (!invoice.canBeCancelled) {
        throw Exception(
            'Invoice cannot be cancelled (status: ${invoice.status})');
      }

      // Create audit entry
      final auditEntry = InvoiceAuditEntry(
        timestamp: DateTime.now(),
        action: 'cancelled',
        performedBy: cancelledBy,
        details: 'Reason: $reason',
      );

      // Update invoice status
      await _firestore.collection('invoices').doc(id).update({
        'status': InvoiceStatus.cancelled.name,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'cancelledBy': cancelledBy,
        'cancellationReason': reason,
        'auditLog': FieldValue.arrayUnion([auditEntry.toMap()]),
      });

      print('✅ [Invoice] Cancelled invoice: $id');

      // ⚡ OPTIMIZATION: Update daily summary
      try {
        final updatedInvoice = invoice.copyWith(
          status: InvoiceStatus.cancelled,
          cancelledAt: DateTime.now(),
          cancelledBy: cancelledBy,
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

      await _firestore.collection('invoices').doc(invoiceId).update({
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
      Query query = _firestore.collection('invoices');

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
      final doc = await _firestore.collection('invoices').doc(id).get();

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
      Query query = _firestore
          .collection('invoices')
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
      final snapshot = await _firestore
          .collection('invoices')
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

  /// Verify sequential numbering integrity
  /// בדיקת תקינות המספור הרץ
  Future<bool> verifySequentialIntegrity() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .orderBy('sequentialNumber')
          .get();

      if (snapshot.docs.isEmpty) return true;

      int expectedNumber = 1;
      for (final doc in snapshot.docs) {
        final invoice = Invoice.fromMap(doc.data(), doc.id);
        if (invoice.sequentialNumber != expectedNumber) {
          print(
              '❌ [Invoice] Sequential number gap detected: expected $expectedNumber, got ${invoice.sequentialNumber}');
          return false;
        }
        expectedNumber++;
      }

      print('✅ [Invoice] Sequential numbering integrity verified');
      return true;
    } catch (e) {
      print('❌ [Invoice] Error verifying sequential integrity: $e');
      return false;
    }
  }
}
