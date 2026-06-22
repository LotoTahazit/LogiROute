import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/invoice.dart';
import '../../models/accounting_doc.dart';

/// Shared helpers for accounting section widgets.
///
/// Contains label/color resolvers used by multiple widgets:
/// AccountingSection, CreateDocFormDialog, DocumentChainDialog.

/// Конвертация типов owner-UI → единый движок `invoices`.
extension AccountingDocTypeInvoice on AccountingDocType {
  InvoiceDocumentType get toInvoiceDocumentType {
    switch (this) {
      case AccountingDocType.taxInvoice:
        return InvoiceDocumentType.invoice;
      case AccountingDocType.receipt:
        return InvoiceDocumentType.receipt;
      case AccountingDocType.taxInvoiceReceipt:
        return InvoiceDocumentType.taxInvoiceReceipt;
      case AccountingDocType.creditNote:
        return InvoiceDocumentType.creditNote;
      case AccountingDocType.deliveryNote:
        return InvoiceDocumentType.delivery;
    }
  }

  String get canonicalCounterKey => toInvoiceDocumentType.canonicalCounterKey;
}

/// Строка owner-формы → [InvoiceItem].
InvoiceItem accountingLineToInvoiceItem(AccountingDocLine line) {
  return InvoiceItem(
    productCode: 'OWNER',
    type: '',
    number: '',
    quantity: line.quantity.round().clamp(1, 999999),
    pricePerUnit: line.unitPrice,
    description: line.description,
    vatRate: line.vatRate,
  );
}

String docTypeLabel(BuildContext context, AccountingDocType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case AccountingDocType.taxInvoice:
      return l10n.taxInvoice;
    case AccountingDocType.receipt:
      return l10n.receipt;
    case AccountingDocType.taxInvoiceReceipt:
      return l10n.taxInvoiceReceipt;
    case AccountingDocType.creditNote:
      return l10n.creditNote;
    case AccountingDocType.deliveryNote:
      return l10n.settingsDeliveryNote;
  }
}

String docStatusLabel(BuildContext context, AccountingDocStatus status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case AccountingDocStatus.draft:
      return l10n.draftStatus;
    case AccountingDocStatus.issued:
      return l10n.issuedStatus;
    case AccountingDocStatus.locked:
      return l10n.lockedStatus;
    case AccountingDocStatus.credited:
      return l10n.creditedStatus;
    case AccountingDocStatus.voidedBeforeDelivery:
      return l10n.voidedStatus;
  }
}

Color docStatusColor(AccountingDocStatus status) {
  switch (status) {
    case AccountingDocStatus.draft:
      return Colors.grey;
    case AccountingDocStatus.issued:
      return Colors.green;
    case AccountingDocStatus.locked:
      return Colors.blue;
    case AccountingDocStatus.credited:
      return Colors.orange;
    case AccountingDocStatus.voidedBeforeDelivery:
      return Colors.red;
  }
}

String formatCurrency(double value) {
  if (value == 0) return '0.00';
  final parts = value.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buffer = StringBuffer();
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}${buffer.toString()}.$decPart';
}

String externalSyncLabel(BuildContext context, String? status) {
  final l10n = AppLocalizations.of(context)!;
  switch (status) {
    case 'synced':
      return l10n.accountingSyncStatusSynced;
    case 'failed':
      return l10n.accountingSyncStatusFailed;
    case 'processing':
      return l10n.accountingSyncStatusProcessing;
    default:
      return l10n.accountingSyncStatusPending;
  }
}

Color externalSyncColor(String? status) {
  switch (status) {
    case 'synced':
      return Colors.green;
    case 'failed':
      return Colors.red;
    case 'processing':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
