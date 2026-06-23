import '../../models/invoice.dart';
import '../../models/invoice_payment_line.dart';
import 'bkmv_records.dart';

/// Разворачивает строки D120 из invoice.paymentLines или fallback.
List<InvoicePaymentLine> resolveBkmvPaymentLines(Invoice invoice) {
  if (invoice.paymentLines.isNotEmpty) {
    return invoice.paymentLines;
  }

  final method = _normalizeMethodKey(invoice.paymentMethod);
  final total = invoice.totalWithVAT;
  final due = invoice.paymentDueDate ?? invoice.deliveryDate;

  final installments = _installmentCountFromMethod(invoice.paymentMethod);
  if (installments != null && installments > 1) {
    return InvoicePaymentLine.equalInstallments(
      method: method,
      total: total,
      count: installments,
      firstDue: due,
      cardName: _cardNameFromMethod(invoice.paymentMethod),
      clearingHouseCode: method == 'credit_card' ? 1 : null,
    );
  }

  return [
    InvoicePaymentLine(
      method: method,
      amount: total,
      dueDate: due,
      cardName: _cardNameFromMethod(invoice.paymentMethod),
      clearingHouseCode: method == 'credit_card' ? 1 : null,
      creditDealType: 1,
    ),
  ];
}

String _normalizeMethodKey(String? raw) {
  final m = (raw ?? '').toLowerCase();
  if (m.contains('cash') || m.contains('מזומן')) return 'cash';
  if (m.contains('cheque') || m.contains('check') || m.contains('המחא')) {
    return 'cheque';
  }
  if (m.contains('credit') || m.contains('אשראי') || m.contains('כרטיס')) {
    return 'credit_card';
  }
  if (m.contains('bank') || m.contains('העבר')) return 'bank_transfer';
  if (m.isEmpty) return 'cash';
  return 'other';
}

int? _installmentCountFromMethod(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final m = raw.toLowerCase();
  final match =
      RegExp(r'(\d+)\s*(?:x|תשלומים|payments|installments)').firstMatch(m);
  if (match != null) {
    final n = int.tryParse(match.group(1)!);
    if (n != null && n > 1) return n;
  }
  return null;
}

String? _cardNameFromMethod(String? raw) {
  if (raw == null) return null;
  final m = raw.toLowerCase();
  if (m.contains('isracard') || m.contains('ישראכרט')) return 'Isracard';
  if (m.contains('visa') || m.contains('ויזה')) return 'Visa';
  if (m.contains('master')) return 'Mastercard';
  if (m.contains('amex') || m.contains('אמריקן')) return 'Amex';
  return null;
}

int paymentMeansCodeFromLine(InvoicePaymentLine line) =>
    BkmvRecords.paymentMeansCode(line.method);
