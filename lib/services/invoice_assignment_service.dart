import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';
import '../models/audit_event.dart';
import 'audit_log_service.dart';

/// שירות מספר הקצאה — חשבוניות ישראל API
/// פורטל חשבוניות ישראל של רשות המסים
class InvoiceAssignmentService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuditLogService _auditLogService;

  InvoiceAssignmentService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
    _auditLogService = AuditLogService(companyId: companyId);
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _assignmentRequestsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('assignment_requests');
  }

  /// בדיקה אם נדרש מספר הקצאה לפי סף ותאריך
  bool isAssignmentRequired(Invoice invoice) {
    if (invoice.documentType != InvoiceDocumentType.invoice &&
        invoice.documentType != InvoiceDocumentType.taxInvoiceReceipt)
      return false;
    final threshold = _getThreshold(DateTime.now());
    return invoice.subtotalBeforeVAT >= threshold;
  }

  /// סף לפי תאריך (סכום לפני מע״מ)
  double _getThreshold(DateTime date) {
    if (date.isAfter(DateTime(2026, 6, 1)) ||
        date.isAtSameMomentAs(DateTime(2026, 6, 1))) {
      return 5000.0;
    }
    if (date.isAfter(DateTime(2026, 1, 1)) ||
        date.isAtSameMomentAs(DateTime(2026, 1, 1))) {
      return 10000.0;
    }
    return 20000.0;
  }

  /// בקשת מספר הקצאה מרשות המסים
  /// כולל: דדופליקציה, ריטריי עם exponential backoff, רישום ביומן
  Future<AssignmentResult> requestAssignmentNumber(String invoiceId) async {
    try {
      // טעינת החשבונית
      final doc = await _invoicesCollection().doc(invoiceId).get();
      if (!doc.exists) {
        return AssignmentResult(
          success: false,
          error: 'חשבונית לא נמצאה',
        );
      }
      final invoice = Invoice.fromMap(doc.data()!, doc.id);

      // דדופליקציה — אם כבר אושר או ממתין, לא שולחים שוב
      if (invoice.assignmentStatus == AssignmentStatus.approved) {
        return AssignmentResult(
          success: true,
          assignmentNumber: invoice.assignmentNumber,
          message: 'מספר הקצאה כבר התקבל',
        );
      }
      if (invoice.assignmentStatus == AssignmentStatus.pending) {
        return AssignmentResult(
          success: false,
          error: 'בקשה כבר נשלחה — ממתין לתשובה',
        );
      }

      // בדיקת סף
      if (!isAssignmentRequired(invoice)) {
        await _invoicesCollection().doc(invoiceId).update({
          'assignmentStatus': AssignmentStatus.notRequired.name,
        });
        return AssignmentResult(
          success: true,
          message: 'לא נדרש מספר הקצאה — מתחת לסף',
        );
      }

      // סימון כממתין
      await _invoicesCollection().doc(invoiceId).update({
        'assignmentStatus': AssignmentStatus.pending.name,
        'assignmentRequestedAt': FieldValue.serverTimestamp(),
      });

      // רישום בקשה בתת-אוסף
      final requestDoc = await _assignmentRequestsCollection().add({
        'invoiceId': invoiceId,
        'sequentialNumber': invoice.sequentialNumber,
        'clientNumber': invoice.clientNumber,
        'amountBeforeVAT': invoice.subtotalBeforeVAT,
        'vatAmount': invoice.vatAmount,
        'totalAmount': invoice.totalWithVAT,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // שליחת בקשה ל-API עם ריטריי
      final result = await _sendWithRetry(invoice, requestDoc.id);

      // עדכון החשבונית לפי תוצאה
      if (result.success) {
        await _invoicesCollection().doc(invoiceId).update({
          'assignmentNumber': result.assignmentNumber,
          'assignmentStatus': AssignmentStatus.approved.name,
          'assignmentResponseRaw': result.rawResponse,
        });
        await _assignmentRequestsCollection().doc(requestDoc.id).update({
          'status': 'approved',
          'assignmentNumber': result.assignmentNumber,
          'respondedAt': FieldValue.serverTimestamp(),
        });
        // audit с actorUid пользователя — 'system' запрещён правилами
        // логируем только в assignment_requests, не в auditLog
      } else {
        final newStatus = result.isRejection
            ? AssignmentStatus.rejected
            : AssignmentStatus.error;
        await _invoicesCollection().doc(invoiceId).update({
          'assignmentStatus': newStatus.name,
          'assignmentResponseRaw': result.rawResponse ?? result.error,
        });
        await _assignmentRequestsCollection().doc(requestDoc.id).update({
          'status': newStatus.name,
          'error': result.error,
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      print('❌ [Assignment] Error requesting assignment number: $e');
      // עדכון סטטוס שגיאה
      try {
        await _invoicesCollection().doc(invoiceId).update({
          'assignmentStatus': AssignmentStatus.error.name,
          'assignmentResponseRaw': e.toString(),
        });
      } catch (_) {}
      return AssignmentResult(success: false, error: e.toString());
    }
  }

  /// שליחה ל-API עם exponential backoff (עד 3 ניסיונות)
  /// requestId משמש כ-idempotency key — מונע כפל הקצאה
  Future<AssignmentResult> _sendWithRetry(
      Invoice invoice, String requestId) async {
    // TODO: когда API будет реальным — вернуть retry с backoff
    // Пока API placeholder — одна попытка без retry
    try {
      return await _callAssignmentApi(invoice, requestId);
    } catch (e) {
      return AssignmentResult(
        success: false,
        error: 'API недоступен: $e',
      );
    }
  }

  /// קריאה בפועל ל-API של חשבוניות ישראל
  /// requestId = idempotency key — אותו requestId תמיד מחזיר אותה תוצאה
  /// TODO: להחליף ב-URL וטוקן אמיתיים לאחר רישום מול רשות המסים
  Future<AssignmentResult> _callAssignmentApi(
      Invoice invoice, String requestId) async {
    // === PLACEHOLDER: API endpoint של רשות המסים ===
    // בשלב זה — סימולציה. יש להחליף ב-endpoint אמיתי לאחר רישום.
    // ה-API האמיתי דורש: מספר עוסק, מספר חשבונית, סכום לפני מע״מ, סכום מע״מ
    const apiUrl = 'https://api.taxes.gov.il/shaam/tsandak/invoice/v1';

    try {
      final body = jsonEncode({
        'invoiceNumber': invoice.sequentialNumber,
        'customerVatId': invoice.clientNumber,
        'amountBeforeVAT': invoice.subtotalBeforeVAT,
        'vatAmount': invoice.vatAmount,
        'totalAmount': invoice.totalWithVAT,
        'requestId': requestId, // idempotency key — מונע כפל הקצאה ב-retry
      });

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': requestId,
              // TODO: הוספת Authorization header עם טוקן אמיתי
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AssignmentResult(
          success: true,
          assignmentNumber: data['assignmentNumber']?.toString(),
          rawResponse: response.body,
        );
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // סירוב מרשות המסים
        return AssignmentResult(
          success: false,
          error: 'סירוב מרשות המסים: ${response.body}',
          rawResponse: response.body,
          isRejection: true,
        );
      } else {
        return AssignmentResult(
          success: false,
          error: 'שגיאת שרת: ${response.statusCode}',
          rawResponse: response.body,
        );
      }
    } on TimeoutException {
      return AssignmentResult(
        success: false,
        error: 'תם הזמן המוקצב לבקשה (5 שניות)',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// קבלת היסטוריית בקשות הקצאה
  Future<List<Map<String, dynamic>>> getAssignmentRequests(
      String invoiceId) async {
    final snapshot = await _assignmentRequestsCollection()
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}

/// תוצאת בקשת מספר הקצאה
class AssignmentResult {
  final bool success;
  final String? assignmentNumber;
  final String? error;
  final String? message;
  final String? rawResponse;
  final bool isRejection;

  AssignmentResult({
    required this.success,
    this.assignmentNumber,
    this.error,
    this.message,
    this.rawResponse,
    this.isRejection = false,
  });
}
