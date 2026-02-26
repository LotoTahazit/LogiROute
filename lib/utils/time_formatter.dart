/// Утилита для форматирования времени на иврите
/// Используется для ETA и других временных меток
class TimeFormatter {
  /// Форматирует время в минутах в строку на иврите
  ///
  /// Примеры:
  /// - 45 минут → "45 ד"
  /// - 90 минут → "1 ש 30 ד"
  /// - 120 минут → "2 ש"
  static String formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} ד'; // דקות (минуты)
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = (minutes % 60).round();

      if (remainingMinutes > 0) {
        return '$hours ש $remainingMinutes ד'; // שעות (часы) דקות (минуты)
      } else {
        return '$hours ש'; // שעות (часы)
      }
    }
  }

  /// Форматирует время в секундах в строку на иврите
  static String formatDurationFromSeconds(int seconds) {
    return formatDuration(seconds / 60);
  }
}
