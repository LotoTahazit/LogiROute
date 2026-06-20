import 'dart:math' as math;
import '../models/delivery_point.dart';
import '../config/app_config.dart';

/// Route optimization algorithms: nearest-neighbor with urgency priority,
/// distance calculation (Haversine), alternative route generation.
class RouteOptimizer {
  /// Параметры учёта временных окон (вариант 1: окна поверх 2-opt).
  static const double avgSpeedKmh = 30.0; // средняя городская скорость
  static const int serviceMinutes = 8; // время разгрузки у точки
  static const double _latePenaltyPerMin =
      0.5; // штраф (км-эквивалент) за минуту опоздания
  static const int defaultDepartureMinutes = 8 * 60; // плановый выезд 08:00

  /// Nearest-neighbor optimization with urgency priority
  static List<DeliveryPoint> optimizeRouteOrder(
    List<DeliveryPoint> points,
    Map<String, double>? driverLocation, {
    double? speedKmh,
    int? serviceMin,
    int? departureMin,
  }) {
    if (points.length <= 1) return points;

    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
      print('📍 [RouteOptimizer] Using driver location: ($baseLat, $baseLng)');
    } else {
      print(
          '📍 [RouteOptimizer] Using warehouse location: ($baseLat, $baseLng)');
    }

    // Split by priority
    final urgentPoints = points.where((p) => p.urgency == 'urgent').toList();
    final normalPoints = points.where((p) => p.urgency != 'urgent').toList();

    // Sort urgent by opening time then distance
    urgentPoints.sort((a, b) {
      if (a.openingTime != null && b.openingTime != null) {
        final timeCompare = a.openingTime!.compareTo(b.openingTime!);
        if (timeCompare != 0) return timeCompare;
      }
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    normalPoints.sort((a, b) {
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    // Nearest-neighbor with 20% urgency bonus
    final optimizedOrder = <DeliveryPoint>[];
    final remainingPoints =
        List<DeliveryPoint>.from([...urgentPoints, ...normalPoints]);

    double currentLat = baseLat;
    double currentLng = baseLng;

    while (remainingPoints.isNotEmpty) {
      DeliveryPoint? nextPoint;
      double minScore = double.infinity;
      int nextIndex = -1;

      for (int i = 0; i < remainingPoints.length; i++) {
        final p = remainingPoints[i];
        final dist =
            calculateDistance(currentLat, currentLng, p.latitude, p.longitude);
        final score = p.urgency == 'urgent' ? dist * 0.8 : dist;

        if (score < minScore) {
          minScore = score;
          nextPoint = p;
          nextIndex = i;
        }
      }

      if (nextPoint != null) {
        optimizedOrder.add(nextPoint);
        currentLat = nextPoint.latitude;
        currentLng = nextPoint.longitude;
        remainingPoints.removeAt(nextIndex);
      } else {
        break;
      }
    }

    // 2-opt improvement: пробуем менять пары рёбер пока есть улучшения.
    // Urgent точки зафиксированы в начале — 2-opt работает только с normal.
    final urgentCount =
        optimizedOrder.where((p) => p.urgency == 'urgent').length;
    // Если у точек заданы окна — оптимизируем по стоимости (дистанция + штраф
    // за опоздания). Иначе — прежний чисто дистанционный 2-opt (без регрессии).
    final hasWindows =
        points.any((p) => p.openingTime != null || p.closingTime != null);
    if (hasWindows) {
      _twoOptWindows(
        optimizedOrder,
        baseLat,
        baseLng,
        departureMin ?? defaultDepartureMinutes,
        speedKmh ?? avgSpeedKmh,
        serviceMin ?? serviceMinutes,
        fixedPrefix: urgentCount,
      );
    } else {
      _twoOpt(optimizedOrder, baseLat, baseLng, fixedPrefix: urgentCount);
    }

    print('🎯 [RouteOptimizer] Route optimization complete (NN + 2-opt):');
    for (int i = 0; i < optimizedOrder.length; i++) {
      final point = optimizedOrder[i];
      print(
          '  ${i + 1}. ${point.clientName} (${point.urgency == 'urgent' ? 'URGENT' : 'normal'})');
    }

    return optimizedOrder;
  }

  /// 2-opt local search: разворачивает подмаршруты пока есть улучшения.
  /// [fixedPrefix] — количество точек в начале которые нельзя двигать (urgent).
  /// Сложность: O(n² × iterations), для 50 точек <10ms.
  static void _twoOpt(
    List<DeliveryPoint> route,
    double startLat,
    double startLng, {
    int fixedPrefix = 0,
  }) {
    if (route.length - fixedPrefix <= 2) return;

    bool improved = true;
    int iterations = 0;
    const maxIterations = 50; // guard для больших маршрутов

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = fixedPrefix; i < route.length - 1; i++) {
        for (int j = i + 1; j < route.length; j++) {
          // Расстояние до точки i от предыдущей
          final prevLat = i == 0 ? startLat : route[i - 1].latitude;
          final prevLng = i == 0 ? startLng : route[i - 1].longitude;
          final afterJ = j + 1 < route.length ? route[j + 1] : null;

          // Текущие рёбра: prev→route[i] + route[j]→afterJ
          final currentDist = calculateDistance(
                  prevLat, prevLng, route[i].latitude, route[i].longitude) +
              (afterJ != null
                  ? calculateDistance(route[j].latitude, route[j].longitude,
                      afterJ.latitude, afterJ.longitude)
                  : 0.0);

          // После разворота: prev→route[j] + route[i]→afterJ
          final newDist = calculateDistance(
                  prevLat, prevLng, route[j].latitude, route[j].longitude) +
              (afterJ != null
                  ? calculateDistance(route[i].latitude, route[i].longitude,
                      afterJ.latitude, afterJ.longitude)
                  : 0.0);

          if (newDist < currentDist - 0.001) {
            // Разворачиваем подмаршрут [i..j]
            _reverseSublist(route, i, j);
            improved = true;
          }
        }
      }
    }

    if (iterations > 1) {
      print('🔄 [RouteOptimizer] 2-opt: $iterations iterations');
    }
  }

  /// Разворачивает подсписок route[i..j] на месте
  static void _reverseSublist(List<DeliveryPoint> route, int i, int j) {
    int left = i;
    int right = j;
    while (left < right) {
      final temp = route[left];
      route[left] = route[right];
      route[right] = temp;
      left++;
      right--;
    }
  }

  /// Alternative route: simple distance sort from base
  static List<DeliveryPoint> createAlternativeRoute(
      List<DeliveryPoint> points, Map<String, double>? driverLocation) {
    if (points.length <= 1) return points;

    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
    }

    final sortedPoints = List<DeliveryPoint>.from(points);
    sortedPoints.sort((a, b) {
      final distA =
          calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    print(
        '🔄 [RouteOptimizer] Alternative route created from ($baseLat, $baseLng)');
    return sortedPoints;
  }

  /// Haversine distance between two points (km)
  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return AppConfig.earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // ───────────────────────── Временные окна ─────────────────────────
  //
  // Окна и ETA считаются по ВРЕМЕНИ СУТОК (минуты от полуночи), а не по
  // абсолютной дате: маршрут может строиться на завтра или (чт→вс) на другой
  // день, но окно «09:00–12:00» одинаково. Дата доставки в расчёте не нужна.

  /// Минуты от полуночи (время суток) для DateTime.
  static int minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

  /// Время прибытия (минуты от полуночи) в каждую точку при данном порядке.
  /// [startMin] — время выезда; приехали раньше окна «с» — ждём открытия.
  static List<int> _arrivalMinutes(
    List<DeliveryPoint> order,
    double baseLat,
    double baseLng,
    int startMin,
    double speedKmh,
    int serviceMin,
  ) {
    final res = <int>[];
    double t = startMin.toDouble();
    double curLat = baseLat, curLng = baseLng;
    for (final p in order) {
      final km = calculateDistance(curLat, curLng, p.latitude, p.longitude);
      double arrive = t + km / speedKmh * 60.0;
      if (p.openingTime != null) {
        final openMin = minutesOfDay(p.openingTime!).toDouble();
        if (arrive < openMin) arrive = openMin; // ждём открытия окна «с»
      }
      res.add(arrive.round());
      t = arrive + serviceMin;
      curLat = p.latitude;
      curLng = p.longitude;
    }
    return res;
  }

  /// Суммарное опоздание (минуты) относительно окон «по».
  static double _latenessMinutes(
      List<DeliveryPoint> order, List<int> arrivals) {
    double total = 0;
    for (var i = 0; i < order.length; i++) {
      final c = order[i].closingTime;
      if (c != null) {
        final closeMin = minutesOfDay(c);
        if (arrivals[i] > closeMin) total += arrivals[i] - closeMin;
      }
    }
    return total;
  }

  static double _totalDistanceKm(
      List<DeliveryPoint> order, double baseLat, double baseLng) {
    double d = 0;
    double curLat = baseLat, curLng = baseLng;
    for (final p in order) {
      d += calculateDistance(curLat, curLng, p.latitude, p.longitude);
      curLat = p.latitude;
      curLng = p.longitude;
    }
    return d;
  }

  /// Стоимость порядка = дистанция (км) + штраф за опоздания по окнам.
  static double _routeCost(List<DeliveryPoint> order, double baseLat,
      double baseLng, int startMin, double speedKmh, int serviceMin) {
    final dist = _totalDistanceKm(order, baseLat, baseLng);
    final late = _latenessMinutes(order,
        _arrivalMinutes(order, baseLat, baseLng, startMin, speedKmh, serviceMin));
    return dist + _latePenaltyPerMin * late;
  }

  /// 2-opt по полной стоимости (дистанция + штраф за окна). Для малых n
  /// (≤ maxPointsPerRoute) полный пересчёт стоимости на ход допустим.
  static void _twoOptWindows(
    List<DeliveryPoint> route,
    double startLat,
    double startLng,
    int startMin,
    double speedKmh,
    int serviceMin, {
    int fixedPrefix = 0,
  }) {
    if (route.length - fixedPrefix <= 2) return;
    bool improved = true;
    int iterations = 0;
    const maxIterations = 50;
    double bestCost =
        _routeCost(route, startLat, startLng, startMin, speedKmh, serviceMin);
    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;
      for (int i = fixedPrefix; i < route.length - 1; i++) {
        for (int j = i + 1; j < route.length; j++) {
          _reverseSublist(route, i, j);
          final cost = _routeCost(
              route, startLat, startLng, startMin, speedKmh, serviceMin);
          if (cost < bestCost - 0.001) {
            bestCost = cost;
            improved = true;
          } else {
            _reverseSublist(route, i, j); // откат хода
          }
        }
      }
    }
  }

  /// Расписание для UI (опоздание по точкам).
  ///
  /// Плановый режим: [origin]=null (старт от склада), [startMinutes]=null →
  /// плановое время выезда [defaultDepartureMinutes].
  /// «Живой» режим: передай позицию водителя в [origin], текущее время суток
  /// в [startMinutes], а в [order] — оставшиеся (невыполненные) точки.
  /// [speedKmh]/[serviceMin] — параметры компании (по умолчанию — константы).
  static List<StopSchedule> routeSchedule(
    List<DeliveryPoint> order,
    Map<String, double>? origin, {
    int? startMinutes,
    double? speedKmh,
    int? serviceMin,
  }) {
    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;
    if (origin != null) {
      baseLat = origin['latitude']!;
      baseLng = origin['longitude']!;
    }
    final startMin = startMinutes ?? defaultDepartureMinutes;
    final arr = _arrivalMinutes(order, baseLat, baseLng, startMin,
        speedKmh ?? avgSpeedKmh, serviceMin ?? serviceMinutes);
    return [
      for (var i = 0; i < order.length; i++)
        StopSchedule(
          arrivalMinutes: arr[i],
          lateMinutes: (order[i].closingTime != null &&
                  arr[i] > minutesOfDay(order[i].closingTime!))
              ? arr[i] - minutesOfDay(order[i].closingTime!)
              : 0,
        ),
    ];
  }
}

/// Прогноз по точке: время прибытия (минуты от полуночи) и опоздание.
class StopSchedule {
  final int arrivalMinutes;
  final int lateMinutes;
  const StopSchedule(
      {required this.arrivalMinutes, required this.lateMinutes});
  bool get isLate => lateMinutes > 0;
}
