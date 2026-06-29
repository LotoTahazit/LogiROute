import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'
    show debugPrint, listEquals, kDebugMode;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../utils/delivery_point_address_resolver.dart';
import '../l10n/app_localizations.dart';
import '../services/optimized_location_service.dart';
import '../services/firestore_paths.dart';
import '../utils/polyline_decoder.dart';
import '../utils/gps_utils.dart';
import '../services/osrm_directions_service.dart';
import '../services/route_progress_service.dart';
import '../models/shift_schedule_config.dart';
import '../services/company_cache.dart';
part 'map_mixins/driver_markers_mixin.dart';
part 'map_mixins/route_polylines_mixin.dart';
part 'map_mixins/drag_drop_mixin.dart';

/// Callback при drag & drop точки на водителя
/// pointId, driverId, driverName
typedef OnPointDragToDriver = void Function(
    String pointId, String driverId, String driverName);

/// Хвост сохранённого OSRM-polyline от последней выполненной точки (web без live OSRM).
List<LatLng>? _polylineTailFromAnchor(List<LatLng> full, LatLng anchor) {
  if (full.length < 2) return null;
  var best = double.infinity;
  var bestSeg = 0;
  LatLng? at;
  for (var i = 0; i < full.length - 1; i++) {
    final a = full[i];
    final b = full[i + 1];
    final abx = b.latitude - a.latitude;
    final aby = b.longitude - a.longitude;
    final apx = anchor.latitude - a.latitude;
    final apy = anchor.longitude - a.longitude;
    final ab2 = abx * abx + aby * aby + 1e-18;
    final t = ((abx * apx + aby * apy) / ab2).clamp(0.0, 1.0);
    final cx = a.latitude + abx * t;
    final cy = a.longitude + aby * t;
    final c = LatLng(cx, cy);
    final dx = anchor.latitude - c.latitude;
    final dy = anchor.longitude - c.longitude;
    final d = dx * dx + dy * dy;
    if (d < best) {
      best = d;
      bestSeg = i;
      at = c;
    }
  }
  // ~0.05° ≈ несколько км — если далеко от линии, кэш не подходит (другой маршрут/данные)
  if (best > 0.0025 || at == null) return null;
  final tail = <LatLng>[at, ...full.sublist(bestSeg + 1)];
  if (tail.length >= 2 &&
      (tail[0].latitude - tail[1].latitude).abs() < 1e-9 &&
      (tail[0].longitude - tail[1].longitude).abs() < 1e-9) {
    tail.removeAt(0);
  }
  return PolylineDecoder.isValid(tail) ? tail : null;
}

List<LatLng>? _polylineHeadToAnchor(List<LatLng> full, LatLng anchor) {
  if (full.length < 2) return null;
  var best = double.infinity;
  var bestSeg = 0;
  LatLng? at;
  for (var i = 0; i < full.length - 1; i++) {
    final a = full[i];
    final b = full[i + 1];
    final abx = b.latitude - a.latitude;
    final aby = b.longitude - a.longitude;
    final apx = anchor.latitude - a.latitude;
    final apy = anchor.longitude - a.longitude;
    final ab2 = abx * abx + aby * aby + 1e-18;
    final t = ((abx * apx + aby * apy) / ab2).clamp(0.0, 1.0);
    final cx = a.latitude + abx * t;
    final cy = a.longitude + aby * t;
    final c = LatLng(cx, cy);
    final dx = anchor.latitude - c.latitude;
    final dy = anchor.longitude - c.longitude;
    final d = dx * dx + dy * dy;
    if (d < best) {
      best = d;
      bestSeg = i;
      at = c;
    }
  }
  if (best > 0.0025 || at == null) return null;
  final head = <LatLng>[...full.sublist(0, bestSeg + 1), at];
  if (head.length >= 2 &&
      (head[head.length - 1].latitude - head[head.length - 2].latitude).abs() <
          1e-9 &&
      (head[head.length - 1].longitude - head[head.length - 2].longitude)
              .abs() <
          1e-9) {
    head.removeLast();
  }
  return PolylineDecoder.isValid(head) ? head : null;
}

class DeliveryMapWidget extends StatefulWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool showDriverTracks;
  final bool clearMapMode;
  final Map<String, String> routePolylines; // routeId → encoded polyline
  final double warehouseLat;
  final double warehouseLng;
  final bool enableDragDrop; // Включить drag & drop (только для диспетчера)
  final OnPointDragToDriver? onPointDragToDriver; // Callback при drop

  const DeliveryMapWidget({
    super.key,
    required this.points,
    required this.companyId,
    this.showDriverTracks = false,
    this.clearMapMode = false,
    this.routePolylines = const {},
    required this.warehouseLat,
    required this.warehouseLng,
    this.enableDragDrop = false,
    this.onPointDragToDriver,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

abstract class _DeliveryMapWidgetStateBase extends State<DeliveryMapWidget>
    with WidgetsBindingObserver {
  GoogleMapController? _controller;
  Set<Marker> _deliveryMarkers = {};
  final ValueNotifier<Set<Marker>> _driverMarkersNotifier = ValueNotifier({});
  Set<Polyline> _polylines = {};
  Set<Polyline> _driverProgressPolylines =
      {}; // Пройденные и оставшиеся маршруты
  Set<Circle> _driverZoneCircles = {}; // Зоны водителей для drag&drop
  final Map<String, DateTime> _driverStopStartTimes =
      {}; // Время начала стоянки водителей
  final Map<String, double> _driverAlphas =
      {}; // Плавные переходы alpha для маркеров
  double _currentZoom = 14.0; // 🎯 Zoom-aware режим
  bool _isAppResumed = true;
  bool _pendingGpsRefreshAfterResume = false;
  bool _pendingZoomRefreshAfterResume = false;
  late final OptimizedLocationService _locationService;

  StreamSubscription<List<Map<String, dynamic>>>? _driverLocationsSubscription;
  Timer? _debounceTimer;
  bool _isLoadingRoute = false;
  bool _isUpdatingMap = false;
  bool _initialCameraFitDone = false;
  String? _lastRouteSignature; // Кеш для предотвращения лишних запросов
  final Map<String, Map<String, dynamic>> _driverLocations =
      {}; // Текущие позиции водителей
  final Map<String, String> _driverETAs = {}; // ETA для каждого водителя
  final Map<String, double> _lastEtaByDriver = {}; // Сглаженный ETA (мин)
  Set<Polyline> _trackPolylines = {}; // GPS-треки водителей за сутки
  final Map<String, GpsLatLng> _lastDriverPositions =
      {}; // Последние позиции для фильтра
  final Map<String, double> _driverHeadings =
      {}; // Направление движения водителей
  final Map<String, DateTime> _lastPositionTimes =
      {}; // Время последних позиций

  // Плавное движение маркеров водителей
  final Map<String, LatLng> _driverCurrentPositions =
      {}; // Текущая (анимированная) позиция
  final Map<String, LatLng> _driverTargetPositions =
      {}; // Целевые позиции водителей
  final Map<String, String> _driverNames = {}; // Имена водителей
  final Map<String, dynamic> _driverStates = {}; // Состояния водителей с TTL
  // Структура: String (старый формат) или Map{'state': ..., 'updatedAt': ...} (новый TTL)
  // TTL: автоматическая очистка через 60 минут

  // 🕐 TTL АКТИВАЦИЯ (когда логика состояний будет реализована):
  /*
  // 🔥 НАЙТИ МЕСТО ГДЕ ОПРЕДЕЛЯЕТСЯ СОСТОЯНИЕ ВОДИТЕЛЯ
  // (например в _buildPointMarkers или _updateDriverMarkers)
  
  // 📍 СТАРАЯ ЛОГИКА:
  // String newState = determineState(...);
  // _driverStates[driverId] = newState;
  
  // 📍 НОВАЯ ЛОГИКА С TTL:
  // String newState = determineState(...);
  // _driverStates[driverId] = {
  //   'state': newState,
  //   'updatedAt': now,
  // };
  
  // 🎯 РЕЗУЛЬТАТ:
  // - Новые состояния записываются с TTL
  // - Старые данные продолжают работать (обратная совместимость)
  // - Автоматическая очистка через 60 минут
  */
  Timer? _markerAnimationTimer;
  Timer? _markerBatchTimer; // Батчинг setState
  bool _markersDirty = false; // Флаг что нужен setState
  Timer? _etaDebounce; // ⚡ Debounce ETA — не чаще раз в 5 сек
  Timer? _trackReloadTimer;
  bool _showOffShiftDrivers =
      false; // 🔘 Toggle: показывать OFF_SHIFT водителей
  ShiftScheduleConfig _shiftSchedule = ShiftScheduleConfig.defaults;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _shiftsSubscription;
  final Map<String, List<LatLng>> _decodedPolylineCache =
      {}; // routeId → decoded points
  /// Последняя дорожная полилиния по водителю (из OSRM/cached), для Waze-прогресса — не прямые между стопами.
  final Map<String, List<LatLng>> _driverRoadPolylinePoints = {};

  // Цвет маршрута по загрузке (паллеты / capacity)
  // 🟢 ≤80%  🟡 80–100%  🔴 >100%
  Color _getRouteLoadColor(String driverKey) {
    final driverPoints =
        widget.points.where((p) => p.driverId == driverKey).toList();
    if (driverPoints.isEmpty) return Colors.blue;

    final capacity = driverPoints.first.driverCapacity ?? 0;
    if (capacity == 0) return Colors.blue;

    final totalPallets = driverPoints.fold(
      0,
      (runningTotal, p) => runningTotal + p.pallets,
    );
    final ratio = totalPallets / capacity;

    if (ratio > 1.0) return Colors.red;
    if (ratio > 0.8) return Colors.orange;
    return Colors.green;
  }

  // 📍 Проверка свежести GPS данных
  bool isGpsFresh(DateTime now, DateTime timestamp) {
    final difference = now.difference(timestamp).inMinutes;
    return difference <= 120; // GPS актуален если не старше 2 часов
  }

  // 🎯 Финальная проверка отображения водителя
  bool shouldShowDriver(DateTime timestamp) {
    final now = DateTime.now();

    // Единственный фильтр: слишком старый GPS (>2ч)
    if (!isGpsFresh(now, timestamp)) return false;

    return true;
  }

  // Оставляем для обратной совместимости (используется в треках)
  Color _getDriverColor(String driverKey, int index) =>
      _getRouteLoadColor(driverKey);

  bool get _executionUsesDriverOrigin => _shiftSchedule.allows(DateTime.now());

  // =========================================================================
  // 🔧 SHARED HELPERS — used by multiple mixins
  // =========================================================================

  /// GPS расстояние в километрах (haversine approximation)
  double _gpsDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Строит snippet для infoWindow маркера точки
  String _buildMarkerSnippet(DeliveryPoint point, AppLocalizations? l10n) {
    final buffer = StringBuffer();

    buffer.write(
      '${point.pallets} ${l10n?.pallets ?? ''} • ${l10n?.order ?? 'Order'}: ${point.orderInRoute + 1}',
    );

    final resolved = resolveDeliveryPointAddress(point);
    final displayAddress = resolved.displayAddress;
    if (resolved.hasOverride && resolved.overrideMissingCoordinates) {
      buffer.write('\n⚠️ ${l10n?.deliveryAddressOverrideNoCoords ?? ''}');
    }
    buffer.write('\n📍 $displayAddress');

    return buffer.toString();
  }

  /// Вычисляет bounds для списка точек полилинии
  LatLngBounds _calculatePolylineBounds(List<LatLng> points) {
    final validPoints = points
        .where((p) => DeliveryPoint.isValidCoordinates(p.latitude, p.longitude))
        .toList();

    if (validPoints.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(widget.warehouseLat, widget.warehouseLng),
        northeast: LatLng(widget.warehouseLat, widget.warehouseLng),
      );
    }

    double minLat = validPoints.first.latitude;
    double maxLat = validPoints.first.latitude;
    double minLng = validPoints.first.longitude;
    double maxLng = validPoints.first.longitude;

    for (final p in validPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Проверяет, находится ли точка в пределах Израиля (с запасом).
  /// Делегирует в DeliveryPoint.isValidCoordinates — единый валидатор.
  bool _isInIsraelBounds(double lat, double lng) {
    return DeliveryPoint.isValidCoordinates(lat, lng);
  }

  /// Координаты для карты: точка → клиент из кеша (если lat/lng точки = 0).
  LatLng? _resolveMapPosition(DeliveryPoint point) {
    final resolved = resolveDeliveryPointAddress(point);
    if (resolved.navLat != null &&
        resolved.navLng != null &&
        _isInIsraelBounds(resolved.navLat!, resolved.navLng!)) {
      return LatLng(resolved.navLat!, resolved.navLng!);
    }
    if (_isInIsraelBounds(point.latitude, point.longitude)) {
      return LatLng(point.latitude, point.longitude);
    }
    final cn = point.clientNumber;
    if (cn == null || cn.isEmpty) return null;
    for (final c in CompanyCache.instance(widget.companyId).clients) {
      if (c.clientNumber == cn &&
          _isInIsraelBounds(c.latitude, c.longitude)) {
        return LatLng(c.latitude, c.longitude);
      }
    }
    return null;
  }

  /// Разводит маркеры с одинаковыми координатами (~25 м по кругу).
  LatLng _offsetStackedMarker(LatLng base, int index) {
    if (index <= 0) return base;
    const meters = 28.0;
    final angle = (index * 72) * math.pi / 180;
    final cosLat = math.cos(base.latitude * math.pi / 180);
    return LatLng(
      base.latitude + (meters / 111320) * math.cos(angle),
      base.longitude + (meters / (111320 * cosLat)) * math.sin(angle),
    );
  }

  /// Безопасная анимация camera к bounds (с guard от ошибок Google Maps)
  /// 🛡️ GUARD: если bounds выходят за пределы Израиля — игнорируем.
  Future<void> _moveToBoundsSafe(LatLngBounds bounds,
      {bool animated = true}) async {
    if (_controller == null || !mounted) return;

    // 🛡️ Валидация: bounds должны быть в пределах Израиля
    if (!_isInIsraelBounds(
            bounds.southwest.latitude, bounds.southwest.longitude) ||
        !_isInIsraelBounds(
            bounds.northeast.latitude, bounds.northeast.longitude)) {
      debugPrint(
        '⚠️ [Map] Bounds outside Israel, ignoring camera move: '
        'SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}) '
        'NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})',
      );
      return;
    }

    try {
      final update = CameraUpdate.newLatLngBounds(bounds, 56);
      if (animated) {
        await _controller!.animateCamera(update);
      } else {
        await _controller!.moveCamera(update);
      }
    } catch (e) {
      debugPrint('⚠️ [Map] Camera bounds error: $e');
    }
  }

  /// Safe warehouse target for initial camera position
  LatLng _safeWarehouseTarget() {
    final lat = widget.warehouseLat;
    final lng = widget.warehouseLng;
    // Validate Israel bounds via centralized validator
    if (DeliveryPoint.isValidCoordinates(lat, lng)) {
      return LatLng(lat, lng);
    }
    // Default to Mishmarot if warehouse coords are invalid
    return const LatLng(32.48698, 34.982121);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(
      this,
    ); // 🔄 Добавляем observer для lifecycle

    _locationService = OptimizedLocationService(widget.companyId);

    // 🏭 Маркер склада сразу при старте — карта не пустая
    _deliveryMarkers = {
      Marker(
        markerId: const MarkerId('warehouse'),
        position: LatLng(widget.warehouseLat, widget.warehouseLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndexInt: 999,
      ),
    };

    _startDriverLocationTracking();
    _startMarkerAnimation();
    _shiftsSubscription =
        FirestorePaths.companyShiftsOf(widget.companyId).snapshots().listen(
      (snap) {
        final data = snap.data();
        if (!mounted || data == null) return;
        setState(() {
          _shiftSchedule = ShiftScheduleConfig.fromFirestore(data);
        });
      },
    );

    _syncTrackReloadLoop();
  }

  bool get _canApplyLiveMarkerRefresh => _isAppResumed;

  void _markGpsRefreshPending() {
    if (_isAppResumed) return;
    _pendingGpsRefreshAfterResume = true;
  }

  void _handleCameraMove(CameraPosition position) {
    final previousZoomedOut = _currentZoom < 11;
    _currentZoom = position.zoom;
    final currentZoomedOut = _currentZoom < 11;
    if (previousZoomedOut != currentZoomedOut) {
      if (_isAppResumed) {
        _markersDirty = true;
      } else {
        _pendingZoomRefreshAfterResume = true;
      }
    }
  }

  void _syncTrackReloadLoop() {
    _trackReloadTimer?.cancel();
    if (!widget.showDriverTracks || widget.clearMapMode) return;
    _trackReloadTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      if (!mounted || !_isAppResumed || !widget.showDriverTracks) return;
      _loadDriverTracks();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppResumed = true;
      final shouldRefresh =
          _pendingGpsRefreshAfterResume || _pendingZoomRefreshAfterResume;
      _pendingGpsRefreshAfterResume = false;
      _pendingZoomRefreshAfterResume = false;
      if (shouldRefresh) {
        _rebuildDriverMarkers();
        _updateDriverProgressPolylines();
      }
      if (widget.showDriverTracks && !widget.clearMapMode) {
        _loadDriverTracks();
      }
      _syncTrackReloadLoop();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isAppResumed = false;
      _trackReloadTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.clearMapMode != widget.clearMapMode && widget.clearMapMode) {
      _debounceTimer?.cancel();
      _trackReloadTimer?.cancel();
      _decodedPolylineCache.clear();
      _driverRoadPolylinePoints.clear();
      _lastRouteSignature = null;
      _polylines = {};
      _driverProgressPolylines = {};
      _trackPolylines = {};
      _driverCurrentPositions.clear();
      _driverTargetPositions.clear();
      _driverMarkersNotifier.value = {};
      _deliveryMarkers = {
        Marker(
          markerId: const MarkerId('warehouse'),
          position: LatLng(widget.warehouseLat, widget.warehouseLng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndexInt: 999,
        ),
      };
      setState(() {});
      return;
    }

    final oldSignature = _buildPointSignature(oldWidget.points);
    final newSignature = _buildPointSignature(widget.points);
    final polylinesChanged =
        oldWidget.routePolylines.length != widget.routePolylines.length ||
            oldWidget.routePolylines.entries.any(
              (e) => widget.routePolylines[e.key] != e.value,
            );

    // Обновляем карту только при реальных изменениях (с debounce)
    if (!listEquals(oldSignature, newSignature) || polylinesChanged) {
      if (polylinesChanged) {
        _decodedPolylineCache.clear();
        _driverRoadPolylinePoints.clear();
        _lastRouteSignature = null;
        debugPrint('🔄 [Map] Route polylines changed, invalidating cache');
      }
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) _updateMapData();
      });
      if (widget.showDriverTracks && !widget.clearMapMode) {
        _trackPolylines = {};
        _loadDriverTracks();
      }
      _syncTrackReloadLoop();
    }

    // Треки включили/выключили
    if (oldWidget.showDriverTracks != widget.showDriverTracks) {
      if (widget.showDriverTracks) {
        // Всегда перезагружаем при включении (свежие данные)
        _trackPolylines = {};
        _loadDriverTracks();
      } else {
        _trackPolylines = {};
        setState(() {}); // перерисовка polylines
      }
      _syncTrackReloadLoop();
    }
  }

  List<String> _buildPointSignature(List<DeliveryPoint> points) {
    return points
        .map(
          (p) =>
              '${p.id}|${p.driverId}|${p.orderInRoute}|${p.status}|${p.latitude}|${p.longitude}',
        )
        .toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _driverLocationsSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    _markerBatchTimer?.cancel();
    _etaDebounce?.cancel();
    _trackReloadTimer?.cancel();
    _shiftsSubscription?.cancel();
    _driverMarkersNotifier.dispose();
    super.dispose();
  }

  // Cross-mixin abstract declarations
  Future<void> _updateMapData();
  void _onPointDragStart(DeliveryPoint point);
  void _onPointDragEnd(DeliveryPoint point, LatLng newPosition);
  void _updateDriverProgressPolylines();
  void _startDriverLocationTracking();
  void _startMarkerAnimation();
  void _updateDriverMarkers(List<Map<String, dynamic>> driverLocations);
  void _rebuildDriverMarkers();
  Future<void> _loadDriverTracks();
}

class _DeliveryMapWidgetState extends _DeliveryMapWidgetStateBase
    with _DriverMarkersMixin, _RoutePolylinesMixin, _DragDropMixin {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      onCameraMove: _handleCameraMove,
      onMapCreated: (controller) {
        _controller = controller;
        if (!widget.clearMapMode) {
          _updateMapData();
        }
        if (widget.showDriverTracks && !widget.clearMapMode) {
          _loadDriverTracks();
        }
      },
      markers: widget.clearMapMode
          ? _deliveryMarkers
          : {..._deliveryMarkers, ..._driverMarkersNotifier.value},
      polylines: {
        if (!widget.clearMapMode) ..._polylines,
        if (!widget.clearMapMode) ..._driverProgressPolylines,
        if (!widget.clearMapMode) ..._trackPolylines,
      },
      circles: _driverZoneCircles,
      initialCameraPosition: CameraPosition(
        target: _safeWarehouseTarget(),
        zoom: 12,
      ),
    );
  }
}

