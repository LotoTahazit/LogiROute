import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice.dart';

/// אירוע הדפסה — תת-אוסף: companies/{cId}/invoices/{iId}/printEvents/{eId}
class PrintEvent {
  final String id;
  final String documentId;
  final DateTime? printedAt; // זמן שרת
  final String printedBy; // UID
  final String? printedByName; // שם (דנורמליזציה)
  final InvoiceCopyType mode; // original / copy / replacesOriginal
  final int copiesCount;
  final String? templateVersion;
  final String? device;
  final String? pdfSnapshotUrl; // URL ל-Firebase Storage (אופציונלי)

  PrintEvent({
    required this.id,
    required this.documentId,
    this.printedAt,
    required this.printedBy,
    this.printedByName,
    required this.mode,
    this.copiesCount = 1,
    this.templateVersion,
    this.device,
    this.pdfSnapshotUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'printedAt': FieldValue.serverTimestamp(),
      'printedBy': printedBy,
      if (printedByName != null) 'printedByName': printedByName,
      'mode': mode.name,
      'copiesCount': copiesCount,
      if (templateVersion != null) 'templateVersion': templateVersion,
      if (device != null) 'device': device,
      if (pdfSnapshotUrl != null) 'pdfSnapshotUrl': pdfSnapshotUrl,
    };
  }

  factory PrintEvent.fromMap(Map<String, dynamic> map, String id) {
    return PrintEvent(
      id: id,
      documentId: map['documentId'] ?? '',
      printedAt: map['printedAt'] != null
          ? (map['printedAt'] as Timestamp).toDate()
          : null,
      printedBy: map['printedBy'] ?? '',
      printedByName: map['printedByName'],
      mode: InvoiceCopyType.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => InvoiceCopyType.copy,
      ),
      copiesCount: map['copiesCount'] ?? 1,
      templateVersion: map['templateVersion'],
      device: map['device'],
      pdfSnapshotUrl: map['pdfSnapshotUrl'],
    );
  }
}
