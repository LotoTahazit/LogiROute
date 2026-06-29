import '../../../../l10n/app_localizations.dart';
import '../../../../models/invoice.dart';
import '../../../../services/cross_module_audit_service.dart';
import '../../../../utils/document_type_labels.dart';
import '../models/audit_event.dart';
import '../services/audit_event_enricher.dart';

/// Локализованные подписи для cross-module audit (UI, CSV).
abstract final class AuditEventLabels {
  static String type(
    String type,
    AppLocalizations l10n, {
    InvoiceDocumentType? documentType,
  }) {
    switch (type) {
      case CrossModuleAuditService.typeReceiptCreated:
        return l10n.eventReceiptCreated;
      case CrossModuleAuditService.typeCreditNoteCreated:
        return l10n.eventCreditNoteCreated;
      case CrossModuleAuditService.typeDocumentVoided:
        return l10n.eventDocumentVoided;
      case CrossModuleAuditService.typeInvoiceVoided:
        return l10n.eventInvoiceVoided;
      case CrossModuleAuditService.typeBillingStatusChanged:
        return l10n.eventBillingStatusChanged;
      case CrossModuleAuditService.typeTrialUntilChanged:
        return l10n.eventTrialUntilChanged;
      case CrossModuleAuditService.typeAccountingLockedUntilChanged:
        return l10n.eventAccountingLockedUntilChanged;
      case 'invoice_issued':
        if (documentType != null) {
          return '${invoiceDocTypeLabel(l10n, documentType)} · ${l10n.issuedStatus}';
        }
        return l10n.eventInvoiceIssued;
      case 'invoice_printed':
        if (documentType != null) {
          return '${invoiceDocTypeLabel(l10n, documentType)} · ${l10n.eventInvoicePrinted}';
        }
        return l10n.eventInvoicePrinted;
      case 'inventory_adjusted':
        return l10n.eventInventoryAdjusted;
      case 'inventory_count_completed':
        return l10n.eventInventoryCountCompleted;
      case 'inventory_count_approved':
        return l10n.eventInventoryCountApproved;
      case 'route_published':
        return l10n.eventRoutePublished;
      case 'delivery_point_status_changed':
        return l10n.eventDeliveryPointStatusChanged;
      case CrossModuleAuditService.typeDeliveryAddressChanged:
        return l10n.eventDeliveryAddressChanged;
      case 'manual_assignment':
        return l10n.eventManualAssignment;
      case 'payment_received':
        return l10n.eventPaymentReceived;
      case 'module_changed':
        return l10n.eventModuleChanged;
      case 'plan_changed':
        return l10n.eventPlanChanged;
      case 'backup_recorded':
        return l10n.eventBackupRecorded;
      case 'retention_checked':
        return l10n.eventRetentionChecked;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static String module(String key, AppLocalizations l10n) {
    switch (key) {
      case 'logistics':
        return l10n.moduleLogistics;
      case 'warehouse':
        return l10n.moduleWarehouse;
      case 'accounting':
        return l10n.moduleAccounting;
      case 'dispatcher':
        return l10n.moduleDispatcher;
      default:
        return key;
    }
  }

  static String collection(String collection, AppLocalizations l10n) {
    switch (collection) {
      case 'invoices':
        return l10n.invoicesTab;
      case 'creditNotes':
        return l10n.creditNotes;
      case 'deliveryNotes':
        return l10n.deliveryNotesReport;
      case 'receipts':
        return l10n.receiptsReport;
      case 'inventory':
        return l10n.warehouseInventory;
      case 'routes':
        return l10n.routes;
      case 'deliveryPoints':
        return l10n.deliveryPoints;
      default:
        return collection;
    }
  }

  static String entityLine(
    CrossModuleAuditEvent event,
    AppLocalizations l10n, {
    AuditEventMeta? meta,
  }) =>
      headline(event, l10n, meta: meta);

  /// Одна понятная строка: тип · מס׳ N · שם לקוח
  static String headline(
    CrossModuleAuditEvent event,
    AppLocalizations l10n, {
    AuditEventMeta? meta,
  }) {
    final docNum = _firstStr(
      event.extra['docNumberFormatted'],
      event.extra['docNumber'],
      event.extra['sequentialNumber'],
      meta?.docNumber,
    );
    final client = _firstStr(event.extra['clientName'], meta?.clientName);
    final docTypeRaw =
        _firstStr(event.extra['documentType'], meta?.documentType);
    final docType = _parseDocType(docTypeRaw);

    final label = type(event.type, l10n, documentType: docType);

    if (event.type == CrossModuleAuditService.typeDeliveryAddressChanged) {
      final oldA = _firstStr(event.extra['oldAddress']);
      final newA = _firstStr(event.extra['newAddress']);
      if (oldA != null && newA != null) {
        return '$label: $oldA → $newA';
      }
    }

    final parts = <String>[label];
    if (docNum != null) parts.add('${l10n.docNumberShort} $docNum');
    if (client != null) parts.add(client);
    return parts.join(' · ');
  }

  static String actorLine(
    String uid,
    AppLocalizations l10n, {
    Map<String, String>? names,
  }) {
    final who = actor(uid, names: names);
    return '${l10n.auditEventBy} $who';
  }

  static InvoiceDocumentType? parseDocumentType(String? raw) =>
      _parseDocType(raw);

  static String eventTypeLabel(
    CrossModuleAuditEvent event,
    AppLocalizations l10n, {
    AuditEventMeta? meta,
  }) {
    final docType = _parseDocType(
      _firstStr(event.extra['documentType'], meta?.documentType),
    );
    return type(event.type, l10n, documentType: docType);
  }

  static InvoiceDocumentType? _parseDocType(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'delivery_note':
      case 'delivery':
        return InvoiceDocumentType.delivery;
      case 'tax_invoice':
        return InvoiceDocumentType.invoice;
      case 'receipt':
        return InvoiceDocumentType.receipt;
      case 'tax_invoice_receipt':
      case 'taxInvoiceReceipt':
        return InvoiceDocumentType.taxInvoiceReceipt;
      case 'credit_note':
      case 'creditNote':
        return InvoiceDocumentType.creditNote;
    }
    for (final t in InvoiceDocumentType.values) {
      if (t.name == raw) return t;
    }
    return null;
  }

  static String? _firstStr(Object? a, [Object? b, Object? c, Object? d]) {
    for (final v in [a, b, c, d]) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String actor(String uid, {Map<String, String>? names}) {
    if (uid == 'system') return 'מערכת';
    final name = names?[uid];
    if (name != null && name.isNotEmpty) return name;
    return uid.length > 12 ? '${uid.substring(0, 12)}…' : uid;
  }
}
