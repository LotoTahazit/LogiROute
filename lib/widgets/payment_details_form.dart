import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice_payment_line.dart';

/// Канонические ключи способа оплаты (Firestore + BKMV).
class PaymentMethodKeys {
  static const cash = 'cash';
  static const creditCard = 'credit_card';
  static const bankTransfer = 'bank_transfer';
  static const cheque = 'cheque';
  static const all = [cash, creditCard, bankTransfer, cheque];
}

String paymentMethodLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case PaymentMethodKeys.cash:
      return l10n.cash;
    case PaymentMethodKeys.creditCard:
      return l10n.creditCard;
    case PaymentMethodKeys.bankTransfer:
      return l10n.bankTransfer;
    case PaymentMethodKeys.cheque:
      return l10n.cheque;
    default:
      return key;
  }
}

/// Иврит / legacy → канонический ключ.
String normalizePaymentMethodKey(String? raw) {
  final m = (raw ?? '').toLowerCase();
  if (m == PaymentMethodKeys.cash || m.contains('cash') || m.contains('מזומן')) {
    return PaymentMethodKeys.cash;
  }
  if (m == PaymentMethodKeys.cheque ||
      m.contains('cheque') ||
      m.contains('check') ||
      m.contains('המחא') ||
      m.contains("צ'ק")) {
    return PaymentMethodKeys.cheque;
  }
  if (m == PaymentMethodKeys.creditCard ||
      m.contains('credit') ||
      m.contains('אשראי') ||
      m.contains('כרטיס')) {
    return PaymentMethodKeys.creditCard;
  }
  if (m == PaymentMethodKeys.bankTransfer ||
      m.contains('bank') ||
      m.contains('העבר')) {
    return PaymentMethodKeys.bankTransfer;
  }
  return PaymentMethodKeys.cash;
}

/// Результат диалога оплаты (קבלה / квитанция).
class PaymentDialogResult {
  final String methodKey;
  final List<InvoicePaymentLine> paymentLines;

  const PaymentDialogResult({
    required this.methodKey,
    required this.paymentLines,
  });
}

/// Состояние полей D120 в формах.
class PaymentDetailsController {
  String methodKey = PaymentMethodKeys.cash;
  final bankCtrl = TextEditingController();
  final branchCtrl = TextEditingController();
  final accountCtrl = TextEditingController();
  final chequeCtrl = TextEditingController();
  final cardNameCtrl = TextEditingController();
  int installmentCount = 1;
  int creditDealType = 1;
  int? clearingHouseCode;
  DateTime? dueDate;

  void dispose() {
    bankCtrl.dispose();
    branchCtrl.dispose();
    accountCtrl.dispose();
    chequeCtrl.dispose();
    cardNameCtrl.dispose();
  }

  String? validate(AppLocalizations l10n) {
    if (methodKey == PaymentMethodKeys.cheque) {
      if (bankCtrl.text.trim().isEmpty) return l10n.paymentBankRequired;
      if (branchCtrl.text.trim().isEmpty) return l10n.paymentBranchRequired;
      if (accountCtrl.text.trim().isEmpty) return l10n.paymentAccountRequired;
      if (chequeCtrl.text.trim().isEmpty) return l10n.paymentChequeRequired;
      if (dueDate == null) return l10n.paymentDueDateRequired;
    }
    if (methodKey == PaymentMethodKeys.bankTransfer) {
      if (bankCtrl.text.trim().isEmpty) return l10n.paymentBankRequired;
      if (branchCtrl.text.trim().isEmpty) return l10n.paymentBranchRequired;
      if (accountCtrl.text.trim().isEmpty) return l10n.paymentAccountRequired;
    }
    if (methodKey == PaymentMethodKeys.creditCard && installmentCount > 1) {
      if (installmentCount < 2 || installmentCount > 36) {
        return l10n.paymentInstallmentRange;
      }
    }
    return null;
  }

  List<InvoicePaymentLine> buildLines({
    required double total,
    required DateTime defaultDue,
  }) {
    final due = dueDate ?? defaultDue;
    if (methodKey == PaymentMethodKeys.creditCard && installmentCount > 1) {
      return InvoicePaymentLine.equalInstallments(
        method: methodKey,
        total: total,
        count: installmentCount,
        firstDue: due,
        clearingHouseCode: clearingHouseCode,
        cardName: _opt(cardNameCtrl.text),
      );
    }
    return [
      InvoicePaymentLine(
        method: methodKey,
        amount: total,
        bankNumber: _opt(bankCtrl.text),
        branchNumber: _opt(branchCtrl.text),
        accountNumber: _opt(accountCtrl.text),
        chequeNumber: _opt(chequeCtrl.text),
        dueDate: methodKey == PaymentMethodKeys.cash ? null : due,
        clearingHouseCode: clearingHouseCode,
        cardName: _opt(cardNameCtrl.text),
        creditDealType: methodKey == PaymentMethodKeys.creditCard
            ? (installmentCount > 1 ? 2 : creditDealType)
            : 1,
      ),
    ];
  }

  String? _opt(String v) => v.trim().isEmpty ? null : v.trim();
}

/// Поля банка / המחאה / כרטיס אשראי для BKMV D120.
class PaymentDetailsForm extends StatelessWidget {
  final PaymentDetailsController controller;
  final double totalAmount;
  final DateTime defaultDueDate;
  final VoidCallback onChanged;

  const PaymentDetailsForm({
    super.key,
    required this.controller,
    required this.totalAmount,
    required this.defaultDueDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: c.methodKey,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodLabel,
            border: const OutlineInputBorder(),
          ),
          items: PaymentMethodKeys.all
              .map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(paymentMethodLabel(l10n, k)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              c.methodKey = v;
              onChanged();
            }
          },
        ),
        if (c.methodKey != PaymentMethodKeys.cash) ...[
          const SizedBox(height: 12),
          _dueDateTile(context, l10n),
        ],
        if (c.methodKey == PaymentMethodKeys.cheque ||
            c.methodKey == PaymentMethodKeys.bankTransfer) ...[
          const SizedBox(height: 12),
          Text(l10n.bankDetails, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _bankFields(l10n, c),
        ],
        if (c.methodKey == PaymentMethodKeys.cheque) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: c.chequeCtrl,
            decoration: InputDecoration(
              labelText: l10n.paymentChequeNumber,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
          ),
        ],
        if (c.methodKey == PaymentMethodKeys.creditCard) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: c.clearingHouseCode,
            decoration: InputDecoration(
              labelText: l10n.paymentClearingHouse,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.notSelected)),
              DropdownMenuItem(value: 1, child: Text(l10n.paymentClearingIsracard)),
              DropdownMenuItem(value: 2, child: Text(l10n.paymentClearingCal)),
              DropdownMenuItem(value: 3, child: Text(l10n.paymentClearingDiners)),
              DropdownMenuItem(value: 4, child: Text(l10n.paymentClearingAmex)),
              DropdownMenuItem(value: 6, child: Text(l10n.paymentClearingLeumi)),
            ],
            onChanged: (v) {
              c.clearingHouseCode = v;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: c.cardNameCtrl,
            decoration: InputDecoration(
              labelText: l10n.paymentCardName,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: c.installmentCount > 1 ? 2 : c.creditDealType,
                  decoration: InputDecoration(
                    labelText: l10n.paymentDealType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l10n.paymentDealRegular)),
                    DropdownMenuItem(
                        value: 2, child: Text(l10n.paymentDealInstallments)),
                    DropdownMenuItem(value: 3, child: Text(l10n.paymentDealCredit)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    c.creditDealType = v;
                    if (v != 2) c.installmentCount = 1;
                    onChanged();
                  },
                ),
              ),
              if (c.creditDealType == 2) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<int>(
                    value: c.installmentCount < 2 ? 2 : c.installmentCount,
                    decoration: InputDecoration(
                      labelText: l10n.paymentInstallmentCount,
                      border: const OutlineInputBorder(),
                    ),
                    items: [2, 3, 4, 6, 9, 12, 18, 24, 36]
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        c.installmentCount = v;
                        c.creditDealType = 2;
                        onChanged();
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _dueDateTile(BuildContext context, AppLocalizations l10n) {
    final due = controller.dueDate ?? defaultDueDate;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.paymentDueDateLabel),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(due)),
      trailing: const Icon(Icons.calendar_today, size: 20),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: due,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (picked != null) {
          controller.dueDate = picked;
          onChanged();
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }

  Widget _bankFields(AppLocalizations l10n, PaymentDetailsController c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: c.bankCtrl,
                decoration: InputDecoration(
                  labelText: l10n.paymentBankNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: c.branchCtrl,
                decoration: InputDecoration(
                  labelText: l10n.paymentBranchNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c.accountCtrl,
          decoration: InputDecoration(
            labelText: l10n.paymentAccountNumber,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
