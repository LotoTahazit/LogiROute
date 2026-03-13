import 'package:logiroute/features/owner_dashboard/models/accounting_doc.dart';

/// Допустимые переходы статусов бухгалтерского документа.
///
/// Машина состояний:
///   draft → issued
///   draft → voided_before_delivery
///   issued → credited
///   issued → locked
///   locked → credited
///
/// Запрещено:
///   любой → draft
///   voided_before_delivery → любой
///   credited → любой
const Map<AccountingDocStatus, Set<AccountingDocStatus>> _allowedTransitions = {
  AccountingDocStatus.draft: {
    AccountingDocStatus.issued,
    AccountingDocStatus.voidedBeforeDelivery,
  },
  AccountingDocStatus.issued: {
    AccountingDocStatus.credited,
    AccountingDocStatus.locked,
  },
  AccountingDocStatus.locked: {
    AccountingDocStatus.credited,
  },
  AccountingDocStatus.credited: {},
  AccountingDocStatus.voidedBeforeDelivery: {},
};

/// Проверяет, допустим ли переход из статуса [from] в статус [to].
bool canTransition(AccountingDocStatus from, AccountingDocStatus to) {
  final allowed = _allowedTransitions[from];
  if (allowed == null) return false;
  return allowed.contains(to);
}
