import 'dart:math';

/// Утилиты для работы с GPS координатами
class GpsUtils {
  /// Расстояние между двумя точками в метрах (Haversine formula)
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Радиус Земли в метрах
    final dLat = (lat2 - lat1) * 0.01745329252; // to radians
    final dLon = (lon2 - lon1) * 0.01745329252; // to radians

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * 0.01745329252) *
            cos(lat2 * 0.01745329252) *
            (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Проверяет, нужно ли обновлять позицию (фильтр дергания)
  /// Возвращает true если нужно обновить, false если игнорировать
  static bool shouldUpdatePosition(
    GpsLatLng? lastPosition,
    GpsLatLng newPosition, {
    double minDistanceMeters = 25.0,
  }) {
    if (lastPosition == null) {
      return true; // Первая позиция всегда принимается
    }

    final distance = distanceMeters(
      lastPosition.latitude,
      lastPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance >= minDistanceMeters;
  }

  /// Сглаживание GPS координат (простой скользящий фильтр)
  /// Усредняет последние N позиций для уменьшения шумов
  static GpsLatLng smoothPosition(List<GpsLatLng> positions,
      {int windowSize = 3}) {
    if (positions.isEmpty) {
      throw ArgumentError('Positions list cannot be empty');
    }

    if (positions.length == 1) {
      return positions.first;
    }

    // Берем последние windowSize позиций
    final recentPositions = positions.length > windowSize
        ? positions.sublist(positions.length - windowSize)
        : positions;

    final avgLat =
        recentPositions.map((p) => p.latitude).reduce((a, b) => a + b) /
            recentPositions.length;
    final avgLng =
        recentPositions.map((p) => p.longitude).reduce((a, b) => a + b) /
            recentPositions.length;

    return GpsLatLng(avgLat, avgLng);
  }

  /// Проверяет, находится ли точка в пределах радиуса от другой точки
  static bool isWithinRadius(
    GpsLatLng center,
    GpsLatLng point,
    double radiusMeters,
  ) {
    return distanceMeters(
          center.latitude,
          center.longitude,
          point.latitude,
          point.longitude,
        ) <=
        radiusMeters;
  }

  /// Вычисляет б bearing (направление) от точки A к точке B в градусах
  static double bearing(
    GpsLatLng from,
    GpsLatLng to,
  ) {
    final lat1 = from.latitude * 0.01745329252;
    final lat2 = to.latitude * 0.01745329252;
    final dLon = (to.longitude - from.longitude) * 0.01745329252;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearingRad = atan2(y, x);
    double bearingDeg = bearingRad * 57.29577951308232; // to degrees

    return (bearingDeg + 360) % 360; // Нормализация к 0-360
  }

  /// Вычисляет heading (направление движения) между двумя GPS позициями
  /// Используется для поворота маркера водителя в направлении движения
  static double calculateHeading(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = (lon2 - lon1) * 0.01745329252;

    final y = sin(dLon) * cos(lat2 * 0.01745329252);
    final x = cos(lat1 * 0.01745329252) * sin(lat2 * 0.01745329252) -
        sin(lat1 * 0.01745329252) * cos(lat2 * 0.01745329252) * cos(dLon);

    final bearing = atan2(y, x);

    return (bearing * 57.295779513 + 360) % 360;
  }

  /// Вычисляет скорость движения между двумя позициями (км/ч)
  static double calculateSpeed(
    GpsLatLng from,
    GpsLatLng to,
    int secondsBetween,
  ) {
    if (secondsBetween <= 0) return 0.0;

    final distanceKm = distanceMeters(
            from.latitude, from.longitude, to.latitude, to.longitude) /
        1000.0;
    final hours = secondsBetween / 3600.0;

    return distanceKm / hours;
  }
}

/// Простая модель GPS позиции
class GpsLatLng {
  final double latitude;
  final double longitude;

  const GpsLatLng(this.latitude, this.longitude);

  @override
  String toString() => 'GpsLatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsLatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
