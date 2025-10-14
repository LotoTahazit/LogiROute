import 'dart:math' as math;
import '../config/app_config.dart';

class DistanceCalculator {
  /// Рассчитывает расстояние между двумя координатами в километрах
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = AppConfig.earthRadiusKm;

    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c;

    return distance.isNaN ? 0.0 : distance;
  }

  static double _toRadians(double degree) => degree * math.pi / 180;

  /// Форматирует расстояние в удобочитаемый вид
  static String formatDistance(double distanceInKm, {String? locale}) {
    if (distanceInKm.isNaN || distanceInKm.isInfinite) return '—';

    final isHebrew = locale == 'he';
    final isEnglish = locale == 'en';

    if (distanceInKm < 1) {
      final meters = (distanceInKm * 1000).toStringAsFixed(0);
      return isHebrew
          ? '$meters מ׳'
          : isEnglish
              ? '$meters m'
              : '$meters м';
    }

    final km = distanceInKm.toStringAsFixed(1);
    return isHebrew
        ? '$km ק״מ'
        : isEnglish
            ? '$km km'
            : '$km км';
  }

  /// Оценка времени поездки при средней скорости (по умолчанию 60 км/ч)
  static double estimateTimeInHours(double distanceKm, {double avgSpeed = 60}) {
    if (avgSpeed <= 0) return 0.0;
    return distanceKm / avgSpeed;
  }
}
