import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../services/osrm_directions_service.dart';
import '../services/smart_navigation_service.dart';
import '../config/app_config.dart';
import '../utils/polyline_decoder.dart';
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
  final OsrmDirectionsService _directionsService = OsrmDirectionsService();
  final SmartNavigationService _smartNavigationService =
      SmartNavigationService();

  StreamSubscription<List<Map<String, dynamic>>>? _driverLocationsSubscription;
  Timer? _debounceTimer;
  bool _isLoadingRoute = false;

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
      final polyline = _polylines.first;
      final bounds = _calculatePolylineBounds(polyline.points);
      try {
        await _controller!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      } catch (e) {
        debugPrint('Map camera animation error (polyline fit): $e');
      }
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

    final markers = widget.points.map((point) {
      final markerColor =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

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

    debugPrint('🗺️ [Map] Created ${markers.length} markers');
    return markers;
  }

  Future<Set<Polyline>> _buildRoutePolylines() async {
    debugPrint(
        '🗺️ [Map] Updating polylines with ${widget.points.length} points');

    if (widget.points.length < 2) {
      debugPrint('🗺️ [Map] Less than 2 points, clearing polylines');
      return {};
    }

    final validRoutePoints = widget.points
        .where((p) =>
            p.orderInRoute != null &&
            p.driverId != null &&
            p.driverId!.isNotEmpty)
        .toList();

    if (validRoutePoints.length < 2) {
      debugPrint(
          '🗺️ [Map] Less than 2 points with valid orderInRoute, clearing polylines');
      return {};
    }

    // Сортируем по driverName, затем по orderInRoute
    validRoutePoints.sort((a, b) {
      final driverCompare = (a.driverName ?? '').compareTo(b.driverName ?? '');
      if (driverCompare != 0) return driverCompare;
      return (a.orderInRoute ?? 0).compareTo(b.orderInRoute ?? 0);
    });

    debugPrint('🗺️ [Map] Sorted route points by driver and order:');
    for (var p in validRoutePoints) {
      debugPrint(
          '  - ${p.clientName}: driver=${p.driverName}, order=${p.orderInRoute}');
    }

    if (_isLoadingRoute) return _polylines;
    _isLoadingRoute = true;

    try {
      final Map<String, List<DeliveryPoint>> routesByDriver = {};

      for (final p in validRoutePoints) {
        final driverKey = p.driverId ?? p.driverName ?? 'unknown';
        routesByDriver.putIfAbsent(driverKey, () => []).add(p);
      }

      final Set<Polyline> result = {};

      for (final entry in routesByDriver.entries) {
        final driverKey = entry.key;
        final points = entry.value;

        if (points.length < 2) continue;

        points.sort(
            (a, b) => (a.orderInRoute ?? 0).compareTo(b.orderInRoute ?? 0));

        final start = points.first;
        final end = points.last;
        final waypoints = points.sublist(1, points.length - 1);

        final smartRoute = await _smartNavigationService.getMultiPointRoute(
          startLat: start.latitude,
          startLng: start.longitude,
          waypoints: waypoints,
          endLat: end.latitude,
          endLng: end.longitude,
          language: 'he',
        );

        debugPrint('🧭 [Map] SmartNavigationService result for driver $driverKey:');
        debugPrint('  - Route found: ${smartRoute != null}');
        if (smartRoute != null) {
          debugPrint('  - Polyline length: ${smartRoute.polyline.length}');
          debugPrint('  - Distance: ${smartRoute.distance}');
          debugPrint('  - Duration: ${smartRoute.duration}');
        }

        if (smartRoute == null || smartRoute.polyline.isEmpty) {
          debugPrint('⚠️ [Map] No route from SmartNavigationService, using fallback');
          result.addAll(_fallbackPolyline(points));
          continue;
        }

        final rawPolyline = smartRoute.polyline;
        debugPrint('🔍 [Map] Raw polyline length: ${rawPolyline.length} chars');
        debugPrint('🔍 [Map] Raw polyline type: ${rawPolyline.runtimeType}');
        debugPrint('🔍 [Map] Raw polyline preview (first 100): ${rawPolyline.substring(0, math.min(100, rawPolyline.length))}');
        
        if (rawPolyline.isNotEmpty) {
          final firstCharCode = rawPolyline.codeUnitAt(0);
          debugPrint('🔍 [Map] First char code: $firstCharCode (char: "${rawPolyline[0]}")');
        }
        
        // Используем утилитный класс для декодирования
        final sanitized = PolylineDecoder.sanitize(rawPolyline);
        var decoded = PolylineDecoder.decode(sanitized, precision: 5);

        if (!PolylineDecoder.isValid(decoded)) {
          debugPrint('⚠️ [Map] Sanitized polyline invalid, trying raw polyline');
          decoded = PolylineDecoder.decode(rawPolyline, precision: 5);
        }

        if (!PolylineDecoder.isValid(decoded)) {
          debugPrint('⚠️ [Map] Both sanitized and raw polylines invalid, using fallback');
          result.addAll(_fallbackPolyline(points));
          continue;
        }

        result.add(
          Polyline(
            polylineId: PolylineId('route_$driverKey'),
            points: decoded,
            width: 8,
            color: Colors.green,
            zIndex: 10,
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ [Map] SmartNavigationService error: $e');
      return _fallbackPolyline(validRoutePoints);
    } finally {
      _isLoadingRoute = false;
    }
  }

  Set<Polyline> _fallbackPolyline(List<DeliveryPoint> points) {
    final routePoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    debugPrint(
        '🗺️ [Map] Created fallback polyline with ${routePoints.length} points (STRAIGHT LINES)');
    debugPrint('⚠️ [Map] This means OSRM/Google routing failed - routes will be straight lines!');

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 8,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _controller != null) {
                _fitBounds();
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

    setState(() {
      final updated = Set<Marker>.from(_markers);

      updated
          .removeWhere((marker) => marker.markerId.value.startsWith('driver_'));

      for (final driverLocation in driverLocations) {
        final driverId = driverLocation['driverId'] as String;
        final latitude = driverLocation['latitude'] as double;
        final longitude = driverLocation['longitude'] as double;
        final timestamp = driverLocation['timestamp'];

        if (timestamp != null) {
          final locationTime = timestamp.toDate();
          final now = DateTime.now();
          final diffMinutes = now.difference(locationTime).inMinutes;
          if (diffMinutes > 5) continue;
        }

        updated.add(
          Marker(
            markerId: MarkerId('driver_$driverId'),
            position: LatLng(latitude, longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: '🚛 Водитель',
              snippet: 'ID: ${driverId.substring(0, 8)}...',
            ),
          ),
        );
      }

      _markers = updated;
    });

    debugPrint(
        '📍 [Driver Tracking] Updated ${driverLocations.length} driver locations');
  }

  String _buildMarkerSnippet(DeliveryPoint point, AppLocalizations? l10n) {
    final buffer = StringBuffer();

    buffer.write(
        '${point.pallets} ${l10n?.pallets ?? ''} • ${l10n?.order ?? 'Order'}: ${(point.orderInRoute ?? 0) + 1}');

    final displayAddress =
        (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty)
            ? point.temporaryAddress!
            : point.address;

    buffer.write('\n📍 $displayAddress');

    return buffer.toString();
  }
}
