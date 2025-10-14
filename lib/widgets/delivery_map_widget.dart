import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, listEquals;

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
  final LocationService _locationService = LocationService();
  StreamSubscription<List<Map<String, dynamic>>>? _driverLocationsSubscription;
  Timer? _debounceTimer;

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

    final oldIds = oldWidget.points.map((p) => p.id).toList();
    final newIds = widget.points.map((p) => p.id).toList();

    // Обновляем карту только при реальных изменениях
    if (!listEquals(oldIds, newIds) ||
        oldWidget.points.length != widget.points.length) {
      _updateMapData();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _driverLocationsSubscription?.cancel();
    // Не вызываем dispose для контроллера на веб, т.к. это вызывает ошибки
    // _controller?.dispose();
    super.dispose();
  }

  void _updateMapData() {
    if (mounted) {
      setState(() {
        _updateMarkers();
        _updatePolylines();
      });
    }
  }

  void _updateMarkers() {
    debugPrint('🗺️ [Map] Updating markers with ${widget.points.length} points');
    final l10n = AppLocalizations.of(context);

    _markers = widget.points.map((point) {
      // Упрощенная цветовая схема - только синие маркеры для всех точек
      final markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

      return Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.latitude, point.longitude),
        icon: markerColor,
        infoWindow: InfoWindow(
          title: point.clientName,
          snippet: _buildMarkerSnippet(point, l10n),
        ),
      );
    }).toSet();
    
    debugPrint('🗺️ [Map] Created ${_markers.length} markers');
  }

  void _updatePolylines() {
    debugPrint('🗺️ [Map] Updating polylines with ${widget.points.length} points');
    
    if (widget.points.length < 2) {
      debugPrint('🗺️ [Map] Less than 2 points, clearing polylines');
      _polylines = {};
      return;
    }

    // Фильтруем точки с валидным orderInRoute и driverId
    final validRoutePoints = widget.points
        .where((p) => p.orderInRoute != null && p.driverId != null && p.driverId!.isNotEmpty)
        .toList();

    if (validRoutePoints.length < 2) {
      debugPrint('🗺️ [Map] Less than 2 points with valid orderInRoute, clearing polylines');
      _polylines = {};
      return;
    }

    // Сортируем по driverName, затем по orderInRoute
    validRoutePoints.sort((a, b) {
      final driverCompare = (a.driverName ?? '').compareTo(b.driverName ?? '');
      if (driverCompare != 0) return driverCompare;
      return (a.orderInRoute ?? 0).compareTo(b.orderInRoute ?? 0);
    });

    debugPrint('🗺️ [Map] Sorted route points by driver and order:');
    for (var p in validRoutePoints) {
      debugPrint('  - ${p.clientName}: driver=${p.driverName}, order=${p.orderInRoute}');
    }

    final routePoints =
        validRoutePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
    
    debugPrint('🗺️ [Map] Created polyline with ${routePoints.length} points');
  }

  void _fitBounds() async {
    if (widget.points.isEmpty || _controller == null) return;
    
    try {
      final bounds = _calculateBounds(widget.points);
      await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      // Игнорируем ошибки анимации камеры на веб
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
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.points.first.latitude,
              widget.points.first.longitude,
            ),
            zoom: 12,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (controller) {
            _controller = controller;
            // На веб не вызываем _fitBounds из-за проблем с инициализацией
            if (!kIsWeb) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _controller != null) {
                  _fitBounds();
                }
              });
            }
          },
        ),
        // Убрали легенду с цветовой градацией
      ],
    );
  }

  /// Запускает отслеживание позиций водителей в реальном времени
  void _startDriverLocationTracking() {
    _driverLocationsSubscription = _locationService.getAllDriverLocationsStream().listen(
      (driverLocations) {
        _updateDriverMarkers(driverLocations);
      },
      onError: (error) {
        debugPrint('❌ [Driver Tracking] Error: $error');
      },
    );
  }

  /// Обновляет маркеры водителей на карте
  void _updateDriverMarkers(List<Map<String, dynamic>> driverLocations) {
    if (!mounted) return;
    
    setState(() {
      // Удаляем старые маркеры водителей (начинающиеся с 'driver_')
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('driver_'));
      
      // Добавляем новые маркеры водителей
      for (final driverLocation in driverLocations) {
        final driverId = driverLocation['driverId'] as String;
        final latitude = driverLocation['latitude'] as double;
        final longitude = driverLocation['longitude'] as double;
        final timestamp = driverLocation['timestamp'];
        
        // Проверяем, что данные не старше 5 минут
        if (timestamp != null) {
          final locationTime = timestamp.toDate();
          final now = DateTime.now();
          final diffMinutes = now.difference(locationTime).inMinutes;
          
          if (diffMinutes > 5) continue; // Пропускаем старые данные
        }
        
        _markers.add(
          Marker(
            markerId: MarkerId('driver_$driverId'),
            position: LatLng(latitude, longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: '🚛 Водитель',
              snippet: 'ID: ${driverId.substring(0, 8)}...',
            ),
          ),
        );
      }
    });
    
    debugPrint('📍 [Driver Tracking] Updated ${driverLocations.length} driver locations');
  }

  /// Строит текст для информационного окна маркера
  String _buildMarkerSnippet(DeliveryPoint point, AppLocalizations? l10n) {
    final buffer = StringBuffer();
    
    // Паллеты и порядок
    buffer.write('${point.pallets} ${l10n?.pallets ?? ''} • ${l10n?.order ?? 'Order'}: ${(point.orderInRoute ?? 0) + 1}');
    
    // Адрес для отображения (временный приоритетнее основного)
    final displayAddress = (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) 
        ? point.temporaryAddress! 
        : point.address;
    
    buffer.write('\n📍 $displayAddress');
    
    return buffer.toString();
  }
}
