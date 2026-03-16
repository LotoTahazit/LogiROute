import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, listEquals, kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';
import '../services/optimized_location_service.dart';
import '../services/smart_navigation_service.dart';
import '../services/firestore_paths.dart';
import '../utils/polyline_decoder.dart';
import '../utils/gps_utils.dart';
import '../services/route_progress_service.dart';

/// Callback при drag & drop точки на водителя
/// pointId, driverId, driverName
typedef OnPointDragToDriver = void Function(
    String pointId, String driverId, String driverName);

class DeliveryMapWidget extends StatefulWidget {
  final List<DeliveryPoint> points;
  final String companyId;
  final bool showDriverTracks;
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
    this.routePolylines = const {},
    required this.warehouseLat,
    required this.warehouseLng,
    this.enableDragDrop = false,
    this.onPointDragToDriver,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget>
    with WidgetsBindingObserver {
  GoogleMapController? _controller;
  Set<Marker> _deliveryMarkers = {};
  Set<Marker> _driverMarkers = {};
  Set<Polyline> _polylines = {};
  Set<Polyline> _driverProgressPolylines =
      {}; // Пройденные и оставшиеся маршруты
  Set<Circle> _driverZoneCircles = {}; // Зоны водителей для drag&drop
  Map<String, DateTime> _driverStopStartTimes =
      {}; // Время начала стоянки водителей
  Map<String, bool> _driverArrivedNearPoints =
      {}; // Флаг прибытия в зону доставки (120m)
  late final OptimizedLocationService _locationService;
  final SmartNavigationService _smartNavigationService =
      SmartNavigationService();

  StreamSubscription<List<Map<String, dynamic>>>? _driverLocationsSubscription;
  Timer? _debounceTimer;
  bool _isLoadingRoute = false;
  bool _isUpdatingMap = false;
  bool _initialCameraFitDone = false;
  String? _lastRouteSignature; // Кеш для предотвращения лишних запросов
  final Map<String, Map<String, dynamic>> _driverLocations =
      {}; // Текущие позиции водителей
  final Map<String, String> _driverETAs = {}; // ETA для каждого водителя
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
      {}; // Целевая позиция (новый GPS)
  final Map<String, String> _driverNames = {}; // Имена водителей
  Timer? _markerAnimationTimer;
  Timer? _markerBatchTimer; // Батчинг setState
  bool _markersDirty = false; // Флаг что нужен setState
  Timer? _etaDebounce; // ⚡ Debounce ETA — не чаще раз в 5 сек
  Timer? _shiftCheckTimer; // 🕐 Таймер проверки смены (каждые 30 секунд)
  bool? _lastShiftState; // 🕐 Последнее состояние смены для оптимизации
  final Map<String, List<LatLng>> _decodedPolylineCache =
      {}; // routeId → decoded points

  // 🖐️ Drag & Drop state
  String? _draggingPointId; // ID точки, которую тащат

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

  // Цвет водителя — ярко-зеленый для видимости
  Color _getDriverMarkerColor() => Colors.green;

  // 🕐 Единая функция времени для Израиля
  DateTime nowIsrael() {
    return DateTime.now(); // UTC время, Firebase использует UTC
  }

  // 🕐 Автоматическое управление сменами водителей
  bool isWorkingShift(DateTime now) {
    final weekday = now.weekday;
    final hour = now.hour;

    // Пятница и суббота — выходные
    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      return false;
    }

    // Рабочие часы 07:00–17:00
    if (hour < 7 || hour >= 17) {
      return false;
    }

    return true;
  }

  // 📍 Проверка свежести GPS данных
  bool isGpsFresh(DateTime now, DateTime timestamp) {
    final difference = now.difference(timestamp).inMinutes;
    return difference <= 5; // GPS актуален если не старше 5 минут
  }

  // 🎯 Финальная проверка отображения водителя
  bool shouldShowDriver(DateTime timestamp) {
    final now = nowIsrael();

    if (!isWorkingShift(now)) {
      // Временно убрал лог чтобы не было спама
      return false;
    }

    if (!isGpsFresh(now, timestamp)) {
      debugPrint(
          '📍 [GPS] Driver GPS data too old (${now.difference(timestamp).inMinutes}min) - hiding');
      return false;
    }

    return true;
  }

  // Оставляем для обратной совместимости (используется в треках)
  Color _getDriverColor(String driverKey, int index) =>
      _getRouteLoadColor(driverKey);

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
            '🕐 [Shift] Shift state changed → ${currentShift ? "ACTIVE" : "INACTIVE"}');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // 🔄 Добавляем observer для lifecycle

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
        zIndex: 999,
      ),
    };

    _startDriverLocationTracking();
    _startMarkerAnimation();
    _startShiftCheckTimer();
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
            _driverLocations.values.toList()); // пересчитать водителей
        setState(() {});
        debugPrint(
            '🔄 [Lifecycle] App resumed - shift updated to: ${currentShift ? "ACTIVE" : "INACTIVE"}');
      }
    }
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

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
        .map((p) =>
            '${p.id}|${p.driverId}|${p.orderInRoute}|${p.status}|${p.latitude}|${p.longitude}')
        .toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🔄 Удаляем observer
    _debounceTimer?.cancel();
    _driverLocationsSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    _markerBatchTimer?.cancel();
    _etaDebounce?.cancel();
    _shiftCheckTimer?.cancel(); // 🕐 Очищаем таймер проверки смен
    super.dispose();
  }

  /// ✅ ВАЖНО: не вызываем async внутри setState
  /// Debounce + guard от конкурентных вызовов.
  /// Маркеры показываются сразу, полилинии подгружаются асинхронно.
  /// Камера анимируется только при первой загрузке polylines.
  Future<void> _updateMapData() async {
    if (!mounted || _isUpdatingMap) return;
    _isUpdatingMap = true;

    try {
      final markers = _buildPointMarkers();

      // Показываем маркеры сразу, не дожидаясь OSRM
      if (!mounted) return;
      setState(() {
        _deliveryMarkers = markers;
      });

      // Фитим камеру по маркерам при первой загрузке (пока нет полилиний)
      if (!_initialCameraFitDone && markers.isNotEmpty && _controller != null) {
        _fitCameraToMarkers(markers);
      }

      // Полилинии подгружаются в фоне
      final polylines = await _buildRoutePolylines();

      if (!mounted) return;
      setState(() {
        _polylines = polylines;
      });

      // Фитим камеру по полилиниям (точнее, чем по маркерам)
      if (!_initialCameraFitDone &&
          _polylines.isNotEmpty &&
          _controller != null) {
        _initialCameraFitDone = true;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted || _controller == null) return;
        final allPolyPoints = <LatLng>[];
        for (final pl in _polylines) {
          allPolyPoints.addAll(pl.points);
        }
        if (allPolyPoints.isEmpty) return;
        final bounds = _calculatePolylineBounds(allPolyPoints);
        try {
          await _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        } catch (e) {
          debugPrint('❌ [Map] Camera animation error: $e');
        }
      }
    } finally {
      _isUpdatingMap = false;
    }
  }

  /// Фитим камеру по маркерам (быстрый первый фит, пока полилинии не загрузились)
  void _fitCameraToMarkers(Set<Marker> markers) {
    if (markers.isEmpty || _controller == null) return;
    final positions = markers
        .map((m) => m.position)
        .where(
          (p) =>
              p.latitude != 0 &&
              p.longitude != 0 &&
              p.latitude >= 29.0 &&
              p.latitude <= 34.0 &&
              p.longitude >= 34.0 &&
              p.longitude <= 36.5,
        )
        .toList();
    if (positions.length < 2) return;

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    try {
      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [Map] Marker camera fit error: $e');
    }
  }

  /// Фитит камеру по polyline, а не по маркерам
  /// Фильтрует точки за пределами Израиля (29–34°N, 34–36°E)
  LatLngBounds _calculatePolylineBounds(List<LatLng> points) {
    // Фильтруем нулевые координаты И точки за пределами Израиля
    final valid = points
        .where(
          (p) =>
              p.latitude != 0 &&
              p.longitude != 0 &&
              p.latitude >= 29.0 &&
              p.latitude <= 34.0 &&
              p.longitude >= 34.0 &&
              p.longitude <= 36.5,
        )
        .toList();
    if (valid.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(widget.warehouseLat - 0.1, widget.warehouseLng - 0.1),
        northeast: LatLng(widget.warehouseLat + 0.1, widget.warehouseLng + 0.1),
      );
    }

    double minLat = valid.first.latitude;
    double maxLat = valid.first.latitude;
    double minLng = valid.first.longitude;
    double maxLng = valid.first.longitude;

    for (final p in valid) {
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

  Set<Marker> _buildPointMarkers() {
    debugPrint(
      '🗺️ [Map] Updating markers with ${widget.points.length} points',
    );
    final l10n = AppLocalizations.of(context);

    final markers = <Marker>{};

    // 🏭 Добавляем маркер склада (ВСЕГДА первый)
    markers.add(
      Marker(
        markerId: const MarkerId('warehouse'),
        position: LatLng(widget.warehouseLat, widget.warehouseLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🏭 ${l10n?.warehouse ?? "Склад"}',
          snippet: l10n?.warehouseStartPoint ?? 'Starting point for all routes',
        ),
        zIndexInt: 999, // Склад всегда сверху
      ),
    );

    // Добавляем маркеры точек доставки
    for (final point in widget.points) {
      // Пропускаем точки с нулевыми координатами
      if (point.latitude == 0 && point.longitude == 0) continue;

      // Определяем цвет маркера в зависимости от статуса
      BitmapDescriptor markerColor;
      if (point.status == DeliveryPoint.statusCompleted ||
          point.status == DeliveryPoint.statusCancelled) {
        // Серый для завершенных/отмененных
        markerColor = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      } else {
        // Цвет водителя для активных точек
        final driverKey = point.driverId ?? 'unknown';
        final driverIndex = widget.points
            .where((p) => p.driverId != null)
            .map((p) => p.driverId)
            .toSet()
            .toList()
            .indexOf(driverKey);
        final driverColor = _getDriverColor(driverKey, driverIndex);
        final hue = HSVColor.fromColor(driverColor).hue;
        markerColor = BitmapDescriptor.defaultMarkerWithHue(hue);
      }

      // Определяем, можно ли перетаскивать эту точку
      final isDraggable = widget.enableDragDrop &&
          point.status != DeliveryPoint.statusCompleted &&
          point.status != DeliveryPoint.statusCancelled;

      markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: markerColor,
          draggable: isDraggable,
          onDragStart:
              isDraggable ? (position) => _onPointDragStart(point) : null,
          onDragEnd: isDraggable
              ? (newPosition) => _onPointDragEnd(point, newPosition)
              : null,
          infoWindow: InfoWindow(
            title: point.clientName,
            snippet: _buildMarkerSnippet(point, l10n),
          ),
          alpha: (point.status == DeliveryPoint.statusCompleted ||
                  point.status == DeliveryPoint.statusCancelled)
              ? 0.5
              : 1.0, // Полупрозрачные для завершенных
        ),
      );
    }

    debugPrint(
      '🗺️ [Map] Created ${markers.length} markers (including warehouse)',
    );
    return markers;
  }

  Future<Set<Polyline>> _buildRoutePolylines() async {
    debugPrint(
      '🗺️ [Map] Updating polylines with ${widget.points.length} points',
    );

    // Если нет точек доставки, не строим маршрут
    if (widget.points.isEmpty) {
      return {};
    }

    final validRoutePoints = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .toList();

    // Если нет назначенных точек, не строим маршрут
    if (validRoutePoints.isEmpty) {
      return {};
    }

    // Сортируем по driverName, затем по orderInRoute
    validRoutePoints.sort((a, b) {
      final driverCompare = (a.driverName ?? '').compareTo(b.driverName ?? '');
      if (driverCompare != 0) return driverCompare;
      return a.orderInRoute.compareTo(b.orderInRoute);
    });

    // Создаем сигнатуру маршрута для кеширования
    final routeSignature = validRoutePoints
        .map((p) =>
            '${p.driverId}:${p.orderInRoute}:${p.status}:${p.latitude}:${p.longitude}')
        .join('|');

    // Если маршрут не изменился, возвращаем текущие полилинии
    if (_lastRouteSignature == routeSignature && _polylines.isNotEmpty) {
      return _polylines;
    }

    // Маршрут изменился — очищаем кеш декодированных полилиний
    _decodedPolylineCache.clear();
    debugPrint('🔄 [Map] Route signature changed, clearing polyline cache');

    for (var p in validRoutePoints) {
      debugPrint(
        '  - ${p.clientName}: driver=${p.driverName}, order=${p.orderInRoute}',
      );
    }

    // Если уже загружаем маршрут, возвращаем текущие полилинии (не пустые!)
    if (_isLoadingRoute) {
      debugPrint(
        '⏳ [Map] Route loading in progress, keeping current polylines',
      );
      return _polylines.isNotEmpty ? _polylines : {};
    }
    _isLoadingRoute = true;
    _lastRouteSignature =
        routeSignature; // Сохраняем сигнатуру сразу, чтобы не дублировать запросы

    try {
      final Map<String, List<DeliveryPoint>> routesByDriver = {};

      for (final p in validRoutePoints) {
        final driverKey = p.driverId ?? p.driverName ?? 'unknown';
        routesByDriver.putIfAbsent(driverKey, () => []).add(p);
      }

      final Set<Polyline> result = {};

      int driverIndex = 0;
      for (final entry in routesByDriver.entries) {
        final driverKey = entry.key;
        final points = entry.value;

        if (points.isEmpty) continue;

        // Сортируем точки по orderInRoute
        points.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

        // Разделяем на завершенные и активные точки
        final completedPoints = points
            .where(
              (p) =>
                  p.status == DeliveryPoint.statusCompleted ||
                  p.status == DeliveryPoint.statusCancelled,
            )
            .toList();
        final activePoints = points
            .where(
              (p) =>
                  p.status != DeliveryPoint.statusCompleted &&
                  p.status != DeliveryPoint.statusCancelled,
            )
            .toList();

        debugPrint(
          '🏭 [Map] Driver $driverKey: ${completedPoints.length} completed, ${activePoints.length} active',
        );

        // 🏭 ВАЖНО: Маршрут ВСЕГДА начинается со склада!
        final warehouseLat = widget.warehouseLat;
        final warehouseLng = widget.warehouseLng;

        // Строим серый маршрут для завершенных точек (прямые линии — OSRM не нужен)
        if (completedPoints.isNotEmpty) {
          result.addAll(
            _fallbackPolyline(
              completedPoints,
              driverIndex: driverIndex,
              isCompleted: true,
            ),
          );
        }

        // Если все точки завершены — прямая линия возврата на склад
        if (activePoints.isEmpty && completedPoints.isNotEmpty) {
          final lastCompleted = completedPoints.last;
          result.add(
            Polyline(
              polylineId: PolylineId('route_${driverKey}_return'),
              points: [
                LatLng(lastCompleted.latitude, lastCompleted.longitude),
                LatLng(warehouseLat, warehouseLng),
              ],
              width: 6,
              color: Colors.grey.shade300,
              patterns: [PatternItem.dash(12), PatternItem.gap(8)],
              zIndex: 4,
            ),
          );
        }

        // Строим цветной маршрут для активных точек
        if (activePoints.isNotEmpty) {
          // Начальная точка - последняя завершенная или склад
          final startLat = completedPoints.isNotEmpty
              ? completedPoints.last.latitude
              : warehouseLat;
          final startLng = completedPoints.isNotEmpty
              ? completedPoints.last.longitude
              : warehouseLng;

          debugPrint(
            '🏭 [Map] Building active route for driver $driverKey from ($startLat, $startLng)',
          );

          final driverColor = _getDriverColor(driverKey, driverIndex);

          // 🗺️ Используем polyline из routes коллекции (OSRM не нужен!)
          final firstPoint =
              activePoints.isNotEmpty ? activePoints.first : null;
          final routeId = firstPoint?.routeId;
          final cachedPolyline = routeId != null
              ? widget.routePolylines[routeId]
              : firstPoint?.routePolyline; // fallback для старых данных
          if (cachedPolyline != null && cachedPolyline.isNotEmpty) {
            // ⚡ Decoded polyline cache — не декодируем повторно
            final cacheKey = routeId ?? driverKey;
            var decoded = _decodedPolylineCache[cacheKey];
            if (decoded == null) {
              decoded = PolylineDecoder.decode(cachedPolyline, precision: 5);
              if (PolylineDecoder.isValid(decoded)) {
                // Simplify: если > 500 точек — берём каждую 3-ю
                if (decoded.length > 500) {
                  final simplified = <LatLng>[];
                  for (int i = 0; i < decoded.length; i += 3) {
                    simplified.add(decoded[i]);
                  }
                  simplified.add(decoded.last);
                  decoded = simplified;
                }
                _decodedPolylineCache[cacheKey] = decoded;
              }
            }
            if (decoded.isNotEmpty && PolylineDecoder.isValid(decoded)) {
              debugPrint(
                '✅ [Map] Using cached polyline for driver $driverKey (${cachedPolyline.length} chars)',
              );
              result.add(
                Polyline(
                  polylineId: PolylineId('route_${driverKey}_active'),
                  points: decoded,
                  width: 8,
                  color: driverColor,
                  zIndex: 10,
                ),
              );
              driverIndex++;
              continue;
            }
          }

          // ⚠️ Нет cached polyline — OSRM fallback (только для старых маршрутов)

          debugPrint(
            '🏭 [Map] Start: Warehouse/Last completed ($startLat, $startLng)',
          );
          debugPrint(
            '🏭 [Map] End: Warehouse (return leg)',
          );

          // Маршрут кольцевой: старт → все точки → махсан
          final smartRoute = await _smartNavigationService.getMultiPointRoute(
            startLat: startLat,
            startLng: startLng,
            waypoints: activePoints,
            endLat: widget.warehouseLat,
            endLng: widget.warehouseLng,
            language: 'he',
          );

          debugPrint(
            '🧭 [Map] SmartNavigationService result for driver $driverKey:',
          );
          if (smartRoute != null) {}

          // Начальная точка для fallback: последняя завершённая или склад
          final fallbackStart = completedPoints.isNotEmpty
              ? LatLng(
                  completedPoints.last.latitude,
                  completedPoints.last.longitude,
                )
              : null;

          if (smartRoute == null || smartRoute.polyline.isEmpty) {
            debugPrint(
              '⚠️ [Map] No route from SmartNavigationService, using fallback',
            );
            result.addAll(
              _fallbackPolyline(
                activePoints,
                driverIndex: driverIndex,
                isCompleted: false,
                customStart: fallbackStart,
              ),
            );
            driverIndex++;
            continue;
          }

          final rawPolyline = smartRoute.polyline;
          var decoded = PolylineDecoder.decode(rawPolyline, precision: 5);

          if (!PolylineDecoder.isValid(decoded)) {
            result.addAll(
              _fallbackPolyline(
                activePoints,
                driverIndex: driverIndex,
                isCompleted: false,
                customStart: fallbackStart,
              ),
            );
            driverIndex++;
            continue;
          }

          debugPrint(
            '🎨 [Map] Driver $driverKey active route color: $driverColor',
          );

          result.add(
            Polyline(
              polylineId: PolylineId('route_${driverKey}_active'),
              points: decoded,
              width: 8,
              color: driverColor,
              zIndex: 10, // Активный маршрут сверху
            ),
          );
        }

        driverIndex++;
      }

      _lastRouteSignature = routeSignature;
      return result;
    } catch (e) {
      _lastRouteSignature = null; // Сбрасываем при ошибке, чтобы повторить
      return _fallbackPolyline(validRoutePoints);
    } finally {
      _isLoadingRoute = false;
    }
  }

  Set<Polyline> _fallbackPolyline(
    List<DeliveryPoint> points, {
    int driverIndex = 0,
    bool isCompleted = false,
    LatLng? customStart,
  }) {
    // 🏭 Маршрут начинается со склада или с указанной точки (последняя завершённая)
    final warehousePos = LatLng(widget.warehouseLat, widget.warehouseLng);
    final start = customStart ?? warehousePos;
    final routePoints = <LatLng>[
      start,
      ...points.map((p) => LatLng(p.latitude, p.longitude)),
      warehousePos,
    ];

    final driverKey = points.isNotEmpty && points.first.driverId != null
        ? points.first.driverId!
        : 'unknown_$driverIndex';
    final driverColor = isCompleted
        ? Colors.grey.shade400
        : _getDriverColor(driverKey, driverIndex);

    debugPrint(
      '🗺️ [Map] Created fallback polyline with ${routePoints.length} points (STRAIGHT LINES)',
    );
    debugPrint(
      '🏭 [Map] Starting from warehouse: (${widget.warehouseLat}, ${widget.warehouseLng})',
    );
    debugPrint(
      '⚠️ [Map] This means OSRM/Google routing failed - routes will be straight lines!',
    );
    debugPrint(
      '🎨 [Map] Fallback color: $driverColor (completed: $isCompleted)',
    );

    return {
      Polyline(
        polylineId: PolylineId(
          'route_${driverKey}_${isCompleted ? "completed" : "active"}',
        ),
        points: routePoints,
        color: driverColor,
        width: 8,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        zIndex: isCompleted ? 5 : 10,
      ),
    };
  }

  void _fitBounds() async {
    if (widget.points.isEmpty || _controller == null) return;

    try {
      // Фильтруем точки с нулевыми координатами и за пределами Израиля
      final validPoints = widget.points
          .where(
            (p) =>
                p.latitude != 0 &&
                p.longitude != 0 &&
                p.latitude >= 29.0 &&
                p.latitude <= 34.0 &&
                p.longitude >= 34.0 &&
                p.longitude <= 36.5,
          )
          .toList();
      if (validPoints.isEmpty) return;

      final bounds = _calculateBounds(validPoints);
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      debugPrint('❌ [DeliveryMap] Error animating camera to bounds: $e');
    }
  }

  LatLngBounds _calculateBounds(List<DeliveryPoint> points) {
    // Фильтруем нулевые координаты И точки за пределами Израиля
    final valid = points
        .where(
          (p) =>
              p.latitude != 0 &&
              p.longitude != 0 &&
              p.latitude >= 29.0 &&
              p.latitude <= 34.0 &&
              p.longitude >= 34.0 &&
              p.longitude <= 36.5,
        )
        .toList();
    if (valid.isEmpty) {
      // Fallback на склад
      return LatLngBounds(
        southwest: LatLng(widget.warehouseLat - 0.1, widget.warehouseLng - 0.1),
        northeast: LatLng(widget.warehouseLat + 0.1, widget.warehouseLng + 0.1),
      );
    }

    double minLat = valid.first.latitude;
    double maxLat = valid.first.latitude;
    double minLng = valid.first.longitude;
    double maxLng = valid.first.longitude;

    for (var point in valid) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Показываем карту на всех платформах (Web и Android)
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.warehouseLat, widget.warehouseLng),
            zoom: 12,
          ),
          markers: {..._deliveryMarkers, ..._driverMarkers},
          polylines: {
            ..._polylines,
            if (widget.showDriverTracks) ..._trackPolylines,
            ..._driverProgressPolylines, // 🛣️ Пройденные и оставшиеся маршруты
          },
          circles: _driverZoneCircles,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          onMapCreated: (controller) {
            _controller = controller;
            // ✅ Запускаем _updateMapData() ПОСЛЕ создания карты (не в initState)
            _updateMapData();
            // Фитим камеру после инициализации контроллера (однократно)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted || _controller == null) return;
              if (_polylines.isNotEmpty) {
                _initialCameraFitDone = true;
                final allPoints = <LatLng>[];
                for (final pl in _polylines) {
                  allPoints.addAll(pl.points);
                }
                if (allPoints.isNotEmpty) {
                  final bounds = _calculatePolylineBounds(allPoints);
                  // ⚡ moveCamera при первой загрузке (без анимации — быстрее)
                  _controller!.moveCamera(
                    CameraUpdate.newLatLngBounds(bounds, 50),
                  );
                }
              } else if (widget.points.isNotEmpty) {
                _fitBounds();
              }
            });
          },
        ),
      ],
    );
  }

  /// Загружает GPS-треки водителей с полуночи текущего дня.
  /// Только водители с точками в текущем маршруте.
  /// Фильтрует "прыжки" GPS > 2 км между соседними точками.
  Future<void> _loadDriverTracks() async {
    debugPrint('🛤️ [Track] _loadDriverTracks called');
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final cutoff = Timestamp.fromDate(midnight);

    // Только водители из текущего маршрута
    final allDriverIds = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .map((p) => p.driverId!)
        .toSet()
        .toList();

    debugPrint(
      '🛤️ [Track] Found ${allDriverIds.length} drivers: $allDriverIds',
    );

    if (allDriverIds.isEmpty) {
      debugPrint('🛤️ [Track] No drivers in current route, skipping tracks');
      return;
    }

    try {
      final tracks = <Polyline>{};

      for (final driverId in allDriverIds) {
        final driverRef = FirestorePaths.driverLocationsOf(
          widget.companyId,
        ).doc(driverId);

        // Загружаем history с полуночи
        QuerySnapshot historySnap;
        try {
          historySnap = await driverRef
              .collection('history')
              .where('timestamp', isGreaterThan: cutoff)
              .orderBy('timestamp')
              .get();
        } catch (e) {
          debugPrint('⚠️ [Track] Firestore query failed for $driverId: $e');
          // Fallback: загружаем без фильтра, последние 200 записей
          try {
            historySnap = await driverRef
                .collection('history')
                .orderBy('timestamp', descending: true)
                .limit(200)
                .get();
          } catch (e2) {
            debugPrint(
              '❌ [Track] Fallback query also failed for $driverId: $e2',
            );
            continue;
          }
        }

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${historySnap.docs.length} history docs',
        );

        if (historySnap.docs.length < 2) continue;

        // Фильтруем точки: убираем плохую точность и GPS-прыжки
        final rawPoints = <Map<String, double>>[];
        for (final doc in historySnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 50.0;
          if (lat == null || lng == null) continue;
          if (lat == 0 && lng == 0) continue;
          // Отбрасываем точки с плохой точностью (> 200м)
          if (accuracy > 200) continue;
          rawPoints.add({'lat': lat, 'lng': lng});
        }

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${rawPoints.length} valid points after filtering',
        );

        // Убираем GPS-прыжки: если расстояние между соседними точками > 2 км — пропускаем точку
        final gpsPoints = <Map<String, double>>[];
        for (int i = 0; i < rawPoints.length; i++) {
          if (i == 0) {
            gpsPoints.add(rawPoints[i]);
            continue;
          }
          final prev = gpsPoints.last;
          final curr = rawPoints[i];
          final dist = _gpsDistanceKm(
            prev['lat']!,
            prev['lng']!,
            curr['lat']!,
            curr['lng']!,
          );
          if (dist <= 2.0) {
            gpsPoints.add(curr);
          }
        }

        if (gpsPoints.length < 2) {
          debugPrint(
            '🛤️ [Track] Driver $driverId: not enough points after jump filter (${gpsPoints.length})',
          );
          continue;
        }

        final driverIndex = allDriverIds.indexOf(driverId);
        final baseColor = _getDriverColor(driverId, driverIndex);
        final trackColor = baseColor.withOpacity(0.5);

        // ✅ GPS-треки — прямые линии по GPS точкам (OSRM не нужен для истории)
        final trackPoints =
            gpsPoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

        tracks.add(
          Polyline(
            polylineId: PolylineId('track_$driverId'),
            points: trackPoints,
            width: 4,
            color: trackColor,
            zIndex: 1,
          ),
        );

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${trackPoints.length} track points added (direct GPS)',
        );
      }

      if (!mounted) return;
      setState(() {
        _trackPolylines = tracks;
      });
      debugPrint('🛤️ [Track] Loaded ${tracks.length} driver tracks total');
    } catch (e) {
      debugPrint('❌ [Track] Error loading tracks: $e');
    }
  }

  /// Расстояние между двумя GPS-точками в километрах (упрощённая формула для Израиля)
  double _gpsDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dlat = (lat2 - lat1).abs() * 111.0;
    final dlng = (lng2 - lng1).abs() * 111.0 * 0.848; // cos(32°) ≈ 0.848
    return (dlat * dlat + dlng * dlng) > 0
        ? (dlat * dlat + dlng * dlng) < 1e10
            ? _sqrtSimple(dlat * dlat + dlng * dlng)
            : 0.0
        : 0.0;
  }

  double _sqrtSimple(double v) {
    if (v <= 0) return 0;
    double x = v / 2;
    for (int i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  void _startDriverLocationTracking() {
    // ⚡ Слушаем только водителей из текущих маршрутов (в 10-50x дешевле)
    final activeDriverIds = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .map((p) => p.driverId!)
        .toSet()
        .toList();

    _driverLocationsSubscription = _locationService
        .getAllDriverLocationsStream(
      driverIds: activeDriverIds.isNotEmpty ? activeDriverIds : null,
    )
        .listen((driverLocations) {
      _updateDriverMarkers(driverLocations);
    }, onError: (error) {});
  }

  /// Запускает таймер плавной анимации маркеров (60fps → ~16ms)
  void _startMarkerAnimation() {
    _markerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 50), // 20fps — достаточно для плавности
      (_) => _interpolateDriverPositions(),
    );
    // Батчинг setState — не чаще 1 раза в 200ms
    _markerBatchTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_markersDirty && mounted) {
        _markersDirty = false;
        _rebuildDriverMarkers();
      }
    });
  }

  /// Интерполяция позиций водителей к целевым координатам
  /// Адаптивная скорость: далеко → быстрее, близко → медленнее (как Uber)
  void _interpolateDriverPositions() {
    bool changed = false;

    for (final driverId in _driverTargetPositions.keys) {
      final target = _driverTargetPositions[driverId]!;
      final current = _driverCurrentPositions[driverId];

      if (current == null) {
        _driverCurrentPositions[driverId] = target;
        changed = true;
        continue;
      }

      // Если уже на месте — пропускаем
      final distLat = (target.latitude - current.latitude).abs();
      final distLng = (target.longitude - current.longitude).abs();
      if (distLat < 0.000001 && distLng < 0.000001) continue;

      final distance = distLat + distLng;

      // Адаптивная скорость
      double speed;
      if (distance > 0.01) {
        speed = 0.35; // Далеко — быстро
      } else if (distance > 0.001) {
        speed = 0.25; // Средне
      } else {
        speed = 0.15; // Близко — плавно
      }

      final newLat =
          current.latitude + (target.latitude - current.latitude) * speed;
      final newLng =
          current.longitude + (target.longitude - current.longitude) * speed;
      _driverCurrentPositions[driverId] = LatLng(newLat, newLng);
      changed = true;
    }

    if (changed) {
      _markersDirty = true;
    }
  }

  /// Получает polyline маршрута для конкретного водителя
  List<LatLng> _getDriverRoutePolyline(String driverId) {
    // Ищем polyline для водителя из routePolylines
    for (final entry in widget.routePolylines.entries) {
      final routeId = entry.key;
      final encodedPolyline = entry.value;

      // Проверяем, принадлежит ли маршрут этому водителю
      final routePoints =
          widget.points.where((p) => p.routeId == routeId).toList();
      if (routePoints.isNotEmpty && routePoints.first.driverId == driverId) {
        // Декодируем polyline
        try {
          return PolylineDecoder.decode(encodedPolyline)
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } catch (e) {
          debugPrint('❌ [Map] Error decoding polyline for route $routeId: $e');
          return [];
        }
      }
    }

    // Альтернативно, создаем polyline из точек водителя
    final driverPoints = widget.points
        .where((p) => p.driverId == driverId)
        .where((p) => p.status != DeliveryPoint.statusCompleted)
        .toList();

    if (driverPoints.isNotEmpty) {
      // Сортируем по orderInRoute
      driverPoints
          .sort((a, b) => (a.orderInRoute ?? 0).compareTo(b.orderInRoute ?? 0));
      return driverPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    }

    return [];
  }

  /// Пересоздаёт маркеры водителей из текущих (анимированных) позиций
  void _rebuildDriverMarkers() {
    if (!mounted) return;

    final driverColor = _getDriverMarkerColor();
    final hue = HSVColor.fromColor(driverColor).hue;
    final driverMarkers = <Marker>{};

    for (final entry in _driverCurrentPositions.entries) {
      final driverId = entry.key;
      final position = entry.value;
      final name = _driverNames[driverId] ?? '';
      final eta = _driverETAs[driverId] ?? '';
      final heading = _driverHeadings[driverId] ?? 0.0;

      driverMarkers.add(
        Marker(
          markerId: MarkerId('driver_$driverId'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          rotation: heading, // 🧭 Поворачиваем маркер по направлению движения
          anchor: const Offset(0.5, 0.5), // Центрируем точку вращения
          infoWindow: InfoWindow(
            title: '🚛 $name',
            snippet: eta.isNotEmpty ? 'ETA: $eta' : '',
          ),
          zIndexInt: 100,
        ),
      );
    }

    setState(() {
      _driverMarkers = driverMarkers;
    });
  }

  /// Обновляет маркер конкретного водителя (простой вариант)
  void _updateDriverMarker(String driverId, double lat, double lng) {
    if (!mounted) return;

    final driverColor = _getDriverMarkerColor();
    final hue = HSVColor.fromColor(driverColor).hue;
    final name = _driverNames[driverId] ?? 'Driver';
    final eta = _driverETAs[driverId] ?? '';
    final heading = _driverHeadings[driverId] ?? 0.0;

    final newMarker = Marker(
      markerId: MarkerId('driver_$driverId'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      rotation: heading, // 🧭 Поворачиваем маркер по направлению движения
      anchor: const Offset(0.5, 0.5), // Центрируем точку вращения
      infoWindow: InfoWindow(
        title: '🚛 $name',
        snippet: eta.isNotEmpty ? 'ETA: $eta' : '',
      ),
      zIndexInt: 100,
    );

    setState(() {
      _driverMarkers = Set.from(_driverMarkers)
        ..removeWhere((marker) => marker.markerId.value == 'driver_$driverId');
      _driverMarkers.add(newMarker);
      _driverCurrentPositions[driverId] = LatLng(lat, lng);
      _driverTargetPositions[driverId] = LatLng(lat, lng);
    });
  }

  Future<void> _updateDriverMarkers(
      List<Map<String, dynamic>> driverLocations) async {
    if (!mounted) return;

    // Сохраняем позиции водителей для расчета ETA
    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;
      _driverLocations[driverId] = driverLocation;
    }

    // Пересчитываем ETA для всех водителей (с debounce — не чаще раз в 5 сек)
    _etaDebounce?.cancel();
    _etaDebounce = Timer(const Duration(seconds: 5), () => _calculateETAs());

    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;
      final driverName = driverLocation['driverName']?.toString() ?? '';
      final latitude = (driverLocation['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude =
          (driverLocation['longitude'] as num?)?.toDouble() ?? 0.0;
      final timestamp = driverLocation['timestamp'];
      final now = DateTime.now();

      // 🛡️ Фильтр дергания GPS (игнорируем движения < 25 метров)
      final newPosition = GpsLatLng(latitude, longitude);
      if (!GpsUtils.shouldUpdatePosition(
          _lastDriverPositions[driverId], newPosition)) {
        continue; // Пропускаем слишком маленькое движение
      }

      // ⏱️ Дополнительный фильтр: движение > 20 метров ИЛИ прошло 3 секунды
      final lastPos = _lastDriverPositions[driverId];
      final lastTime = _lastPositionTimes[driverId] ?? now;
      final secondsDiff = now.difference(lastTime).inSeconds;

      if (lastPos != null) {
        final distanceMoved = GpsUtils.distanceMeters(
          lastPos.latitude,
          lastPos.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        // Пропускаем если движение < 20 метров И прошло < 3 секунд
        if (distanceMoved < 20.0 && secondsDiff < 3) {
          debugPrint(
              '⏱️ [GPS Filter] Skipping update: ${distanceMoved.toStringAsFixed(1)}m in ${secondsDiff}s (need >20m OR >3s)');
          continue;
        }

        debugPrint(
            '📍 [GPS Update] Distance: ${distanceMoved.toStringAsFixed(1)}m, Time: ${secondsDiff}s');
      }

      // 🧭 Вычисляем heading (направление движения)
      double newHeading = _driverHeadings[driverId] ?? 0.0;
      double speed = 0.0;

      if (lastPos != null) {
        // Вычисляем скорость и heading
        final secondsDiff = now.difference(lastTime).inSeconds;

        if (secondsDiff > 0) {
          speed = GpsUtils.calculateSpeed(lastPos, newPosition, secondsDiff);

          // Обновляем heading только если скорость > 5 км/ч (чтобы не дергалось на парковке)
          if (speed > 5.0) {
            newHeading = GpsUtils.calculateHeading(
              lastPos.latitude,
              lastPos.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );
          }
        }
      }

      // 🚦 Надежное определение стоянки (двойная проверка)
      final lastPosForStop = _lastDriverPositions[driverId];
      double moved = 0;
      if (lastPosForStop != null) {
        moved = GpsUtils.distanceMeters(
          lastPosForStop.latitude,
          lastPosForStop.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
      }

      // Двойная проверка: скорость < 5 км/ч И движение < 8 метров (AND - оба условия)
      final isStopped = (speed <= 5.0) && (moved < 8.0);

      if (isStopped) {
        // Водитель стоит - начинаем или продолжаем отсчет стоянки
        _driverStopStartTimes.putIfAbsent(driverId, () => now);
        final stopStart = _driverStopStartTimes[driverId]!;
        final stoppedSeconds = now.difference(stopStart).inSeconds;
        debugPrint(
            '🚦 [StopTime] Driver $driverId is stopped (speed: ${speed.toStringAsFixed(1)} km/h, moved: ${moved.toStringAsFixed(1)}m) for ${stoppedSeconds}s');
      } else {
        // Водитель движется - сбрасываем время стоянки
        _driverStopStartTimes.remove(driverId);
        debugPrint(
            '🚗 [StopTime] Driver $driverId is moving (speed: ${speed.toStringAsFixed(1)} km/h, moved: ${moved.toStringAsFixed(1)}m) - stop time reset');
      }

      _lastDriverPositions[driverId] =
          newPosition; // Сохраняем последнюю позицию
      _driverHeadings[driverId] = newHeading; // Сохраняем heading
      _lastPositionTimes[driverId] = now; // Сохраняем время

      // 🕐 Проверка рабочей смены и свежести GPS
      if (timestamp != null) {
        try {
          final locationTime =
              (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();

          // 🎯 Проверяем должен ли водитель отображаться на карте
          if (!shouldShowDriver(locationTime)) {
            continue; // Пропускаем водителя вне смены или с устаревшим GPS
          }
        } catch (e) {
          debugPrint('⚠️ [DeliveryMap] Error parsing timestamp: $e');
          continue;
        }
      } else {
        // Если нет timestamp - пропускаем водителя
        continue;
      }

      // Фильтруем нулевые координаты
      if (latitude == 0 && longitude == 0) continue;

      // 🛡️ GPS фильтр: игнорируем прыжки > 5 км (ошибка GPS)
      final currentPos = _driverCurrentPositions[driverId];
      if (currentPos != null) {
        final jumpDist = (latitude - currentPos.latitude).abs() +
            (longitude - currentPos.longitude).abs();
        if (jumpDist > 0.05) {
          // ~5 км
          debugPrint(
            '⚠️ [Map] GPS jump filtered for $driverId: ${jumpDist.toStringAsFixed(4)}',
          );
          continue;
        }
      }

      // 📍 Обновляем маркер водителя напрямую
      _updateDriverMarker(driverId, latitude, longitude);

      if (!_driverCurrentPositions.containsKey(driverId)) {
        _driverCurrentPositions[driverId] = LatLng(latitude, longitude);
      }

      // 🎯 Автоматическое закрытие ближайших точек (< 70 метров)
      await _autoCompleteNearbyPoints(driverId, LatLng(latitude, longitude));
    }

    // Обновляем линии прогресса маршрутов
    _updateDriverProgressPolylines();
  }

  /// Обновляет полилинии прогресса для всех водителей (эффект Waze)
  void _updateDriverProgressPolylines() {
    if (!mounted) return;

    final progressPolylines = <Polyline>{};

    // Получаем всех активных водителей
    final activeDrivers = _driverCurrentPositions.keys.toList();

    for (final driverId in activeDrivers) {
      final driverPos = _driverCurrentPositions[driverId];
      if (driverPos == null) continue;

      // Получаем маршрут водителя
      final routePolylines = _getDriverRoutePolyline(driverId);
      if (routePolylines.isEmpty) continue;

      // Разделяем маршрут на пройденную и оставшуюся части
      final routeSplit = RouteProgressService.splitRouteAtDriverPosition(
          driverPos, routePolylines);
      final passedRoute = routeSplit['passedRoute'] as List<LatLng>;
      final remainingRoute = routeSplit['remainingRoute'] as List<LatLng>;

      // Цвет маршрута водителя
      final driverColor = _getRouteLoadColor(driverId);

      // 🛣️ Пройденный маршрут (серый пунктир)
      if (passedRoute.length > 1) {
        progressPolylines.add(
          Polyline(
            polylineId: PolylineId('passed_$driverId'),
            points: passedRoute,
            color: Colors.grey.withOpacity(0.7),
            width: 6,
            zIndex: 2,
            patterns: [PatternItem.dash(10)], // Пунктирная линия
          ),
        );
      }

      // 🛣️ Оставшийся маршрут (цвет водителя)
      if (remainingRoute.length > 1) {
        progressPolylines.add(
          Polyline(
            polylineId: PolylineId('remaining_$driverId'),
            points: remainingRoute,
            color: driverColor.withOpacity(0.8),
            width: 6,
            zIndex: 3,
          ),
        );
      }
    }

    setState(() {
      _driverProgressPolylines = progressPolylines;
    });
  }

  /// Автоматически закрывает точки доставки при приближении водителя
  /// Если расстояние < 70 метров, обновляет статус на 'completed'
  Future<void> _autoCompleteNearbyPoints(
      String driverId, LatLng driverPosition) async {
    try {
      // Находим активные точки этого водителя
      final driverPoints = widget.points
          .where((p) =>
              p.driverId == driverId &&
              p.status != DeliveryPoint.statusCompleted &&
              p.status != DeliveryPoint.statusCancelled)
          .toList();

      if (driverPoints.isEmpty) return;

      for (final point in driverPoints) {
        final pointPosition = LatLng(point.latitude, point.longitude);

        // Вычисляем расстояние до точки
        final distance = GpsUtils.distanceMeters(
          driverPosition.latitude,
          driverPosition.longitude,
          pointPosition.latitude,
          pointPosition.longitude,
        );

        // 🏢 Двухфазная модель доставки как в Uber Eats/Wolt
        const arrivalDistance = 120.0; // Фаза 1: Arrival zone
        const completeDistance = 70.0; // Фаза 2: Delivery zone
        const resetDistance =
            900.0; // Сброс флага если уехал далеко (адекватно для Тель-Авива)
        const stopTimeSeconds = 120; // 2 минуты стоянки

        // 🚦 Проверяем время стоянки водителя
        final stopStart = _driverStopStartTimes[driverId];
        final stoppedSeconds = stopStart == null
            ? 0
            : DateTime.now().difference(stopStart).inSeconds;

        // 🛣️ Проверяем находится ли водитель на маршруте
        final isOnRoute = RouteProgressService.isDriverOnRoute(
          driverPosition,
          _getDriverRoutePolyline(driverId),
          maxDistanceMeters: 50,
        );

        // 🎯 Фаза 1: Arrival zone - запоминаем что водитель был рядом
        if (distance < arrivalDistance &&
            point.status != DeliveryPoint.statusCompleted) {
          final pointKey =
              '${driverId}_${point.id}'; // Уникальный ключ для водителя+точки
          if (!_driverArrivedNearPoints.containsKey(pointKey) ||
              !_driverArrivedNearPoints[pointKey]!) {
            _driverArrivedNearPoints[pointKey] = true;
            debugPrint(
                '🏢 [Arrival] Driver $driverId arrived near ${point.clientName} (${distance.toStringAsFixed(1)}m < ${arrivalDistance.toInt()}m)');
          }
        }

        // 🔄 Сброс флага если водитель уехал далеко
        if (distance > resetDistance) {
          final pointKey = '${driverId}_${point.id}';
          if (_driverArrivedNearPoints.containsKey(pointKey)) {
            _driverArrivedNearPoints.remove(pointKey);
            debugPrint(
                '🔄 [Reset] Driver $driverId left area - reset arrival flag for ${point.clientName} (${distance.toStringAsFixed(1)}m > ${resetDistance.toInt()}m)');
          }
        }

        // 🎯 Проверяем флаг прибытия
        final pointKey = '${driverId}_${point.id}';
        final arrivedNearPoint = _driverArrivedNearPoints[pointKey] ?? false;

        debugPrint(
            '🎯 [AutoComplete] Point ${point.clientName}: distance=${distance.toStringAsFixed(1)}m, stopped=${stoppedSeconds}s, onRoute=$isOnRoute, arrived=$arrivedNearPoint');

        // 🛡️ Защита от Firestore spam + правильная двухфазная логика
        if (point.status != DeliveryPoint.statusCompleted &&
            isOnRoute &&
            stoppedSeconds >= stopTimeSeconds &&
            (distance < completeDistance || arrivedNearPoint)) {
          debugPrint(
              '✅ [AutoComplete] Point ${point.clientName} completed! Distance: ${distance.toStringAsFixed(1)}m, Stopped: ${stoppedSeconds}s, Arrived: $arrivedNearPoint, OnRoute: $isOnRoute');

          // Обновляем Firestore
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('delivery_points')
              .doc(point.id)
              .update({
            'status': DeliveryPoint.statusCompleted,
            'completedAt': FieldValue.serverTimestamp(),
            'completedBy': driverId,
          });

          debugPrint(
              '✅ [AutoComplete] Completed point: ${point.clientName} for driver: $driverId');

          // 🔄 Обновляем карту после закрытия точки
          await _refreshMapAfterCompletion(driverId);

          // 🗑️ Очищаем флаг прибытия после закрытия
          _driverArrivedNearPoints.remove(pointKey);
        } else if (distance < completeDistance &&
            point.status == DeliveryPoint.statusCompleted) {
          debugPrint(
              '🛡️ [AutoComplete] Point ${point.clientName} already completed - skipping duplicate update');
        } else if (distance < arrivalDistance) {
          String reason = '';
          if (!isOnRoute) reason += 'NOT_ON_ROUTE ';
          if (stoppedSeconds < stopTimeSeconds)
            reason += 'STOPPED_${stoppedSeconds}s ';
          if (!arrivedNearPoint && distance >= completeDistance)
            reason += 'NOT_ARRIVED_${distance.toInt()}m ';
          debugPrint(
              '⏳ [AutoComplete] Point ${point.clientName} not ready: $reason(distance: ${distance.toStringAsFixed(1)}m)');
        }
      }
    } catch (e) {
      debugPrint('❌ [AutoComplete] Error completing points: $e');
    }
  }

  /// 🔄 Обновляет карту после закрытия точки доставки
  Future<void> _refreshMapAfterCompletion(String driverId) async {
    try {
      debugPrint(
          '🔄 [Refresh] Updating map after completion for driver: $driverId');

      // 1️⃣ Перестраиваем polyline маршрутов (без завершенных точек)
      await _updateRoutePolylines();

      // 2️⃣ Пересчитываем ETA для всех водителей
      _calculateETAs();

      // 3️⃣ Обновляем линии прогресса
      _updateDriverProgressPolylines();

      // ❌ Убираем _updateMapData() - Firestore listener уже обновит точки
      // Это предотвращает двойную перерисовку карты

      debugPrint(
          '✅ [Refresh] Map updated successfully after completion (no double redraw)');
    } catch (e) {
      debugPrint('❌ [Refresh] Error updating map after completion: $e');
    }
  }

  /// Обновляет polyline маршрутов после изменений
  Future<void> _updateRoutePolylines() async {
    if (!mounted) return;

    try {
      // Получаем обновленные маршруты от родительского виджета
      final updatedPolylines = <Polyline>{};

      // Для каждого маршрута строим polyline из активных точек
      final routes = widget.points
          .where((p) => p.routeId != null)
          .map((p) => p.routeId!)
          .toSet();

      for (final routeId in routes) {
        final routePoints = widget.points
            .where((p) =>
                p.routeId == routeId &&
                p.status != DeliveryPoint.statusCompleted)
            .toList();

        if (routePoints.length > 1) {
          // Сортируем по orderInRoute
          routePoints.sort(
              (a, b) => (a.orderInRoute ?? 0).compareTo(b.orderInRoute ?? 0));

          // Создаем polyline из точек
          final polylinePoints =
              routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

          final routeColor =
              _getRouteLoadColor(routePoints.first.driverId ?? '');

          updatedPolylines.add(
            Polyline(
              polylineId: PolylineId('route_$routeId'),
              points: polylinePoints,
              color: routeColor.withOpacity(0.8),
              width: 4,
              zIndex: 1,
            ),
          );
        }
      }

      setState(() {
        _polylines = updatedPolylines;
      });

      debugPrint(
          '🛣️ [Refresh] Updated ${updatedPolylines.length} route polylines');
    } catch (e) {
      debugPrint('❌ [Refresh] Error updating route polylines: $e');
    }
  }

  // Рассчитываем ETA для всех водителей (локально, без OSRM)
  void _calculateETAs() {
    // ...
    // Защита от crash при пустых данных
    if (widget.points.isEmpty || _driverLocations.isEmpty) return;

    for (final entry in _driverLocations.entries) {
      final driverId = entry.key;
      final location = entry.value;
      final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      final speed = (location['speed'] as num?)?.toDouble() ?? 0.0;

      // Находим следующую незавершенную точку для этого водителя
      DeliveryPoint? nextPoint;
      try {
        nextPoint = widget.points.firstWhere(
          (p) =>
              p.driverId == driverId &&
              p.status != DeliveryPoint.statusCompleted &&
              p.status != DeliveryPoint.statusCancelled,
        );
      } catch (_) {
        continue; // Нет активных точек
      }

      // Расстояние по прямой (км)
      final distKm = _gpsDistanceKm(
        latitude,
        longitude,
        nextPoint.latitude,
        nextPoint.longitude,
      );

      // Средняя скорость: если GPS speed > 5 км/ч — используем её, иначе 30 км/ч (город)
      final avgSpeedKmh = (speed * 3.6 > 5) ? speed * 3.6 : 30.0;
      // Коэффициент дороги: реальный путь ~1.4x от прямой
      final etaMinutes = (distKm * 1.4 / avgSpeedKmh * 60).round();

      if (etaMinutes > 0 && etaMinutes < 999) {
        _driverETAs[driverId] = '$etaMinutes min';
      }
    }

    // Обновляем маркеры через батчинг
    if (mounted) {
      _markersDirty = true;
    }
  }

  // =========================================================================
  // 🖐️ DRAG & DROP — перетаскивание точек на водителей
  // =========================================================================

  /// При начале перетаскивания — показываем зоны водителей
  void _onPointDragStart(DeliveryPoint point) {
    _draggingPointId = point.id;
    _showDriverZones();
    debugPrint('🖐️ [DragDrop] Started dragging: ${point.clientName}');
  }

  /// При отпускании — ищем ближайшего водителя и назначаем
  void _onPointDragEnd(DeliveryPoint point, LatLng newPosition) {
    _draggingPointId = null;

    // Убираем зоны водителей
    setState(() {
      _driverZoneCircles = {};
    });

    // Ищем ближайшего водителя (исключаем текущего водителя точки)
    final nearest =
        _findNearestDriver(newPosition, excludeDriverId: point.driverId);
    if (nearest == null) {
      debugPrint('⚠️ [DragDrop] No driver found near drop position');
      _updateMapData();
      return;
    }

    final driverId = nearest['driverId'] as String;
    final driverName = nearest['driverName'] as String;
    final distKm = nearest['distKm'] as double;

    debugPrint(
      '🖐️ [DragDrop] Dropped ${point.clientName} near $driverName (${distKm.toStringAsFixed(1)} km)',
    );

    // Сразу назначаем точку водителю
    widget.onPointDragToDriver?.call(point.id, driverId, driverName);

    // Показываем уведомление
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📦 ${point.clientName} → 🚛 $driverName',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Ищем ближайшего водителя к позиции drop
  /// Сначала по GPS-позициям водителей, затем по точкам маршрутов на карте
  /// Возвращает {driverId, driverName, distKm} или null
  Map<String, dynamic>? _findNearestDriver(LatLng position,
      {String? excludeDriverId}) {
    String? nearestId;
    String? nearestName;
    double minDist = double.infinity;

    // 1️⃣ Ищем по GPS-позициям водителей (если доступны)
    for (final entry in _driverCurrentPositions.entries) {
      final driverId = entry.key;
      if (driverId == excludeDriverId) continue;
      final driverPos = entry.value;
      final name = _driverNames[driverId] ?? 'Driver';

      final dist = _gpsDistanceKm(
        position.latitude,
        position.longitude,
        driverPos.latitude,
        driverPos.longitude,
      );

      if (dist < minDist) {
        minDist = dist;
        nearestId = driverId;
        nearestName = name;
      }
    }

    // 2️⃣ Ищем по точкам маршрутов (для случаев когда GPS недоступен)
    for (final point in widget.points) {
      if (point.driverId == null || point.driverId!.isEmpty) continue;
      if (point.driverId == excludeDriverId) continue;

      final dist = _gpsDistanceKm(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );

      if (dist < minDist) {
        minDist = dist;
        nearestId = point.driverId;
        nearestName = point.driverName ?? 'Driver';
      }
    }

    // Максимальное расстояние для привязки — 50 км (вся территория Израиля)
    if (nearestId == null || minDist > 50.0) return null;

    debugPrint(
      '🎯 [DragDrop] Nearest driver: $nearestName ($nearestId), dist: ${minDist.toStringAsFixed(1)} km',
    );

    return {
      'driverId': nearestId,
      'driverName': nearestName ?? 'Driver',
      'distKm': minDist,
    };
  }

  /// Показываем полупрозрачные круги вокруг водителей при drag
  void _showDriverZones() {
    if (_driverCurrentPositions.isEmpty) return;

    final circles = <Circle>{};
    final driverIds = _driverCurrentPositions.keys.toList();

    for (int i = 0; i < driverIds.length; i++) {
      final driverId = driverIds[i];
      final pos = _driverCurrentPositions[driverId];
      if (pos == null) continue;

      final color = _getRouteLoadColor(driverId);

      circles.add(
        Circle(
          circleId: CircleId('zone_$driverId'),
          center: pos,
          radius: 3000, // 3 км радиус зоны
          fillColor: color.withOpacity(0.15),
          strokeColor: color.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _driverZoneCircles = circles;
    });
  }

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
}
