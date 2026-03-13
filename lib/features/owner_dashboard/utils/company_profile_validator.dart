/// Утилита валидации профиля компании.
///
/// Проверяет обязательные поля перед сохранением профиля.
/// Возвращает `Map<String, String>` с ошибками (поле → сообщение).
/// Пустая карта означает, что валидация пройдена.
class CompanyProfileValidator {
  /// Валидирует профиль компании.
  ///
  /// [nameHebrew] — название компании на иврите (обязательное).
  /// [taxId] — ח.פ. / идентификационный номер (обязательное, 9 цифр, Luhn).
  ///
  /// Возвращает карту ошибок: ключ — имя поля, значение — сообщение об ошибке.
  /// Если карта пуста — валидация пройдена.
  static Map<String, String> validate({
    required String nameHebrew,
    required String taxId,
  }) {
    final errors = <String, String>{};

    if (nameHebrew.trim().isEmpty) {
      errors['nameHebrew'] = 'שם החברה בעברית הוא שדה חובה';
    }

    final taxIdError = validateIsraeliTaxId(taxId);
    if (taxIdError != null) {
      errors['taxId'] = taxIdError;
    }

    return errors;
  }

  /// Валидация израильского ח.פ. (Corporate Number).
  ///
  /// Правила:
  /// - Ровно 9 цифр (допускается ведущий ноль, дополняется слева нулями)
  /// - Контрольная цифра по алгоритму Luhn (mod 10)
  ///
  /// Возвращает сообщение об ошибке или `null` если валидно.
  static String? validateIsraeliTaxId(String taxId) {
    final cleaned = taxId.trim().replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.isEmpty) {
      return 'ח.פ. הוא שדה חובה';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'ח.פ. חייב להכיל ספרות בלבד';
    }

    if (cleaned.length > 9) {
      return 'ח.פ. חייב להכיל עד 9 ספרות';
    }

    // Дополняем до 9 цифр ведущими нулями
    final padded = cleaned.padLeft(9, '0');

    // Luhn mod 10 (Israeli variant)
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      var digit = int.parse(padded[i]);
      // Чётные позиции (0-indexed) умножаем на 1, нечётные на 2
      if (i % 2 != 0) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }

    if (sum % 10 != 0) {
      return 'ח.פ. לא תקין — ספרת ביקורת שגויה';
    }

    return null;
  }
}
