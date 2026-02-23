import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';
import '../services/optimized_location_service.dart';
import '../services/smart_navigation_service.dart';
import '../config/app_config.dart';
import '../utils/polyline_decoder.dart';
import 'package:flutter/foundation.dart' show debugPrint, listEquals;

class DeliveryMapWidget extends StatefulWidget {
  final List<DeliveryPoint> points;

  const DeliveryMapWidget({super.key, required this.points});

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final OptimizedLocationService _locationService = OptimizedLocationService();
  final SmartNavigationService _smartNavigationService =
      SmartNavigationService();

  StreamSubscription<List<Map<String, dynamic>>>? _driverLocationsSubscription;
  Timer? _debounceTimer;
  bool _isLoadingRoute = false;
  String? _lastRouteSignature; // Кеш для предотвращения лишних запросов
  final Map<String, Map<String, dynamic>> _driverLocations =
      {}; // Текущие позиции водителей
  final Map<String, String> _driverETAs = {}; // ETA для каждого водителя

  // Генерация цвета для водителя
  Color _getDriverColor(String driverKey, int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    // Используем хеш от driverKey для стабильного цвета
    final hash = driverKey.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapData();
    });
    _startDriverLocationTracking();
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSignature = _buildPointSignature(oldWidget.points);
    final newSignature = _buildPointSignature(widget.points);

    // Обновляем карту только при реальных изменениях
    if (!listEquals(oldSignature, newSignature)) {
      _updateMapData();
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
    _debounceTimer?.cancel();
    _driverLocationsSubscription?.cancel();
    // _controller?.dispose(); // на web может падать
    super.dispose();
  }

  /// ✅ ВАЖНО: не вызываем async внутри setState
  Future<void> _updateMapData() async {
    if (!mounted) return;

    final markers = _buildPointMarkers();
    final polylines = await _buildRoutePolylines();

    if (!mounted) return;
    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
    // После обновления состояния — фитим камеру по polyline
    if (_polylines.isNotEmpty && _controller != null) {
      debugPrint(
          '🎯 [Map] Centering camera on route with ${_polylines.length} polylines');
      // Небольшая задержка для завершения рендеринга
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _controller == null) return;

      final polyline = _polylines.first;
      debugPrint('📍 [Map] Polyline has ${polyline.points.length} points');
      final bounds = _calculatePolylineBounds(polyline.points);
      debugPrint(
          '🗺️ [Map] Bounds: SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}) NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})');
      try {
        await _controller!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
        debugPrint('✅ [Map] Camera centered on route');
      } catch (e) {
        debugPrint('❌ [Map] Camera animation error (polyline fit): $e');
      }
    } else {
      debugPrint(
          '⚠️ [Map] Cannot center: polylines=${_polylines.length}, controller=${_controller != null}');
    }
  }

  /// Фитит камеру по polyline, а не по маркерам
  LatLngBounds _calculatePolylineBounds(List<LatLng> points) {
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

  Set<Marker> _buildPointMarkers() {
    debugPrint(
        '🗺️ [Map] Updating markers with ${widget.points.length} points');
    final l10n = AppLocalizations.of(context);

    final markers = <Marker>{};

    // 🏭 Добавляем маркер склада (ВСЕГДА первый)
    markers.add(
      Marker(
        markerId: const MarkerId('warehouse'),
        position: const LatLng(
            AppConfig.defaultWarehouseLat, AppConfig.defaultWarehouseLng),
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
      // Определяем цвет маркера в зависимости от статуса
      BitmapDescriptor markerColor;
      if (point.status == DeliveryPoint.statusCompleted ||
          point.status == DeliveryPoint.statusCancelled) {
        // Серый для завершенных/отмененных
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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

      markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: markerColor,
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
        '🗺️ [Map] Created ${markers.length} markers (including warehouse)');
    return markers;
  }

  Future<Set<Polyline>> _buildRoutePolylines() async {
    debugPrint(
        '🗺️ [Map] Updating polylines with ${widget.points.length} points');

    // Если нет точек доставки, не строим маршрут
    if (widget.points.isEmpty) {
      debugPrint('🗺️ [Map] No delivery points, clearing polylines');
      return {};
    }

    final validRoutePoints = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .toList();

    // Если нет назначенных точек, не строим маршрут
    if (validRoutePoints.isEmpty) {
      debugPrint('🗺️ [Map] No points assigned to drivers, clearing polylines');
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
            '${p.driverId}:${p.latitude},${p.longitude}:${p.orderInRoute}')
        .join('|');

    // Если маршрут не изменился, возвращаем текущие полилинии
    if (_lastRouteSignature == routeSignature && _polylines.isNotEmpty) {
      debugPrint('✅ [Map] Route signature unchanged, using cached polylines');
      return _polylines;
    }

    debugPrint('🗺️ [Map] Sorted route points by driver and order:');
    for (var p in validRoutePoints) {
      debugPrint(
          '  - ${p.clientName}: driver=${p.driverName}, order=${p.orderInRoute}');
    }

    // Если уже загружаем маршрут, возвращаем текущие полилинии (не пустые!)
    if (_isLoadingRoute) {
      debugPrint(
          '⏳ [Map] Route loading in progress, keeping current polylines');
      return _polylines.isNotEmpty ? _polylines : {};
    }
    _isLoadingRoute = true;

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
            .where((p) =>
                p.status == DeliveryPoint.statusCompleted ||
                p.status == DeliveryPoint.statusCancelled)
            .toList();
        final activePoints = points
            .where((p) =>
                p.status != DeliveryPoint.statusCompleted &&
                p.status != DeliveryPoint.statusCancelled)
            .toList();

        debugPrint(
            '🏭 [Map] Driver $driverKey: ${completedPoints.length} completed, ${activePoints.length} active');

        // 🏭 ВАЖНО: Маршрут ВСЕГДА начинается со склада!
        final warehouseLat = AppConfig.defaultWarehouseLat;
        final warehouseLng = AppConfig.defaultWarehouseLng;

        // Строим серый маршрут для завершенных точек (если есть)
        if (completedPoints.isNotEmpty) {
          final completedEnd = completedPoints.last;
          final completedWaypoints =
              completedPoints.sublist(0, completedPoints.length - 1);

          final completedRoute =
              await _smartNavigationService.getMultiPointRoute(
            startLat: warehouseLat,
            startLng: warehouseLng,
            waypoints: completedWaypoints,
            endLat: completedEnd.latitude,
            endLng: completedEnd.longitude,
            language: 'he',
          );

          if (completedRoute != null && completedRoute.polyline.isNotEmpty) {
            final decoded =
                PolylineDecoder.decode(completedRoute.polyline, precision: 5);
            if (PolylineDecoder.isValid(decoded)) {
              result.add(
                Polyline(
                  polylineId: PolylineId('route_${driverKey}_completed'),
                  points: decoded,
                  width: 8,
                  color: Colors.grey.shade400, // Серый для пройденного
                  zIndex: 5, // Ниже активного маршрута
                ),
              );
              debugPrint(
                  '🎨 [Map] Added completed route (grey) for driver $driverKey');
            }
          }
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
              '🏭 [Map] Building active route for driver $driverKey from ($startLat, $startLng)');
          debugPrint('📍 [Map] Route has ${activePoints.length} active points');
          debugPrint(
              '🏭 [Map] Start: Warehouse/Last completed ($startLat, $startLng)');
          debugPrint(
              '🎯 [Map] End: ${activePoints.last.clientName} (${activePoints.last.latitude}, ${activePoints.last.longitude})');

          final end = activePoints.last;
          final waypoints = activePoints.sublist(0, activePoints.length - 1);

          debugPrint('📍 [Map] Waypoints count: ${waypoints.length}');

          final smartRoute = await _smartNavigationService.getMultiPointRoute(
            startLat: startLat,
            startLng: startLng,
            waypoints: waypoints,
            endLat: end.latitude,
            endLng: end.longitude,
            language: 'he',
          );

          debugPrint(
              '🧭 [Map] SmartNavigationService result for driver $driverKey:');
          debugPrint('  - Route found: ${smartRoute != null}');
          if (smartRoute != null) {
            debugPrint('  - Polyline length: ${smartRoute.polyline.length}');
            debugPrint('  - Distance: ${smartRoute.distance}');
            debugPrint('  - Duration: ${smartRoute.duration}');
          }

          if (smartRoute == null || smartRoute.polyline.isEmpty) {
            debugPrint(
                '⚠️ [Map] No route from SmartNavigationService, using fallback');
            result.addAll(_fallbackPolyline(activePoints,
                driverIndex: driverIndex, isCompleted: false));
            driverIndex++;
            continue;
          }

          final rawPolyline = smartRoute.polyline;
          var decoded = PolylineDecoder.decode(rawPolyline, precision: 5);

          if (!PolylineDecoder.isValid(decoded)) {
            debugPrint('⚠️ [Map] Polyline invalid, using fallback');
            result.addAll(_fallbackPolyline(activePoints,
                driverIndex: driverIndex, isCompleted: false));
            driverIndex++;
            continue;
          }

          final driverColor = _getDriverColor(driverKey, driverIndex);
          debugPrint(
              '🎨 [Map] Driver $driverKey active route color: $driverColor');

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

      _lastRouteSignature = routeSignature; // Сохраняем сигнатуру
      return result;
    } catch (e) {
      debugPrint('❌ [Map] SmartNavigationService error: $e');
      return _fallbackPolyline(validRoutePoints);
    } finally {
      _isLoadingRoute = false;
    }
  }

  Set<Polyline> _fallbackPolyline(
    List<DeliveryPoint> points, {
    int driverIndex = 0,
    bool isCompleted = false,
  }) {
    // 🏭 Маршрут начинается со склада
    final routePoints = <LatLng>[
      const LatLng(
          AppConfig.defaultWarehouseLat, AppConfig.defaultWarehouseLng),
      ...points.map((p) => LatLng(p.latitude, p.longitude)),
    ];

    final driverKey = points.isNotEmpty && points.first.driverId != null
        ? points.first.driverId!
        : 'unknown_$driverIndex';
    final driverColor = isCompleted
        ? Colors.grey.shade400
        : _getDriverColor(driverKey, driverIndex);

    debugPrint(
        '🗺️ [Map] Created fallback polyline with ${routePoints.length} points (STRAIGHT LINES)');
    debugPrint(
        '🏭 [Map] Starting from warehouse: (${AppConfig.defaultWarehouseLat}, ${AppConfig.defaultWarehouseLng})');
    debugPrint(
        '⚠️ [Map] This means OSRM/Google routing failed - routes will be straight lines!');
    debugPrint(
        '🎨 [Map] Fallback color: $driverColor (completed: $isCompleted)');

    return {
      Polyline(
        polylineId: PolylineId(
            'route_${driverKey}_${isCompleted ? "completed" : "active"}'),
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
      final bounds = _calculateBounds(widget.points);
      await _controller!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      debugPrint('Map camera animation error: $e');
    }
  }

  LatLngBounds _calculateBounds(List<DeliveryPoint> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
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
    final l10n = AppLocalizations.of(context)!;

    if (widget.points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noDeliveryPoints,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(
              AppConfig.defaultWarehouseLat,
              AppConfig.defaultWarehouseLng,
            ),
            zoom: 12,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          onMapCreated: (controller) {
            _controller = controller;
            debugPrint('🗺️ [Map] Controller initialized');
            // Центрируем карту после инициализации контроллера
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _controller != null) {
                if (_polylines.isNotEmpty) {
                  debugPrint(
                      '🎯 [Map] Auto-centering on route after controller init');
                  _centerOnRoute();
                } else {
                  _fitBounds();
                }
              }
            });
          },
        ),
      ],
    );
  }

  void _startDriverLocationTracking() {
    _driverLocationsSubscription =
        _locationService.getAllDriverLocationsStream().listen(
      (driverLocations) {
        _updateDriverMarkers(driverLocations);
      },
      onError: (error) {
        debugPrint('❌ [Driver Tracking] Error: $error');
      },
    );
  }

  void _updateDriverMarkers(List<Map<String, dynamic>> driverLocations) {
    if (!mounted) return;

    debugPrint(
        '🚛 [Driver Tracking] Processing ${driverLocations.length} driver locations');

    // Сохраняем позиции водителей для расчета ETA
    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId'] as String;
      _driverLocations[driverId] = driverLocation;
    }

    // Пересчитываем ETA для всех водителей
    _calculateETAs();

    // Создаем новый набор маркеров водителей
    final driverMarkers = <Marker>{};

    // Получаем список всех водителей с точками для определения цветов
    final allDriverIds = widget.points
        .where((p) => p.driverId != null)
        .map((p) => p.driverId!)
        .toSet()
        .toList();

    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId'] as String;
      final driverName = driverLocation['driverName'] as String? ?? 'Водитель';
      final latitude = driverLocation['latitude'] as double;
      final longitude = driverLocation['longitude'] as double;
      final timestamp = driverLocation['timestamp'];

      // Проверяем свежесть данных (не старше 5 минут)
      if (timestamp != null) {
        final locationTime = timestamp.toDate();
        final now = DateTime.now();
        final diffMinutes = now.difference(locationTime).inMinutes;
        if (diffMinutes > 5) {
          debugPrint(
              '⚠️ [Driver Tracking] Skipping stale location for $driverName (${diffMinutes}min old)');
          continue;
        }
      }

      debugPrint(
          '📍 [Driver Tracking] Adding marker for $driverName at ($latitude, $longitude)');

      // Получаем ETA для водителя
      final eta = _driverETAs[driverId] ?? '';

      // Добавляем водителя в список если его там нет
      if (!allDriverIds.contains(driverId)) {
        allDriverIds.add(driverId);
      }

      final driverIndex = allDriverIds.indexOf(driverId);
      final driverColor = _getDriverColor(driverId, driverIndex);

      // Конвертируем Color в BitmapDescriptor hue (0-360)
      final hue = HSVColor.fromColor(driverColor).hue;

      driverMarkers.add(
        Marker(
          markerId: MarkerId('driver_$driverId'),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '🚛 $driverName',
            snippet: eta.isNotEmpty ? 'ETA: $eta' : 'Активен',
          ),
          zIndex: 100, // Водитель всегда сверху
        ),
      );
    }

    debugPrint(
        '🚛 [Driver Tracking] Created ${driverMarkers.length} driver markers');

    // Обновляем только если маркеры водителей действительно изменились
    final currentDriverMarkers = _markers
        .where((marker) => marker.markerId.value.startsWith('driver_'))
        .toSet();

    if (!_markersEqual(currentDriverMarkers, driverMarkers)) {
      setState(() {
        // Удаляем старые маркеры водителей
        _markers.removeWhere(
            (marker) => marker.markerId.value.startsWith('driver_'));
        // Добавляем новые
        _markers.addAll(driverMarkers);
      });

      debugPrint(
          '✅ [Driver Tracking] Updated ${driverMarkers.length} driver markers on map');
    }
  }

  // Рассчитываем ETA для всех водителей
  Future<void> _calculateETAs() async {
    for (final entry in _driverLocations.entries) {
      final driverId = entry.key;
      final location = entry.value;
      final latitude = location['latitude'] as double;
      final longitude = location['longitude'] as double;

      // Находим следующую незавершенную точку для этого водителя
      final nextPoint = widget.points.firstWhere(
        (p) =>
            p.driverId == driverId &&
            p.status != DeliveryPoint.statusCompleted &&
            p.status != DeliveryPoint.statusCancelled,
        orElse: () => widget.points.firstWhere(
          (p) => p.driverId == driverId,
          orElse: () => DeliveryPoint(
            id: '',
            clientName: '',
            address: '',
            latitude: 0,
            longitude: 0,
            pallets: 0,
            orderInRoute: 0,
            status: '',
            urgency: 'normal',
            boxes: 0,
            eta: null,
          ),
        ),
      );

      if (nextPoint.id.isEmpty) continue;

      // Запрашиваем маршрут от текущей позиции до следующей точки
      try {
        final route = await _smartNavigationService.getMultiPointRoute(
          startLat: latitude,
          startLng: longitude,
          waypoints: [],
          endLat: nextPoint.latitude,
          endLng: nextPoint.longitude,
          language: 'he',
        );

        if (route != null) {
          _driverETAs[driverId] = route.duration;
          debugPrint(
              '⏱️ [ETA] Driver $driverId: ${route.duration} to ${nextPoint.clientName}');
        }
      } catch (e) {
        debugPrint('❌ [ETA] Error calculating ETA for driver $driverId: $e');
      }
    }

    // Обновляем UI если есть изменения
    if (mounted) {
      setState(() {});
    }
  }

  // Сравнение маркеров по ID и позиции
  bool _markersEqual(Set<Marker> set1, Set<Marker> set2) {
    if (set1.length != set2.length) return false;

    final map1 = {for (var m in set1) m.markerId.value: m.position};
    final map2 = {for (var m in set2) m.markerId.value: m.position};

    if (map1.length != map2.length) return false;

    for (final entry in map1.entries) {
      final pos2 = map2[entry.key];
      if (pos2 == null) return false;
      // Сравниваем координаты с точностью до 6 знаков
      if ((entry.value.latitude - pos2.latitude).abs() > 0.000001 ||
          (entry.value.longitude - pos2.longitude).abs() > 0.000001) {
        return false;
      }
    }

    return true;
  }

  /// Центрирует карту на маршруте
  Future<void> _centerOnRoute() async {
    if (_polylines.isEmpty || _controller == null) {
      debugPrint(
          '⚠️ [Map] Cannot center on route: polylines=${_polylines.length}, controller=${_controller != null}');
      return;
    }

    try {
      final polyline = _polylines.first;
      final bounds = _calculatePolylineBounds(polyline.points);
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
      debugPrint('✅ [Map] Successfully centered on route');
    } catch (e) {
      debugPrint('❌ [Map] Error centering on route: $e');
    }
  }

  String _buildMarkerSnippet(DeliveryPoint point, AppLocalizations? l10n) {
    final buffer = StringBuffer();

    buffer.write(
        '${point.pallets} ${l10n?.pallets ?? ''} • ${l10n?.order ?? 'Order'}: ${point.orderInRoute + 1}');

    final displayAddress =
        (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty)
            ? point.temporaryAddress!
            : point.address;

    buffer.write('\n📍 $displayAddress');

    return buffer.toString();
  }
}
