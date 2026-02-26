import 'package:cloud_firestore/cloud_firestore.dart';

/// סוג קישור בין מסמכים
enum DocumentLinkType {
  creditToInvoice, // זיכוי → חשבונית מקור
  invoiceToDelivery, // חשבונית → תעודת משלוח
  receiptToInvoice, // קבלה → חשבונית
  cancellation, // ביטול → מסמך מקורי
}

/// קישור בין מסמכים חשבונאיים
/// אוסף: companies/{cId}/document_links/{linkId}
class DocumentLink {
  final String id;
  final String companyId;
  final String sourceDocumentId;
  final String sourceDocumentType; // invoice, creditNote, receipt, delivery
  final int sourceSequentialNumber;
  final String targetDocumentId;
  final String targetDocumentType;
  final int targetSequentialNumber;
  final DocumentLinkType linkType;
  final DateTime? createdAt;
  final String createdBy;
  final String? reason;

  DocumentLink({
    required this.id,
    required this.companyId,
    required this.sourceDocumentId,
    required this.sourceDocumentType,
    required this.sourceSequentialNumber,
    required this.targetDocumentId,
    required this.targetDocumentType,
    required this.targetSequentialNumber,
    required this.linkType,
    this.createdAt,
    required this.createdBy,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'sourceDocumentId': sourceDocumentId,
      'sourceDocumentType': sourceDocumentType,
      'sourceSequentialNumber': sourceSequentialNumber,
      'targetDocumentId': targetDocumentId,
      'targetDocumentType': targetDocumentType,
      'targetSequentialNumber': targetSequentialNumber,
      'linkType': linkType.name,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      if (reason != null) 'reason': reason,
    };
  }

  factory DocumentLink.fromMap(Map<String, dynamic> map, String id) {
    return DocumentLink(
      id: id,
      companyId: map['companyId'] ?? '',
      sourceDocumentId: map['sourceDocumentId'] ?? '',
      sourceDocumentType: map['sourceDocumentType'] ?? '',
      sourceSequentialNumber: map['sourceSequentialNumber'] ?? 0,
      targetDocumentId: map['targetDocumentId'] ?? '',
      targetDocumentType: map['targetDocumentType'] ?? '',
      targetSequentialNumber: map['targetSequentialNumber'] ?? 0,
      linkType: DocumentLinkType.values.firstWhere(
        (e) => e.name == map['linkType'],
        orElse: () => DocumentLinkType.creditToInvoice,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] ?? '',
      reason: map['reason'],
    );
  }
}
