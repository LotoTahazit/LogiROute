import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/optimized_location_service.dart';
import '../../services/background_location_service.dart';
import '../../core/correlation/correlation_context.dart';
import '../../services/realtime_gps_service.dart';
import '../../services/work_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../utils/delivery_point_address_resolver.dart';
import '../../models/driver_gps_status.dart';
import '../../services/gps_health.dart';
import '../../models/shift_schedule_config.dart';
import 'widgets/driver_app_bar_actions.dart';
import 'android_setup_sheet.dart';
import '../../widgets/delivery_map_widget.dart';
import '../../services/company_cache.dart';
import '../../services/firestore_paths.dart';
import '../../config/app_config.dart';
import '../../widgets/proof_of_delivery_sheet.dart';
import '../../services/driver_close_undo_state.dart';
import '../../services/driver_navigation_launcher.dart';
import '../../services/driver_auto_close_logic.dart';
import '../../services/driver_auto_close_prefs.dart';
import '../../services/driver_auto_close_state.dart';
import '../../services/company_settings_service.dart';
import '../../services/driver_session_service.dart';
import '../../services/driver_session_logic.dart';
import '../../models/driver_session.dart';
import '../../models/company_remote_config.dart';
import '../../services/company_remote_config_service.dart';
import 'widgets/driver_session_gate.dart';
import '../../theme/app_theme.dart';

// === ARRIVAL CONFIG ===
const double kStopSpeed = 2.0; // m/s (~7 km/h)
const int kStopTimeSec = 12; // seconds

enum _DriverSessionUi { loading, ready, blocked, lost }

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
  DriverGpsStatus _gpsStatus = DriverGpsStatus.waiting;
  DateTime? _lastGpsFixAt;
  DateTime? _trackingStartedAt;
  bool _needsBackgroundPermission = false;
  bool _firestoreWriteFailed = false;
  DateTime? _lastFirestoreOkAt;
  DateTime? _lastGpsFlipAt;
  Timer? _gpsHealthTimer;
  DateTime _lastFirestoreWarning = DateTime(2000);
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
  Set<String> _autoCloseDisabledIds = {};
  /// Политика компании: требовать POD-фото на каждую доставку (тогда нет
  /// автозакрытия и кнопки «Доставлено» — только «Закрыть с фото»).
  bool _photoRequired = false;
  /// Политика компании: разрешено ли автозакрытие точек по GPS. Если false —
  /// точки закрывает только водитель вручную (без таймера стоянки).
  bool _autoCloseCompanyEnabled = true;
  /// Показали ли уже в этой сессии подсказку про фоновое разрешение «Всегда».
  bool _bgPromptShown = false;
  /// Активное предложение «Отменить» (одна точка, с таймером).
  DriverCloseUndoOffer? _activeUndoOffer;
  Timer? _undoExpireTimer;
  Timer? _undoCountdownTimer;
  double? _lastKnownLat;
  double? _lastKnownLng;
  String? _visibleRouteKey;
  /// Все активные точки водителя (все маршруты) — для автозакрытия по GPS.
  List<DeliveryPoint> _allDriverActivePoints = [];
  String? _autoCloseDriverId;
  DeliveryPoint? _autoClosePendingPoint;
  double? _autoClosePendingDistanceM;
  int? _autoClosePendingRemainingSec;
  bool _bgServiceRunning = false;
  bool _bgSystemStopped = false;
  Timer? _bgStatusTimer;

  // Device session lock (только реальный водитель)
  bool _sessionEnforced = false;
  _DriverSessionUi _sessionUi = _DriverSessionUi.ready;
  DriverSessionService? _driverSessionService;
  DriverSession? _remoteSession;
  String? _sessionDeviceLabel;
  StreamSubscription<DriverSession?>? _sessionSub;
  Timer? _sessionHeartbeatTimer;

  CompanyRemoteConfig _rc = CompanyRemoteConfig.defaults;

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

  /// Другие маршруты с активными (assigned/in_progress) точками.
  int _otherActiveRoutePointCount(List<DeliveryPoint> all) {
    if (_visibleRouteKey == null) return 0;
    return all
        .where((p) =>
            _isActiveRoutePoint(p) &&
            _routeKeyForPoint(p) != _visibleRouteKey)
        .length;
  }

  String? _firstOtherActiveRouteKey(List<DeliveryPoint> all) {
    for (final p in all) {
      if (!_isActiveRoutePoint(p)) continue;
      final key = _routeKeyForPoint(p);
      if (key != _visibleRouteKey) return key;
    }
    return null;
  }

  Widget _buildOtherRouteBanner(
    List<DeliveryPoint> allPoints,
    AppLocalizations l10n,
  ) {
    final count = _otherActiveRoutePointCount(allPoints);
    if (count == 0) return const SizedBox.shrink();
    final otherKey = _firstOtherActiveRouteKey(allPoints);
    return Material(
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: otherKey == null
            ? null
            : () => setState(() => _visibleRouteKey = otherKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.alt_route, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.driverAnotherRoutePoints(count),
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade700),
            ],
          ),
        ),
      ),
    );
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
      final group = byRoute[preferredRouteKey]!;
      // Кеш маршрута удерживаем только пока есть незакрытые точки
      if (group.any((p) => !_isClosedPoint(p))) {
        return preferredRouteKey;
      }
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
        'deliveryAddressOverride': p.deliveryAddressOverride,
        'deliveryAddressOverrideLat': p.deliveryAddressOverrideLat,
        'deliveryAddressOverrideLng': p.deliveryAddressOverrideLng,
        'taskNote': p.taskNote,
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
        deliveryAddressOverride: m['deliveryAddressOverride'] ?? m['temporaryAddress'],
        deliveryAddressOverrideLat:
            (m['deliveryAddressOverrideLat'] as num?)?.toDouble(),
        deliveryAddressOverrideLng:
            (m['deliveryAddressOverrideLng'] as num?)?.toDouble(),
        taskNote: m['taskNote'],
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

  bool _isRealDriver(AuthService auth) {
    if (auth.viewAsRole != null) return false;
    return auth.userModel?.isDriver == true;
  }

  Future<void> _bootDriverSession() async {
    final auth = context.read<AuthService>();
    if (!_isRealDriver(auth)) {
      if (mounted) {
        setState(() {
          _sessionEnforced = false;
          _sessionUi = _DriverSessionUi.ready;
        });
      }
      return;
    }

    final companyId = auth.userModel?.companyId ?? '';
    final driverId = auth.currentUser?.uid ?? '';
    if (companyId.isEmpty || driverId.isEmpty) return;

    // Load remote config from prefs (cached by foreground app).
    _rc = await CompanyRemoteConfigService.fromPrefs(companyId);

    // If session lock disabled via remote config — skip entirely.
    if (!_rc.driverDeviceSessionLockEnabled) {
      if (mounted) {
        setState(() {
          _sessionEnforced = false;
          _sessionUi = _DriverSessionUi.ready;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _sessionEnforced = true;
        _sessionUi = _DriverSessionUi.loading;
      });
    }

    _driverSessionService = DriverSessionService(
      companyId: companyId,
      sessionStale: _rc.sessionStale,
    );
    final deviceLabel = await DriverSessionService.resolveDeviceLabel();

    if (await DriverSessionService.consumeSessionLostFlag()) {
      if (mounted) {
        setState(() {
          _sessionEnforced = true;
          _sessionUi = _DriverSessionUi.lost;
          _sessionDeviceLabel = deviceLabel;
        });
      }
      return;
    }

    final result = await _driverSessionService!.tryClaimOrVerify(
      driverId: driverId,
      userId: driverId,
      correlationId: CorrelationContext.resolveId(),
    );
    if (!mounted) return;

    if (result.isBlocked) {
      setState(() {
        _sessionEnforced = true;
        _sessionUi = _DriverSessionUi.blocked;
        _remoteSession = result.remote;
        _sessionDeviceLabel = deviceLabel;
      });
      return;
    }

    setState(() {
      _sessionEnforced = true;
      _sessionUi = _DriverSessionUi.ready;
      _sessionDeviceLabel = deviceLabel;
    });
    _startSessionWatch(driverId);
    _startSessionHeartbeat(driverId);
  }

  void _startSessionWatch(String driverId) {
    _sessionSub?.cancel();
    _sessionSub = _driverSessionService?.watchSession(driverId).listen((session) async {
      if (!_sessionEnforced || session == null || _sessionUi != _DriverSessionUi.ready) {
        return;
      }
      final deviceId = await DriverSessionService.getOrCreateDeviceId();
      if (!driverSessionOwnedByDevice(session, deviceId)) {
        await _onSessionLost(session);
      }
    });
  }

  void _startSessionHeartbeat(String driverId) {
    _sessionHeartbeatTimer?.cancel();
    _sessionHeartbeatTimer = Timer.periodic(
      _rc.sessionHeartbeat,
      (_) async {
        if (_sessionUi != _DriverSessionUi.ready || _driverSessionService == null) {
          return;
        }
        final ok = await _driverSessionService!.heartbeat(
          driverId: driverId,
          userId: driverId,
          correlationId: CorrelationContext.resolveId(),
        );
        if (!ok && mounted) {
          final remote = await _driverSessionService!.fetchSession(driverId);
          await _onSessionLost(remote);
        }
      },
    );
  }

  Future<void> _onSessionLost(DriverSession? remote) async {
    if (_sessionUi == _DriverSessionUi.lost) return;
    _sessionHeartbeatTimer?.cancel();
    if (_isTrackingActive) await _stopTracking();
    final driverId = context.read<AuthService>().currentUser?.uid ?? '';
    if (driverId.isNotEmpty) {
      await _driverSessionService?.auditSessionLost(
        driverId: driverId,
        userId: driverId,
        remote: remote,
        correlationId: CorrelationContext.resolveId(),
      );
    }
    await DriverSessionService.markSessionLostFlag();
    if (mounted) setState(() => _sessionUi = _DriverSessionUi.lost);
  }

  Future<bool> _ensureSessionActive() async {
    if (!_sessionEnforced || _sessionUi != _DriverSessionUi.ready) return false;
    final auth = context.read<AuthService>();
    final companyId = auth.userModel?.companyId ?? '';
    final driverId = auth.currentUser?.uid ?? '';
    if (companyId.isEmpty || driverId.isEmpty) return true;
    final ok = await DriverSessionService.verifyOwnership(
      companyId: companyId,
      driverId: driverId,
    );
    if (!ok) {
      final remote = await _driverSessionService?.fetchSession(driverId);
      await _onSessionLost(remote);
    }
    return ok;
  }

  Future<void> _takeoverDriverSession() async {
    final auth = context.read<AuthService>();
    final driverId = auth.currentUser?.uid ?? '';
    if (driverId.isEmpty || _driverSessionService == null) return;
    await _driverSessionService!.forceTakeover(
      driverId: driverId,
      userId: driverId,
      correlationId: CorrelationContext.resolveId(),
    );
    if (!mounted) return;
    setState(() => _sessionUi = _DriverSessionUi.ready);
    _startSessionWatch(driverId);
    _startSessionHeartbeat(driverId);
  }

  Future<void> _logoutFromSessionGate() async {
    final auth = context.read<AuthService>();
    final driverId = auth.currentUser?.uid ?? '';
    if (driverId.isNotEmpty) {
      await _driverSessionService?.releaseSession(driverId);
    }
    await auth.signOut();
  }

  void _acknowledgeSessionLost() {
    unawaited(_logoutFromSessionGate());
  }

  @override
  void initState() {
    super.initState();

    // 🛡️ Восстанавливаем кеш при старте (до первого build)
    _restorePointsFromCache();
    _loadAutoClosePrefs();
    _recoverBackgroundState();

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
      if (_isTrackingActive && _gpsStatus == DriverGpsStatus.active) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootDriverSession();
    });

    _gpsHealthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _runGpsHealthCheck();
    });
    _bgStatusTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshBgServiceStatus();
    });
  }

  Future<void> _recoverBackgroundState() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final wasActive = prefs.getBool('bg_tracking_active') ?? false;
    if (!wasActive) return;

    final pending = await DriverAutoCloseState.loadPending();
    if (pending != null) {
      _autoCloseArrivalTimes[pending.pointId] = pending.startedAt;
    }

    await _refreshBgServiceStatus();
    if (!mounted) return;

    if (_bgSystemStopped) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.bgSystemStoppedWarning),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: l10n.bgOpenSetup,
                onPressed: () => showAndroidSetupSheet(context),
              ),
            ),
          );
        });
      }
    }
  }

  Future<void> _refreshBgServiceStatus() async {
    if (kIsWeb) return;
    final running = await BackgroundLocationService.isRunning();
    final stopped = await DriverAutoCloseState.wasSystemStoppedBg();
    if (!mounted) return;
    if (running == _bgServiceRunning && stopped == _bgSystemStopped) return;
    setState(() {
      _bgServiceRunning = running;
      _bgSystemStopped = stopped;
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

  Future<void> _loadAutoClosePrefs() async {
    if (kIsWeb) return;
    final ids = await DriverAutoClosePrefs.loadDisabled();
    if (mounted) setState(() => _autoCloseDisabledIds = ids);

    // Политика компании «POD-фото обязательно»: при включении автозакрытие
    // (без фото) отключаем и прячем кнопку «Доставлено». Зеркалим в prefs,
    // чтобы фоновый сервис тоже учитывал.
    try {
      final companyId = context.read<AuthService>().userModel?.companyId ?? '';
      if (companyId.isNotEmpty) {
        final rc = await CompanyRemoteConfigService().get(companyId);
        if (mounted) setState(() => _rc = rc);
        final cs =
            await CompanySettingsService(companyId: companyId).getSettings();
        final req = cs?.requirePodPhoto ?? false;
        final autoOn = cs?.autoCloseEnabled ?? true;
        await DriverAutoClosePrefs.setPhotoRequired(req);
        await DriverAutoClosePrefs.setAutoCloseEnabled(autoOn);
        if (mounted) {
          setState(() {
            _photoRequired = req;
            _autoCloseCompanyEnabled = autoOn;
          });
        }
      }
    } catch (e) {
      debugPrint('autoclose: load company photo policy: $e');
    }
  }

  Future<void> _setAutoCloseEnabled(DeliveryPoint point, bool enabled) async {
    if (kIsWeb) return;
    await DriverAutoClosePrefs.setDisabled(point.id, !enabled);
    if (!mounted) return;
    setState(() {
      if (enabled) {
        _autoCloseDisabledIds.remove(point.id);
      } else {
        _autoCloseDisabledIds.add(point.id);
        _autoCloseArrivalTimes.remove(point.id);
      }
    });
  }

  void _offerCloseUndo(
    DeliveryPoint point, {
    required String previousStatus,
    required bool autoCompleted,
    Duration? uiDuration,
  }) {
    _clearCloseUndo();
    final now = DateTime.now();
    _activeUndoOffer = createCloseUndoOffer(
      point: point,
      previousStatus: previousStatus,
      autoCompleted: autoCompleted,
      now: now,
      uiDuration: uiDuration ?? _rc.closeUndo,
    );
    final remaining = _activeUndoOffer!.expiresAt.difference(now);
    _undoExpireTimer = Timer(remaining, _clearCloseUndo);
    _undoCountdownTimer?.cancel();
    _undoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_activeUndoOffer == null ||
          _activeUndoOffer!.isExpired(DateTime.now())) {
        _clearCloseUndo();
      } else {
        setState(() {});
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {});
  }

  void _clearCloseUndo() {
    _undoExpireTimer?.cancel();
    _undoCountdownTimer?.cancel();
    _undoExpireTimer = null;
    _undoCountdownTimer = null;
    if (_activeUndoOffer == null) return;
    _activeUndoOffer = null;
    if (mounted) setState(() {});
  }

  Future<void> _performCloseUndo() async {
    final offer = _activeUndoOffer;
    if (offer == null || offer.isExpired(DateTime.now())) {
      _clearCloseUndo();
      return;
    }
    if (_routeService == null) return;
    final driverId = context.read<AuthService>().currentUser?.uid ?? '';
    final correlationId = CorrelationContext.resolveId();
    _clearCloseUndo();
    try {
      final ok = await _routeService!.undoPointClose(
        offer.pointId,
        restoreStatus: offer.previousStatus,
        updatedByUid: driverId,
        correlationId: correlationId,
      );
      if (!ok || !mounted) return;
      setState(() {
        _lastPoints = _lastPoints.map((p) {
          if (p.id != offer.pointId) return p;
          return p.copyWith(
            status: offer.previousStatus,
            autoCompleted: false,
            completedAt: null,
            updatedAt: DateTime.now(),
          );
        }).toList();
        if (_currentPoint == null || _currentPoint!.id == offer.pointId) {
          _currentPoint = _lastPoints.cast<DeliveryPoint?>().firstWhere(
                (p) => p?.id == offer.pointId,
                orElse: () => null,
              );
        }
        _autoCloseArrivalTimes[offer.pointId] = DateTime.now();
      });
    } catch (e) {
      debugPrint('❌ [Undo] failed: $e');
      if (mounted) setState(() {});
    }
  }

  /// Undo для автозакрытия в фоне, когда баннер не успел показаться.
  void _maybeOfferBackgroundUndo(List<DeliveryPoint> points) {
    if (kIsWeb || !mounted || _activeUndoOffer != null) return;
    final now = DateTime.now();
    for (final p in points) {
      if (!shouldOfferBackgroundUndo(
        point: p,
        now: now,
        activeOffer: _activeUndoOffer,
      )) {
        continue;
      }
      final remaining = closeUndoRemainingUi(
        p.completedAt!,
        now,
        maxUi: _rc.closeUndo,
      );
      if (remaining <= Duration.zero) continue;
      _offerCloseUndo(
        p,
        previousStatus: DeliveryPoint.statusInProgress,
        autoCompleted: true,
        uiDuration: remaining,
      );
      break;
    }
  }

  Widget _buildCloseUndoBanner(AppLocalizations l10n) {
    final offer = _activeUndoOffer;
    if (offer == null || offer.isExpired(DateTime.now())) {
      return const SizedBox.shrink();
    }
    final sec = offer.remainingSeconds(DateTime.now());
    final msg = offer.autoCompleted
        ? l10n.autoCloseUndoMessage
        : l10n.pointCloseUndoMessage(offer.clientName);
    return Material(
      color: Colors.deepOrange.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.undo, color: Colors.deepOrange.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$msg · ${sec}s',
                style: TextStyle(
                  color: Colors.deepOrange.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _performCloseUndo,
              child: Text(l10n.undo),
            ),
          ],
        ),
      ),
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

  void _onGpsStatusChanged(DriverGpsStatus status) {
    _applyGpsStatus(status, source: 'stream');
  }

  /// Единая точка смены статуса с антидребезгом (цвет-флип ≤ 1 раз / 30 с) и
  /// debug-логом `[GPS Health]`. Источники: stream / local / manual / background.
  void _applyGpsStatus(
    DriverGpsStatus next, {
    required String source,
    bool debounce = true,
    bool? permission,
    bool? serviceEnabled,
  }) {
    if (!mounted) return;
    final prev = _gpsStatus;
    final now = DateTime.now();
    final apply = !debounce ||
        GpsHealth.shouldApplyDriverStatus(
          current: prev,
          next: next,
          lastFlipAt: _lastGpsFlipAt,
          now: now,
        );
    debugPrint('[GPS Health] ${jsonEncode({
          'source': source,
          'statusBefore': prev.name,
          'statusAfter': (apply ? next : prev).name,
          'localFixAgeSec': _lastGpsFixAt == null
              ? null
              : now.difference(_lastGpsFixAt!).inSeconds,
          'firestoreAgeSec': _lastFirestoreOkAt == null
              ? null
              : now.difference(_lastFirestoreOkAt!).inSeconds,
          'uploadOk': !_firestoreWriteFailed,
          'permission': permission,
          'serviceEnabled': serviceEnabled,
          'applied': apply && next != prev,
        })}');
    if (!apply || next == prev) return;
    if (GpsHealth.isDriverColorFlip(prev, next)) _lastGpsFlipAt = now;
    setState(() => _gpsStatus = next);
  }

  void _onGpsFirestoreOk() {
    _lastFirestoreOkAt = DateTime.now();
    if (_firestoreWriteFailed && mounted) {
      setState(() => _firestoreWriteFailed = false);
    }
  }

  void _onGpsFirestoreError(Object error) {
    debugPrint('❌ [Driver] GPS Firestore write error: $error');
    if (!mounted) return;
    setState(() => _firestoreWriteFailed = true);
    final now = DateTime.now();
    if (now.difference(_lastFirestoreWarning).inSeconds < 60) return;
    _lastFirestoreWarning = now;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.gpsFirestoreWriteFailed),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _refreshBackgroundPermissionFlag() async {
    if (kIsWeb) return;
    final perm = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _needsBackgroundPermission = perm == LocationPermission.whileInUse;
      });
    }
  }

  void _runGpsHealthCheck() {
    if (!mounted || !_isTrackingActive) return;
    unawaited(_evaluateGpsHealth(source: 'background'));
  }

  /// Централизованная оценка GPS-здоровья. КЛЮЧ ФИКСА: возраст локального fix
  /// освежаем из OS last-known (стрим молчит на стоянке из-за distanceFilter),
  /// затем решение принимает чистая [GpsHealth.evaluateDriverGpsStatus].
  Future<void> _evaluateGpsHealth({required String source}) async {
    if (kIsWeb || !mounted || !_isTrackingActive) return;

    var serviceEnabled = true;
    var permissionGranted = true;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      permissionGranted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (serviceEnabled && permissionGranted) {
        final last = await Geolocator.getLastKnownPosition();
        final ts = last?.timestamp;
        if (ts != null &&
            (_lastGpsFixAt == null || ts.isAfter(_lastGpsFixAt!))) {
          _lastGpsFixAt = ts;
        }
      }
    } catch (e) {
      debugPrint('[GPS Health] probe error: $e');
    }
    if (!mounted || !_isTrackingActive) return;

    final now = DateTime.now();
    final next = GpsHealth.evaluateDriverGpsStatus(
      serviceEnabled: serviceEnabled,
      permissionGranted: permissionGranted,
      localFixAge:
          _lastGpsFixAt == null ? null : now.difference(_lastGpsFixAt!),
      sinceTrackingStart: _trackingStartedAt == null
          ? Duration.zero
          : now.difference(_trackingStartedAt!),
      uploadOk: !_firestoreWriteFailed,
      uiStaleThreshold: _rc.driverGpsUiStale,
    );
    _applyGpsStatus(
      next,
      source: source,
      permission: permissionGranted,
      serviceEnabled: serviceEnabled,
    );
  }

  /// Кнопка «בדוק שוב»: реальный health-refresh — проверка службы/разрешения,
  /// свежий getCurrentPosition, запись в Firestore, и только потом смена статуса.
  Future<void> _recheckGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _applyGpsStatus(DriverGpsStatus.disabled,
          source: 'manual', debounce: false);
      await Geolocator.openLocationSettings();
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _applyGpsStatus(DriverGpsStatus.permissionRequired,
          source: 'manual', debounce: false);
      await Geolocator.openAppSettings();
      return;
    }

    await _refreshBackgroundPermissionFlag();
    if (!mounted || !_isTrackingActive) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (!mounted || !_isTrackingActive) return;

    if (pos != null) {
      _lastKnownLat = pos.latitude;
      _lastKnownLng = pos.longitude;
      _lastGpsFixAt = DateTime.now();
      final ok = await _locationService?.writeManualFix(pos) ?? false;
      if (ok) _onGpsFirestoreOk();
      _lastGpsFlipAt = null; // ручная проверка обходит антидребезг
      _applyGpsStatus(
        ok ? DriverGpsStatus.active : DriverGpsStatus.uploadError,
        source: 'manual',
        debounce: false,
      );
      return;
    }

    // Нет позиции вовсе — перезапуск стрима как fallback.
    await _restartTracking();
  }

  Future<void> _restartTracking() async {
    if (!mounted || !_isTrackingActive) return;
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthService>();
    final driverId = auth.currentUser?.uid ?? '';
    if (driverId.isEmpty) return;
    final driverName = auth.userModel?.name ?? l10n?.driverFallbackName ?? 'Driver';
    final userRole = auth.userModel?.role ?? 'driver';

    _locationService?.stopTracking();
    final status = await _locationService?.startTracking(
          driverId,
          driverName,
          _onLocationUpdate,
          userRole: userRole,
          onStatusChanged: _onGpsStatusChanged,
          onFirestoreWriteError: _onGpsFirestoreError,
          onFirestoreWriteOk: _onGpsFirestoreOk,
        ) ??
        DriverGpsStatus.stale;

    if (mounted) {
      setState(() {
        _gpsStatus = status;
        _trackingStartedAt = DateTime.now();
        _lastGpsFixAt = null;
        _firestoreWriteFailed = false;
        _lastGpsFlipAt = null;
      });
    }
  }

  String _gpsStatusLabel(DriverGpsStatus status, AppLocalizations l10n) {
    switch (status) {
      case DriverGpsStatus.active:
        return l10n.gpsStatusActive;
      case DriverGpsStatus.waiting:
        return l10n.gpsStatusWaiting;
      case DriverGpsStatus.uploadError:
        return l10n.gpsStatusUploadError;
      case DriverGpsStatus.stale:
        return l10n.gpsStatusError;
      case DriverGpsStatus.disabled:
        return l10n.gpsStatusDisabled;
      case DriverGpsStatus.permissionRequired:
        return l10n.gpsStatusPermissionRequired;
    }
  }

  Future<void> _startTracking() async {
    debugPrint('🚀 [GPS] _startTracking() called from driver dashboard');
    if (!await _ensureSessionActive()) return;
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
    setState(() {
      _isTrackingActive = true;
      _trackingStartedAt = DateTime.now();
      _lastGpsFixAt = null;
      _firestoreWriteFailed = false;
      _lastGpsFlipAt = null;
    });

    final gpsStatus = await _locationService?.startTracking(
          driverId,
          driverName,
          _onLocationUpdate,
          userRole: userRole,
          onStatusChanged: _onGpsStatusChanged,
          onFirestoreWriteError: _onGpsFirestoreError,
          onFirestoreWriteOk: _onGpsFirestoreOk,
        ) ??
        DriverGpsStatus.stale;

    if (mounted) {
      setState(() => _gpsStatus = gpsStatus);
      await _refreshBackgroundPermissionFlag();
    }

    // Background foreground-service (когда приложение свёрнуто, только мобильные)
    if (!kIsWeb &&
        gpsStatus != DriverGpsStatus.disabled &&
        gpsStatus != DriverGpsStatus.permissionRequired) {
      await DriverAutoCloseState.clearSystemStoppedBg();
      BackgroundLocationService.start(driverId, driverName, companyId);
      unawaited(_refreshBgServiceStatus());
    }

    // WebSocket GPS для live-карты диспетчера
    _realtimeGps.connectAsDriver();

    // Foreground auto-close: таймер каждые 30 сек проверяет точки
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkAutoClose(),
    );

    if (_gpsStatus == DriverGpsStatus.active ||
        _gpsStatus == DriverGpsStatus.waiting) {
      _showGpsNotification();
    }
    if (!kIsWeb && Platform.isAndroid) {
      _maybeShowAndroidSetup();
    } else {
      _ensureBackgroundLocation();
    }
    debugPrint('✅ [Driver] Tracking started: $driverName status=$_gpsStatus');
  }

  /// Один раз на установку показываем памятку по фоновым настройкам Android
  /// (геолокация «Всегда», батарея, автозапуск). Потом доступна из меню «?».
  Future<void> _maybeShowAndroidSetup() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('driver_android_setup_shown') ?? false) return;
    await prefs.setBool('driver_android_setup_shown', true);
    if (!mounted) return;
    await showAndroidSetupSheet(context);
  }

  /// Если выдан доступ к локации только «при использовании» — трек обрывается,
  /// когда телефон заблокирован. Подсказываем водителю включить «Всегда».
  Future<void> _ensureBackgroundLocation() async {
    if (kIsWeb || _bgPromptShown) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse) return;
      if (!mounted) return;
      _bgPromptShown = true;
      final l10n = AppLocalizations.of(context);
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.bgLocationTitle ?? 'Background location'),
          content: Text(l10n?.bgLocationBody ??
              'For full trip tracking, allow location "All the time".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n?.cancelButton ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n?.bgLocationOpenSettings ?? 'Open settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('bg-location prompt: $e');
    }
  }

  Future<void> _stopTracking() async {
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
    setState(() {
      _isTrackingActive = false;
      _gpsStatus = DriverGpsStatus.waiting;
      _lastGpsFixAt = null;
      _trackingStartedAt = null;
      _needsBackgroundPermission = false;
      _firestoreWriteFailed = false;
      _lastGpsFlipAt = null;
    });
    _hideGpsNotification();
    debugPrint('🛑 [Driver] Tracking stopped');
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _sessionHeartbeatTimer?.cancel();
    _shiftsSub?.cancel();
    _scheduleStatusTimer?.cancel();
    _gpsHealthTimer?.cancel();
    _autoCloseTimer?.cancel();
    _undoExpireTimer?.cancel();
    _undoCountdownTimer?.cancel();
    _bgStatusTimer?.cancel();
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

  // Оценка скорости по смещению GPS-фиксов — для гейта «стоит/едет».
  double? _autoPrevLat;
  double? _autoPrevLng;
  DateTime? _autoPrevAt;
  double? _lastGpsSpeedMps;

  /// Водитель считается стоящим, если скорость < ~1.5 м/с (≈5 км/ч) или ещё
  /// неизвестна (нет данных — не блокируем закрытие, край ловит Undo).
  bool get _isDriverStationaryNow {
    final s = _lastGpsSpeedMps;
    return s == null || s < 1.5;
  }

  void _onLocationUpdate(double lat, double lon) {
    if (_routeService == null) return;

    // Сохраняем последнюю GPS-позицию для таймера автозакрытия
    _lastKnownLat = lat;
    _lastKnownLng = lon;
    _lastGpsFixAt = DateTime.now();
    // Реальный fix — наземная истина: статус ставим сразу, без антидребезга.
    _applyGpsStatus(
      _firestoreWriteFailed
          ? DriverGpsStatus.uploadError
          : DriverGpsStatus.active,
      source: 'local',
      debounce: false,
    );

    // Скорость по смещению между фиксами (для гейта по остановке).
    final nowFix = DateTime.now();
    if (_autoPrevLat != null && _autoPrevAt != null) {
      final moved = _simpleDistanceMeters(_autoPrevLat!, _autoPrevLng!, lat, lon);
      final secs = nowFix.difference(_autoPrevAt!).inMilliseconds / 1000.0;
      if (secs >= 1.0) _lastGpsSpeedMps = moved / secs;
    }
    _autoPrevLat = lat;
    _autoPrevLng = lon;
    _autoPrevAt = nowFix;

    if (_isTrackingActive && _gpsStatus == DriverGpsStatus.active) {
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
    final isInsideRadius = distance <= _rc.autoCloseRadiusMeters;

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

  /// Foreground auto-close: проверяет ВСЕ активные точки водителя (все маршруты).
  /// Ближайшая в радиусе — без привязки к порядку маршрута.
  Future<void> _checkAutoClose() async {
    if (_photoRequired) return;
    if (!_autoCloseCompanyEnabled) return;
    if (!await _ensureSessionActive()) return;
    final lat = _lastKnownLat;
    final lng = _lastKnownLng;
    if (lat == null || lng == null) return;
    if (_routeService == null) return;
    if (!mounted) return;

    final driverId = _autoCloseDriverId ??
        context.read<AuthService>().currentUser?.uid ??
        '';
    if (driverId.isEmpty) return;

    final now = DateTime.now();
    final candidates = _allDriverActivePoints.isNotEmpty
        ? _allDriverActivePoints
        : _lastPoints
            .where((p) => isDriverAutoCloseEligible(
                  p,
                  driverId: driverId,
                  disabledPointIds: _autoCloseDisabledIds,
                ))
            .toList();

    final activeIds = candidates.map((p) => p.id).toSet();
    _autoCloseArrivalTimes.removeWhere((id, _) => !activeIds.contains(id));

    final target = selectNearestDriverAutoCloseTarget(
      driverLat: lat,
      driverLng: lng,
      points: candidates,
      driverId: driverId,
      disabledPointIds: _autoCloseDisabledIds,
      enterRadiusM: _rc.autoCloseRadiusMeters,
    );

    if (target == null ||
        shouldResetDriverAutoCloseTimer(
          distanceMeters: target.distanceMeters,
          resetRadiusM: _rc.autoCloseResetRadiusMeters,
        )) {
      if (_autoCloseArrivalTimes.isNotEmpty || _autoClosePendingPoint != null) {
        debugPrint('↩️ [AutoClose] Вне радиуса — таймер сброшен');
        _autoCloseArrivalTimes.clear();
        unawaited(DriverAutoCloseState.clearPending());
        _updateAutoClosePendingUi(null, null, null);
      }
      return;
    }

    final targetId = target.point.id;
    _autoCloseArrivalTimes.removeWhere((id, _) => id != targetId);

    if (!_autoCloseArrivalTimes.containsKey(targetId)) {
      _autoCloseArrivalTimes[targetId] = now;
      unawaited(DriverAutoCloseState.savePending(
        pointId: targetId,
        startedAt: now,
      ));
      _logAutoCloseAudit(
        driverId: driverId,
        point: target.point,
        distanceMeters: target.distanceMeters,
        phase: 'timer_started',
        waitSeconds: _rc.autoCloseWaitSeconds,
      );
      debugPrint(
        '📍 [AutoClose] Стоит у ${target.point.clientName} '
        '(${target.distanceMeters.toStringAsFixed(0)} м), таймер запущен',
      );
    }

    final startedAt = _autoCloseArrivalTimes[targetId]!;
    final remaining = driverAutoCloseRemainingSeconds(
      startedAt,
      now,
      waitDuration: _rc.autoCloseWait,
    );
    _updateAutoClosePendingUi(target.point, target.distanceMeters, remaining);

    if (driverAutoCloseWaitComplete(
      startedAt,
      now,
      waitDuration: _rc.autoCloseWait,
    )) {
      final correlationId = CorrelationContext.resolveId();
      _logAutoCloseAudit(
        driverId: driverId,
        point: target.point,
        distanceMeters: target.distanceMeters,
        phase: 'closing',
        waitSeconds: _rc.autoCloseWaitSeconds,
        correlationId: correlationId,
      );
      debugPrint(
        '✅ [AutoClose] Автозакрытие: ${target.point.clientName} '
        '(${now.difference(startedAt).inSeconds} сек стоянки)',
      );
      final ok = await _autoCompletePoint(
        target.point,
        correlationId: correlationId,
        distanceMeters: target.distanceMeters,
      );
      if (ok) {
        _autoCloseArrivalTimes.remove(targetId);
        _updateAutoClosePendingUi(null, null, null);
      }
    }
  }

  void _updateAutoClosePendingUi(
    DeliveryPoint? point,
    double? distanceM,
    int? remainingSec,
  ) {
    if (!mounted) return;
    if (_autoClosePendingPoint?.id == point?.id &&
        _autoClosePendingDistanceM == distanceM &&
        _autoClosePendingRemainingSec == remainingSec) {
      return;
    }
    setState(() {
      _autoClosePendingPoint = point;
      _autoClosePendingDistanceM = distanceM;
      _autoClosePendingRemainingSec = remainingSec;
    });
  }

  void _logAutoCloseAudit({
    required String driverId,
    required DeliveryPoint point,
    required double distanceMeters,
    required String phase,
    required int waitSeconds,
    String? correlationId,
  }) {
    debugPrint(
      '🔎 [AutoClose] ${jsonEncode({
        'phase': phase,
        'driverId': driverId,
        'selectedPointId': point.id,
        'selectedPointName': point.clientName,
        'distanceMeters': distanceMeters.round(),
        'radiusMeters': _rc.autoCloseRadiusMeters.round(),
        'resetRadiusMeters': _rc.autoCloseResetRadiusMeters.round(),
        'waitSeconds': waitSeconds,
        if (correlationId != null) 'correlationId': correlationId,
      })}',
    );
  }

  Widget _buildAutoClosePendingBanner(AppLocalizations l10n) {
    final point = _autoClosePendingPoint;
    final dist = _autoClosePendingDistanceM;
    final sec = _autoClosePendingRemainingSec;
    if (point == null || dist == null || sec == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.blue.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.autoClosePendingBanner(
                  point.clientName,
                  dist.round(),
                  sec,
                ),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completePointWithPod(
    BuildContext context,
    DeliveryPoint point,
    AppLocalizations l10n,
  ) async {
    if (_routeService == null) return;
    if (!await _ensureSessionActive()) return;
    if (!kIsWeb) await _setAutoCloseEnabled(point, false);
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser?.uid ?? '';

    final correlationId = CorrelationContext.resolveId();

    if (!kIsWeb && companyId.isNotEmpty) {
      final pod = await showProofOfDeliverySheet(
        context: context,
        point: point,
        companyId: companyId,
      );
      if (pod == null || !mounted) return;

      await _routeService!.updatePointStatus(
        point.id,
        DeliveryPoint.statusCompleted,
        updatedByUid: driverId,
        podPhotoUrl: pod.photoUrl,
        podLat: pod.lat,
        podLng: pod.lng,
        podDistanceM: pod.distanceM,
        correlationId: correlationId,
      );
    } else {
      await _routeService!.updatePointStatus(
        point.id,
        DeliveryPoint.statusCompleted,
        updatedByUid: driverId,
        correlationId: correlationId,
      );
      try {
        if (companyId.isNotEmpty &&
            _lastSentLat != 0 &&
            _lastSentLng != 0) {
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
    }

    if (!mounted) return;
    setState(() => _markPointCompletedLocally(point.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text('✅ ${l10n.pointCompleted}: ${point.clientName}'),
      ),
    );
  }

  /// Ручное закрытие БЕЗ фото («Доставлено») — для обычной доставки, когда
  /// автозакрытие не сработало. Ведёт себя как авто: completed, без POD.
  Future<void> _completePointPlain(
    BuildContext context,
    DeliveryPoint point,
    AppLocalizations l10n,
  ) async {
    if (_routeService == null) return;
    if (!await _ensureSessionActive()) return;
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser?.uid ?? '';
    final previousStatus = DeliveryPoint.normalizeStatus(point.status);

    final correlationId = CorrelationContext.resolveId();

    await _routeService!.updatePointStatus(
      point.id,
      DeliveryPoint.statusCompleted,
      updatedByUid: driverId,
      correlationId: correlationId,
    );
    // Лог посещения (GPS) — как в ветке без фото у _completePointWithPod.
    try {
      if (companyId.isNotEmpty && _lastSentLat != 0 && _lastSentLng != 0) {
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

    if (!mounted) return;
    setState(() => _markPointCompletedLocally(point.id));
    _offerCloseUndo(
      point,
      previousStatus: previousStatus,
      autoCompleted: false,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text('✅ ${l10n.pointCompleted}: ${point.clientName}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _autoCompletePoint(
    DeliveryPoint point, {
    String? correlationId,
    double? distanceMeters,
  }) async {
    try {
      if (!await _ensureSessionActive()) return false;
      final authService = context.read<AuthService>();
      final driverId = authService.currentUser?.uid ?? '';
      final companyId = authService.userModel?.companyId ?? '';
      if (companyId.isEmpty || driverId.isEmpty) return false;
      final previousStatus = DeliveryPoint.normalizeStatus(point.status);
      final cid = correlationId ?? CorrelationContext.resolveId();
      final lat = _lastKnownLat;
      final lng = _lastKnownLng;
      if (lat == null || lng == null) return false;

      final closed = await DriverAutoCloseState.tryCompletePoint(
        companyId: companyId,
        pointId: point.id,
        driverId: driverId,
        lat: lat,
        lng: lng,
        distanceMeters: distanceMeters ?? 0,
        correlationId: cid,
      );
      if (!closed) return false;

      if (mounted) {
        setState(() {
          _markPointCompletedLocally(point.id);
          _autoCloseArrivalTimes.remove(point.id);
        });
        _offerCloseUndo(
          point,
          previousStatus: previousStatus,
          autoCompleted: true,
        );
      }
      debugPrint(
          '✅ [AutoClose] Point ${point.clientName} auto-completed');
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

  Widget _buildGpsStatusBanner(AppLocalizations l10n) {
    late Color bg;
    late Color border;
    late Color fg;
    late IconData icon;
    late String title;
    final subtitles = <String>[];

    if (!_isTrackingActive) {
      bg = AppTheme.muted.withValues(alpha: 0.14);
      border = AppTheme.muted;
      fg = AppTheme.muted;
      icon = Icons.info_outline;
      title = l10n.gpsTrackingStopped;
    } else {
      switch (_gpsStatus) {
        case DriverGpsStatus.active:
          bg = AppTheme.green.withValues(alpha: 0.12);
          border = AppTheme.green;
          fg = AppTheme.green;
          icon = Icons.gps_fixed;
          title = l10n.gpsTrackingActive;
          break;
        case DriverGpsStatus.waiting:
          bg = AppTheme.warning.withValues(alpha: 0.12);
          border = AppTheme.warning;
          fg = AppTheme.warning;
          icon = Icons.gps_not_fixed;
          title = l10n.gpsStatusWaiting;
          break;
        case DriverGpsStatus.uploadError:
          // GPS исправен, но запись в Firestore не прошла → жёлтый warning,
          // НЕ красный «GPS не работает».
          bg = AppTheme.warning.withValues(alpha: 0.12);
          border = AppTheme.warning;
          fg = AppTheme.warning;
          icon = Icons.warning_amber_rounded;
          title = l10n.gpsFirestoreWriteFailed;
          break;
        case DriverGpsStatus.stale:
          bg = AppTheme.danger.withValues(alpha: 0.12);
          border = AppTheme.danger;
          fg = AppTheme.danger;
          icon = Icons.gps_not_fixed;
          title = l10n.gpsStatusError;
          subtitles.add(
            _lastGpsFixAt == null ? l10n.gpsUnavailableHint : l10n.gpsStaleHint,
          );
          break;
        case DriverGpsStatus.disabled:
        case DriverGpsStatus.permissionRequired:
          bg = AppTheme.warning.withValues(alpha: 0.12);
          border = AppTheme.warning;
          fg = AppTheme.warning;
          icon = Icons.location_disabled;
          title = l10n.gpsUnavailableHint;
          break;
      }
      if (_needsBackgroundPermission) {
        subtitles.add(l10n.gpsBackgroundHintShort);
      }
      if (_isTrackingActive && !kIsWeb) {
        if (_bgSystemStopped) {
          subtitles.add(l10n.bgSystemStoppedWarning);
        } else if (_bgServiceRunning) {
          subtitles.add(l10n.bgModeActive);
        } else {
          subtitles.add(l10n.bgModeInactive);
        }
      }
      if (_firestoreWriteFailed && _gpsStatus != DriverGpsStatus.uploadError) {
        subtitles.add(l10n.gpsFirestoreWriteFailed);
      }
    }

    if (_scheduleStatus.isNotEmpty) subtitles.add(_scheduleStatus);

    if (_sessionEnforced &&
        _sessionUi == _DriverSessionUi.ready &&
        _sessionDeviceLabel != null) {
      subtitles.add(l10n.driverSessionActiveDevice(_sessionDeviceLabel!));
    }

    final showRecheck =
        _isTrackingActive && _gpsStatus != DriverGpsStatus.active;
    final showBgSetup = _isTrackingActive &&
        !kIsWeb &&
        (_bgSystemStopped || _needsBackgroundPermission);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (_isTrackingActive)
                  Text(
                    _gpsStatusLabel(_gpsStatus, l10n),
                    style: TextStyle(color: fg, fontSize: 11),
                  ),
                for (final line in subtitles)
                  Text(
                    line,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (showRecheck)
            TextButton(
              onPressed: _recheckGps,
              child: Text(l10n.gpsRecheck),
            ),
          if (showBgSetup && !kIsWeb && Platform.isAndroid)
            TextButton(
              onPressed: () => showAndroidSetupSheet(context),
              child: Text(l10n.bgOpenSetup),
            ),
        ],
      ),
    );
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

    if (_sessionEnforced) {
      switch (_sessionUi) {
        case _DriverSessionUi.loading:
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        case _DriverSessionUi.blocked:
          return DriverSessionBlockedScreen(
            remoteSession: _remoteSession,
            onTakeover: () => unawaited(_takeoverDriverSession()),
            onLogout: () => unawaited(_logoutFromSessionGate()),
          );
        case _DriverSessionUi.lost:
          return DriverSessionLostScreen(
            onAcknowledge: _acknowledgeSessionLost,
          );
        case _DriverSessionUi.ready:
          break;
      }
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
            DriverAppBarActions(
              companyId: companyId,
              authService: authService,
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
                  color: AppTheme.surfaceHi,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.45),
                      width: 2,
                    ),
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
                            color: AppTheme.accentSoft, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${l10n.viewingAs} ${l10n.driver}',
                            style: TextStyle(
                              color: AppTheme.text,
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
            _buildGpsStatusBanner(l10n),
            _buildCloseUndoBanner(l10n),
            _buildAutoClosePendingBanner(l10n),
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
                          final driverId = authService.viewAsDriverId ??
                              authService.currentUser!.uid;
                          _autoCloseDriverId = driverId;
                          _allDriverActivePoints = incomingPoints
                              .where((p) => isDriverAutoCloseEligible(
                                    p,
                                    driverId: driverId,
                                    disabledPointIds: _autoCloseDisabledIds,
                                  ))
                              .toList();
                          final routePoints =
                              _filterDriverPointsToCurrentRoute(incomingPoints);
                          points = _mergeVisibleRoutePoints(routePoints);

                          // 🛡️ GUARD: никогда не затираем _lastPoints пустым
                          // списком, если у нас был завершённый маршрут.
                          if (points.isNotEmpty || _lastPoints.isEmpty) {
                            _lastPoints = points;
                            // 🛡️ Сохраняем в persistent cache
                            _savePointsToCache();
                            // Undo для авто-закрытий в фоне (snackbar не показался)
                            final closed = List<DeliveryPoint>.from(points);
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _maybeOfferBackgroundUndo(closed));
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

                        final isAndroidNoMap = !kIsWeb && Platform.isAndroid;
                        final allIncoming = snapshot.data ?? const <DeliveryPoint>[];

                        return Column(
                          children: [
                            _buildOtherRouteBanner(allIncoming, l10n),
                            if (isAndroidNoMap)
                              _buildAndroidRouteSummary(points, l10n)
                            else
                              Expanded(
                                flex: 3,
                                child: DeliveryMapWidget(
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
                            Expanded(
                              child: points.isEmpty
                                  ? Center(
                                      child: Text(
                                        l10n.noActivePoints,
                                        style: TextStyle(
                                            color: AppTheme.muted,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        top: 2,
                                        bottom: 8 +
                                            MediaQuery.of(context)
                                                .padding
                                                .bottom,
                                      ),
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
                                              child: isActive && !isCompleted
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        _buildPointTitleRow(
                                                          point: point,
                                                          index: index,
                                                          isCompleted:
                                                              isCompleted,
                                                          isActive: isActive,
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _buildWazeButton(
                                                                context,
                                                                point,
                                                                l10n),
                                                            Expanded(
                                                              child:
                                                                  _buildActivePointActions(
                                                                context,
                                                                point,
                                                                l10n,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    )
                                                  : _buildCompactPointRow(
                                                      context: context,
                                                      point: point,
                                                      index: index,
                                                      isCompleted: isCompleted,
                                                      isActive: isActive,
                                                      l10n: l10n,
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
    final result = await launchDriverNavigation(
      point,
      preferWaze: _rc.navigationPreferWaze,
    );

    if (!context.mounted) return;

    if (result.success) return;

    final messenger = ScaffoldMessenger.of(context);
    if (result.reason == 'no_destination') {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.navigationNoDestination)),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.wazeLaunchFailed)),
      );
    }
  }

  /// Строит текст с фактическим временем на точке
  String _buildPointTiming(DeliveryPoint p) {
    final parts = <String>[];
    if (p.arrivedAt != null) {
      final t = p.arrivedAt!;
      parts.add(
          '⏱ ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
    if (p.completedAt != null) {
      final t = p.completedAt!;
      parts.add(
          '✅ ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
    if (p.arrivedAt != null && p.completedAt != null) {
      final min = p.completedAt!.difference(p.arrivedAt!).inMinutes;
      if (min > 0) parts.add('(${min}m)');
    }
    return parts.join(' → ');
  }

  Widget _buildPointBadge({
    required int index,
    required bool isCompleted,
    required bool isActive,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircleAvatar(
        backgroundColor: isCompleted
            ? Colors.grey.shade400
            : (isActive ? Colors.green : Colors.blueGrey.shade400),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildPointTexts(DeliveryPoint point, bool isCompleted) {
    final resolved = resolveDeliveryPointAddress(point);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          point.clientName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isCompleted ? Colors.grey.shade700 : Colors.black87,
            decoration:
                isCompleted ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (resolved.hasOverride) ...[
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.deliveryAddressOverrideBadge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade900,
                ),
              ),
            );
          }),
          Text(
            resolved.displayAddress,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else if (resolved.displayAddress.isNotEmpty)
          Text(
            resolved.displayAddress,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildPointTitleRow({
    required DeliveryPoint point,
    required int index,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPointBadge(
          index: index,
          isCompleted: isCompleted,
          isActive: isActive,
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildPointTexts(point, isCompleted)),
      ],
    );
  }

  Widget _buildWazeButton(
    BuildContext context,
    DeliveryPoint point,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 36,
      width: 36,
      child: IconButton(
        onPressed: () => _openWazeForPoint(context, point, l10n),
        icon: const Icon(Icons.navigation, color: Colors.blue, size: 22),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Waze',
      ),
    );
  }

  Widget _buildCompactPointRow({
    required BuildContext context,
    required DeliveryPoint point,
    required int index,
    required bool isCompleted,
    required bool isActive,
    required AppLocalizations l10n,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompleted) ...[
          _buildWazeButton(context, point, l10n),
          const SizedBox(width: 4),
        ],
        _buildPointBadge(
          index: index,
          isCompleted: isCompleted,
          isActive: isActive,
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildPointTexts(point, isCompleted)),
        if (isCompleted) _buildClosedStatusIcon(point),
      ],
    );
  }

  Widget _buildClosedStatusIcon(DeliveryPoint point) {
    if (DeliveryPoint.normalizeStatus(point.status) ==
        DeliveryPoint.statusCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }
    return const Icon(Icons.cancel, color: Colors.grey, size: 22);
  }

  Widget _buildActivePointActions(
    BuildContext context,
    DeliveryPoint point,
    AppLocalizations l10n,
  ) {
    final autoOn = !_autoCloseDisabledIds.contains(point.id);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (!kIsWeb) ...[
          if (!_photoRequired && _autoCloseCompanyEnabled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.autoCloseToggle,
                    style: const TextStyle(fontSize: 12)),
                Switch.adaptive(
                  value: autoOn,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => _setAutoCloseEnabled(point, v),
                ),
              ],
            ),
          if (!_photoRequired)
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: () => _completePointPlain(context, point, l10n),
                icon: const Icon(Icons.check, size: 16),
                label: Text(l10n.delivered),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () => _completePointWithPod(context, point, l10n),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(l10n.closeWithPhoto),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ] else
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => _completePointWithPod(context, point, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: Text(l10n.pointDone),
            ),
          ),
        // «Неверное место» — водитель на точке, обновляет координаты клиента
        // по своему текущему GPS (мобильное; его позиция = реальное место).
        if (!kIsWeb)
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () => _fixClientLocation(point, l10n),
              icon: const Icon(Icons.wrong_location_outlined, size: 16),
              label: Text(l10n.fixLocationButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  /// Водитель на точке исправляет координаты КЛИЕНТА по своему текущему GPS
  /// (он физически на месте). Меняем только lat/lng клиента (правила это
  /// разрешают водителю); адрес/прочее не трогаем. Чинит будущие доставки.
  Future<void> _fixClientLocation(
    DeliveryPoint point,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    final clientNumber = point.clientNumber ?? '';
    if (companyId.isEmpty || clientNumber.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.fixLocationClientMissing)),
      );
      return;
    }

    // Свежий GPS (водитель сейчас на месте).
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null ||
        !DeliveryPoint.isValidCoordinates(pos.latitude, pos.longitude)) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.fixLocationGpsError),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fixLocationTitle),
        content: Text(l10n.fixLocationBody(point.clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final q = await FirestorePaths()
          .clients(companyId)
          .where('clientNumber', isEqualTo: clientNumber)
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.fixLocationClientMissing)),
          );
        }
        return;
      }
      await q.docs.first.reference
          .update({'latitude': lat, 'longitude': lng});
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.fixLocationSuccess),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('${l10n.fixLocationGpsError}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  /// Компактная сводка маршрута на Android (без карты).
  Widget _buildAndroidRouteSummary(
      List<DeliveryPoint> points, AppLocalizations l10n) {
    final completedCount = points.where(_isClosedPoint).length;
    final totalCount = points.length;
    final remainingCount = totalCount - completedCount;
    final pct = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: AppTheme.surfaceHi),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, size: 18, color: AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                l10n.driverRouteTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                ),
              ),
              const Spacer(),
              if (remainingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.nPoints(remainingCount),
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceHi,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          if (totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.percentCompleted((pct * 100).toInt()),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    );
  }
}
