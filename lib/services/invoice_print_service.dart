import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/audit_event.dart';
import '../models/company_settings.dart';
import '../services/company_settings_service.dart';
import '../services/audit_log_service.dart';
import '../services/print_event_service.dart';
import 'invoice_pdf_helpers.dart';
import 'invoice_pdf_layout.dart';

class InvoicePrintService {
  /// Loads company settings with fallback to defaults
  static Future<CompanySettings> _loadSettings(String companyId) async {
    final settings =
        await CompanySettingsService(companyId: companyId).getSettings();
    return settings ?? defaultCompanySettings(companyId);
  }

  /// Печать חשבונית — generates PDF with multiple copies
  /// log-before-action: log first, then PDF
  static Future<void> printInvoice(
    Invoice invoice, {
    InvoiceCopyType? copyType,
    int copies = 1,
    String? actorUid,
    String? actorName,
  }) async {
    final settingsFuture = _loadSettings(invoice.companyId);
    await Future.wait([settingsFuture, loadPdfFonts()]);
    final companySettings = await settingsFuture;

    // Determine copy type
    InvoiceCopyType actualCopyType;
    if (copyType != null) {
      actualCopyType = copyType;
    } else if (!invoice.originalPrinted) {
      actualCopyType = InvoiceCopyType.original;
    } else {
      actualCopyType = InvoiceCopyType.copy;
    }

    // Protection: מקור cannot be reprinted (Israeli law)
    if (invoice.originalPrinted && actualCopyType == InvoiceCopyType.original) {
      actualCopyType = InvoiceCopyType.copy;
    }

    // Block original print without assignment number (above threshold)
    if (actualCopyType == InvoiceCopyType.original &&
        invoice.requiresAssignment &&
        invoice.assignmentStatus != AssignmentStatus.approved) {
      throw Exception('לא ניתן להדפיס מקור — ממתין למספר הקצאה מרשות המסים');
    }

    // log-before-action
    if (actorUid != null && invoice.id.isNotEmpty) {
      await Future.wait([
        _logPrintEvent(invoice, actorUid, actorName, actualCopyType, copies),
        loadPdfFonts(),
      ]);
    } else {
      await loadPdfFonts();
    }

    final hebFont = fontHebrewCache;
    final hebBoldFont = fontHebrewBoldCache;
    final latFont = fontLatinCache;
    if (hebFont == null || hebBoldFont == null || latFont == null) {
      throw StateError('PDF fonts not loaded — call loadPdfFonts() first');
    }

    final pdf = pw.Document();
    for (int i = 0; i < copies; i++) {
      pdf.addPage(buildInvoicePage(
          invoice,
          hebFont,
          hebBoldFont,
          latFont,
          actualCopyType,
          companySettings));
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (invoice.id.isNotEmpty) {
      await _updatePrintCounters(invoice.id, invoice.companyId, actualCopyType);
    }
  }

  /// First print: 1 מקור + 2 העתק in one PDF
  static Future<void> printFirstTime(Invoice invoice,
      {String? actorUid, String? actorName}) async {
    final settingsFuture = _loadSettings(invoice.companyId);
    await Future.wait([settingsFuture, loadPdfFonts()]);
    final companySettings = await settingsFuture;

    final hebFont = fontHebrewCache;
    final hebBoldFont = fontHebrewBoldCache;
    final latFont = fontLatinCache;
    if (hebFont == null || hebBoldFont == null || latFont == null) {
      throw StateError('PDF fonts not loaded — call loadPdfFonts() first');
    }

    final pdf = pw.Document();

    // Block original without assignment — print as copy instead
    if (actorUid != null && invoice.id.isNotEmpty) {
      if (invoice.requiresAssignment &&
          invoice.assignmentStatus != AssignmentStatus.approved) {
        await _logPrintEvent(
          invoice,
          actorUid,
          actorName,
          InvoiceCopyType.copy,
          3,
          metadata: {
            'copyType': 'copy_pending_assignment',
            'isFirstPrint': true,
            'note': 'printed as copy — awaiting assignment number',
          },
        );
        for (int i = 0; i < 3; i++) {
          pdf.addPage(buildInvoicePage(
              invoice,
              hebFont,
              hebBoldFont,
              latFont,
              InvoiceCopyType.copy,
              companySettings));
        }
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name:
              'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        return;
      }
      await _logPrintEvent(
        invoice,
        actorUid,
        actorName,
        InvoiceCopyType.original,
        3,
        metadata: {'isFirstPrint': true},
      );
    }

    pdf.addPage(buildInvoicePage(
        invoice,
        hebFont,
        hebBoldFont,
        latFont,
        InvoiceCopyType.original,
        companySettings));
    for (int i = 0; i < 2; i++) {
      pdf.addPage(buildInvoicePage(
          invoice,
          hebFont,
          hebBoldFont,
          latFont,
          InvoiceCopyType.copy,
          companySettings));
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (invoice.id.isNotEmpty) {
      await _updatePrintCounters(
          invoice.id, invoice.companyId, InvoiceCopyType.original);
    }
  }

  /// Print all route invoices in one PDF
  static Future<void> printAllRouteInvoices(List<Invoice> invoices,
      {String? actorUid, String? actorName}) async {
    if (invoices.isEmpty) return;

    await loadPdfFonts();

    // Load settings for all unique companies in parallel
    final uniqueIds = invoices.map((i) => i.companyId).toSet().toList();
    final settingsList = await Future.wait(
      uniqueIds.map((id) => _loadSettings(id)),
    );
    final Map<String, CompanySettings> settingsCache = {};
    for (int i = 0; i < uniqueIds.length; i++) {
      settingsCache[uniqueIds[i]] = settingsList[i];
    }

    final pdf = pw.Document();

    final hebFont = fontHebrewCache;
    final hebBoldFont = fontHebrewBoldCache;
    final latFont = fontLatinCache;
    if (hebFont == null || hebBoldFont == null || latFont == null) {
      throw StateError('PDF fonts not loaded — call loadPdfFonts() first');
    }

    // Log all invoices in parallel
    if (actorUid != null) {
      final logFutures = <Future>[];
      for (final invoice in invoices) {
        if (invoice.id.isEmpty) continue;
        if (invoice.requiresAssignment &&
            invoice.assignmentStatus != AssignmentStatus.approved) {
          continue;
        }
        logFutures.add(_logPrintEvent(
          invoice,
          actorUid,
          actorName,
          InvoiceCopyType.original,
          3,
          metadata: {'isRoutePrint': true},
        ));
      }
      await Future.wait(logFutures);
    }

    for (final invoice in invoices) {
      if (invoice.requiresAssignment &&
          invoice.assignmentStatus != AssignmentStatus.approved) {
        print('⚠️ [Print] Skipping invoice ${invoice.id} — pending assignment');
        continue;
      }
      final settings = settingsCache[invoice.companyId]!;
      pdf.addPage(buildInvoicePage(
          invoice,
          hebFont,
          hebBoldFont,
          latFont,
          InvoiceCopyType.original,
          settings));
      for (int i = 0; i < 2; i++) {
        pdf.addPage(buildInvoicePage(
            invoice,
            hebFont,
            hebBoldFont,
            latFont,
            InvoiceCopyType.copy,
            settings));
      }
    }

    // Update counters in parallel
    await Future.wait(invoices.where((inv) => inv.id.isNotEmpty).map((inv) =>
        _updatePrintCounters(inv.id, inv.companyId, InvoiceCopyType.original)));

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Route_Invoices_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Logs print event to audit log and print events collection
  static Future<void> _logPrintEvent(
    Invoice invoice,
    String actorUid,
    String? actorName,
    InvoiceCopyType copyType,
    int copies, {
    Map<String, dynamic>? metadata,
  }) async {
    final auditService = AuditLogService(companyId: invoice.companyId);
    final printEventService = PrintEventService(companyId: invoice.companyId);
    await Future.wait([
      auditService.logEvent(
        entityId: invoice.id,
        entityType: invoice.documentType.name,
        eventType: AuditEventType.printed,
        actorUid: actorUid,
        actorName: actorName,
        metadata: {
          'copyType': copyType.name,
          'copies': copies,
          'isOriginal': copyType == InvoiceCopyType.original,
          ...?metadata,
        },
      ),
      printEventService.recordPrintEvent(
        documentId: invoice.id,
        printedBy: actorUid,
        printedByName: actorName,
        mode: copyType,
        copiesCount: copies,
      ),
    ]);
  }

  /// Updates print counters in Firestore
  static Future<void> _updatePrintCounters(
    String invoiceId,
    String companyId,
    InvoiceCopyType copyType,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('accounting')
          .doc('_root')
          .collection('invoices')
          .doc(invoiceId);

      if (copyType == InvoiceCopyType.original ||
          copyType == InvoiceCopyType.replacesOriginal) {
        await docRef.update({'originalPrinted': true});
      } else {
        await docRef.update({'copiesPrinted': FieldValue.increment(1)});
      }
    } catch (e) {
      print('⚠️ [Print] Failed to update print counters (non-critical): $e');
    }
  }
}
