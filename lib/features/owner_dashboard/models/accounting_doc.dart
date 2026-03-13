import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип бухгалтерского документа.
enum AccountingDocType {
  taxInvoice,
  receipt,
  taxInvoiceReceipt,
  creditNote;

  String get value {
    switch (this) {
      case AccountingDocType.taxInvoice:
        return 'tax_invoice';
      case AccountingDocType.receipt:
        return 'receipt';
      case AccountingDocType.taxInvoiceReceipt:
        return 'tax_invoice_receipt';
      case AccountingDocType.creditNote:
        return 'credit_note';
    }
  }

  static AccountingDocType fromString(String type) {
    switch (type) {
      case 'tax_invoice':
        return AccountingDocType.taxInvoice;
      case 'receipt':
        return AccountingDocType.receipt;
      case 'tax_invoice_receipt':
        return AccountingDocType.taxInvoiceReceipt;
      case 'credit_note':
        return AccountingDocType.creditNote;
      default:
        throw ArgumentError('Unknown accounting doc type: $type');
    }
  }
}

/// Статус жизненного цикла бухгалтерского документа.
enum AccountingDocStatus {
  draft,
  issued,
  locked,
  credited,
  voidedBeforeDelivery;

  String get value {
    switch (this) {
      case AccountingDocStatus.draft:
        return 'draft';
      case AccountingDocStatus.issued:
        return 'issued';
      case AccountingDocStatus.locked:
        return 'locked';
      case AccountingDocStatus.credited:
        return 'credited';
      case AccountingDocStatus.voidedBeforeDelivery:
        return 'voided_before_delivery';
    }
  }

  static AccountingDocStatus fromString(String status) {
    switch (status) {
      case 'draft':
        return AccountingDocStatus.draft;
      case 'issued':
        return AccountingDocStatus.issued;
      case 'locked':
        return AccountingDocStatus.locked;
      case 'credited':
        return AccountingDocStatus.credited;
      case 'voided_before_delivery':
        return AccountingDocStatus.voidedBeforeDelivery;
      default:
        throw ArgumentError('Unknown accounting doc status: $status');
    }
  }
}

/// Строка бухгалтерского документа.
class AccountingDocLine {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalBeforeVat;
  final double vatRate;
  final double vatAmount;
  final double totalWithVat;

  AccountingDocLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalBeforeVat,
    this.vatRate = 0.18,
    required this.vatAmount,
    required this.totalWithVat,
  });

  factory AccountingDocLine.fromMap(Map<String, dynamic> map) {
    return AccountingDocLine(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalBeforeVat: (map['totalBeforeVat'] ?? 0).toDouble(),
      vatRate: (map['vatRate'] ?? 0.18).toDouble(),
      vatAmount: (map['vatAmount'] ?? 0).toDouble(),
      totalWithVat: (map['totalWithVat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalBeforeVat': totalBeforeVat,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalWithVat': totalWithVat,
    };
  }
}

/// Итоги бухгалтерского документа.
class AccountingDocTotals {
  final double net;
  final double vat;
  final double gross;

  AccountingDocTotals({
    required this.net,
    required this.vat,
    required this.gross,
  });

  factory AccountingDocTotals.fromMap(Map<String, dynamic> map) {
    return AccountingDocTotals(
      net: (map['net'] ?? 0).toDouble(),
      vat: (map['vat'] ?? 0).toDouble(),
      gross: (map['gross'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'net': net,
      'vat': vat,
      'gross': gross,
    };
  }
}

/// Ссылки бухгалтерского документа (для credit_note и связанных документов).
class AccountingDocReferences {
  final String? originalDocId;
  final int? originalDocNumber;
  final List<String>? creditNoteIds;

  AccountingDocReferences({
    this.originalDocId,
    this.originalDocNumber,
    this.creditNoteIds,
  });

  factory AccountingDocReferences.fromMap(Map<String, dynamic> map) {
    return AccountingDocReferences(
      originalDocId: map['originalDocId'],
      originalDocNumber: map['originalDocNumber'] != null
          ? (map['originalDocNumber'] as num).toInt()
          : null,
      creditNoteIds: map['creditNoteIds'] != null
          ? List<String>.from(map['creditNoteIds'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (originalDocId != null) 'originalDocId': originalDocId,
      if (originalDocNumber != null) 'originalDocNumber': originalDocNumber,
      if (creditNoteIds != null) 'creditNoteIds': creditNoteIds,
    };
  }
}

/// AccountingDoc-документ: `/companies/{companyId}/accountingDocs/{docId}`
///
/// Бухгалтерский документ: חשבונית מס, קבלה, חשבונית מס קבלה, תעודת זיכוי.
class AccountingDoc {
  /// Firestore document ID (populated when reading from Firestore).
  final String? id;
  final AccountingDocType type;
  final AccountingDocStatus status;
  final int? docNumber;
  final DateTime? issuedAt;
  final String customerId;
  final String customerName;
  final String? customerTaxId;
  final List<AccountingDocLine> lines;
  final AccountingDocTotals totals;
  final AccountingDocReferences? references;
  final String? reason;
  final String? correctionType;
  final DateTime? createdAt;
  final String createdBy;
  final String companyId;
  final String? immutableSnapshotHash;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? notes;

  AccountingDoc({
    this.id,
    required this.type,
    required this.status,
    this.docNumber,
    this.issuedAt,
    required this.customerId,
    required this.customerName,
    this.customerTaxId,
    required this.lines,
    required this.totals,
    this.references,
    this.reason,
    this.correctionType,
    this.createdAt,
    required this.createdBy,
    required this.companyId,
    this.immutableSnapshotHash,
    this.updatedAt,
    this.updatedBy,
    this.notes,
  });

  factory AccountingDoc.fromMap(Map<String, dynamic> map) {
    return AccountingDoc(
      type: AccountingDocType.fromString(map['type'] ?? 'tax_invoice'),
      status: AccountingDocStatus.fromString(map['status'] ?? 'draft'),
      docNumber:
          map['docNumber'] != null ? (map['docNumber'] as num).toInt() : null,
      issuedAt: map['issuedAt'] != null
          ? (map['issuedAt'] as Timestamp).toDate()
          : null,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerTaxId: map['customerTaxId'],
      lines: map['lines'] != null
          ? (map['lines'] as List)
              .map((e) =>
                  AccountingDocLine.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      totals: map['totals'] != null
          ? AccountingDocTotals.fromMap(
              Map<String, dynamic>.from(map['totals']))
          : AccountingDocTotals(net: 0, vat: 0, gross: 0),
      references: map['references'] != null
          ? AccountingDocReferences.fromMap(
              Map<String, dynamic>.from(map['references']))
          : null,
      reason: map['reason'],
      correctionType: map['correctionType'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] ?? '',
      companyId: map['companyId'] ?? '',
      immutableSnapshotHash: map['immutableSnapshotHash'],
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: map['updatedBy'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'status': status.value,
      if (docNumber != null) 'docNumber': docNumber,
      if (issuedAt != null) 'issuedAt': Timestamp.fromDate(issuedAt!),
      'customerId': customerId,
      'customerName': customerName,
      if (customerTaxId != null) 'customerTaxId': customerTaxId,
      'lines': lines.map((e) => e.toMap()).toList(),
      'totals': totals.toMap(),
      if (references != null) 'references': references!.toMap(),
      if (reason != null) 'reason': reason,
      if (correctionType != null) 'correctionType': correctionType,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'companyId': companyId,
      if (immutableSnapshotHash != null)
        'immutableSnapshotHash': immutableSnapshotHash,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (notes != null) 'notes': notes,
    };
  }
}
