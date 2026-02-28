import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/audit_event.dart';
import 'audit_log_service.dart';

/// Форматы экспорта в бухгалтерские системы
enum AccountingExportFormat {
  hashavshevet, // חשבשבת — самая популярная в Израиле
  priority, // Priority ERP
  csv, // Универсальный CSV (для любой системы)
}

/// Кодировка экспорта
enum ExportEncoding {
  utf8bom, // UTF-8 with BOM — Excel, Priority, большинство современных систем
  utf8, // UTF-8 без BOM — для программной обработки
  windows1255, // Windows-1255 — старые версии חשבשבת
}

/// Разделитель CSV
enum CsvSeparator {
  comma, // , — стандартный CSV
  semicolon, // ; — Excel в локалях с запятой как десятичный разделитель
  tab, // \t — TSV (חשבשבת)
}

/// Сервис экспорта данных в бухгалтерские системы.
/// Поддерживает: חשבשבת (Hashavshevet), Priority, универсальный CSV.
///
/// Формат חשבשבת: фиксированная ширина полей, кодировка Windows-1255.
/// Формат Priority: CSV с определёнными колонками.
/// Формат CSV: универсальный UTF-8 CSV.
class AccountingExportService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuditLogService _auditLogService;

  AccountingExportService({required this.companyId}) {
    _auditLogService = AuditLogService(companyId: companyId);
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _exportRunsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting_export_runs');
  }

  /// Экспорт за период в выбранном формате.
  /// Возвращает строку с содержимым файла.
  Future<AccountingExportResult> export({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    required AccountingExportFormat format,
    InvoiceDocumentType? filterDocType,
    CsvSeparator? separator,
  }) async {
    // log-before-action
    await _auditLogService.logEvent(
      entityId:
          'acct_export_${fromDate.toIso8601String()}_${toDate.toIso8601String()}',
      entityType: 'accounting_export',
      eventType: AuditEventType.exported,
      actorUid: exportedBy,
      metadata: {
        'format': format.name,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        if (filterDocType != null) 'docType': filterDocType.name,
      },
    );

    // Fetch invoices
    final snapshot = await _invoicesCollection()
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
        .orderBy('createdAt')
        .get();

    var invoices = snapshot.docs
        .map((doc) => Invoice.fromMap(doc.data(), doc.id))
        .where((i) =>
            i.status == InvoiceStatus.issued ||
            i.status == InvoiceStatus.active)
        .toList();

    if (filterDocType != null) {
      invoices =
          invoices.where((i) => i.documentType == filterDocType).toList();
    }

    String content;
    String fileExtension;
    String mimeType;

    switch (format) {
      case AccountingExportFormat.hashavshevet:
        content = _buildHashavshevet(invoices, fromDate, toDate);
        fileExtension = 'txt';
        mimeType = 'text/plain';
        break;
      case AccountingExportFormat.priority:
        final sep = separator ?? CsvSeparator.comma;
        content = _buildPriority(invoices, fromDate, toDate, sep);
        fileExtension = 'csv';
        mimeType = 'text/csv';
        break;
      case AccountingExportFormat.csv:
        final sep = separator ?? CsvSeparator.comma;
        content = _buildUniversalCsv(invoices, fromDate, toDate, sep);
        fileExtension = 'csv';
        mimeType = 'text/csv';
        break;
    }

    // Log export run
    await _exportRunsCollection().add({
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'exportedBy': exportedBy,
      'exportedAt': FieldValue.serverTimestamp(),
      'recordCount': invoices.length,
      'format': format.name,
      if (filterDocType != null) 'docTypeFilter': filterDocType.name,
    });

    final fileName =
        'export_${format.name}_${_fmtDateFile(fromDate)}_${_fmtDateFile(toDate)}.$fileExtension';

    return AccountingExportResult(
      content: content,
      fileName: fileName,
      mimeType: mimeType,
      recordCount: invoices.length,
      format: format,
      separator: separator ?? CsvSeparator.comma,
    );
  }

  /// Export as bytes with encoding support.
  /// - utf8bom: UTF-8 with BOM (default, best for Excel)
  /// - utf8: plain UTF-8
  /// - windows1255: for legacy חשבשבת versions
  Future<List<int>> exportAsBytes({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    required AccountingExportFormat format,
    InvoiceDocumentType? filterDocType,
    ExportEncoding encoding = ExportEncoding.utf8bom,
    CsvSeparator? separator,
  }) async {
    final result = await export(
      fromDate: fromDate,
      toDate: toDate,
      exportedBy: exportedBy,
      format: format,
      filterDocType: filterDocType,
      separator: separator,
    );

    switch (encoding) {
      case ExportEncoding.utf8bom:
        // UTF-8 BOM (EF BB BF) + content — Excel auto-detects encoding
        return [0xEF, 0xBB, 0xBF, ...utf8.encode(result.content)];
      case ExportEncoding.utf8:
        return utf8.encode(result.content);
      case ExportEncoding.windows1255:
        // Windows-1255 encoding for legacy Hebrew software.
        // Dart doesn't have built-in 1255 — we use a simple mapping table
        // for the Hebrew range (0x05D0-0x05EA → 0xE0-0xFA).
        // Non-Hebrew chars fall back to Latin-1 range.
        return _encodeWindows1255(result.content);
    }
  }

  /// Simple Windows-1255 encoder for Hebrew text.
  /// Maps Unicode Hebrew block (U+05D0..U+05EA) → bytes 0xE0..0xFA.
  /// ASCII passes through. Other chars replaced with '?'.
  List<int> _encodeWindows1255(String input) {
    final bytes = <int>[];
    for (final codeUnit in input.codeUnits) {
      if (codeUnit < 0x80) {
        // ASCII
        bytes.add(codeUnit);
      } else if (codeUnit >= 0x05D0 && codeUnit <= 0x05EA) {
        // Hebrew letters: א(05D0)=E0 ... ת(05EA)=FA
        bytes.add(codeUnit - 0x05D0 + 0xE0);
      } else if (codeUnit == 0x05B0) {
        bytes.add(0xC0); // שווא
      } else if (codeUnit == 0x20AA) {
        bytes.add(0xA4); // ₪ (shekel sign)
      } else if (codeUnit == 0x00AB) {
        bytes.add(0xAB); // «
      } else if (codeUnit == 0x00BB) {
        bytes.add(0xBB); // »
      } else {
        bytes.add(0x3F); // '?' for unmapped chars
      }
    }
    return bytes;
  }

  // =========================================================
  // חשבשבת (Hashavshevet) format
  // =========================================================

  /// Формат חשבשבת — текстовый файл с разделителем табуляция.
  /// Колонки: סוג תנועה, מספר חשבון, תאריך, אסמכתא, סכום, מטבע, פרטים
  String _buildHashavshevet(
      List<Invoice> invoices, DateTime from, DateTime to) {
    final buf = StringBuffer();

    // Header row
    buf.writeln([
      'סוג_תנועה',
      'מספר_חשבון',
      'תאריך_ערך',
      'אסמכתא',
      'חובה',
      'זכות',
      'מטבע',
      'פרטים',
      'מספר_חשבונית',
    ].join('\t'));

    for (final inv in invoices) {
      final date = _fmtDateHeb(inv.deliveryDate);
      final ref = '${_docTypeCode(inv.documentType)}${inv.sequentialNumber}';
      final total = inv.totalWithVAT;
      final vat = inv.vatAmount;
      final net = inv.subtotalBeforeVAT;

      // Debit: client account (חובה)
      buf.writeln([
        '1', // סוג תנועה: 1 = רגיל
        inv.clientNumber.isNotEmpty ? inv.clientNumber : '0000',
        date,
        ref,
        total.toStringAsFixed(2), // חובה
        '', // זכות
        'ILS',
        _tabEscape(inv.clientName),
        inv.sequentialNumber.toString(),
      ].join('\t'));

      // Credit: income account (זכות) — net amount
      buf.writeln([
        '1',
        _incomeAccount(inv.documentType),
        date,
        ref,
        '', // חובה
        net.toStringAsFixed(2), // זכות
        'ILS',
        _tabEscape('הכנסה - ${_docTypeName(inv.documentType)}'),
        inv.sequentialNumber.toString(),
      ].join('\t'));

      // Credit: VAT account (מע"מ)
      if (vat > 0) {
        buf.writeln([
          '1',
          '9999', // חשבון מע"מ עסקאות
          date,
          ref,
          '', // חובה
          vat.toStringAsFixed(2), // זכות
          'ILS',
          'מע"מ עסקאות',
          inv.sequentialNumber.toString(),
        ].join('\t'));
      }
    }

    return buf.toString();
  }

  // =========================================================
  // Priority ERP format
  // =========================================================

  /// Формат Priority — CSV с колонками, совместимыми с импортом Priority.
  String _buildPriority(
      List<Invoice> invoices, DateTime from, DateTime to, CsvSeparator sep) {
    final buf = StringBuffer();
    final d = _sepChar(sep);
    final esc = sep == CsvSeparator.semicolon ? _semicolonEscape : _csvEscape;

    // Priority header
    buf.writeln([
      'IVNUM',
      'IVDATE',
      'CUSTNAME',
      'CUSTDES',
      'QPRICE',
      'VAT',
      'TOTPRICE',
      'PAYDATE',
      'DETAILS',
      'IVTYPE',
      'DOCNO',
    ].join(d));

    for (final inv in invoices) {
      buf.writeln([
        inv.sequentialNumber,
        _fmtDatePriority(inv.deliveryDate),
        esc(inv.clientName),
        esc(inv.clientNumber),
        inv.subtotalBeforeVAT.toStringAsFixed(2),
        inv.vatAmount.toStringAsFixed(2),
        inv.totalWithVAT.toStringAsFixed(2),
        inv.paymentDueDate != null
            ? _fmtDatePriority(inv.paymentDueDate!)
            : _fmtDatePriority(inv.deliveryDate),
        esc('${_docTypeName(inv.documentType)} #${inv.sequentialNumber}'),
        _priorityDocType(inv.documentType),
        inv.linkedInvoiceId ?? '',
      ].join(d));
    }

    return buf.toString();
  }

  // =========================================================
  // Universal CSV format
  // =========================================================

  String _buildUniversalCsv(
      List<Invoice> invoices, DateTime from, DateTime to, CsvSeparator sep) {
    final buf = StringBuffer();
    final d = _sepChar(sep);
    final esc = sep == CsvSeparator.semicolon ? _semicolonEscape : _csvEscape;

    // Metadata
    buf.writeln('# Accounting Export — LogiRoute');
    buf.writeln('# Company: $companyId');
    buf.writeln('# Period: ${_fmtDate(from)} - ${_fmtDate(to)}');
    buf.writeln(
        '# Exported: ${_fmtDate(DateTime.now())} ${_fmtTime(DateTime.now())}');
    buf.writeln('# Records: ${invoices.length}');
    buf.writeln('# Separator: ${sep.name}');
    buf.writeln('');

    // Header
    buf.writeln([
      'doc_type',
      'doc_number',
      'date',
      'client_name',
      'client_number',
      'net_amount',
      'vat_amount',
      'total_amount',
      'discount',
      'payment_due',
      'payment_method',
      'status',
      'doc_id',
      'linked_doc_id',
    ].join(d));

    for (final inv in invoices) {
      buf.writeln([
        inv.documentType.name,
        inv.sequentialNumber,
        _fmtDate(inv.deliveryDate),
        esc(inv.clientName),
        esc(inv.clientNumber),
        inv.subtotalBeforeVAT.toStringAsFixed(2),
        inv.vatAmount.toStringAsFixed(2),
        inv.totalWithVAT.toStringAsFixed(2),
        inv.discount.toStringAsFixed(2),
        inv.paymentDueDate != null ? _fmtDate(inv.paymentDueDate!) : '',
        inv.paymentMethod ?? '',
        inv.status.name,
        inv.id,
        inv.linkedInvoiceId ?? '',
      ].join(d));
    }

    return buf.toString();
  }

  // =========================================================
  // Helpers
  // =========================================================

  /// Get separator character for CsvSeparator enum
  String _sepChar(CsvSeparator sep) {
    switch (sep) {
      case CsvSeparator.comma:
        return ',';
      case CsvSeparator.semicolon:
        return ';';
      case CsvSeparator.tab:
        return '\t';
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDateFile(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  /// חשבשבת date format: DD/MM/YY
  String _fmtDateHeb(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${(dt.year % 100).toString().padLeft(2, '0')}';

  /// Priority date format: YYYY-MM-DD
  String _fmtDatePriority(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Escape for semicolon-separated CSV (Excel locale with , as decimal)
  String _semicolonEscape(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _tabEscape(String value) =>
      value.replaceAll('\t', ' ').replaceAll('\n', ' ');

  String _docTypeName(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 'חשבונית מס';
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 'חשבונית מס/קבלה';
      case InvoiceDocumentType.receipt:
        return 'קבלה';
      case InvoiceDocumentType.delivery:
        return 'תעודת משלוח';
      case InvoiceDocumentType.creditNote:
        return 'זיכוי';
    }
  }

  /// קוד סוג מסמך לאסמכתא
  String _docTypeCode(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 'INV';
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 'TIR';
      case InvoiceDocumentType.receipt:
        return 'RCP';
      case InvoiceDocumentType.delivery:
        return 'DLV';
      case InvoiceDocumentType.creditNote:
        return 'CRN';
    }
  }

  /// חשבון הכנסה לפי סוג מסמך (ברירת מחדל — ניתן להגדרה)
  String _incomeAccount(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
      case InvoiceDocumentType.taxInvoiceReceipt:
        return '4000'; // הכנסות ממכירות
      case InvoiceDocumentType.receipt:
        return '4000';
      case InvoiceDocumentType.delivery:
        return '4000';
      case InvoiceDocumentType.creditNote:
        return '4000'; // זיכוי — סכום שלילי
    }
  }

  /// Priority document type code
  String _priorityDocType(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 'T';
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 'A';
      case InvoiceDocumentType.receipt:
        return 'R';
      case InvoiceDocumentType.delivery:
        return 'D';
      case InvoiceDocumentType.creditNote:
        return 'C';
    }
  }
}

/// Результат экспорта
class AccountingExportResult {
  final String content;
  final String fileName;
  final String mimeType;
  final int recordCount;
  final AccountingExportFormat format;
  final CsvSeparator separator;

  AccountingExportResult({
    required this.content,
    required this.fileName,
    required this.mimeType,
    required this.recordCount,
    required this.format,
    this.separator = CsvSeparator.comma,
  });
}
