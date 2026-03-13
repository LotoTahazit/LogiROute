import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус счёта биллинга.
enum BillingInvoiceStatus {
  paid,
  pending,
  overdue,
  cancelled;

  String get value => name;

  static BillingInvoiceStatus fromString(String status) {
    switch (status) {
      case 'paid':
        return BillingInvoiceStatus.paid;
      case 'pending':
        return BillingInvoiceStatus.pending;
      case 'overdue':
        return BillingInvoiceStatus.overdue;
      case 'cancelled':
        return BillingInvoiceStatus.cancelled;
      default:
        throw ArgumentError('Unknown billing invoice status: $status');
    }
  }
}

/// BillingInvoice-документ: `/companies/{companyId}/billing_invoices/{invoiceId}`
///
/// Счёт от платформы за использование сервиса.
class BillingInvoice {
  final double amount;
  final String currency;
  final DateTime? issuedAt;
  final DateTime? paidAt;
  final BillingInvoiceStatus status;
  final String description;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? pdfUrl;

  BillingInvoice({
    required this.amount,
    this.currency = 'ILS',
    this.issuedAt,
    this.paidAt,
    required this.status,
    required this.description,
    this.periodStart,
    this.periodEnd,
    this.pdfUrl,
  });

  factory BillingInvoice.fromMap(Map<String, dynamic> map) {
    return BillingInvoice(
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'ILS',
      issuedAt: map['issuedAt'] != null
          ? (map['issuedAt'] as Timestamp).toDate()
          : null,
      paidAt:
          map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
      status: BillingInvoiceStatus.fromString(map['status'] ?? 'pending'),
      description: map['description'] ?? '',
      periodStart: map['periodStart'] != null
          ? (map['periodStart'] as Timestamp).toDate()
          : null,
      periodEnd: map['periodEnd'] != null
          ? (map['periodEnd'] as Timestamp).toDate()
          : null,
      pdfUrl: map['pdfUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
      'issuedAt': issuedAt != null
          ? Timestamp.fromDate(issuedAt!)
          : FieldValue.serverTimestamp(),
      'status': status.value,
      'description': description,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (periodStart != null) 'periodStart': Timestamp.fromDate(periodStart!),
      if (periodEnd != null) 'periodEnd': Timestamp.fromDate(periodEnd!),
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
    };
  }
}
