/// Результат операции импорта шаблонов товаров.
/// Содержит счётчики добавленных, пропущенных и ошибочных товаров.
class ImportResult {
  final int addedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errorProductNames;

  ImportResult({
    required this.addedCount,
    required this.skippedCount,
    required this.errorCount,
    this.errorProductNames = const [],
  });

  /// Общее количество обработанных товаров.
  int get total => addedCount + skippedCount + errorCount;

  /// Форматированная строка итогов в формате:
  /// "נוספו X | דולגו Y כפילויות | שגיאות Z"
  String get summaryString =>
      'נוספו $addedCount | דולגו $skippedCount כפילויות | שגיאות $errorCount';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportResult &&
          runtimeType == other.runtimeType &&
          addedCount == other.addedCount &&
          skippedCount == other.skippedCount &&
          errorCount == other.errorCount &&
          _listEquals(errorProductNames, other.errorProductNames);

  @override
  int get hashCode => Object.hash(
        addedCount,
        skippedCount,
        errorCount,
        Object.hashAll(errorProductNames),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'ImportResult(added: $addedCount, skipped: $skippedCount, errors: $errorCount)';
}
