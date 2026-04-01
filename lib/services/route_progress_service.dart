import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/gps_utils.dart';

/// Сервис для проверки прогресса движения водителя по маршруту
class RouteProgressService {
  /// Вычисляет расстояние от водителя до ближайшей точки маршрута
  ///
  /// [driver] - текущая позиция водителя
  /// [polyline] - список точек маршрута
  ///
  /// Возвращает расстояние в метрах до ближайшей точки маршрута
  static double distanceToRoute(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) {
      return double.infinity;
    }

    if (polyline.length == 1) {
      // Если маршрут из одной точки, считаем расстояние до неё
      return GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        polyline.first.latitude,
        polyline.first.longitude,
      );
    }

    double minDistance = double.infinity;

    // Ищем ближайшую точку на polyline
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];

      // Находим ближайшую точку на отрезке [segmentStart, segmentEnd]
      final closestPoint = _findClosestPointOnSegment(
        driver,
        segmentStart,
        segmentEnd,
      );

      final distance = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        closestPoint.latitude,
        closestPoint.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Находит ближайшую точку на отрезке между двумя точками
  static LatLng _findClosestPointOnSegment(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    // Equirectangular projection: приводим к плоским координатам
    // с поправкой cos(lat) для долготы. Для Израиля погрешность <0.1%.
    final midLat = (segmentStart.latitude + segmentEnd.latitude) / 2.0;
    final cosLat = cos(midLat * pi / 180.0);

    // Плоские координаты (в условных единицах, пропорциональных метрам)
    final x1 = segmentStart.longitude * cosLat;
    final y1 = segmentStart.latitude;
    final x2 = segmentEnd.longitude * cosLat;
    final y2 = segmentEnd.latitude;
    final x3 = point.longitude * cosLat;
    final y3 = point.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    // Если отрезок вырожден в точку
    if (dx.abs() < 1e-12 && dy.abs() < 1e-12) {
      return segmentStart;
    }

    // Параметр t для проекции точки на отрезок (0 <= t <= 1)
    final t = ((x3 - x1) * dx + (y3 - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    // Интерполируем в исходных градусах (не в плоских координатах)
    final closestLat = segmentStart.latitude +
        clampedT * (segmentEnd.latitude - segmentStart.latitude);
    final closestLng = segmentStart.longitude +
        clampedT * (segmentEnd.longitude - segmentStart.longitude);

    return LatLng(closestLat, closestLng);
  }

  /// Проверяет, находится ли водитель на маршруте
  ///
  /// [driver] - позиция водителя
  /// [polyline] - точки маршрута
  /// [maxDistanceMeters] - максимальное расстояние (по умолчанию 50м)
  ///
  /// Возвращает true если водитель в пределах maxDistanceMeters от маршрута
  static bool isDriverOnRoute(
    LatLng driver,
    List<LatLng> polyline, {
    double maxDistanceMeters = 50.0,
  }) {
    final distance = distanceToRoute(driver, polyline);
    return distance <= maxDistanceMeters;
  }

  /// Вычисляет прогресс движения по маршруту (0.0 - 1.0)
  ///
  /// [driver] - позиция водителя
  /// [polyline] - точки маршрута
  ///
  /// Возвращает 0.0 если водитель не на маршруте,
  /// 1.0 если достиг конца маршрута
  static double calculateRouteProgress(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return 0.0;
    if (polyline.length == 1) return 1.0;

    // Находим ближайший сегмент и точку на нем
    double minDistance = double.infinity;
    int closestSegmentIndex = 0;
    LatLng closestPoint = polyline.first;

    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];

      final pointOnSegment = _findClosestPointOnSegment(
        driver,
        segmentStart,
        segmentEnd,
      );

      final distance = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        pointOnSegment.latitude,
        pointOnSegment.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
        closestPoint = pointOnSegment;
      }
    }

    // Если водитель далеко от маршрута, прогресс 0
    if (minDistance > 100.0) {
      return 0.0;
    }

    // Вычисляем длину пройденного пути
    double traveledDistance = 0.0;

    // Расстояние от начала маршрута до начала ближайшего сегмента
    for (int i = 0; i < closestSegmentIndex; i++) {
      traveledDistance += GpsUtils.distanceMeters(
        polyline[i].latitude,
        polyline[i].longitude,
        polyline[i + 1].latitude,
        polyline[i + 1].longitude,
      );
    }

    // Расстояние от начала ближайшего сегмента до ближайшей точки
    traveledDistance += GpsUtils.distanceMeters(
      polyline[closestSegmentIndex].latitude,
      polyline[closestSegmentIndex].longitude,
      closestPoint.latitude,
      closestPoint.longitude,
    );

    // Общая длина маршрута
    double totalDistance = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDistance += GpsUtils.distanceMeters(
        polyline[i].latitude,
        polyline[i].longitude,
        polyline[i + 1].latitude,
        polyline[i + 1].longitude,
      );
    }

    if (totalDistance == 0) return 0.0;

    return (traveledDistance / totalDistance).clamp(0.0, 1.0);
  }

  /// Находит ближайший индекс точки в polyline к позиции водителя
  static int findClosestPointIndex(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return -1;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < polyline.length; i++) {
      final distance = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        polyline[i].latitude,
        polyline[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Находит индекс ближайшей точки polyline к позиции водителя
  /// Учитывает не только точки, но и отрезки между ними
  ///
  /// [driver] - текущая позиция водителя
  /// [polyline] - список точек маршрута
  ///
  /// Возвращает индекс ближайшей точки в polyline
  static int findNearestPolylineIndex(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return -1;
    if (polyline.length == 1) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    // Проверяем каждую точку polyline
    for (int i = 0; i < polyline.length; i++) {
      final distance = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        polyline[i].latitude,
        polyline[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Дополнительно проверяем отрезки между точками
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];

      // Находим ближайшую точку на отрезке
      final closestPointOnSegment = _findClosestPointOnSegment(
        driver,
        segmentStart,
        segmentEnd,
      );

      final distanceToSegment = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        closestPointOnSegment.latitude,
        closestPointOnSegment.longitude,
      );

      // Если ближайшая точка на отрезке ближе, чем ближайшая вершина
      if (distanceToSegment < minDistance) {
        minDistance = distanceToSegment;

        // Определяем, какой индекс выбрать (начало или конец отрезка)
        final distToStart = GpsUtils.distanceMeters(
          driver.latitude,
          driver.longitude,
          segmentStart.latitude,
          segmentStart.longitude,
        );

        final distToEnd = GpsUtils.distanceMeters(
          driver.latitude,
          driver.longitude,
          segmentEnd.latitude,
          segmentEnd.longitude,
        );

        // Выбираем ближайший конец отрезка
        closestIndex = distToStart <= distToEnd ? i : i + 1;
      }
    }

    return closestIndex;
  }

  /// Находит ближайшую точку polyline с расстоянием
  /// Возвращает Map с индексом и расстоянием
  static Map<String, dynamic> findNearestPolylinePoint(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    final index = findNearestPolylineIndex(driver, polyline);

    if (index == -1) {
      return {
        'index': -1,
        'point': null,
        'distance': double.infinity,
      };
    }

    final point = polyline[index];
    final distance = GpsUtils.distanceMeters(
      driver.latitude,
      driver.longitude,
      point.latitude,
      point.longitude,
    );

    return {
      'index': index,
      'point': point,
      'distance': distance,
    };
  }

  /// Разделяет маршрут на пройденную и оставшуюся части
  ///
  /// [polyline] - полный маршрут
  /// [splitIndex] - индекс разделения
  ///
  /// Возвращает Map с двумя частями маршрута
  static Map<String, List<LatLng>> splitRouteAtIndex(
    List<LatLng> polyline,
    int splitIndex,
  ) {
    if (polyline.isEmpty) {
      return {
        'passedRoute': [],
        'remainingRoute': [],
      };
    }

    if (splitIndex < 0) {
      // Если индекс отрицательный, весь маршрут считается оставшимся
      return {
        'passedRoute': [],
        'remainingRoute': polyline,
      };
    }

    if (splitIndex >= polyline.length) {
      // Если индекс за пределами, весь маршрут считается пройденным
      return {
        'passedRoute': polyline,
        'remainingRoute': [],
      };
    }

    // Разделяем маршрут на две части
    final passedRoute = polyline.sublist(0, splitIndex);
    final remainingRoute = polyline.sublist(splitIndex);

    return {
      'passedRoute': passedRoute,
      'remainingRoute': remainingRoute,
    };
  }

  /// Разделяет маршрут на основе позиции водителя
  /// Находит ближайший индекс и разделяет маршрут
  ///
  /// [driver] - позиция водителя
  /// [polyline] - полный маршрут
  ///
  /// Возвращает Map с частями маршрута и метаданными
  static Map<String, dynamic> splitRouteAtDriverPosition(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    final nearestPoint = findNearestPolylinePoint(driver, polyline);
    final splitIndex = nearestPoint['index'] as int;

    final routeParts = splitRouteAtIndex(polyline, splitIndex);
    var remaining = List<LatLng>.from(
      routeParts['remainingRoute'] as List<LatLng>,
    );
    // Линия «остатка» начинается с GPS водителя, иначе визуально отрывается от метки
    if (remaining.isNotEmpty) {
      final d = GpsUtils.distanceMeters(
        driver.latitude,
        driver.longitude,
        remaining.first.latitude,
        remaining.first.longitude,
      );
      remaining = d > 4
          ? <LatLng>[driver, ...remaining]
          : <LatLng>[driver, ...remaining.skip(1)];
    }

    // Добавляем метаданные
    return {
      'splitIndex': splitIndex,
      'nearestPoint': nearestPoint['point'],
      'distanceToNearest': nearestPoint['distance'],
      'passedRoute': routeParts['passedRoute'],
      'remainingRoute': remaining,
      'passedPointsCount': (routeParts['passedRoute'] as List<LatLng>).length,
      'remainingPointsCount':
          (routeParts['remainingRoute'] as List<LatLng>).length,
      'totalPointsCount': polyline.length,
      'passedPercentage': polyline.isNotEmpty
          ? (splitIndex / polyline.length * 100).round()
          : 0.0,
    };
  }

  /// Получает следующую точку маршрута для водителя
  ///
  /// [driver] - позиция водителя
  /// [polyline] - полный маршрут
  /// [lookAheadPoints] - сколько следующих точек вернуть (по умолчанию 1)
  ///
  /// Возвращает список следующих точек
  static List<LatLng> getNextRoutePoints(
    LatLng driver,
    List<LatLng> polyline, {
    int lookAheadPoints = 1,
  }) {
    final splitResult = splitRouteAtDriverPosition(driver, polyline);
    final remainingRoute = splitResult['remainingRoute'] as List<LatLng>;

    if (remainingRoute.isEmpty) return [];

    // Возвращаем следующие N точек (или меньше, если маршрута заканчивается)
    final endIndex = (lookAheadPoints < remainingRoute.length)
        ? lookAheadPoints
        : remainingRoute.length;

    return remainingRoute.sublist(0, endIndex);
  }

  /// Получает пройденные точки маршрута
  ///
  /// [driver] - позиция водителя
  /// [polyline] - полный маршрут
  ///
  /// Возвращает список пройденных точек
  static List<LatLng> getPassedRoutePoints(
    LatLng driver,
    List<LatLng> polyline,
  ) {
    final splitResult = splitRouteAtDriverPosition(driver, polyline);
    return splitResult['passedRoute'] as List<LatLng>;
  }
}
