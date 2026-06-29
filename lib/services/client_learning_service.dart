import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_paths.dart';

/// Самообучение клиентских данных на основе реальных доставок.
/// 1. navigation_point — реальная точка подъезда (GPS водителя при доставке)
/// 2. service_time — реальное время разгрузки (arrivedAt → completedAt)
class ClientLearningService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ClientLearningService({required this.companyId});

  /// Минимум доставок для обновления клиента
  static const int minDeliveries = 5;

  /// Ссылка на коллекцию клиентов
  CollectionReference<Map<String, dynamic>> _clientsCollection() {
    return FirestorePaths(firestore: _firestore).clients(companyId);
  }

  /// Вызывается при завершении доставки.
  /// Сохраняет GPS водителя и время обслуживания в историю клиента.
  Future<void> recordDelivery({
    required String clientNumber,
    required double driverLat,
    required double driverLng,
    DateTime? arrivedAt,
    DateTime? completedAt,
  }) async {
    if (clientNumber.isEmpty) return;
    if (driverLat == 0 && driverLng == 0) return;

    try {
      // Находим клиента по номеру
      final clientSnap = await _clientsCollection()
          .where('clientNumber', isEqualTo: clientNumber)
          .limit(1)
          .get();

      if (clientSnap.docs.isEmpty) return;

      final clientDoc = clientSnap.docs.first;
      final clientId = clientDoc.id;

      // Рассчитываем service_time (секунды)
      int? serviceTimeSec;
      if (arrivedAt != null && completedAt != null) {
        serviceTimeSec = completedAt.difference(arrivedAt).inSeconds;
        // Фильтруем аномалии: < 1 мин или > 60 мин
        if (serviceTimeSec < 60 || serviceTimeSec > 3600) {
          serviceTimeSec = null;
        }
      }

      // Сохраняем в историю доставок клиента
      await clientDoc.reference.collection('delivery_history').add({
        'deliveryLat': driverLat,
        'deliveryLng': driverLng,
        if (serviceTimeSec != null) 'serviceTimeSec': serviceTimeSec,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '📍 [Learning] Recorded delivery for client $clientNumber: '
        'GPS=($driverLat, $driverLng), service=${serviceTimeSec}s',
      );

      // Проверяем, достаточно ли данных для обучения
      await _tryUpdateClient(clientId, clientDoc.reference);
    } catch (e) {
      debugPrint('❌ [Learning] Error recording delivery: $e');
    }
  }

  /// Проверяет историю и обновляет navigation_point + avgServiceTime
  Future<void> _tryUpdateClient(
    String clientId,
    DocumentReference<Map<String, dynamic>> clientRef,
  ) async {
    final historySnap = await clientRef
        .collection('delivery_history')
        .orderBy('timestamp', descending: true)
        .limit(20) // Последние 20 доставок
        .get();

    if (historySnap.docs.length < minDeliveries) return;

    // Считаем средний GPS (navigation_point)
    double sumLat = 0, sumLng = 0;
    int gpsCount = 0;
    final serviceTimes = <int>[];

    for (final doc in historySnap.docs) {
      final data = doc.data();
      final lat = (data['deliveryLat'] as num?)?.toDouble();
      final lng = (data['deliveryLng'] as num?)?.toDouble();
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        sumLat += lat;
        sumLng += lng;
        gpsCount++;
      }
      final st = data['serviceTimeSec'] as int?;
      if (st != null) {
        serviceTimes.add(st);
      }
    }

    final Map<String, dynamic> updates = {};

    // Обновляем navigation_point
    if (gpsCount >= minDeliveries) {
      updates['navigationLat'] = sumLat / gpsCount;
      updates['navigationLng'] = sumLng / gpsCount;
      debugPrint(
        '🎯 [Learning] Updated navigation_point for client $clientId: '
        '(${(sumLat / gpsCount).toStringAsFixed(6)}, ${(sumLng / gpsCount).toStringAsFixed(6)})',
      );
    }

    // Обновляем среднее время обслуживания
    if (serviceTimes.length >= minDeliveries) {
      // Медиана вместо среднего — устойчива к выбросам
      serviceTimes.sort();
      final median = serviceTimes[serviceTimes.length ~/ 2];
      final avgMinutes = (median / 60.0 * 10).round() / 10; // округляем до 0.1
      updates['avgServiceTimeMinutes'] = avgMinutes;
      debugPrint(
        '⏱️ [Learning] Updated avgServiceTime for client $clientId: ${avgMinutes}min',
      );
    }

    if (updates.isNotEmpty) {
      await clientRef.update(updates);
    }
  }
}
