import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_event.dart';
import '../models/invoice.dart';
import 'audit_log_service.dart';
import 'bkmv/bkmv_exporter.dart';
import 'bkmv/bkmv_records.dart';

/// ייצוא OPENFRMT (INI.TXT + BKMVDATA.TXT) — horaot 1.31.
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
        .collection('accounting')
        .doc('_root')
        .collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _exportRunsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('uniform_export_runs');
  }

  Future<List<Invoice>> _loadInvoices({
    required DateTime fromDate,
    required DateTime toDate,
    InvoiceDocumentType? filterDocType,
  }) async {
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
    final snapshot = await _invoicesCollection()
        .where('deliveryDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
        .where('deliveryDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('deliveryDate')
        .get();

    var invoices = snapshot.docs
        .map((doc) =>
            Invoice.fromMap(doc.data(), doc.id))
        .toList();

    if (filterDocType != null) {
      invoices =
          invoices.where((i) => i.documentType == filterDocType).toList();
    }
    return invoices;
  }

  /// ZIP עם INI.TXT + BKMVDATA.TXT (ISO-8859-8).
  Future<BkmvExportResult> exportOpenFormat({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    required BkmvCompanyContext company,
    InvoiceDocumentType? filterDocType,
    BkmvSoftwareInfo software = const BkmvSoftwareInfo(),
  }) async {
    await _auditLogService.logEvent(
      entityId:
          'bkmv_${fromDate.toIso8601String()}_${toDate.toIso8601String()}',
      entityType: 'export',
      eventType: AuditEventType.exported,
      actorUid: exportedBy,
      metadata: {
        'format': 'openfrmt_131',
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        if (filterDocType != null) 'docType': filterDocType.name,
      },
    );

    final invoices = await _loadInvoices(
      fromDate: fromDate,
      toDate: toDate,
      filterDocType: filterDocType,
    );

    final result = BkmvExporter(company: company, software: software).build(
      invoices: invoices,
      fromDate: fromDate,
      toDate: toDate,
    );

    await _exportRunsCollection().add({
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'exportedBy': exportedBy,
      'exportedAt': FieldValue.serverTimestamp(),
      'recordCount': result.documentCount,
      'format': 'openfrmt_131',
      'primaryId': result.primaryId,
      'recordCounts': result.recordCounts,
      if (filterDocType != null) 'docTypeFilter': filterDocType.name,
    });

    return result;
  }

  /// Bytes של ZIP OPENFRMT (להורדה).
  Future<List<int>> exportPeriodAsBytes({
    required DateTime fromDate,
    required DateTime toDate,
    required String exportedBy,
    required BkmvCompanyContext company,
    InvoiceDocumentType? filterDocType,
  }) async {
    final result = await exportOpenFormat(
      fromDate: fromDate,
      toDate: toDate,
      exportedBy: exportedBy,
      company: company,
      filterDocType: filterDocType,
    );
    return result.zipBytes;
  }

  /// שם קובץ ZIP לפי מוסכמת OPENFRMT: BKMV_{עוסק}_{שנה}.zip
  static String zipFileName(String vatId, DateTime periodEnd) {
    final vat = vatId.replaceAll(RegExp(r'\D'), '').padLeft(9, '0');
    return 'BKMV_${vat}_${periodEnd.year}.zip';
  }
}
