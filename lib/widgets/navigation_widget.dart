// lib/widgets/navigation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../services/navigation_service.dart';
import '../services/navigation_launcher_service.dart';
import '../services/full_route_launcher.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';

class NavigationWidget extends StatefulWidget {
  final List<DeliveryPoint> route;
  final double? currentLat;
  final double? currentLng;
  final Function(int)? onStepCompleted;
  
  const NavigationWidget({
    super.key,
    required this.route,
    this.currentLat,
    this.currentLng,
    this.onStepCompleted,
  });

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  final NavigationService _navigationService = NavigationService();
  NavigationRoute? _navigationRoute;
  bool _isLoading = false;
  String? _error;
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadNavigationRoute();
  }

  @override
  void didUpdateWidget(NavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Перезагружаем маршрут если изменился список точек
    if (oldWidget.route.length != widget.route.length ||
        oldWidget.currentLat != widget.currentLat ||
        oldWidget.currentLng != widget.currentLng) {
      _loadNavigationRoute();
    }
  }

  Future<void> _loadNavigationRoute() async {
    print('🧭 [Navigation] Loading FULL route with ${widget.route.length} points');
    for (var point in widget.route) {
      print('  - ${point.clientName}: (${point.latitude}, ${point.longitude}) status=${point.status}');
    }
    
    if (widget.route.isEmpty) {
      print('❌ [Navigation] No points in route');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Сразу отображаем ВСЕ точки на карте
      _updateMap();
      
      NavigationRoute? route;
      
      // Строим маршрут через ВСЕ точки водителя
      if (widget.route.length == 1) {
        // Только одна точка - простой маршрут
        final point = widget.route.first;
      if (widget.currentLat != null && widget.currentLng != null) {
          route = await _navigationService.getNavigationRoute(
            startLat: widget.currentLat!,
            startLng: widget.currentLng!,
            endLat: point.latitude,
            endLng: point.longitude,
          );
          print('🧭 [Navigation] Single point route built');
        }
        } else {
        // Несколько точек - строим маршрут через ВСЕ точки
        final startLat = widget.currentLat ?? widget.route.first.latitude;
        final startLng = widget.currentLng ?? widget.route.first.longitude;
          final lastPoint = widget.route.last;
        
        // Waypoints = все точки кроме последней
        final waypoints = (widget.currentLat != null && widget.currentLng != null)
            ? widget.route.toList()  // Все точки как waypoints если есть текущая позиция
            : widget.route.skip(1).take(widget.route.length - 2).toList();  // Средние точки
        
        print('🧭 [Navigation] Building route: start→${waypoints.length} waypoints→end');
          
          route = await _navigationService.getMultiPointRoute(
          startLat: startLat,
          startLng: startLng,
            waypoints: waypoints,
            endLat: lastPoint.latitude,
            endLng: lastPoint.longitude,
          );
        
        if (route != null) {
          print('✅ [Navigation] Full route built: ${route.distance}, ${route.duration}');
        }
      }

      if (mounted) {
        setState(() {
          _navigationRoute = route;
          _isLoading = false;
        });
        _updateMap(); // Обновляем карту после загрузки маршрута
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    _updateMap();
  }

  void _updateMap() {
    if (_mapController == null || _navigationRoute == null) return;

    _markers.clear();
    _polylines.clear();

    // Добавляем маркеры для всех точек маршрута
    for (int i = 0; i < widget.route.length; i++) {
      final point = widget.route[i];
      _markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('point_$i'),
          position: gmaps.LatLng(point.latitude, point.longitude),
          infoWindow: gmaps.InfoWindow(title: point.clientName),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Добавляем маркер для текущего местоположения водителя
    if (widget.currentLat != null && widget.currentLng != null) {
      _markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('driver_location'),
          position: gmaps.LatLng(widget.currentLat!, widget.currentLng!),
          infoWindow: const gmaps.InfoWindow(title: 'Ваше местоположение'),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Создаем полилинию из точек маршрута
    if (widget.route.isNotEmpty) {
      final routePoints = <gmaps.LatLng>[];
      
      // Добавляем текущее местоположение водителя как начальную точку
      if (widget.currentLat != null && widget.currentLng != null) {
        routePoints.add(gmaps.LatLng(widget.currentLat!, widget.currentLng!));
      }
      
      // Добавляем все точки маршрута
      for (final point in widget.route) {
        routePoints.add(gmaps.LatLng(point.latitude, point.longitude));
      }
      
      // Добавляем промежуточную точку если только 2 точки (для лучшей видимости)
      if (routePoints.length == 2) {
        final a = routePoints.first;
        final b = routePoints.last;
        final mid = gmaps.LatLng(
          (a.latitude + b.latitude) / 2,
          (a.longitude + b.longitude) / 2,
        );
        routePoints.insert(1, mid);
        debugPrint('🧩 [Navigation] Inserted midpoint for better visibility');
      }
      
      debugPrint('🧭 [Navigation] Drawing route with ${routePoints.length} points');
      
      if (routePoints.length > 1) {
        _polylines = {
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId('activeRoute'),
            color: Colors.blue,
            width: 6,
            startCap: gmaps.Cap.roundCap,
            endCap: gmaps.Cap.roundCap,
            geodesic: true,
            visible: true,
            points: routePoints,
          ),
        };
        
        // Автоматический фокус камеры на весь маршрут
        if (_mapController != null && routePoints.isNotEmpty) {
          final bounds = _createBoundsFromPoints(routePoints);
          _mapController!.animateCamera(
            gmaps.CameraUpdate.newLatLngBounds(bounds, 80),
          );
          
          // Дополнительный фокус на центр маршрута
          final centerIndex = (routePoints.length / 2).floor();
          final center = routePoints[centerIndex];
          _mapController!.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(center, 11.0),
          );
          debugPrint('🎯 [Navigation] Focused camera on route center: ${center.latitude}, ${center.longitude}');
        }
      }
    } else {
      debugPrint('⚠️ [Navigation] No polyline to draw');
    }


    setState(() {});
  }

  List<gmaps.LatLng> _decodePolyline(String encoded) {
    final List<gmaps.LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(gmaps.LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  gmaps.LatLngBounds _boundsFromLatLngList(List<gmaps.LatLng> list) {
    double x0 = double.infinity;
    double y0 = double.infinity;
    double x1 = -double.infinity;
    double y1 = -double.infinity;
    
    for (gmaps.LatLng latLng in list) {
      if (latLng.latitude == null || latLng.longitude == null) continue;
      
      final lat = latLng.latitude!.toDouble();
      final lng = latLng.longitude!.toDouble();
      
      if (lat < x0) x0 = lat;
      if (lat > x1) x1 = lat;
      if (lng < y0) y0 = lng;
      if (lng > y1) y1 = lng;
    }
    
    return gmaps.LatLngBounds(
      northeast: gmaps.LatLng(x1, y1),
      southwest: gmaps.LatLng(x0, y0),
    );
  }

  gmaps.LatLngBounds _createBoundsFromPoints(List<gmaps.LatLng> points) {
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

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
  }

  /// Открывает полный маршрут во внешней навигации или OSRM
  Future<void> _openFullRouteInMaps() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final launcher = FullRouteLauncher();
      
      await launcher.openFullRoute(widget.route);
      
      if (mounted) {
        // Если маршрут короткий (≤3 точки), показываем уведомление об открытии Maps
        if (widget.route.length <= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.openInMaps),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Для длинных маршрутов (OSRM) показываем что маршрут построен
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Маршрут построен с ${widget.route.length} точками'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия навигации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Открывает навигацию к конкретной точке
  Future<void> _openNavigationToPoint(DeliveryPoint point) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      
      await NavigationLauncherService.openExternalNavigation(
        latitude: point.latitude,
        longitude: point.longitude,
        destinationName: point.clientName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.navigate} к ${point.clientName}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка навигации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.loadingNavigation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.navigationError,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNavigationRoute,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_navigationRoute == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.route,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNavigationRoute,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с информацией о маршруте
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.navigation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_navigationRoute!.distance} • ${_navigationRoute!.duration}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                Text(
                      '${widget.route.length} נקודות',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: l10n.openInMaps,
                      onPressed: () => _openFullRouteInMaps(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Карта навигации
          Expanded(
            child: gmaps.GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(
                  widget.currentLat ?? widget.route.first.latitude,
                  widget.currentLng ?? widget.route.first.longitude,
                ),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
          
          // Список точек маршрута с кнопками навигации
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Заголовок списка
                    Container(
                  padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Точки маршрута',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Список точек
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.route.length,
                    itemBuilder: (context, index) {
                      final point = widget.route[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            point.clientName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                              fontSize: 12,
                        color: Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 24,
                            ),
                            tooltip: l10n.navigate,
                            onPressed: () => _openNavigationToPoint(point),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
