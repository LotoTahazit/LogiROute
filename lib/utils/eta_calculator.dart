import 'dart:math';
import '../models/delivery_point.dart';

/// Локальный пересчёт ETA на клиенте — без Firestore/OSRM запросов.
/// Используется и водителем, и диспетчером.
///
/// Логика: если есть завершённые точки — ETA считается от последнего
/// фактического completedAt. Если нет — от планового 07:00.
class EtaCalculator {
  static const double _avgSpeedKmh = 38.0;
  static const double _serviceMin = 7.0;
  static const double _parkingMin = 2.0;

  /// Пересчитывает ETA для всех активных точек на основе фактического прогресса.
  /// Возвращает Map<pointId, etaString>.
  /// 0 запросов — чистая математика в памяти.
  static Map<String, String> recalculate(List<DeliveryPoint> allPoints) {
    if (allPoints.isEmpty) return {};

    final sorted = List<DeliveryPoint>.from(allPoints)
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    // Находим последнюю завершённую точку (по orderInRoute)
    DeliveryPoint? lastCompleted;
    for (final p in sorted.reversed) {
      if (p.status == DeliveryPoint.statusCompleted && p.completedAt != null) {
        lastCompleted = p;
        break;
      }
    }

    // Базовое время: от completedAt последней завершённой или от 07:00
    double baseMinutes;
    double prevLat;
    double prevLng;

    if (lastCompleted != null) {
      final ct = lastCompleted.completedAt!;
      baseMinutes = ct.hour * 60.0 + ct.minute - 420; // 420 = 7*60
      if (baseMinutes < 0) baseMinutes = 0;
      prevLat = lastCompleted.latitude;
      prevLng = lastCompleted.longitude;
    } else {
      baseMinutes = 0;
      prevLat = 32.48698; // склад
      prevLng = 34.982121;
    }

    final result = <String, String>{};
    double cumMin = baseMinutes;

    for (final point in sorted) {
      if (point.status == DeliveryPoint.statusCompleted ||
          point.status == DeliveryPoint.statusCancelled) {
        continue;
      }

      final distKm =
          _haversineKm(prevLat, prevLng, point.latitude, point.longitude);
      final driveMin = (distKm / _avgSpeedKmh) * 60;
      cumMin += driveMin + _serviceMin + _parkingMin;

      result[point.id] = _formatEta(cumMin);

      prevLat = point.latitude;
      prevLng = point.longitude;
    }

    return result;
  }

  static String _formatEta(double minutesFrom7) {
    final totalMin = minutesFrom7.round();
    final h = (7 + totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    final timeStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    if (totalMin >= 60) {
      return '$timeStr (${totalMin ~/ 60} h $m m)';
    }
    return '$timeStr ($totalMin m)';
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
