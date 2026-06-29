import 'dart:math' as math;

import '../config/app_config.dart';
import '../models/delivery_point.dart';
/// Результат выбора точки для автозакрытия по GPS.
class DriverAutoCloseTarget {
  final DeliveryPoint point;
  final double distanceMeters;

  const DriverAutoCloseTarget({
    required this.point,
    required this.distanceMeters,
  });
}

/// Допускается ли точка для автозакрытия (без учёта расстояния).
bool isDriverAutoCloseEligible(
  DeliveryPoint point, {
  required String driverId,
  Set<String> disabledPointIds = const {},
}) {
  if (driverId.isEmpty) return false;
  if (point.driverId != null && point.driverId != driverId) return false;
  if (!point.hasValidCoordinates) return false;
  if (disabledPointIds.contains(point.id)) return false;

  final status = DeliveryPoint.normalizeStatus(point.status);
  if (status == DeliveryPoint.statusCompleted ||
      status == DeliveryPoint.statusCancelled) {
    return false;
  }
  return status == DeliveryPoint.statusAssigned ||
      status == DeliveryPoint.statusInProgress;
}

/// Расстояние в метрах (haversine).
double driverAutoCloseDistanceMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Ближайшая подходящая точка внутри [enterRadiusM]. Порядок маршрута не учитывается.
DriverAutoCloseTarget? selectNearestDriverAutoCloseTarget({
  required double driverLat,
  required double driverLng,
  required List<DeliveryPoint> points,
  required String driverId,
  Set<String> disabledPointIds = const {},
  double enterRadiusM = AppConfig.autoCompleteRadius,
}) {
  DriverAutoCloseTarget? best;
  for (final p in points) {
    if (!isDriverAutoCloseEligible(
      p,
      driverId: driverId,
      disabledPointIds: disabledPointIds,
    )) {
      continue;
    }
    final d = driverAutoCloseDistanceMeters(
      driverLat,
      driverLng,
      p.latitude,
      p.longitude,
    );
    if (d <= enterRadiusM && (best == null || d < best.distanceMeters)) {
      best = DriverAutoCloseTarget(point: p, distanceMeters: d);
    }
  }
  return best;
}

/// Вышел из зоны — сброс таймера (гистерезис против GPS-дрожания).
bool shouldResetDriverAutoCloseTimer({
  required double distanceMeters,
  double resetRadiusM = AppConfig.autoCompleteResetRadius,
}) =>
    distanceMeters > resetRadiusM;

/// Секунд до автозакрытия (0 = пора закрывать).
int driverAutoCloseRemainingSeconds(
  DateTime startedAt,
  DateTime now, {
  Duration waitDuration = AppConfig.autoCompleteDuration,
}) {
  final elapsed = now.difference(startedAt);
  final left = waitDuration.inSeconds - elapsed.inSeconds;
  return left > 0 ? left : 0;
}

bool driverAutoCloseWaitComplete(
  DateTime startedAt,
  DateTime now, {
  Duration waitDuration = AppConfig.autoCompleteDuration,
}) =>
    now.difference(startedAt) >= waitDuration;
