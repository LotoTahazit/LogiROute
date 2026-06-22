/// Проверка блокировки учётного периода (deliveryDate vs accountingLockedUntil).
class AccountingPeriodLock {
  AccountingPeriodLock._();

  /// Документ в закрытом периоде, если deliveryDate ≤ lockedUntil.
  static bool isLocked(DateTime docDate, DateTime lockedUntil) =>
      !docDate.isAfter(lockedUntil);

  /// Первая допустимая дата после границы закрытия.
  static DateTime firstOpenDate(DateTime lockedUntil) => DateTime(
        lockedUntil.year,
        lockedUntil.month,
        lockedUntil.day,
      ).add(const Duration(days: 1));

  static DateTime resolveOpenDate(DateTime preferred, DateTime? lockedUntil) {
    if (lockedUntil == null || preferred.isAfter(lockedUntil)) return preferred;
    return firstOpenDate(lockedUntil);
  }
}
