import '../l10n/app_localizations.dart';
import '../models/invoice.dart';

String invoiceDocTypeLabel(AppLocalizations l10n, InvoiceDocumentType type) {
  switch (type) {
    case InvoiceDocumentType.invoice:
      return l10n.taxInvoice;
    case InvoiceDocumentType.taxInvoiceReceipt:
      return l10n.taxInvoiceReceipt;
    case InvoiceDocumentType.receipt:
      return l10n.receipt;
    case InvoiceDocumentType.delivery:
      return l10n.settingsDeliveryNote;
    case InvoiceDocumentType.creditNote:
      return l10n.creditNote;
  }
}

String invoiceDocTypeLabelOptional(
    AppLocalizations l10n, InvoiceDocumentType? type) {
  if (type == null) return l10n.filterAll;
  return invoiceDocTypeLabel(l10n, type);
}
