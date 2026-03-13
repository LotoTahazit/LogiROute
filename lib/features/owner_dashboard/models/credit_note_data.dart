import 'accounting_doc.dart';

/// Данные для создания Credit Note (תעודת זיכוי).
///
/// Используется при вызове `AccountingDocsRepository.createCreditNote(data)`.
class CreditNoteData {
  final String originalDocId;
  final int originalDocNumber;
  final String reason;
  final String correctionType; // 'full' | 'partial'
  final String customerId;
  final List<AccountingDocLine> lines;
  final AccountingDocTotals totals;

  CreditNoteData({
    required this.originalDocId,
    required this.originalDocNumber,
    required this.reason,
    required this.correctionType,
    required this.customerId,
    required this.lines,
    required this.totals,
  });

  factory CreditNoteData.fromMap(Map<String, dynamic> map) {
    return CreditNoteData(
      originalDocId: map['originalDocId'] ?? '',
      originalDocNumber: map['originalDocNumber'] != null
          ? (map['originalDocNumber'] as num).toInt()
          : 0,
      reason: map['reason'] ?? '',
      correctionType: map['correctionType'] ?? 'full',
      customerId: map['customerId'] ?? '',
      lines: map['lines'] != null
          ? (map['lines'] as List)
              .map(
                (e) => AccountingDocLine.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList()
          : [],
      totals: map['totals'] != null
          ? AccountingDocTotals.fromMap(
              Map<String, dynamic>.from(map['totals']),
            )
          : AccountingDocTotals(net: 0, vat: 0, gross: 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalDocId': originalDocId,
      'originalDocNumber': originalDocNumber,
      'reason': reason,
      'correctionType': correctionType,
      'customerId': customerId,
      'lines': lines.map((e) => e.toMap()).toList(),
      'totals': totals.toMap(),
    };
  }
}
