import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';
import '../models/delivery_point.dart';
import '../models/driver_gps_status.dart';
import 'driver_auto_close_logic.dart';
import 'driver_session_service.dart';
import 'firestore_paths.dart';

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
  final bool isOnShift;

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
    required this.isOnShift,
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
    final isOnShift =
        data['isOnShift'] ?? true; // 🎯 Читаем isOnShift, по умолчанию true

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
      isOnShift: isOnShift,
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
  void Function(DriverGpsStatus status)? _onStatusChanged;
  void Function(Object error)? _onFirestoreWriteError;

  // Configuration
  static const Duration batchInterval = Duration(seconds: 30);
  static const double significantDistanceMeters =
      50.0; // Only save if moved >50m
  static const Duration historyRetention = Duration(hours: 24);

  OptimizedLocationService(this.companyId);

  /// Company-scoped driver_locations (must match FirestorePaths + dispatcher reads)
  CollectionReference<Map<String, dynamic>> get _driverLocationsRef =>
      FirestorePaths.driverLocationsOf(companyId);

  Future<DriverGpsStatus> startTracking(
    String driverId,
    String driverName,
    Function(double, double) onLocationUpdate, {
    String? userRole,
    void Function(DriverGpsStatus status)? onStatusChanged,
    void Function(Object error)? onFirestoreWriteError,
  }) async {
    debugPrint(
        '🚀 [GPS] OptimizedLocationService STARTED for driver=$driverId');
    _currentDriverId = driverId;
    _onStatusChanged = onStatusChanged;
    _onFirestoreWriteError = onFirestoreWriteError;

    void emit(DriverGpsStatus status) => _onStatusChanged?.call(status);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ [GPS] Location services disabled');
      emit(DriverGpsStatus.disabled);
      return DriverGpsStatus.disabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ [GPS] Location permission denied');
        emit(DriverGpsStatus.permissionRequired);
        return DriverGpsStatus.permissionRequired;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ [GPS] Location permission denied forever');
      emit(DriverGpsStatus.permissionRequired);
      return DriverGpsStatus.permissionRequired;
    }

    if (permission == LocationPermission.whileInUse) {
      try {
        final escalated = await Geolocator.requestPermission();
        if (escalated == LocationPermission.always ||
            escalated == LocationPermission.whileInUse) {
          permission = escalated;
        }
      } catch (e, st) {
        debugPrint('[Location] background permission escalation: $e');
        debugPrint('$st');
      }
    }

    try {
      await _driverLocationsRef.doc(driverId).set({
        'driverName': driverName,
        'role': userRole ?? 'driver',
        'isOnShift': true,
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
          '✅ [Location] Driver name and role saved: $driverName ($userRole)');
    } catch (e, st) {
      debugPrint('❌ [Location] Error saving driver name: $e');
      debugPrint('$st');
      _onFirestoreWriteError?.call(e);
    }

    await _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.locationDistanceFilter,
      ),
    ).listen(
      (Position position) {
        debugPrint(
            '📍 [GPS] Position received: lat=${position.latitude} lng=${position.longitude}');
        _lastPosition = position;
        onLocationUpdate(position.latitude, position.longitude);
        _considerSavingLocation(position);
        emit(DriverGpsStatus.active);
      },
      onError: (Object e, StackTrace st) {
        debugPrint('❌ [GPS] Position stream error: $e');
        debugPrint('$st');
        emit(DriverGpsStatus.error);
      },
    );

    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(batchInterval, (_) {
      _saveBatchedLocation();
    });

    debugPrint(
        '✅ [Location] Tracking started with batching (${batchInterval.inSeconds}s)');
    emit(DriverGpsStatus.waiting);
    return DriverGpsStatus.waiting;
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

    final ownsSession = await DriverSessionService.verifyOwnership(
      companyId: companyId,
      driverId: _currentDriverId!,
    );
    if (!ownsSession) {
      await DriverSessionService.markSessionLostFlag();
      stopTracking();
      return;
    }

    try {
      final geoBucket = _buildGeoBucket(position.latitude, position.longitude);
      // Не отбрасывать запись по той же ячейке: иначе при стоянке (>60 с / батч)
      // координаты в Firestore не обновляются — диспетчер видит «старый» GPS.
      _lastSavedPosition = position;
      _lastSaveTime = DateTime.now();

      // OPTIMIZATION: Single write instead of two
      if (kDebugMode) {
        debugPrint(
            '[GPS SEND] driver=$_currentDriverId lat=${position.latitude} lng=${position.longitude}');
      }
      await _driverLocationsRef.doc(_currentDriverId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'geoBucket': geoBucket,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('GPS SENT: driver=$_currentDriverId');
      }

      // OPTIMIZATION: History с лимитом 500 записей
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
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
        });
      } catch (e, st) {
        debugPrint('[Location] Error saving to history: $e');
        debugPrint('$st');
        _onFirestoreWriteError?.call(e);
      }
    } catch (e, st) {
      debugPrint('[Location] Error saving: $e');
      debugPrint('$st');
      _onFirestoreWriteError?.call(e);
    }
  }

  /// Save to history (only when needed, not every update)
  /// OPTIMIZATION: Max 500 entries per driver
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
      debugPrint('[Location] Error saving history: $e');
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _batchTimer?.cancel();
    _trackingData.clear();
    _lastPosition = null;
    _lastSavedPosition = null;
    _lastSaveTime = null;
    _onStatusChanged = null;
    _onFirestoreWriteError = null;
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
    Function(DeliveryPoint) onComplete, {
    String? driverId,
    Set<String> disabledPointIds = const {},
    double enterRadiusM = AppConfig.autoCompleteRadius,
    double resetRadiusM = AppConfig.autoCompleteResetRadius,
    Duration waitDuration = AppConfig.autoCompleteDuration,
  }) {
    if (driverId != null &&
        !isDriverAutoCloseEligible(
          point,
          driverId: driverId,
          disabledPointIds: disabledPointIds,
        )) {
      _trackingData.remove(point.id);
      return;
    } else if (driverId == null) {
      final status = DeliveryPoint.normalizeStatus(point.status);
      if (status == DeliveryPoint.statusCompleted ||
          status == DeliveryPoint.statusCancelled) {
        return;
      }
    }

    final distance = driverAutoCloseDistanceMeters(
      currentLat,
      currentLon,
      point.latitude,
      point.longitude,
    );

    if (distance <= enterRadiusM) {
      final trackingData = _trackingData.putIfAbsent(
        point.id,
        () => _PointTrackingData(arrivedAt: DateTime.now()),
      );

      if (driverAutoCloseWaitComplete(
            trackingData.arrivedAt,
            DateTime.now(),
            waitDuration: waitDuration,
          ) &&
          !trackingData.completed) {
        trackingData.completed = true;
        onComplete(point);
      }
    } else if (shouldResetDriverAutoCloseTimer(
      distanceMeters: distance,
      resetRadiusM: resetRadiusM,
    )) {
      _trackingData.remove(point.id);
    }
  }

  Map<String, dynamic>? getAutoCompleteProgress(
    String pointId, {
    Duration waitDuration = AppConfig.autoCompleteDuration,
  }) {
    final trackingData = _trackingData[pointId];
    if (trackingData == null) return null;

    final duration = DateTime.now().difference(trackingData.arrivedAt);
    final totalSeconds = waitDuration.inSeconds;
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
        final data = doc.data();
        if (data == null) return null;
        return LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[Location] Error getting location: $e');
      return null;
    }
  }

  /// Stream driver location (realtime)
  /// OPTIMIZATION: Small document, updates every 30s instead of every second
  Stream<LatLng?> watchDriverLocation(String driverId) {
    return _driverLocationsRef.doc(driverId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
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
  /// ФИЛЬТРАЦИЯ: Показываем ТОЛЬКО водителей (role == 'driver') — в [normalizeDriver]
  /// НЕ фильтруем isOnShift в Firestore: у старых документов поля нет → where==true даёт 0 строк.
  ///    Фильтр «вне смены» — в UI ([DeliveryMapWidget] + toggle).
  /// SaaS: company-scoped — видим только своих водителей
  Stream<List<Map<String, dynamic>>> getAllDriverLocationsStream({
    List<String>? driverIds,
  }) {
    // Если переданы конкретные водители — слушаем только их (в 10-50x дешевле)
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
          .map((driver) {
        return {
          'driverId': driver.id,
          'driverName': driver.name,
          'latitude': driver.lat,
          'longitude': driver.lng,
          'timestamp': driver.timestamp,
          'speed': driver.speed,
          'heading': driver.heading,
          'isOnShift': driver.isOnShift,
        };
      }).toList();
      if (kDebugMode) {
        debugPrint('GPS READ: Total drivers: ${drivers.length}');
      }
      return drivers;
    });
  }

  /// Cleanup old location history
  /// OPTIMIZATION: Delete old data to reduce storage costs
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
