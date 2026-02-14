import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice.dart';

/// Separate status document for invoices
/// ⚡ OPTIMIZATION: Small document for realtime updates
///
/// This allows listening to status changes without reading full invoice data
/// Typical size: ~200 bytes vs ~5KB for full invoice
class InvoiceStatus {
  final String invoiceId;
  final InvoiceStatusEnum status;
  final bool originalPrinted;
  final int copiesPrinted;
  final DateTime? lastPrintedAt;
  final DateTime lastUpdated;

  InvoiceStatus({
    required this.invoiceId,
    required this.status,
    this.originalPrinted = false,
    this.copiesPrinted = 0,
    this.lastPrintedAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'status': status.name,
      'originalPrinted': originalPrinted,
      'copiesPrinted': copiesPrinted,
      if (lastPrintedAt != null)
        'lastPrintedAt': Timestamp.fromDate(lastPrintedAt!),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory InvoiceStatus.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceStatus(
      invoiceId: id,
      status: InvoiceStatusEnum.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatusEnum.active,
      ),
      originalPrinted: map['originalPrinted'] ?? false,
      copiesPrinted: map['copiesPrinted'] ?? 0,
      lastPrintedAt: map['lastPrintedAt'] != null
          ? (map['lastPrintedAt'] as Timestamp).toDate()
          : null,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  InvoiceStatus copyWith({
    InvoiceStatusEnum? status,
    bool? originalPrinted,
    int? copiesPrinted,
    DateTime? lastPrintedAt,
    DateTime? lastUpdated,
  }) {
    return InvoiceStatus(
      invoiceId: invoiceId,
      status: status ?? this.status,
      originalPrinted: originalPrinted ?? this.originalPrinted,
      copiesPrinted: copiesPrinted ?? this.copiesPrinted,
      lastPrintedAt: lastPrintedAt ?? this.lastPrintedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Status enum for invoice_status collection
enum InvoiceStatusEnum {
  active,
  cancelled,
  draft,
}
