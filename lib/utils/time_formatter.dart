/// Utility for formatting time durations and ETA
/// Used for ETA and other timestamps
class TimeFormatter {
  /// Formats minutes into a duration string
  ///
  /// Examples:
  /// - 45 minutes → "45 m"
  /// - 90 minutes → "1 h 30 m"
  /// - 120 minutes → "2 h"
  static String formatDuration(double minutes,
      {String hourSuffix = 'h', String minuteSuffix = 'm'}) {
    if (minutes < 60) {
      return '${minutes.round()} $minuteSuffix';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = (minutes % 60).round();

      if (remainingMinutes > 0) {
        return '$hours $hourSuffix $remainingMinutes $minuteSuffix';
      } else {
        return '$hours $hourSuffix';
      }
    }
  }

  /// Formats seconds into a duration string
  static String formatDurationFromSeconds(int seconds) {
    return formatDuration(seconds / 60);
  }

  /// Formats ETA as absolute arrival time
  /// Shift starts at 07:00, cumulative calculation
  /// Returns: "08:45 (1 h 45 m)"
  static String formatArrivalTime(double cumulativeMinutes,
      {int shiftStartHour = 7, int shiftStartMinute = 0}) {
    final totalMinutes =
        shiftStartHour * 60 + shiftStartMinute + cumulativeMinutes;
    final hours = (totalMinutes ~/ 60) % 24;
    final mins = (totalMinutes % 60).round();
    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    final durationStr = formatDuration(cumulativeMinutes);
    return '$timeStr ($durationStr)';
  }
}
