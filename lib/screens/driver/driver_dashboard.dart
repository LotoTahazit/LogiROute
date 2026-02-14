import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/optimized_location_service.dart';
import '../../services/work_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/auto_complete_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../widgets/delivery_map_widget.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final RouteService _routeService = RouteService();
  final OptimizedLocationService _locationService = OptimizedLocationService();
  final WorkScheduleService _scheduleService = WorkScheduleService();
  final AutoCompleteService _autoCompleteService = AutoCompleteService();
  DeliveryPoint? _currentPoint;
  bool _isAutoCompleting = false;
  bool _isTrackingActive = false;
  String _scheduleStatus = '';

  /// Начать навигацию по всему маршруту
  Future<void> _startFullRouteNavigation(List<DeliveryPoint> points) async {
    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noActivePoints),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Строим URL для Google Maps с ВСЕМИ точками
    final origin = '${points.first.latitude},${points.first.longitude}';
    final destination = '${points.last.latitude},${points.last.longitude}';

    // Промежуточные точки (waypoints) - все точки кроме первой и последней
    String waypoints = '';
    if (points.length > 2) {
      waypoints =
          '&waypoints=${points.skip(1).take(points.length - 2).map((p) => '${p.latitude},${p.longitude}').join('|')}';
    }

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '$waypoints'
        '&travelmode=driving';

    debugPrint('🚀 [Driver] Opening full route navigation:');
    debugPrint('   📍 Origin: ${points.first.clientName}');
    if (points.length > 2) {
      debugPrint('   🔄 Waypoints: ${points.length - 2} points');
    }
    debugPrint('   🎯 Destination: ${points.last.clientName}');
    debugPrint('   🌐 URL: $url');

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ [Driver] Navigation opened successfully');
      } else {
        throw 'Could not launch navigation';
      }
    } catch (e) {
      debugPrint('❌ [Driver] Error opening navigation: $e');
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

  String _getStatusText(String status, AppLocalizations l10n) {
    final normalized = DeliveryPoint.normalizeStatus(status);
    if (normalized == DeliveryPoint.statusAssigned) {
      return l10n.assigned;
    } else if (normalized == DeliveryPoint.statusInProgress) {
      return l10n.inProgress;
    } else if (normalized == DeliveryPoint.statusCompleted) {
      return l10n.completed;
    } else if (normalized == DeliveryPoint.statusCancelled) {
      return l10n.cancelled;
    } else if (normalized == DeliveryPoint.statusPending) {
      return l10n.pending;
    } else {
      return status;
    }
  }

  @override
  void initState() {
    super.initState();

    // Инициализируем уведомления и планируем ежедневное напоминание
    _initializeNotifications();

    // Запускаем мониторинг расписания
    _scheduleService.startScheduleMonitoring(
      onStartTracking: _startTracking,
      onStopTracking: _stopTracking,
    );

    // Обновляем статус расписания каждую минуту
    Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          final status = _scheduleService.getScheduleStatus();
          _scheduleStatus = status['statusMessage'];
        });
      }
    });
  }

  Future<void> _initializeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleDailyWorkReminder();
    debugPrint('✅ [Driver] Notifications initialized and scheduled');
  }

  void _startTracking() {
    final authService = context.read<AuthService>();
    _locationService.startTracking(
      authService.currentUser!.uid,
      _onLocationUpdate,
    );
    _autoCompleteService
        .startMonitoring(); // Запускаем автоматическое завершение на мобильном
    setState(() {
      _isTrackingActive = true;
    });
    debugPrint('✅ [Driver] GPS tracking started');
  }

  void _stopTracking() {
    _locationService.stopTracking();
    _autoCompleteService
        .stopMonitoring(); // Останавливаем автоматическое завершение
    setState(() {
      _isTrackingActive = false;
    });
    debugPrint('🛑 [Driver] GPS tracking stopped');
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _scheduleService.dispose();
    super.dispose();
  }

  void _onLocationUpdate(double lat, double lon) {
    final l10n = AppLocalizations.of(context)!;

    if (_currentPoint != null) {
      _locationService.checkPointCompletion(
        _currentPoint!,
        lat,
        lon,
        (point) async {
          if (!_isAutoCompleting) {
            _isAutoCompleting = true;

            await _routeService.updatePointStatus(
                point.id, DeliveryPoint.statusCompleted);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('✅ ${l10n.pointCompleted}: ${point.clientName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            _isAutoCompleting = false;
          }
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
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(l10n.driver),
          actions: [
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
                child: Row(
                  children: [
                    Icon(Icons.visibility,
                        color: Colors.orange.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.viewingAs} ${l10n.driver}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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
                            fontWeight: FontWeight.w600,
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
              child: StreamBuilder<List<DeliveryPoint>>(
                stream: _routeService.getDriverPoints(
                    authService.viewAsDriverId ?? authService.currentUser!.uid),
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
                  print(
                      '🚛 [Driver] Loaded ${points.length} points for driver');
                  for (var point in points) {
                    print('  - ${point.clientName}: status=${point.status}');
                  }

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
                        p.status != DeliveryPoint.statusCompleted &&
                        p.status != DeliveryPoint.statusCancelled,
                    orElse: () => points.first,
                  );

                  return Column(
                    children: [
                      // Большая кнопка "НАЧАТЬ НАВИГАЦИЮ"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () => _startFullRouteNavigation(points),
                          icon: const Icon(Icons.navigation, size: 32),
                          label: Text(
                            l10n.navigation.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Карта с маршрутом
                      Expanded(
                        flex: 2,
                        child: DeliveryMapWidget(points: points),
                      ),
                      // Список точек
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
          ],
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
    if (point.status == DeliveryPoint.statusCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 32);
    }

    if (point.status == DeliveryPoint.statusAssigned && isActive) {
      return ElevatedButton(
        onPressed: () async {
          await _routeService.updatePointStatus(
              point.id, DeliveryPoint.statusCompleted);

          // Переход к следующей точке
          final nextPoint = allPoints.firstWhere(
            (p) =>
                p.status != DeliveryPoint.statusCompleted && p.id != point.id,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(l10n.pointDone),
      );
    }

    return Text(
      _getStatusText(point.status, l10n),
      style: TextStyle(
        color: point.status == DeliveryPoint.statusCompleted
            ? Colors.green
            : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
