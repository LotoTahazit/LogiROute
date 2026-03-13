/// Хелпер для валидации данных
class ValidationHelper {
  /// Проверка email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Проверка телефона (израильский формат)
  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Израильские номера: 10 цифр, начинаются с 0
    return cleanPhone.length == 10 && cleanPhone.startsWith('0');
  }

  /// Проверка координат
  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= -90 && lat <= 90;
  }

  static bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng >= -180 && lng <= 180;
  }

  /// Проверка положительного числа
  static bool isPositiveNumber(String value) {
    final number = double.tryParse(value);
    return number != null && number > 0;
  }

  /// Проверка целого положительного числа
  static bool isPositiveInteger(String value) {
    final number = int.tryParse(value);
    return number != null && number > 0;
  }

  /// Проверка непустой строки
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Проверка минимальной длины
  static bool hasMinLength(String value, int minLength) {
    return value.trim().length >= minLength;
  }

  /// Проверка максимальной длины
  static bool hasMaxLength(String value, int maxLength) {
    return value.trim().length <= maxLength;
  }

  /// Проверка диапазона чисел
  static bool isInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  /// Форматирование телефона (израильский формат)
  static String formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      // 0XX-XXX-XXXX
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    }
    return phone;
  }

  /// Очистка телефона (только цифры)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}
