import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart'
    show debugPrint, listEquals, kDebugMode;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';
import '../services/optimized_location_service.dart';
import '../services/smart_navigation_service.dart';
import '../services/osrm_navigation_service.dart';
import '../services/firestore_paths.dart';
import '../utils/polyline_decoder.dart';
import '../utils/gps_utils.dart';
import '../services/osrm_directions_service.dart';
import '../services/route_progress_service.dart';
import '../models/shift_schedule_config.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

part 'map_mixins/demo_mode_mixin.dart';
part 'map_mixins/driver_markers_mixin.dart';
part 'map_mixins/route_polylines_mixin.dart';
part 'map_mixins/drag_drop_mixin.dart';

bool _deliveryMapTzInited = false;
void _deliveryMapEnsureTz() {
  if (_deliveryMapTzInited) return;
  tzdata.initializeTimeZones();
  _deliveryMapTzInited = true;
}

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

class DeliveryMapWidget extends StatefulWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool showDriverTracks;
  final Map<String, String> routePolylines; // routeId → encoded polyline
  final double warehouseLat;
  final double warehouseLng;
  final bool enableDragDrop; // Включить drag & drop (только для диспетчера)
  final OnPointDragToDriver? onPointDragToDriver; // Callback при drop
  /// Авто-сценарий для демо (логика карты не меняется — только каркас таймера).
  final bool demoMode;

  /// Вызывается один раз, когда сценарий демо дошёл до конца (шаг 10). Не при ручном выключении.
  final VoidCallback? onDemoFinished;

  const DeliveryMapWidget({
    super.key,
    required this.points,
    required this.companyId,
    this.demoMode = false,
    this.showDriverTracks = false,
    this.routePolylines = const {},
    required this.warehouseLat,
    required this.warehouseLng,
    this.enableDragDrop = false,
    this.onPointDragToDriver,
    this.onDemoFinished,
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
  late final OptimizedLocationService _locationService;
  final SmartNavigationService _smartNavigationService =
      SmartNavigationService();
  final OsrmNavigationService _osrmNavigation = OsrmNavigationService();

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
  Timer? _shiftCheckTimer; // 🕐 Таймер проверки смены (каждые 30 секунд)
  bool? _lastShiftState; // 🕐 Последнее состояние смены для оптимизации
  bool _showOffShiftDrivers =
      false; // 🔘 Toggle: показывать OFF_SHIFT водителей
  /// `companies/{companyId}/settings/shifts`
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

  // 🕐 Часы смены — по стеночным часам Asia/Jerusalem (как לוח משמרות).
  DateTime nowIsrael() {
    _deliveryMapEnsureTz();
    return tz.TZDateTime.now(tz.getLocation('Asia/Jerusalem'));
  }

  // 🕐 Расписание смен — `companies/{companyId}/settings/shifts`
  bool isWorkingShift(DateTime now) => _shiftSchedule.allows(now);

  // 📍 Проверка свежести GPS данных
  bool isGpsFresh(DateTime now, DateTime timestamp) {
    final difference = now.difference(timestamp).inMinutes;
    return difference <= 120; // GPS актуален если не старше 2 часов
  }

  // 🎯 Финальная проверка отображения водителя
  bool shouldShowDriver(DateTime timestamp) {
    final now = nowIsrael();

    // Водители всегда видны, но меняют состояние вне смены
    // Единственный фильтр: слишком старый GPS (>2ч)
    if (!isGpsFresh(now, timestamp)) return false;

    return true;
  }

  // Оставляем для обратной совместимости (используется в треках)
  Color _getDriverColor(String driverKey, int index) =>
      _getRouteLoadColor(driverKey);

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

    final displayAddress =
        (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty)
            ? point.temporaryAddress!
            : point.address;

    buffer.write('\n📍 $displayAddress');

    return buffer.toString();
  }

  /// Вычисляет bounds для списка точек полилинии
  LatLngBounds _calculatePolylineBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(widget.warehouseLat, widget.warehouseLng),
        northeast: LatLng(widget.warehouseLat, widget.warehouseLng),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
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

  /// Безопасная анимация camera к bounds (с guard от ошибок Google Maps)
  Future<void> _moveToBoundsSafe(LatLngBounds bounds,
      {bool animated = true}) async {
    if (_controller == null || !mounted) return;

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
    // Validate Israel bounds roughly
    if (lat >= 29.0 && lat <= 34.0 && lng >= 34.0 && lng <= 36.5) {
      return LatLng(lat, lng);
    }
    // Default to Tel Aviv if warehouse coords are invalid
    return const LatLng(32.0853, 34.7818);
  }

  // 🕐 Запуск таймера проверки смены (обновление только при смене состояния)
  void _startShiftCheckTimer() {
    _shiftCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;

      final now = nowIsrael();
      final currentShift = isWorkingShift(now);

      // Обновляем только если состояние смены изменилось
      if (_lastShiftState != currentShift) {
        _lastShiftState = currentShift;
        setState(() {});
        debugPrint(
          '🕐 [Shift] Shift state changed → ${currentShift ? "ACTIVE" : "INACTIVE"}',
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(
      this,
    ); // 🔄 Добавляем observer для lifecycle

    _locationService = OptimizedLocationService(widget.companyId);

    // 🕐 Инициализируем состояние смены чтобы избежать лишнего setState при запуске
    final now = nowIsrael();
    _lastShiftState = isWorkingShift(now);

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
    _startShiftCheckTimer();

    _shiftsSubscription =
        FirestorePaths.companyShiftsOf(widget.companyId).snapshots().listen(
      (snap) {
        if (!mounted) return;
        final config = ShiftScheduleConfig.fromFirestore(snap.data());
        debugPrint(
            '🕐 [Shifts] loaded: exists=${snap.exists} days=${config.workingDays} '
            'start=${config.startHour} end=${config.endHour}');
        ShiftScheduleConfig.saveToPrefs(config);
        setState(() {
          _shiftSchedule = config;
        });
      },
      onError: (e) => debugPrint('⚠️ [Shifts] stream error: $e'),
    );

    if (widget.demoMode) {
      // Без затемнения — иначе склад/линии/נהג не видны на шагах 1–3.
      _demoOverlayOpacity = 0.0;
      _demoMapScale = 1.0;
      _demoMarkers = {_demoWarehouseMarker(), _demoDriverMarker()};
      _startDemo();
      _ensureDemoRoadGeometry();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(_DemoModeMixin._kDemoCameraDelay, () {
          if (mounted) _fitDemoSceneCamera();
        });
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔄 Приложение вернулось на передний план - проверяем смену
      final now = nowIsrael();
      final currentShift = isWorkingShift(now);

      if (_lastShiftState != currentShift) {
        _lastShiftState = currentShift;
        _updateDriverMarkers(
          _driverLocations.values.toList(),
        ); // пересчитать водителей
        setState(() {});
        debugPrint(
          '🔄 [Lifecycle] App resumed - shift updated to: ${currentShift ? "ACTIVE" : "INACTIVE"}',
        );
      }
    }
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.demoMode != widget.demoMode) {
      if (widget.demoMode) {
        _beginDemoFromToggle();
      } else {
        _stopDemo();
      }
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
    }

    // Треки включили/выключили
    if (oldWidget.showDriverTracks != widget.showDriverTracks) {
      if (widget.showDriverTracks) {
        // Всегда перезагружаем при включении (свежие данные)
        _trackPolylines = {};
        _loadDriverTracks();
      } else {
        setState(() {}); // перерисовка polylines
      }
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
    _shiftCheckTimer?.cancel();
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
  void _stopDemo();
  void _beginDemoFromToggle();
  Marker _demoWarehouseMarker();
  Marker _demoDriverMarker();
  void _startDemo();
  Future<void> _ensureDemoRoadGeometry();
  void _fitDemoSceneCamera();
  void _updateDriverMarkers(List<Map<String, dynamic>> driverLocations);
  Future<void> _loadDriverTracks();

  // Demo fields (defined in _DemoModeMixin)
  double get _demoOverlayOpacity;
  set _demoOverlayOpacity(double value);
  double get _demoMapScale;
  set _demoMapScale(double value);
  Set<Marker> get _demoMarkers;
  set _demoMarkers(Set<Marker> value);
  Timer? get _demoTimer;
  set _demoTimer(Timer? value);
  Timer? get _pulseTimer;
  set _pulseTimer(Timer? value);
  Timer? get _demoDriverMoveTimer;
  set _demoDriverMoveTimer(Timer? value);
}

// Final class combining all mixins
class _DeliveryMapWidgetState extends _DeliveryMapWidgetStateBase
    with
        _DemoModeMixin,
        _DriverMarkersMixin,
        _RoutePolylinesMixin,
        _DragDropMixin {
  // initState / didChangeAppLifecycleState / didUpdateWidget — только в
  // [_DeliveryMapWidgetStateBase]; дубликат здесь повторно инициализировал
  // late final _locationService → LateInitializationError и серый экран карты.

  @override
  void dispose() {
    _stopDemo();
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _driverLocationsSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    _markerBatchTimer?.cancel();
    _etaDebounce?.cancel();
    _shiftCheckTimer?.cancel();
    _demoTimer?.cancel();
    _pulseTimer?.cancel();
    _demoDriverMoveTimer?.cancel();
    _shiftsSubscription?.cancel();
    _driverMarkersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
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
          onMapCreated: (controller) {
            _controller = controller;
            _updateMapData();
            if (widget.showDriverTracks) {
              _loadDriverTracks();
            }
          },
          markers: {..._deliveryMarkers, ..._driverMarkersNotifier.value},
          polylines: {
            ..._polylines,
            ..._driverProgressPolylines,
            ..._trackPolylines
          },
          circles: _driverZoneCircles,
          initialCameraPosition: CameraPosition(
            target: _safeWarehouseTarget(),
            zoom: 12,
          ),
        ),
        if (widget.demoMode) _buildDemoOverlay(),
      ],
    );
  }

  Widget _buildDemoOverlay() {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          // Demo UI layers
          if (_demoTopMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _demoTopMessageOpacity,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _demoTopMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_demoShowDriverCard)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _demoShowDriverCard ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping,
                              color: Colors.green, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'נהג פעיל',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'כיוון: ${_demoRoadWhToDriver.isNotEmpty ? "למחסן" : "לא ידוע"}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ETA: ~12 min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
