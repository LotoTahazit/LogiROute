import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../models/accounting_doc.dart';

/// Shared helpers for accounting section widgets.
///
/// Contains label/color resolvers used by multiple widgets:
/// AccountingSection, CreateDocFormDialog, DocumentChainDialog.

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
