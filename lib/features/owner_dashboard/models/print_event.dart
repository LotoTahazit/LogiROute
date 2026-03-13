import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус события печати.
enum PrintEventStatus {
  success,
  error;

  String get value => name;

  static PrintEventStatus fromString(String status) {
    switch (status) {
      case 'success':
        return PrintEventStatus.success;
      case 'error':
        return PrintEventStatus.error;
      default:
        throw ArgumentError('Unknown print event status: $status');
    }
  }
}

/// PrintEvent-документ: `/companies/{companyId}/printEvents/{eventId}`
///
/// Событие печати — зеркальная summary-копия из подколлекции invoices.
/// Read-only: создаётся модулем accounting, клиент только читает.
class PrintEvent {
  final String id;
  final String invoiceId;
  final String printedBy;
  final DateTime? printedAt;
  final PrintEventStatus status;
  final String? errorMessage;
  final String? printerName;

  PrintEvent({
    required this.id,
    required this.invoiceId,
    required this.printedBy,
    this.printedAt,
    required this.status,
    this.errorMessage,
    this.printerName,
  });

  factory PrintEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return PrintEvent(
      id: id ?? (map['id'] ?? ''),
      invoiceId: map['invoiceId'] ?? '',
      printedBy: map['printedBy'] ?? '',
      printedAt: map['printedAt'] != null
          ? (map['printedAt'] as Timestamp).toDate()
          : null,
      status: PrintEventStatus.fromString(map['status'] ?? 'error'),
      errorMessage: map['errorMessage'],
      printerName: map['printerName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'printedBy': printedBy,
      'printedAt': printedAt != null
          ? Timestamp.fromDate(printedAt!)
          : FieldValue.serverTimestamp(),
      'status': status.value,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (printerName != null) 'printerName': printerName,
    };
  }
}
