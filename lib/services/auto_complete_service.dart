// lib/services/auto_complete_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_point.dart';
import '../config/app_config.dart';
import 'optimized_location_service.dart';
import 'firestore_paths.dart';

/// Сервис автоматического завершения точек доставки
/// Если водитель находится в радиусе 100м от точки и неподвижен 10 минут,
/// точка автоматически помечается как выполненная
class AutoCompleteService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final OptimizedLocationService _locationService;

  AutoCompleteService({required this.companyId})
      : _locationService = OptimizedLocationService(companyId);

  Timer? _checkTimer;
  Timer? _cleanupTimer;

  // Храним информацию о том, когда водитель прибыл к точке
  final Map<String, DateTime> _arrivalTimes = {}; // pointId -> время прибытия
  final Map<String, Map<String, dynamic>> _lastLocations =
      {}; // driverId -> {lat, lng, timestamp}

  static const int _checkIntervalSeconds = 60; // проверка каждую минуту
  static const int _cleanupIntervalMinutes = 60; // очистка истории каждый час
  static const int _historyRetentionHours =
      24; // хранить историю за последние 24 часа

  /// Запускает мониторинг автоматического завершения
  void startMonitoring() {
    debugPrint('🤖 [AutoComplete] Starting monitoring');

    // Останавливаем предыдущие таймеры если были
    _checkTimer?.cancel();
    _cleanupTimer?.cancel();

    // Запускаем периодическую проверку точек
    _checkTimer = Timer.periodic(
      const Duration(seconds: _checkIntervalSeconds),
      (_) => _checkPoints(),
    );

    // Запускаем периодическую очистку старой истории
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: _cleanupIntervalMinutes),
      (_) => _cleanupOldHistory(),
    );

    // Выполняем первую очистку сразу
    _cleanupOldHistory();
  }

  /// Останавливает мониторинг
  void stopMonitoring() {
    debugPrint('🤖 [AutoComplete] Stopping monitoring');
    _checkTimer?.cancel();
    _cleanupTimer?.cancel();
    _arrivalTimes.clear();
    _lastLocations.clear();
  }

  /// Проверяет все активные точки
  Future<void> _checkPoints() async {
    try {
      // Получаем все активные точки (assigned или in_progress)
      final pointsSnapshot = await FirestorePaths.deliveryPointsOf(companyId)
          .where('status', whereIn: ['assigned', 'in_progress']).get();

      if (pointsSnapshot.docs.isEmpty) {
        return;
      }

      // Получаем текущие локации всех водителей из stream (берем последнее значение)
      final driverLocationsStream =
          _locationService.getAllDriverLocationsStream();
      final driverLocations = await driverLocationsStream.first;

      // Обновляем информацию о локациях водителей
      for (final location in driverLocations) {
        final driverId = location['driverId'] as String;
        _lastLocations[driverId] = location;
      }

      // Проверяем каждую точку
      for (final doc in pointsSnapshot.docs) {
        final point = DeliveryPoint.fromMap(doc.data(), doc.id);

        if (point.driverId == null || point.driverId!.isEmpty) {
          continue;
        }

        // Получаем локацию водителя
        final driverLocation = _lastLocations[point.driverId];
        if (driverLocation == null) {
          continue;
        }

        // Проверяем расстояние до точки
        final distance = _calculateDistance(
          point.latitude,
          point.longitude,
          (driverLocation['latitude'] as num?)?.toDouble() ?? 0.0,
          (driverLocation['longitude'] as num?)?.toDouble() ?? 0.0,
        );

        if (distance <= AppConfig.autoCompleteRadius) {
          // Водитель рядом с точкой
          await _handleProximity(point, driverLocation);
        } else {
          // Водитель далеко - сбрасываем время прибытия
          if (_arrivalTimes.containsKey(point.id)) {
            debugPrint(
                '🤖 [AutoComplete] Driver left point ${point.clientName}, resetting timer');
            _arrivalTimes.remove(point.id);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [AutoComplete] Error checking points: $e');
    }
  }

  /// Обрабатывает ситуацию когда водитель рядом с точкой
  Future<void> _handleProximity(
    DeliveryPoint point,
    Map<String, dynamic> driverLocation,
  ) async {
    final pointId = point.id;
    final now = DateTime.now();

    // Проверяем, двигается ли водитель
    final isStationary = await _isDriverStationary(
      point.driverId!,
      driverLocation,
    );

    if (!isStationary) {
      // Водитель движется - сбрасываем таймер
      if (_arrivalTimes.containsKey(pointId)) {
        debugPrint(
            '🤖 [AutoComplete] Driver is moving near ${point.clientName}, resetting timer');
        _arrivalTimes.remove(pointId);
      }
      return;
    }

    // Водитель неподвижен рядом с точкой
    if (!_arrivalTimes.containsKey(pointId)) {
      // Первый раз обнаружили - запоминаем время
      _arrivalTimes[pointId] = now;
      debugPrint(
          '🤖 [AutoComplete] Driver arrived at ${point.clientName}, starting timer');
      return;
    }

    // Проверяем сколько времени прошло
    final arrivalTime = _arrivalTimes[pointId]!;
    final waitedMinutes = now.difference(arrivalTime).inMinutes;

    if (waitedMinutes >= AppConfig.autoCompleteDuration.inMinutes) {
      // Прошло достаточно времени - автоматически завершаем точку
      debugPrint(
          '🤖 [AutoComplete] Auto-completing point ${point.clientName} after $waitedMinutes minutes');
      await _completePoint(point);
      _arrivalTimes.remove(pointId);
    } else {
      debugPrint(
          '🤖 [AutoComplete] Driver at ${point.clientName} for $waitedMinutes/${AppConfig.autoCompleteDuration.inMinutes} minutes');
    }
  }

  /// Проверяет, неподвижен ли водитель
  Future<bool> _isDriverStationary(
    String driverId,
    Map<String, dynamic> currentLocation,
  ) async {
    // Быстрая проверка по скорости (если доступна)
    final speed = currentLocation['speed'];
    if (speed != null && speed is num && speed < 1.0) {
      return true; // Скорость < 1 м/с = стоит на месте
    }

    // Fallback: проверяем историю
    final locationsSnapshot = await FirestorePaths.driverLocationsOf(companyId)
        .doc(driverId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    if (locationsSnapshot.docs.isEmpty) {
      // Нет истории — считаем неподвижным если скорость не указана
      return true;
    }

    // Проверяем, не сдвинулся ли водитель больше чем на 50 метров
    final currentLat = (currentLocation['latitude'] as num?)?.toDouble() ?? 0.0;
    final currentLng =
        (currentLocation['longitude'] as num?)?.toDouble() ?? 0.0;

    for (final doc in locationsSnapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      final distance = _calculateDistance(currentLat, currentLng, lat, lng);
      if (distance > 50) {
        return false; // Водитель двигался
      }
    }

    return true; // Водитель неподвижен
  }

  /// Автоматически завершает точку
  Future<void> _completePoint(DeliveryPoint point) async {
    try {
      await FirestorePaths.deliveryPointsOf(companyId).doc(point.id).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'autoCompleted': true, // Помечаем что завершено автоматически
        'updatedByUid':
            point.driverId ?? '', // Аудит: кто обновил (водитель точки)
        'updatedAt': FieldValue.serverTimestamp(), // Аудит: когда обновлено
      });

      debugPrint('✅ [AutoComplete] Point ${point.clientName} auto-completed');
    } catch (e) {
      debugPrint('❌ [AutoComplete] Error completing point: $e');
    }
  }

  /// Вычисляет расстояние между двумя точками в метрах
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // метров

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Очищает старую историю локаций для экономии хранилища Firestore
  Future<void> _cleanupOldHistory() async {
    try {
      debugPrint('🧹 [AutoComplete] Starting history cleanup...');

      final cutoffTime = DateTime.now().subtract(
        const Duration(hours: _historyRetentionHours),
      );

      int totalDeleted = 0;

      // Очищаем историю для каждого водителя
      for (final driverId in _lastLocations.keys) {
        final oldDocs = await FirestorePaths.driverLocationsOf(companyId)
            .doc(driverId)
            .collection('history')
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffTime))
            .get();

        if (oldDocs.docs.isEmpty) continue;

        // Удаляем старые записи батчами (по 500 за раз для оптимизации)
        final batch = _firestore.batch();
        int batchCount = 0;

        for (final doc in oldDocs.docs) {
          batch.delete(doc.reference);
          batchCount++;

          // Firestore позволяет максимум 500 операций в одном batch
          if (batchCount >= 500) {
            await batch.commit();
            totalDeleted += batchCount;
            batchCount = 0;
          }
        }

        // Коммитим оставшиеся операции
        if (batchCount > 0) {
          await batch.commit();
          totalDeleted += batchCount;
        }
      }

      if (totalDeleted > 0) {
        debugPrint(
            '✅ [AutoComplete] Cleaned up $totalDeleted old location records');
      } else {
        debugPrint('✅ [AutoComplete] No old records to clean up');
      }
    } catch (e) {
      debugPrint('❌ [AutoComplete] Error cleaning up history: $e');
    }
  }

  void dispose() {
    stopMonitoring();
  }
}
