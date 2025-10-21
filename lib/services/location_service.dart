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

  Future<void> startTracking(String driverId, Function(double, double) onLocationUpdate) async {
    // Защита от повторного запуска - сначала останавливаем существующий поток
    await stopTracking();
    
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
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.locationDistanceFilter,
      ),
    ).listen(
      (Position position) {
        // Обновляем позицию водителя в Firestore в реальном времени
        _updateDriverLocation(position.latitude, position.longitude);
        
        // Вызываем callback для локального обновления
        onLocationUpdate(position.latitude, position.longitude);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
        // При ошибке останавливаем отслеживание
        stopTracking();
      },
    );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null; // Важно: обнуляем ссылку для предотвращения утечек
    _trackingData.clear();
    _currentDriverId = null; // Очищаем ID водителя
  }

  void checkPointCompletion(
    DeliveryPoint point,
    double currentLat,
    double currentLon,
    Function(DeliveryPoint) onComplete,
  ) {
    if (point.status == 'completed' || point.status == 'cancelled') return;

    final distance = Geolocator.distanceBetween(
      currentLat,
      currentLon,
      point.latitude,
      point.longitude,
    );

    if (distance <= 50) {
      final trackingData = _trackingData.putIfAbsent(
        point.id,
        () => _PointTrackingData(arrivedAt: DateTime.now()),
      );

      final duration = DateTime.now().difference(trackingData.arrivedAt);
      
      if (duration.inMinutes >= 2 && !trackingData.completed) {
        trackingData.completed = true;
        onComplete(point);
      }
    } else {
      _trackingData.remove(point.id);
    }
  }

  /// Обновляет позицию водителя в Firestore в реальном времени
  Future<void> _updateDriverLocation(double latitude, double longitude) async {
    if (_currentDriverId == null) return;
    
    try {
      await _firestore.collection('driver_locations').doc(_currentDriverId).set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'accuracy': 5.0, // Высокая точность GPS
        'speed': 0.0, // Можно добавить скорость если нужно
      }, SetOptions(merge: true));
      
      debugPrint('📍 [Real-time] Driver location updated: ($latitude, $longitude)');
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

  _PointTrackingData({required this.arrivedAt, this.completed = false});
}

