import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/optimized_location_service.dart';
import '../../services/background_location_service.dart';
import '../../services/realtime_gps_service.dart';
import '../../services/work_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../models/shift_schedule_config.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/delivery_map_widget.dart';
import '../../services/company_cache.dart';
import '../../services/firestore_paths.dart';
import '../../config/app_config.dart';

// === ARRIVAL CONFIG ===
const double kArrivalRadius = AppConfig.autoCompleteRadius; // meters
const double kStopSpeed = 2.0; // m/s (~7 km/h)
const int kStopTimeSec = 12; // seconds

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  RouteService? _routeService;
  OptimizedLocationService? _locationService;
  final RealtimeGpsService _realtimeGps = RealtimeGpsService();
  final WorkScheduleService _scheduleService = WorkScheduleService();
  DeliveryPoint? _currentPoint;
  List<DeliveryPoint> _lastPoints = [];
  bool _isTrackingActive = false;
  String _scheduleStatus = '';
  Timer? _scheduleStatusTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _shiftsSub;
  DateTime _lastGpsNotificationSync = DateTime(2000);
  DateTime? _stopStartTime;
  String? _lastArrivedPointId;
  double? _arrivalPrevLat;
  double? _arrivalPrevLng;
  DateTime? _arrivalPrevTime;

  // ── Foreground auto-close (основной механизм, Android) ──
  Timer? _autoCloseTimer;
  final Map<String, DateTime> _autoCloseArrivalTimes = {};
  double? _lastKnownLat;
  double? _lastKnownLng;
  String? _visibleRouteKey;

  // 🛡️ Cached stream — НЕ пересоздаётся на каждый build()
  Stream<List<DeliveryPoint>>? _cachedStream;
  String? _cachedStreamDriverId;

  bool _isActiveRoutePoint(DeliveryPoint point) {
    final status = DeliveryPoint.normalizeStatus(point.status);
    return status == DeliveryPoint.statusAssigned ||
        status == DeliveryPoint.statusInProgress;
  }

  String _routeKeyForPoint(DeliveryPoint point) =>
      point.routeId?.isNotEmpty == true
          ? point.routeId!
          : '__driver__${point.driverId ?? ''}';

  DateTime _pointSortTime(DeliveryPoint point) =>
      point.updatedAt ??
      point.completedAt ??
      point.arrivedAt ??
      point.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  bool _isClosedPoint(DeliveryPoint point) {
    final status = DeliveryPoint.normalizeStatus(point.status);
    return status == DeliveryPoint.statusCompleted ||
        status == DeliveryPoint.statusCancelled;
  }

  bool _shouldApplyPointUpdate(DeliveryPoint incoming, DeliveryPoint? local) {
    if (local == null) return true;
    if (incoming.updatedAt == null) return true;
    if (local.updatedAt == null) return true;
    return incoming.updatedAt!.isAfter(local.updatedAt!);
  }

  String? _selectCurrentRouteKey(
    List<DeliveryPoint> points, {
    String? preferredRouteKey,
  }) {
    if (points.isEmpty) return null;

    final byRoute = <String, List<DeliveryPoint>>{};
    for (final point in points) {
      byRoute.putIfAbsent(_routeKeyForPoint(point), () => []).add(point);
    }

    String? bestKey;
    DateTime? bestTime;

    if (preferredRouteKey != null && byRoute.containsKey(preferredRouteKey)) {
      return preferredRouteKey;
    }

    void consider(String key, List<DeliveryPoint> group) {
      final latest = group
          .map(_pointSortTime)
          .fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0), (a, b) {
        return a.isAfter(b) ? a : b;
      });
      if (bestTime == null || latest.isAfter(bestTime!)) {
        bestTime = latest;
        bestKey = key;
      }
    }

    for (final entry in byRoute.entries) {
      if (entry.value.any(_isActiveRoutePoint)) {
        consider(entry.key, entry.value);
      }
    }
    if (bestKey != null) return bestKey;

    for (final entry in byRoute.entries) {
      consider(entry.key, entry.value);
    }
    return bestKey;
  }

  List<DeliveryPoint> _filterDriverPointsToCurrentRoute(
    List<DeliveryPoint> points,
  ) {
    final currentRouteKey = _selectCurrentRouteKey(
      points,
      preferredRouteKey: _visibleRouteKey,
    );
    if (currentRouteKey == null) {
      // НЕ сбрасываем _visibleRouteKey — merge использует его
      // чтобы сохранить завершённые точки маршрута в UI
      return [];
    }
    _visibleRouteKey = currentRouteKey;

    final filtered = points
        .where((point) => _routeKeyForPoint(point) == currentRouteKey)
        .toList()
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
    return filtered;
  }

  /// Merge incoming stream data with local state.
  ///
  /// INVARIANT: Если маршрут завершён (все точки closed), данные
  /// НИКОГДА не должны обнуляться. Три уровня защиты:
  ///   1) _filterDriverPointsToCurrentRoute НЕ сбрасывает _visibleRouteKey
  ///   2) Этот метод сохраняет closed точки из _lastPoints
  ///   3) StreamBuilder НЕ затирает _lastPoints пустым списком
  List<DeliveryPoint> _mergeVisibleRoutePoints(
    List<DeliveryPoint> incomingPoints,
  ) {
    if (_lastPoints.isEmpty) return incomingPoints;

    // 🛡️ Защита: incoming пуст, но у нас есть данные завершённого маршрута.
    // Сохраняем предыдущее состояние как есть.
    if (incomingPoints.isEmpty && _visibleRouteKey != null) {
      return List.of(_lastPoints);
    }

    final incomingById = {
      for (final point in incomingPoints) point.id: point,
    };
    final merged = <DeliveryPoint>[];

    for (final incoming in incomingPoints) {
      final local = _lastPoints.cast<DeliveryPoint?>().firstWhere(
            (point) => point?.id == incoming.id,
            orElse: () => null,
          );
      merged.add(_shouldApplyPointUpdate(incoming, local) ? incoming : local!);
    }

    for (final local in _lastPoints) {
      if (incomingById.containsKey(local.id)) continue;
      if (_routeKeyForPoint(local) != _visibleRouteKey) continue;
      if (_isClosedPoint(local)) {
        merged.add(local);
      }
    }

    merged.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
    return merged;
  }

  void _markPointCompletedLocally(String pointId) {
    final now = DateTime.now();
    _lastPoints = _lastPoints.map((point) {
      if (point.id != pointId) return point;
      return point.copyWith(
        status: DeliveryPoint.statusCompleted,
        completedAt: now,
        updatedAt: now,
      );
    }).toList()
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    if (_currentPoint?.id == pointId) {
      _currentPoint = _lastPoints.firstWhere(
        (p) => !_isClosedPoint(p),
        orElse: () =>
            _lastPoints.isNotEmpty ? _lastPoints.first : _currentPoint!,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 🛡️ PERSISTENT CACHE — точки переживают рефреш страницы
  static const _cacheKey = 'driver_last_points';
  static const _cacheRouteKey = 'driver_visible_route_key';
  static const _cacheTsKey = 'driver_cache_ts';

  /// JSON-safe сериализация точки (без Firestore Timestamp/FieldValue)
  Map<String, dynamic> _pointToJson(DeliveryPoint p) => {
        'id': p.id,
        'companyId': p.companyId,
        'address': p.address,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'clientName': p.clientName,
        'clientNumber': p.clientNumber,
        'urgency': p.urgency,
        'pallets': p.pallets,
        'boxes': p.boxes,
        'status': p.status,
        'orderInRoute': p.orderInRoute,
        'driverId': p.driverId,
        'driverName': p.driverName,
        'driverCapacity': p.driverCapacity,
        'temporaryAddress': p.temporaryAddress,
        'autoCompleted': p.autoCompleted,
        'routeId': p.routeId,
        'routePolyline': p.routePolyline,
        'zone': p.zone,
        'eta': p.eta,
        'distanceKm': p.distanceKm,
        if (p.openingTime != null)
          'openingTime': p.openingTime!.millisecondsSinceEpoch,
        if (p.completedAt != null)
          'completedAt': p.completedAt!.millisecondsSinceEpoch,
        if (p.arrivedAt != null)
          'arrivedAt': p.arrivedAt!.millisecondsSinceEpoch,
        if (p.updatedAt != null)
          'updatedAt': p.updatedAt!.millisecondsSinceEpoch,
        if (p.createdAt != null)
          'createdAt': p.createdAt!.millisecondsSinceEpoch,
      };

  DeliveryPoint _pointFromJson(Map<String, dynamic> m) => DeliveryPoint(
        id: m['id'] ?? '',
        companyId: m['companyId'] ?? '',
        address: m['address'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
        clientName: m['clientName'] ?? '',
        clientNumber: m['clientNumber'],
        urgency: m['urgency'] ?? 'normal',
        pallets: m['pallets'] ?? 0,
        boxes: m['boxes'] ?? 0,
        status: m['status'] ?? 'pending',
        orderInRoute: m['orderInRoute'] ?? 0,
        driverId: m['driverId'],
        driverName: m['driverName'],
        driverCapacity: m['driverCapacity'],
        temporaryAddress: m['temporaryAddress'],
        autoCompleted: m['autoCompleted'] ?? false,
        routeId: m['routeId'],
        routePolyline: m['routePolyline'],
        zone: m['zone'],
        eta: m['eta'],
        distanceKm: (m['distanceKm'] as num?)?.toDouble(),
        openingTime: m['openingTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['openingTime'])
            : null,
        completedAt: m['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['completedAt'])
            : null,
        arrivedAt: m['arrivedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['arrivedAt'])
            : null,
        updatedAt: m['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['updatedAt'])
            : null,
        createdAt: m['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'])
            : null,
      );

  Future<void> _savePointsToCache() async {
    if (_lastPoints.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          _lastPoints.map((p) => jsonEncode(_pointToJson(p))).toList();
      await prefs.setStringList(_cacheKey, jsonList);
      if (_visibleRouteKey != null) {
        await prefs.setString(_cacheRouteKey, _visibleRouteKey!);
      }
      await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ [DriverCache] Save failed: $e');
    }
  }

  Future<void> _restorePointsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_cacheTsKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - ts;
      // Кеш актуален не более 12 часов
      if (cacheAge > 12 * 60 * 60 * 1000) {
        debugPrint(
            '🗑️ [DriverCache] Cache too old (${cacheAge ~/ 3600000}h), ignoring');
        return;
      }
      final jsonList = prefs.getStringList(_cacheKey);
      if (jsonList == null || jsonList.isEmpty) return;

      final restored = <DeliveryPoint>[];
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          restored.add(_pointFromJson(map));
        } catch (_) {}
      }
      if (restored.isNotEmpty) {
        _lastPoints = restored;
        _visibleRouteKey = prefs.getString(_cacheRouteKey);
        debugPrint('✅ [DriverCache] Restored ${restored.length} points, '
            'routeKey=$_visibleRouteKey');
      }
    } catch (e) {
      debugPrint('⚠️ [DriverCache] Restore failed: $e');
    }
  }

  Stream<List<DeliveryPoint>> _getOrCreateStream(String driverId) {
    if (_cachedStream != null && _cachedStreamDriverId == driverId) {
      return _cachedStream!;
    }
    _cachedStreamDriverId = driverId;
    _cachedStream = _routeService!.getTodayRoutes(driverId: driverId);
    debugPrint('🔄 [Driver] Created new stream for driver $driverId');
    return _cachedStream!;
  }

  @override
  void initState() {
    super.initState();

    // 🛡️ Восстанавливаем кеш при старте (до первого build)
    _restorePointsFromCache();

    // Инициализируем уведомления, затем запускаем расписание
    _initializeAndStartSchedule();

    // Обновляем статус расписания каждую минуту
    _scheduleStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          final status = _scheduleService.getScheduleStatus(
            weekendDayText: l10n.weekendDay,
            workDayEndedText: l10n.workDayEnded,
            workStartsInFn: (m) => l10n.workStartsIn(m),
            workEndsInFn: (m) => l10n.workEndsIn(m),
          );
          _scheduleStatus = status['statusMessage'];
        });
      }
    });

    // Устанавливаем начальный статус
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isTrackingActive) {
        _showGpsNotification();
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          final status = _scheduleService.getScheduleStatus(
            weekendDayText: l10n.weekendDay,
            workDayEndedText: l10n.workDayEnded,
            workStartsInFn: (m) => l10n.workStartsIn(m),
            workEndsInFn: (m) => l10n.workEndsIn(m),
          );
          _scheduleStatus = status['statusMessage'];
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachShiftsListener();
    });
  }

  /// Тот же документ, что экран לוח משמרות — статус «рабочий день» совпадает с настройками.
  void _attachShiftsListener() {
    final auth = context.read<AuthService>();
    final cid = auth.userModel?.companyId ?? '';
    if (cid.isEmpty) return;
    _shiftsSub?.cancel();
    _shiftsSub = FirestorePaths.companyShiftsOf(cid).snapshots().listen((snap) {
      final config = ShiftScheduleConfig.fromFirestore(snap.data());
      ShiftScheduleConfig.saveToPrefs(config);
      _scheduleService.updateShiftSchedule(config);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        final status = _scheduleService.getScheduleStatus(
          weekendDayText: l10n.weekendDay,
          workDayEndedText: l10n.workDayEnded,
          workStartsInFn: (m) => l10n.workStartsIn(m),
          workEndsInFn: (m) => l10n.workEndsIn(m),
        );
        _scheduleStatus = status['statusMessage'] as String;
      });
    });
  }

  Future<void> _initializeAndStartSchedule() async {
    await _initializeNotifications();

    // Запускаем мониторинг расписания ПОСЛЕ инициализации BGService
    _scheduleService.startScheduleMonitoring(
      onStartTracking: _startTracking,
      onStopTracking: _stopTracking,
    );
  }

  Future<void> _initializeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleDailyWorkReminder();
    // Инициализируем фоновый сервис (только на мобильных платформах)
    if (!kIsWeb) {
      await BackgroundLocationService.initialize();
    }
    debugPrint('✅ [Driver] Notifications + BGService initialized');
  }

  void _startTracking() {
    debugPrint('🚀 [GPS] _startTracking() called from driver dashboard');
    final authService = context.read<AuthService>();
    final driverName = authService.userModel?.name ??
        (AppLocalizations.of(context)?.driverFallbackName ?? 'Driver');
    final userRole = authService.userModel?.role ?? 'driver';
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser!.uid;

    // Ensure services are initialized (may be called before build())
    if (companyId.isNotEmpty && _locationService == null) {
      _routeService ??= RouteService(companyId: companyId);
      _locationService = OptimizedLocationService(companyId);
      CompanyCache.instance(companyId).preload(companyId, authService);
      debugPrint('🚛 [Driver] Services lazy-initialized in _startTracking');
    }

    // Foreground GPS (пока приложение открыто)
    debugPrint('🚀 [GPS] Calling locationService.startTracking()');
    _locationService?.startTracking(
      driverId,
      driverName,
      _onLocationUpdate,
      userRole: userRole,
    );

    // Background foreground-service (когда приложение свёрнуто, только мобильные)
    if (!kIsWeb) {
      BackgroundLocationService.start(driverId, driverName, companyId);
    }

    // WebSocket GPS для live-карты диспетчера
    _realtimeGps.connectAsDriver();

    // Foreground auto-close: таймер каждые 30 сек проверяет точки
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAutoClose(),
    );

    setState(() => _isTrackingActive = true);
    _showGpsNotification();
    debugPrint('✅ [Driver] Tracking started: $driverName');
  }

  void _stopTracking() async {
    _locationService?.stopTracking();
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser?.uid ?? '';
    final driverName = authService.userModel?.name ?? '';
    if (companyId.isNotEmpty && driverId.isNotEmpty) {
      try {
        await FirestorePaths.driverLocationsOf(companyId).doc(driverId).set({
          'driverId': driverId,
          'driverName': driverName,
          'role': 'driver',
          'isOnShift': false,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ [Driver] Failed to mark off-shift: $e');
      }
    }
    if (!kIsWeb) BackgroundLocationService.stop();
    _realtimeGps.dispose();
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
    _autoCloseArrivalTimes.clear();
    setState(() => _isTrackingActive = false);
    _hideGpsNotification();
    debugPrint('🛑 [Driver] Tracking stopped');
  }

  @override
  void dispose() {
    _shiftsSub?.cancel();
    _scheduleStatusTimer?.cancel();
    _autoCloseTimer?.cancel();
    _locationService?.stopTracking();
    _realtimeGps.dispose();
    // НЕ вызываем BackgroundLocationService.stop() —
    // BGService должен продолжать работать когда приложение свёрнуто/закрыто.
    // Он сам остановится в 17:00 через _isWorkTime().
    _scheduleService.dispose();
    super.dispose();
  }

  // Умная отправка GPS — только если машина двигается
  double _lastSentLat = 0;
  double _lastSentLng = 0;
  DateTime _lastSentTime = DateTime(2000);

  void _onLocationUpdate(double lat, double lon) {
    if (_routeService == null) return;

    // Сохраняем последнюю GPS-позицию для таймера автозакрытия
    _lastKnownLat = lat;
    _lastKnownLng = lon;

    if (_isTrackingActive) {
      _showGpsNotification();
    }
    _handleArrivalLogic(lat, lon);

    // Отправляем GPS через WebSocket только если сдвинулись > 10м или прошло > 10 сек
    final now = DateTime.now();
    final distM = _simpleDistanceMeters(_lastSentLat, _lastSentLng, lat, lon);
    final elapsed = now.difference(_lastSentTime).inSeconds;

    if (distM > 10 || elapsed > 10) {
      final authService = context.read<AuthService>();
      _realtimeGps.sendGps(
        driverId: authService.currentUser?.uid ?? '',
        driverName: authService.userModel?.name ?? '',
        lat: lat,
        lng: lon,
      );
      _lastSentLat = lat;
      _lastSentLng = lon;
      _lastSentTime = now;
    }

    // Автозакрытие: основной механизм — _autoCloseTimer (foreground),
    // резерв — BackgroundLocationService (когда приложение свёрнуто).
  }

  void _handleArrivalLogic(double lat, double lon) {
    final point = _currentPoint;
    if (point == null) return;
    if (_isClosedPoint(point)) {
      _stopStartTime = null;
      return;
    }

    if (_lastArrivedPointId == point.id) return;
    if (point.arrivedAt != null) return;

    final now = DateTime.now();
    final distance =
        _simpleDistanceMeters(lat, lon, point.latitude, point.longitude);
    final isInsideRadius = distance <= kArrivalRadius;

    double speedMps = double.infinity;
    if (_arrivalPrevLat != null &&
        _arrivalPrevLng != null &&
        _arrivalPrevTime != null) {
      final elapsedMs = now.difference(_arrivalPrevTime!).inMilliseconds;
      if (elapsedMs > 0) {
        final moved = _simpleDistanceMeters(
          _arrivalPrevLat!,
          _arrivalPrevLng!,
          lat,
          lon,
        );
        speedMps = moved / (elapsedMs / 1000.0);
      }
    }

    final isSlow = speedMps <= kStopSpeed;
    if (isInsideRadius && isSlow) {
      _stopStartTime ??= now;
      final stoppedSec = now.difference(_stopStartTime!).inSeconds;
      if (stoppedSec >= kStopTimeSec) {
        _lastArrivedPointId = point.id;
        _markArrived(point.id);
      }
    } else {
      _stopStartTime = null;
    }

    _arrivalPrevLat = lat;
    _arrivalPrevLng = lon;
    _arrivalPrevTime = now;
  }

  Future<void> _markArrived(String pointId) async {
    try {
      final authService = context.read<AuthService>();
      final companyId = authService.userModel?.companyId ?? '';
      if (companyId.isEmpty) return;
      await FirestorePaths.deliveryPointsOf(companyId).doc(pointId).update({
        'status': DeliveryPoint.statusInProgress,
        'arrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('ARRIVED: $pointId');
    } catch (e) {
      debugPrint('ARRIVAL ERROR: $e');
    }
  }

  /// Foreground auto-close: каждые 30 сек проверяет ВСЕ активные точки водителя.
  /// Если водитель в радиусе 100 м от точки ≥ 2 мин — автозакрытие.
  /// Работает даже когда distanceFilter не генерирует GPS-апдейты (водитель стоит).
  Future<void> _checkAutoClose() async {
    final lat = _lastKnownLat;
    final lng = _lastKnownLng;
    if (lat == null || lng == null) return;
    if (_routeService == null) return;
    if (!mounted) return;

    final now = DateTime.now();
    final activePoints = _lastPoints.where((p) {
      final s = DeliveryPoint.normalizeStatus(p.status);
      return s == DeliveryPoint.statusAssigned ||
          s == DeliveryPoint.statusInProgress;
    }).toList();

    for (final point in activePoints) {
      final dist =
          _simpleDistanceMeters(lat, lng, point.latitude, point.longitude);

      if (dist <= AppConfig.autoCompleteRadius) {
        if (!_autoCloseArrivalTimes.containsKey(point.id)) {
          _autoCloseArrivalTimes[point.id] = point.arrivedAt ?? now;
          debugPrint(
            '📍 [AutoClose] В радиусе ${point.clientName} '
            '(${dist.toStringAsFixed(0)} м), таймер запущен',
          );
        } else {
          final arrived = _autoCloseArrivalTimes[point.id]!;
          final waited = now.difference(arrived);
          if (waited >= AppConfig.autoCompleteDuration) {
            debugPrint(
              '✅ [AutoClose] Автозакрытие: ${point.clientName} '
              '(${waited.inSeconds} сек в радиусе)',
            );
            final ok = await _autoCompletePoint(point);
            if (ok) {
              _autoCloseArrivalTimes.remove(point.id);
            }
          }
        }
      } else if (dist > AppConfig.autoCompleteResetRadius) {
        if (_autoCloseArrivalTimes.containsKey(point.id)) {
          debugPrint(
            '↩️ [AutoClose] Вышел из радиуса ${point.clientName}, таймер сброшен',
          );
          _autoCloseArrivalTimes.remove(point.id);
        }
      }
    }

    // Очистка таймеров для точек, которых больше нет в активных
    final activeIds = activePoints.map((p) => p.id).toSet();
    _autoCloseArrivalTimes.removeWhere((id, _) => !activeIds.contains(id));
  }

  Future<bool> _autoCompletePoint(DeliveryPoint point) async {
    try {
      if (_routeService == null) return false;
      final authService = context.read<AuthService>();
      final driverId = authService.currentUser?.uid ?? '';

      // Используем updatePointStatus чтобы сработало обучение координат
      await _routeService!.updatePointStatus(
        point.id,
        DeliveryPoint.statusCompleted,
        updatedByUid: driverId,
        autoCompleted: true,
      );
      if (mounted) {
        setState(() {
          _markPointCompletedLocally(point.id);
        });
      }
      debugPrint(
          '✅ [AutoClose] Point ${point.clientName} auto-completed via RouteService');
      return true;
    } catch (e) {
      debugPrint('❌ [AutoClose] Error auto-completing ${point.clientName}: $e');
      return false;
    }
  }

  Future<void> _showGpsNotification() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    if (now.difference(_lastGpsNotificationSync).inSeconds < 15) return;
    _lastGpsNotificationSync = now;
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser?.uid ?? '';
    final driverName = authService.userModel?.name ?? 'Driver';
    if (companyId.isEmpty || driverId.isEmpty) return;
    final isRunning = await BackgroundLocationService.isRunning();
    if (!isRunning) {
      await BackgroundLocationService.start(driverId, driverName, companyId);
    }
  }

  Future<void> _hideGpsNotification() async {
    if (kIsWeb) return;
    final isRunning = await BackgroundLocationService.isRunning();
    if (isRunning) {
      await BackgroundLocationService.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    // Инициализируем сервисы с companyId водителя
    final companyId = authService.userModel?.companyId ?? '';
    if (_routeService == null && companyId.isNotEmpty) {
      _routeService = RouteService(companyId: companyId);
      _locationService = OptimizedLocationService(companyId);
      // ⚡ Предзагрузка кеша компании для водителя
      CompanyCache.instance(companyId).preload(companyId, authService);
      debugPrint('🚛 [Driver] Services initialized with companyId: $companyId');
    }

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(l10n.driver),
          actions: [
            NotificationBell(companyId: companyId),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Индикатор режима просмотра для админа
            if (authService.userModel?.isAdmin == true &&
                authService.viewAsRole == 'driver')
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade300, width: 2),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility,
                            color: Colors.orange.shade900, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${l10n.viewingAs} ${l10n.driver}',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => authService.setViewAsRole(null),
                      icon: const Icon(Icons.admin_panel_settings, size: 18),
                      label: Text(l10n.backToAdmin),
                    ),
                  ],
                ),
              ),
            // Индикатор статуса расписания и GPS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isTrackingActive
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                border: Border(
                  bottom: BorderSide(
                    color: _isTrackingActive
                        ? Colors.green.shade300
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTrackingActive ? Icons.gps_fixed : Icons.gps_off,
                    color: _isTrackingActive
                        ? Colors.green.shade900
                        : Colors.grey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTrackingActive
                              ? '📍 ${l10n.gpsTrackingActive}'
                              : '⏸️ ${l10n.gpsTrackingStopped}',
                          style: TextStyle(
                            color: _isTrackingActive
                                ? Colors.green.shade900
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (_scheduleStatus.isNotEmpty)
                          Text(
                            _scheduleStatus,
                            style: TextStyle(
                              color: _isTrackingActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Основное содержимое
            Expanded(
              child: _routeService == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<DeliveryPoint>>(
                      // 🛡️ Кешированный stream — НЕ пересоздаётся на каждый build()
                      stream: _getOrCreateStream(authService.viewAsDriverId ??
                          authService.currentUser!.uid),
                      initialData: const [],
                      builder: (context, snapshot) {
                        // 🛡️ Waiting/Error: если есть кеш — используем его,
                        // иначе спиннер или ошибка
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData &&
                            _lastPoints.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError && _lastPoints.isEmpty) {
                          debugPrint(
                              '❌ [Driver] Stream error: ${snapshot.error}');
                          return Center(
                            child: Text(
                              '${l10n.error}: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        // 🛡️ Основная логика merge
                        var points = _lastPoints;
                        if (snapshot.hasData && snapshot.data != null) {
                          final incomingPoints = snapshot.data!;
                          final routePoints =
                              _filterDriverPointsToCurrentRoute(incomingPoints);
                          points = _mergeVisibleRoutePoints(routePoints);

                          // 🛡️ GUARD: никогда не затираем _lastPoints пустым
                          // списком, если у нас был завершённый маршрут.
                          if (points.isNotEmpty || _lastPoints.isEmpty) {
                            _lastPoints = points;
                            // 🛡️ Сохраняем в persistent cache
                            _savePointsToCache();
                          } else {
                            points = _lastPoints;
                          }
                        }

                        if (points.isNotEmpty) {
                          _currentPoint = points.firstWhere(
                            (p) => !_isClosedPoint(p),
                            orElse: () => points.first,
                          );
                        } else {
                          _currentPoint = null;
                        }

                        return Column(
                          children: [
                            // 📱 Android fallback: карта или альтернативный UI
                            Expanded(
                              child: (!kIsWeb && Platform.isAndroid)
                                  ? _buildAndroidMapFallback(points, l10n)
                                  : DeliveryMapWidget(
                                      points: points,
                                      companyId: companyId,
                                      showDriverTracks: true,
                                      warehouseLat:
                                          CompanyCache.instance(companyId)
                                              .warehouseLat,
                                      warehouseLng:
                                          CompanyCache.instance(companyId)
                                              .warehouseLng,
                                    ),
                            ),
                            // Большая кнопка навигации убрана - никто не пользуется Google Maps
                            // Компактный список точек — максимум 25% экрана
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: points.isEmpty
                                  ? Center(
                                      child: Text(
                                        l10n.noActivePoints,
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 8,
                                          top: 2,
                                          bottom: 80),
                                      itemCount: points.length,
                                      itemBuilder: (context, index) {
                                        final point = points[index];
                                        final isCompleted =
                                            _isClosedPoint(point);
                                        final isActive = !isCompleted &&
                                            _currentPoint != null &&
                                            point.id == _currentPoint!.id;

                                        return Opacity(
                                          opacity: isCompleted ? 0.38 : 1.0,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? Colors.grey.shade100
                                                  : (isActive
                                                      ? Colors.green.shade50
                                                      : Colors.white),
                                              border: Border.all(
                                                color: isCompleted
                                                    ? Colors.grey.shade300
                                                    : (isActive
                                                        ? Colors.green.shade400
                                                        : Colors.grey.shade300),
                                                width: isActive ? 1.5 : 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              child: Row(
                                                children: [
                                                  // Номер
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          isCompleted
                                                              ? Colors
                                                                  .grey.shade400
                                                              : (isActive
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .blueGrey
                                                                      .shade400),
                                                      child: isCompleted
                                                          ? const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 14)
                                                          : Text(
                                                              '${index + 1}',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Имя + адрес
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          point.clientName,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isCompleted
                                                                ? Colors.grey
                                                                    .shade700
                                                                : Colors
                                                                    .black87,
                                                            decoration: isCompleted
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (point
                                                            .address.isNotEmpty)
                                                          Text(
                                                            point.address,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade800,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Статус / кнопка
                                                  _buildTrailingWidget(
                                                      context,
                                                      point,
                                                      isActive,
                                                      l10n,
                                                      points),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Простое расстояние в метрах (flat-earth, достаточно для Израиля)
  double _simpleDistanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const metersPerDeg = 111000.0;
    final dLat = (lat2 - lat1) * metersPerDeg;
    final dLng = (lng2 - lng1) * metersPerDeg * 0.848; // cos(32°)
    return (dLat * dLat + dLng * dLng) > 0
        ? _sqrtApprox(dLat * dLat + dLng * dLng)
        : 0.0;
  }

  double _sqrtApprox(double v) {
    if (v <= 0) return 0;
    double x = v / 2;
    for (int i = 0; i < 10; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  Future<void> _openWazeForPoint(
    BuildContext context,
    DeliveryPoint point,
    AppLocalizations l10n,
  ) async {
    final hasTemporaryAddress = point.temporaryAddress != null &&
        point.temporaryAddress!.trim().isNotEmpty;
    final address = hasTemporaryAddress
        ? point.temporaryAddress!.trim()
        : point.address.trim();
    final hasCoordinates = point.latitude != 0 || point.longitude != 0;

    final Uri url;
    if (hasTemporaryAddress && hasCoordinates) {
      // Для временного адреса используем уже пересчитанные координаты точки,
      // чтобы Waze не уводил по старому клиентскому адресу.
      url = Uri.parse(
        'https://waze.com/ul?ll=${point.latitude},${point.longitude}&navigate=yes',
      );
    } else if (address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      url = Uri.parse('https://waze.com/ul?q=$encoded&navigate=yes');
    } else {
      url = Uri.parse(
        'https://waze.com/ul?ll=${point.latitude},${point.longitude}&navigate=yes',
      );
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.wazeOpenError(e.toString()))),
        );
      }
    }
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    DeliveryPoint point,
    bool isActive,
    AppLocalizations l10n,
    List<DeliveryPoint> allPoints,
  ) {
    final isClosed = _isClosedPoint(point);
    if (isClosed &&
        DeliveryPoint.normalizeStatus(point.status) ==
            DeliveryPoint.statusCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }

    if (isClosed) {
      return const Icon(Icons.cancel, color: Colors.grey, size: 22);
    }

    // Кнопки "Waze" и "Выполнено" для каждой незавершённой точки
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        // Кнопка Waze
        SizedBox(
          height: 32,
          width: 32,
          child: IconButton(
            onPressed: () => _openWazeForPoint(context, point, l10n),
            icon: const Icon(Icons.navigation, color: Colors.blue, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Waze',
          ),
        ),
        const SizedBox(width: 4),
        // Кнопка "Выполнено"
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () async {
              if (_routeService == null) return;
              final authService = context.read<AuthService>();
              final messenger = ScaffoldMessenger.of(context);
              await _routeService!.updatePointStatus(
                point.id,
                DeliveryPoint.statusCompleted,
                updatedByUid: authService.currentUser?.uid,
              );
              if (mounted) {
                setState(() {
                  _markPointCompletedLocally(point.id);
                });
              }
              // Шаг: фиксируем факт визита (координата водителя в момент ручного закрытия)
              try {
                final companyId = authService.userModel?.companyId ?? '';
                final driverId = authService.currentUser?.uid ?? '';
                final hasDriverPos = _lastSentLat != 0 && _lastSentLng != 0;
                if (companyId.isNotEmpty && hasDriverPos) {
                  await FirestorePaths.deliveryPointsOf(companyId)
                      .doc(point.id)
                      .collection('visit_logs')
                      .add({
                    'lat': _lastSentLat,
                    'lng': _lastSentLng,
                    'driverId': driverId,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
              } catch (e) {
                debugPrint('visit_logs error: $e');
              }
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('✅ ${l10n.pointCompleted}: ${point.clientName}'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isActive ? Colors.green : Colors.blueGrey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: Text(l10n.pointDone),
          ),
        ),
      ],
    );
  }

  /// Android fallback UI when Google Maps is not available
  Widget _buildAndroidMapFallback(
      List<DeliveryPoint> points, AppLocalizations l10n) {
    final completedCount = points.where(_isClosedPoint).length;
    final totalCount = points.length;
    final remainingCount = totalCount - completedCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Заголовок
            Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  l10n.driverRouteTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (remainingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.nPoints(remainingCount),
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Статистика
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(l10n.totalLabel, totalCount, Colors.blue),
                      _buildStatItem(
                          l10n.completedLabel, completedCount, Colors.green),
                      _buildStatItem(
                          l10n.remainingLabel, remainingCount, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Прогресс-бар
                  LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.percentCompleted((totalCount > 0
                            ? (completedCount / totalCount * 100)
                            : 0)
                        .toInt()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Список следующих точек
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: points.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noActivePoints,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: points.length,
                        itemBuilder: (context, index) {
                          final point = points[index];
                          final isCompleted = _isClosedPoint(point);
                          final isNext = !isCompleted &&
                              index ==
                                  points.indexWhere((p) => !_isClosedPoint(p));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade50
                                  : (isNext
                                      ? Colors.blue.shade50
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.green.shade200
                                    : (isNext
                                        ? Colors.blue.shade200
                                        : Colors.grey.shade200),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isCompleted
                                    ? Colors.green
                                    : (isNext ? Colors.blue : Colors.grey),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                point.clientName,
                                style: TextStyle(
                                  fontWeight: isNext
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCompleted
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    point.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (point.eta != null)
                                    Text(
                                      'ETA: ${point.eta}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isCompleted
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20)
                                  : (isNext
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: IconButton(
                                            onPressed: () => _openWazeForPoint(
                                              context,
                                              point,
                                              l10n,
                                            ),
                                            icon: const Icon(
                                              Icons.navigation,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Waze',
                                          ),
                                        )
                                      : null),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
