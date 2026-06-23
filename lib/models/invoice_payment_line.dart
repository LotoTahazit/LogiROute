/// Строка תשלום для D120 (horaot 1.31).
class InvoicePaymentLine {
  /// cash | credit_card | cheque | bank_transfer | other
  final String method;
  final double amount;

  final String? bankNumber;
  final String? branchNumber;
  final String? accountNumber;
  final String? chequeNumber;
  final DateTime? dueDate;

  /// 1313: 1 ישראכרט, 2 כאל, 3 דיינרס, 4 אמריקן אקספרס, 6 לאומי כארד.
  final int? clearingHouseCode;
  final String? cardName;

  /// 1315: 1 רגיל, 2 תשלומים, 3 קרדיט, 4 חיוב נדחה, 5 אחר.
  final int creditDealType;

  const InvoicePaymentLine({
    required this.method,
    required this.amount,
    this.bankNumber,
    this.branchNumber,
    this.accountNumber,
    this.chequeNumber,
    this.dueDate,
    this.clearingHouseCode,
    this.cardName,
    this.creditDealType = 1,
  });

  factory InvoicePaymentLine.fromMap(Map<String, dynamic> map) {
    return InvoicePaymentLine(
      method: map['method'] as String? ?? 'cash',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      bankNumber: map['bankNumber'] as String?,
      branchNumber: map['branchNumber'] as String?,
      accountNumber: map['accountNumber'] as String?,
      chequeNumber: map['chequeNumber'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      clearingHouseCode: (map['clearingHouseCode'] as num?)?.toInt(),
      cardName: map['cardName'] as String?,
      creditDealType: (map['creditDealType'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'method': method,
        'amount': amount,
        if (bankNumber != null) 'bankNumber': bankNumber,
        if (branchNumber != null) 'branchNumber': branchNumber,
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (chequeNumber != null) 'chequeNumber': chequeNumber,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (clearingHouseCode != null) 'clearingHouseCode': clearingHouseCode,
        if (cardName != null) 'cardName': cardName,
        if (creditDealType != 1) 'creditDealType': creditDealType,
      };

  /// תשלומים שווים (חשבונית מס/קבלה בתשלומים).
  static List<InvoicePaymentLine> equalInstallments({
    required String method,
    required double total,
    required int count,
    required DateTime firstDue,
    Duration installmentInterval = const Duration(days: 30),
    String? cardName,
    int? clearingHouseCode,
  }) {
    if (count < 1) count = 1;
    final per = double.parse((total / count).toStringAsFixed(2));
    var remainder = double.parse((total - per * count).toStringAsFixed(2));
    return List.generate(count, (i) {
      var amt = per;
      if (remainder.abs() >= 0.01) {
        amt += remainder > 0 ? 0.01 : -0.01;
        remainder = double.parse((remainder + (remainder > 0 ? -0.01 : 0.01))
            .toStringAsFixed(2));
      }
      return InvoicePaymentLine(
        method: method,
        amount: amt,
        dueDate: firstDue.add(installmentInterval * i),
        cardName: cardName,
        clearingHouseCode: clearingHouseCode,
        creditDealType: count > 1 ? 2 : 1,
      );
    });
  }
}
