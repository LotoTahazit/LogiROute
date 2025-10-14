import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/location_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../widgets/delivery_map_widget.dart';
import '../../widgets/navigation_widget.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();
  DeliveryPoint? _currentPoint;
  bool _isAutoCompleting = false;
  bool _showNavigation = false;
  double? _currentLat;
  double? _currentLng;

  String _getStatusText(String status, AppLocalizations l10n) {
    if (status == l10n.statusAssigned) {
      return l10n.assigned;
    } else if (status == l10n.statusInProgress) {
      return l10n.inProgress;
    } else if (status == l10n.statusCompleted) {
      return l10n.completed;
    } else if (status == l10n.statusCancelled) {
      return l10n.cancelled;
    } else if (status == l10n.statusPending) {
      return l10n.pending;
    } else {
      return status;
    }
  }

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _locationService.startTracking(authService.currentUser!.uid, _onLocationUpdate);
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  void _onLocationUpdate(double lat, double lon) {
    setState(() {
      _currentLat = lat;
      _currentLng = lon;
    });
    
    final l10n = AppLocalizations.of(context)!;

    if (_currentPoint != null && !_isAutoCompleting) {
      _isAutoCompleting = true;

      _locationService.checkPointCompletion(
        _currentPoint!,
        lat,
        lon,
        (point) async {
          await _routeService.updatePointStatus(point.id, l10n.statusCompleted);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.pointCompleted)),
            );
          }

          _isAutoCompleting = false;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.driver),
          actions: [
            IconButton(
              icon: Icon(_showNavigation ? Icons.map : Icons.navigation),
              onPressed: () {
                setState(() {
                  _showNavigation = !_showNavigation;
                });
              },
              tooltip: _showNavigation ? l10n.showMap : l10n.navigation,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
            ),
          ],
        ),
        body: StreamBuilder<List<DeliveryPoint>>(
          stream: _routeService.getDriverPoints(authService.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.error}: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final points = snapshot.data ?? [];
            if (points.isEmpty) {
              return Center(
                child: Text(
                  l10n.noActivePoints,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }

            _currentPoint = points.firstWhere(
              (p) =>
                  p.status != l10n.statusCompleted &&
                  p.status != l10n.statusCancelled,
              orElse: () => points.first,
            );

            return Column(
              children: [
                Expanded(
                  flex: 2,
                  child: _showNavigation 
                    ? NavigationWidget(
                        route: points,
                        currentLat: _currentLat,
                        currentLng: _currentLng,
                      )
                    : DeliveryMapWidget(points: points),
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: points.length,
                    itemBuilder: (context, index) {
                      final point = points[index];
                      final isActive = _currentPoint != null &&
                          point.id == _currentPoint!.id;

                      return Card(
                        color: isActive ? Colors.green.shade50 : null,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isActive ? Colors.green : Colors.grey,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            point.clientName,
                            style: const TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            point.address,
                            style: const TextStyle(color: Colors.black),
                          ),
                          trailing: _buildTrailingWidget(
                              context, point, isActive, l10n, points),
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
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    DeliveryPoint point,
    bool isActive,
    AppLocalizations l10n,
    List<DeliveryPoint> allPoints,
  ) {
    if (point.status == l10n.statusCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 32);
    }

    if (point.status == l10n.statusAssigned && isActive) {
      return ElevatedButton(
        onPressed: () async {
          await _routeService.updatePointStatus(
              point.id, l10n.statusCompleted);

          // Переход к следующей точке
          final nextPoint = allPoints.firstWhere(
            (p) => p.status != l10n.statusCompleted && p.id != point.id,
            orElse: () => allPoints.last,
          );

          await _routeService.updateCurrentPoint(nextPoint.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.pointCompleted}! ${l10n.next}: ${nextPoint.clientName}',
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(l10n.pointDone),
      );
    }

    return Text(
      _getStatusText(point.status, l10n),
      style: TextStyle(
        color: point.status == l10n.statusCompleted
            ? Colors.green
            : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
