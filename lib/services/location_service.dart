import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_point.dart';
import '../config/app_config.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;
  final Map<String, _PointTrackingData> _trackingData = {};
  String? _currentDriverId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> startTracking(
      String driverId, Function(double, double) onLocationUpdate) async {
    _currentDriverId = driverId;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.locationDistanceFilter,
      ),
    ).listen((Position position) {
      // Обновляем позицию водителя в Firestore в реальном времени
      _updateDriverLocation(position.latitude, position.longitude);

      // Вызываем callback для локального обновления
      onLocationUpdate(position.latitude, position.longitude);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _trackingData.clear();
  }

  void checkPointCompletion(
    DeliveryPoint point,
    double currentLat,
    double currentLon,
    Function(DeliveryPoint) onComplete,
  ) {
    if (point.status == DeliveryPoint.statusCompleted ||
        point.status == DeliveryPoint.statusCancelled) {
      return;
    }

    final distance = Geolocator.distanceBetween(
      currentLat,
      currentLon,
      point.latitude,
      point.longitude,
    );

    if (distance <= AppConfig.autoCompleteRadius) {
      final trackingData = _trackingData.putIfAbsent(
        point.id,
        () => _PointTrackingData(arrivedAt: DateTime.now()),
      );

      final duration = DateTime.now().difference(trackingData.arrivedAt);
      final remainingSeconds =
          AppConfig.autoCompleteDuration.inSeconds - duration.inSeconds;

      debugPrint(
          '🎯 [AutoComplete] Distance: ${distance.toStringAsFixed(1)}m, Time: ${duration.inSeconds}s/${AppConfig.autoCompleteDuration.inSeconds}s, Remaining: ${remainingSeconds}s');

      if (duration >= AppConfig.autoCompleteDuration &&
          !trackingData.completed) {
        trackingData.completed = true;
        debugPrint(
            '✅ [AutoComplete] Point "${point.clientName}" auto-completed!');
        onComplete(point);
      }
    } else {
      if (_trackingData.containsKey(point.id)) {
        debugPrint(
            '⚠️ [AutoComplete] Driver moved away from "${point.clientName}" (${distance.toStringAsFixed(1)}m), resetting timer');
        _trackingData.remove(point.id);
      }
    }
  }

  /// Получает информацию о прогрессе автозакрытия точки
  Map<String, dynamic>? getAutoCompleteProgress(String pointId) {
    final trackingData = _trackingData[pointId];
    if (trackingData == null) return null;

    final duration = DateTime.now().difference(trackingData.arrivedAt);
    final totalSeconds = AppConfig.autoCompleteDuration.inSeconds;
    final remainingSeconds = totalSeconds - duration.inSeconds;
    final progress = (duration.inSeconds / totalSeconds).clamp(0.0, 1.0);

    return {
      'arrivedAt': trackingData.arrivedAt,
      'duration': duration,
      'remainingSeconds': remainingSeconds > 0 ? remainingSeconds : 0,
      'progress': progress,
      'isCompleting': remainingSeconds <= 0,
    };
  }

  /// Обновляет позицию водителя в Firestore в реальном времени
  Future<void> _updateDriverLocation(double latitude, double longitude) async {
    if (_currentDriverId == null) return;

    try {
      final timestamp = FieldValue.serverTimestamp();

      // Обновляем текущую позицию
      await _firestore
          .collection('driver_locations')
          .doc(_currentDriverId)
          .set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'accuracy': 5.0, // Высокая точность GPS
        'speed': 0.0, // Можно добавить скорость если нужно
      }, SetOptions(merge: true));

      // Сохраняем в историю для автоматического завершения точек
      await _firestore
          .collection('driver_locations')
          .doc(_currentDriverId)
          .collection('history')
          .add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'accuracy': 5.0,
      });

      debugPrint(
          '📍 [Real-time] Driver location updated: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('❌ [Real-time] Error updating driver location: $e');
    }
  }

  /// Получает текущую позицию водителя из Firestore
  Stream<Map<String, dynamic>?> getDriverLocationStream(String driverId) {
    return _firestore
        .collection('driver_locations')
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'timestamp': data['timestamp'],
          'accuracy': data['accuracy'],
        };
      }
      return null;
    });
  }

  /// Получает все активные позиции водителей
  Stream<List<Map<String, dynamic>>> getAllDriverLocationsStream() {
    return _firestore
        .collection('driver_locations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'driverId': doc.id,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'timestamp': data['timestamp'],
          'accuracy': data['accuracy'],
        };
      }).toList();
    });
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}

class _PointTrackingData {
  final DateTime arrivedAt;
  bool completed;

  _PointTrackingData({required this.arrivedAt}) : completed = false;
}
