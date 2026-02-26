import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/audit_event.dart';
import 'audit_log_service.dart';

/// שירות ייצוא קובץ במבנה אחיד — תואם לדרישות רשות המסים
/// מייצר קובץ CSV/טקסט עם כל הרשומות לתקופה נתונה
/// כולל: מטא-נתונים (מי הפיק, תקופה, תאריך הפקה, מספור עמודים)
class UniformExportService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuditLogService _auditLogService;

  UniformExportService({required this.companyId}) {
    _auditLogService = AuditLogService(companyId: companyId);
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _exportRunsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('uniform_export_runs');
  }

  /// ייצוא כל המסמכים לתקופה נתונה בפורמט אחיד (CSV)
  /// log-before-action: רישום לפני ייצוא
  Future<String> exportPeriod({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    InvoiceDocumentType? filterDocType,
  }) async {
    // log-before-action
    await _auditLogService.logEvent(
      entityId:
          'export_${fromDate.toIso8601String()}_${toDate.toIso8601String()}',
      entityType: 'export',
      eventType: AuditEventType.exported,
      actorUid: exportedBy,
      metadata: {
        'format': 'csv_uniform',
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        if (filterDocType != null) 'docType': filterDocType.name,
      },
    );

    // שליפת מסמכים
    Query query = _invoicesCollection()
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
        .orderBy('createdAt');

    final snapshot = await query.get();
    var invoices = snapshot.docs
        .map((doc) =>
            Invoice.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    if (filterDocType != null) {
      invoices =
          invoices.where((i) => i.documentType == filterDocType).toList();
    }

    // בניית קובץ
    final buffer = StringBuffer();

    // כותרת מטא-נתונים
    final now = DateTime.now();
    buffer.writeln('# קובץ במבנה אחיד — ייצוא רשומות');
    buffer.writeln('# חברה: $companyId');
    buffer
        .writeln('# תקופה: ${_formatDate(fromDate)} - ${_formatDate(toDate)}');
    buffer.writeln('# תאריך הפקה: ${_formatDate(now)} ${_formatTime(now)}');
    buffer.writeln('# מפיק: $exportedBy');
    buffer.writeln('# סה"כ רשומות: ${invoices.length}');
    buffer.writeln('');

    // כותרות עמודות
    buffer.writeln([
      'מס_שורה',
      'סוג_מסמך',
      'מספר_רץ',
      'תאריך_יצירה',
      'שם_לקוח',
      'מספר_לקוח',
      'כתובת',
      'נהג',
      'מספר_רכב',
      'תאריך_אספקה',
      'תשלום_עד',
      'סכום_לפני_מעמ',
      'מעמ',
      'סכום_כולל',
      'הנחה_אחוז',
      'סטטוס',
      'מקור_הודפס',
      'עותקים',
      'מזהה_מסמך',
      'מסמך_מקושר',
    ].join(','));

    // שורות נתונים
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      buffer.writeln([
        i + 1,
        _docTypeName(inv.documentType),
        inv.sequentialNumber,
        _formatDate(inv.createdAt),
        _csvEscape(inv.clientName),
        _csvEscape(inv.clientNumber),
        _csvEscape(inv.address),
        _csvEscape(inv.driverName),
        _csvEscape(inv.truckNumber),
        _formatDate(inv.deliveryDate),
        inv.paymentDueDate != null ? _formatDate(inv.paymentDueDate!) : '',
        inv.subtotalBeforeVAT.toStringAsFixed(2),
        inv.vatAmount.toStringAsFixed(2),
        inv.totalWithVAT.toStringAsFixed(2),
        inv.discount.toStringAsFixed(2),
        inv.status.name,
        inv.originalPrinted ? 'כן' : 'לא',
        inv.copiesPrinted,
        inv.id,
        inv.linkedInvoiceId ?? '',
      ].join(','));
    }

    // סיום קובץ
    buffer.writeln('');
    buffer.writeln('# --- סוף קובץ ---');

    // רישום ריצת ייצוא
    await _exportRunsCollection().add({
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'exportedBy': exportedBy,
      'exportedAt': FieldValue.serverTimestamp(),
      'recordCount': invoices.length,
      'format': 'csv_uniform',
      if (filterDocType != null) 'docTypeFilter': filterDocType.name,
    });

    return buffer.toString();
  }

  /// ייצוא כ-bytes (UTF-8 with BOM for Excel compatibility)
  Future<List<int>> exportPeriodAsBytes({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    InvoiceDocumentType? filterDocType,
  }) async {
    final csvContent = await exportPeriod(
      fromDate: fromDate,
      toDate: toDate,
      exportedBy: exportedBy,
      filterDocType: filterDocType,
    );
    // UTF-8 BOM + content
    return [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _docTypeName(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 'חשבונית_מס';
      case InvoiceDocumentType.receipt:
        return 'קבלה';
      case InvoiceDocumentType.delivery:
        return 'תעודת_משלוח';
      case InvoiceDocumentType.creditNote:
        return 'זיכוי';
    }
  }
}
