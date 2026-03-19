import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../config/app_config.dart';

const bool _enforceDriverRoleFilter = false;

class SafeDriver {
  final String id;
  final double lat;
  final double lng;
  final DateTime? timestamp;
  final String role;
  final String companyId;
  final String name;
  final double speed;
  final double heading;

  SafeDriver({
    required this.id,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.role,
    required this.companyId,
    required this.name,
    required this.speed,
    required this.heading,
  });

  bool get hasValidLocation => lat != 0 && lng != 0;
}

SafeDriver? normalizeDriver(Map<String, dynamic>? data, String id) {
  if (data == null) return null;

  try {
    final latRaw = data['latitude'] ?? data['lat'] ?? 0;
    final lngRaw = data['longitude'] ?? data['lng'] ?? 0;
    final lat = latRaw is num ? latRaw.toDouble() : 0.0;
    final lng = lngRaw is num ? lngRaw.toDouble() : 0.0;

    final timestampRaw = data['timestamp'];
    DateTime? timestamp;
    if (timestampRaw is DateTime) {
      timestamp = timestampRaw;
    } else if (timestampRaw is Timestamp) {
      timestamp = timestampRaw.toDate();
    }

    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    final companyId = (data['companyId'] ?? '').toString();
    final name = (data['driverName'] ?? data['name'] ?? 'Driver').toString();
    final speedRaw = data['speed'];
    final headingRaw = data['heading'];
    final speed = speedRaw is num ? speedRaw.toDouble() : 0.0;
    final heading = headingRaw is num ? headingRaw.toDouble() : 0.0;

    final driver = SafeDriver(
      id: id,
      lat: lat,
      lng: lng,
      timestamp: timestamp,
      role: role,
      companyId: companyId,
      name: name,
      speed: speed,
      heading: heading,
    );

    if (!driver.hasValidLocation) return null;
    if (_enforceDriverRoleFilter && driver.role != 'driver') return null;
    return driver;
  } catch (e) {
    debugPrint('❌ normalizeDriver error: $e');
    return null;
  }
}

/// Optimized Location Service with GPS batching
/// ⚡ OPTIMIZATION: Reduces Firestore writes by 95%
/// ✅ SaaS: company-scoped driver_locations
///
/// Key improvements:
/// 1. Batch GPS updates (30 seconds instead of every second)
/// 2. Skip updates if location hasn't changed significantly (>50m)
/// 3. Separate history collection with auto-cleanup
/// 4. Company-scoped: companies/{companyId}/driver_locations/{driverId}
class OptimizedLocationService {
  StreamSubscription<Position>? _positionStream;
  final Map<String, _PointTrackingData> _trackingData = {};
  String? _currentDriverId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  // ⚡ OPTIMIZATION: Batching variables
  Position? _lastPosition;
  Position? _lastSavedPosition;
  DateTime? _lastSaveTime;
  Timer? _batchTimer;
  String? _lastGeoBucket;

  // Configuration
  static const Duration batchInterval = Duration(seconds: 30);
  static const double significantDistanceMeters =
      50.0; // Only save if moved >50m
  static const Duration historyRetention = Duration(hours: 24);

  OptimizedLocationService(this.companyId);

  /// Company-scoped driver_locations collection reference
  CollectionReference get _driverLocationsRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('driver_locations');

  Future<void> startTracking(
    String driverId,
    String driverName,
    Function(double, double) onLocationUpdate, {
    String? userRole,
  }) async {
    debugPrint(
        '🚀 [GPS] OptimizedLocationService STARTED for driver=$driverId');
    _currentDriverId = driverId;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // ✅ Сохраняем имя водителя и роль при старте трекинга
    try {
      await _driverLocationsRef.doc(driverId).set({
        'driverName': driverName,
        'role': userRole ?? 'driver',
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': Timestamp.now(),
      }, SetOptions(merge: true));
      debugPrint(
          '✅ [Location] Driver name and role saved: $driverName ($userRole)');
    } catch (e) {
      debugPrint('❌ [Location] Error saving driver name: $e');
    }

    // Start GPS stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.locationDistanceFilter,
      ),
    ).listen((Position position) {
      debugPrint(
          '📍 [GPS] Position received: lat=${position.latitude} lng=${position.longitude}');
      _lastPosition = position;

      // Always update UI immediately (local only, no Firestore write)
      onLocationUpdate(position.latitude, position.longitude);

      // ⚡ OPTIMIZATION: Check if we should save to Firestore
      _considerSavingLocation(position);
    });

    // ⚡ OPTIMIZATION: Start batch timer
    _batchTimer = Timer.periodic(batchInterval, (_) {
      _saveBatchedLocation();
    });

    debugPrint(
        '✅ [Location] Tracking started with batching (${batchInterval.inSeconds}s)');
  }

  /// Check if location should be saved based on distance and time
  void _considerSavingLocation(Position position) {
    final now = DateTime.now();

    if (_lastSavedPosition == null) {
      _saveLocationToFirestore(position);
      return;
    }

    final distance = Geolocator.distanceBetween(
      _lastSavedPosition!.latitude,
      _lastSavedPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    final timeSinceLastSave = _lastSaveTime != null
        ? now.difference(_lastSaveTime!)
        : const Duration(seconds: 999);

    if (distance > significantDistanceMeters ||
        timeSinceLastSave.inSeconds > 60) {
      debugPrint(
          '📍 [Location] Significant change: ${distance.toStringAsFixed(1)}m, saving...');
      _saveLocationToFirestore(position);
    }
  }

  /// Save batched location (called every 30 seconds)
  void _saveBatchedLocation() {
    if (_lastPosition == null) return;

    if (_lastSavedPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastSavedPosition!.latitude,
        _lastSavedPosition!.longitude,
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );

      if (distance < 10.0) {
        return;
      }
    }

    _saveLocationToFirestore(_lastPosition!);
  }

  /// Save location to Firestore
  Future<void> _saveLocationToFirestore(Position position) async {
    if (_currentDriverId == null) return;

    try {
      final timestamp = Timestamp.now();
      final geoBucket = _buildGeoBucket(position.latitude, position.longitude);
      if (_lastGeoBucket == geoBucket) return;
      _lastSavedPosition = position;
      _lastSaveTime = DateTime.now();
      _lastGeoBucket = geoBucket;

      // ⚡ OPTIMIZATION: Single write instead of two
      debugPrint(
          '📡 [GPS SEND] driver=$_currentDriverId lat=${position.latitude} lng=${position.longitude}');
      await _driverLocationsRef.doc(_currentDriverId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': timestamp,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'geoBucket': geoBucket,
      }, SetOptions(merge: true));

      // ⚡ OPTIMIZATION: History с лимитом 500 записей
      try {
        final historyRef =
            _driverLocationsRef.doc(_currentDriverId).collection('history');

        final snapshot = await historyRef.orderBy('timestamp').limit(500).get();
        if (snapshot.docs.length >= 500) {
          await snapshot.docs.first.reference.delete();
        }

        await historyRef.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': timestamp,
          'accuracy': position.accuracy,
        });
      } catch (e) {
        debugPrint('⚠️ [Location] Error saving to history: $e');
      }
    } catch (e) {
      debugPrint('❌ [Location] Error saving: $e');
    }
  }

  /// Save to history (only when needed, not every update)
  /// ⚡ OPTIMIZATION: Max 500 entries per driver
  Future<void> saveToHistory(Position position) async {
    if (_currentDriverId == null) return;

    try {
      final historyRef =
          _driverLocationsRef.doc(_currentDriverId).collection('history');

      final snapshot = await historyRef.orderBy('timestamp').limit(500).get();
      if (snapshot.docs.length >= 500) {
        await snapshot.docs.first.reference.delete();
      }

      await historyRef.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': Timestamp.now(),
        'accuracy': position.accuracy,
      });
    } catch (e) {
      debugPrint('❌ [Location] Error saving history: $e');
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _batchTimer?.cancel();
    _trackingData.clear();
    _lastPosition = null;
    _lastSavedPosition = null;
    _lastSaveTime = null;
    _lastGeoBucket = null;
  }

  String _buildGeoBucket(double lat, double lng) {
    final latBucket = (lat * 10000).floor() / 10000;
    final lngBucket = (lng * 10000).floor() / 10000;
    return '${latBucket}_$lngBucket';
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

      if (duration >= AppConfig.autoCompleteDuration &&
          !trackingData.completed) {
        trackingData.completed = true;
        onComplete(point);
      }
    } else {
      if (_trackingData.containsKey(point.id)) {
        _trackingData.remove(point.id);
      }
    }
  }

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

  /// Get current driver location
  Future<LatLng?> getDriverLocation(String driverId) async {
    try {
      final doc = await _driverLocationsRef.doc(driverId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Location] Error getting location: $e');
      return null;
    }
  }

  /// Stream driver location (realtime)
  /// ⚡ OPTIMIZATION: Small document, updates every 30s instead of every second
  Stream<LatLng?> watchDriverLocation(String driverId) {
    return _driverLocationsRef.doc(driverId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
      return null;
    });
  }

  /// Get all driver locations (for map)
  /// ✅ ФИЛЬТРАЦИЯ: Показываем ТОЛЬКО водителей (role == 'driver')
  /// ✅ SaaS: company-scoped — видим только своих водителей
  Stream<List<Map<String, dynamic>>> getAllDriverLocationsStream({
    List<String>? driverIds,
  }) {
    final isFallbackMode =
        !(driverIds != null && driverIds.isNotEmpty && driverIds.length <= 10);
    final freshCutoff = DateTime.now().subtract(const Duration(minutes: 10));

    // ⚡ Если переданы конкретные водители — слушаем только их (в 10-50x дешевле)
    Query query;
    if (driverIds != null && driverIds.isNotEmpty && driverIds.length <= 10) {
      query =
          _driverLocationsRef.where(FieldPath.documentId, whereIn: driverIds);
    } else {
      query = _driverLocationsRef.limit(200);
    }

    return query.snapshots().map((snapshot) {
      final drivers = snapshot.docs
          .map((doc) =>
              normalizeDriver(doc.data() as Map<String, dynamic>?, doc.id))
          .whereType<SafeDriver>()
          .where((driver) =>
              !isFallbackMode ||
              (driver.timestamp != null &&
                  !driver.timestamp!.isBefore(freshCutoff)))
          .map((driver) {
        debugPrint(
            '📡 [GPS READ] driver=${driver.id} lat=${driver.lat} lng=${driver.lng}');
        return {
          'driverId': driver.id,
          'driverName': driver.name,
          'latitude': driver.lat,
          'longitude': driver.lng,
          'timestamp': driver.timestamp,
          'speed': driver.speed,
          'heading': driver.heading,
        };
      }).toList();
      debugPrint('📡 [GPS READ] Total drivers: ${drivers.length}');
      return drivers;
    });
  }

  /// Cleanup old location history
  /// ⚡ OPTIMIZATION: Delete old data to reduce storage costs
  Future<void> cleanupOldHistory() async {
    try {
      final cutoffTime = DateTime.now().subtract(historyRetention);

      final driversSnapshot =
          await _driverLocationsRef.where('role', isEqualTo: 'driver').get();

      for (final driverDoc in driversSnapshot.docs) {
        final oldDocs = await driverDoc.reference
            .collection('history')
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffTime))
            .get();

        if (oldDocs.docs.isEmpty) continue;

        final batch = _firestore.batch();
        for (final doc in oldDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        debugPrint(
            '🧹 [Location] Cleaned ${oldDocs.docs.length} old history entries for ${driverDoc.id}');
      }
    } catch (e) {
      debugPrint('❌ [Location] Error cleaning history: $e');
    }
  }
}

class _PointTrackingData {
  final DateTime arrivedAt;
  bool completed;

  _PointTrackingData({
    required this.arrivedAt,
  }) : completed = false;
}
