import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/optimized_location_service.dart';
import '../../services/background_location_service.dart';
import '../../services/realtime_gps_service.dart';
import '../../services/work_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/delivery_map_widget.dart';
import '../../services/company_cache.dart';

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
  bool _isAutoCompleting = false;
  bool _isTrackingActive = false;
  String _scheduleStatus = '';
  Timer? _scheduleStatusTimer;

  @override
  void initState() {
    super.initState();

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
  }

  Future<void> _initializeAndStartSchedule() async {
    await _initializeNotifications();

    // Запускаем мониторинг расписания ПОСЛЕ инициализации BGService
    _scheduleService.startScheduleMonitoring(
      onStartTracking: _startTracking,
      onStopTracking: _stopTracking,
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

  void _startTracking() {
    final authService = context.read<AuthService>();
    final driverName = authService.userModel?.name ??
        (AppLocalizations.of(context)?.driverFallbackName ?? 'Driver');
    final userRole = authService.userModel?.role ?? 'driver';
    final companyId = authService.userModel?.companyId ?? '';
    final driverId = authService.currentUser!.uid;

    // Foreground GPS (пока приложение открыто)
    _locationService?.startTracking(
      driverId,
      driverName,
      _onLocationUpdate,
      userRole: userRole,
    );

    // Background foreground-service (когда приложение свёрнуто, только мобильные)
    if (!kIsWeb) {
      BackgroundLocationService.start(driverId, driverName, companyId);
    }

    // WebSocket GPS для live-карты диспетчера
    _realtimeGps.connectAsDriver();

    setState(() => _isTrackingActive = true);
    debugPrint('✅ [Driver] Tracking started: $driverName');
  }

  void _stopTracking() {
    _locationService?.stopTracking();
    if (!kIsWeb) BackgroundLocationService.stop();
    _realtimeGps.dispose();
    setState(() => _isTrackingActive = false);
    debugPrint('🛑 [Driver] Tracking stopped');
  }

  @override
  void dispose() {
    _scheduleStatusTimer?.cancel();
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
  DateTime _lastPointCheckTime = DateTime(2000); // debounce проверки точек

  void _onLocationUpdate(double lat, double lon) {
    if (_routeService == null) return;
    final l10n = AppLocalizations.of(context)!;

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

    // Проверяем точки не чаще раза в 60 секунд (debounce)
    if (_isAutoCompleting) return;
    final checkElapsed = now.difference(_lastPointCheckTime).inSeconds;
    if (checkElapsed < 60) return;
    _lastPointCheckTime = now;

    final activePoints = _lastPoints
        .where((p) =>
            p.status != DeliveryPoint.statusCompleted &&
            p.status != DeliveryPoint.statusCancelled)
        .toList();

    for (final point in activePoints) {
      _locationService?.checkPointCompletion(
        point,
        lat,
        lon,
        (completedPoint) async {
          if (_isAutoCompleting) return;
          _isAutoCompleting = true;

          final authService = context.read<AuthService>();
          final currentUid = authService.currentUser?.uid ?? '';
          await _routeService!.updatePointStatus(
            completedPoint.id,
            DeliveryPoint.statusCompleted,
            updatedByUid: currentUid,
            autoCompleted: true,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ ${l10n.pointCompleted}: ${completedPoint.clientName}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
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

    // Инициализируем сервисы с companyId водителя
    final companyId = authService.userModel?.companyId ?? '';
    if (_routeService == null && companyId.isNotEmpty) {
      _routeService = RouteService(companyId: companyId);
      _locationService = OptimizedLocationService(companyId);
      // ⚡ Предзагрузка кеша компании для водителя
      CompanyCache.instance(companyId).preload(companyId, authService);
      debugPrint('🚛 [Driver] Services initialized with companyId: $companyId');
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
            NotificationBell(companyId: companyId),
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
                            color: Colors.orange.shade900, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${l10n.viewingAs} ${l10n.driver}',
                            style: TextStyle(
                              color: Colors.orange.shade900,
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
                            fontWeight: FontWeight.w700,
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
              child: _routeService == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<DeliveryPoint>>(
                      stream: _routeService!.getTodayRoutes(
                          driverId: authService.viewAsDriverId ??
                              authService.currentUser!.uid),
                      initialData: const [],
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                        _lastPoints = points;

                        if (points.isNotEmpty) {
                          _currentPoint = points.firstWhere(
                            (p) =>
                                p.status != DeliveryPoint.statusCompleted &&
                                p.status != DeliveryPoint.statusCancelled,
                            orElse: () => points.first,
                          );
                        }

                        return Column(
                          children: [
                            // 📱 Android fallback: карта или альтернативный UI
                            Expanded(
                              child: (!kIsWeb && Platform.isAndroid)
                                  ? _buildAndroidMapFallback(points, l10n)
                                  : DeliveryMapWidget(
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
                            // Большая кнопка навигации убрана - никто не пользуется Google Maps
                            // Компактный список точек — максимум 25% экрана
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: points.isEmpty
                                  ? Center(
                                      child: Text(
                                        l10n.noActivePoints,
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 8,
                                          top: 2,
                                          bottom: 80),
                                      itemCount: points.length,
                                      itemBuilder: (context, index) {
                                        final point = points[index];
                                        final isCompleted = point.status ==
                                                DeliveryPoint.statusCompleted ||
                                            point.status ==
                                                DeliveryPoint.statusCancelled;
                                        final isActive = !isCompleted &&
                                            _currentPoint != null &&
                                            point.id == _currentPoint!.id;

                                        return Opacity(
                                          opacity: isCompleted ? 0.55 : 1.0,
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
                                              child: Row(
                                                children: [
                                                  // Номер
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          isCompleted
                                                              ? Colors
                                                                  .grey.shade400
                                                              : (isActive
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .blueGrey
                                                                      .shade400),
                                                      child: isCompleted
                                                          ? const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 14)
                                                          : Text(
                                                              '${index + 1}',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Имя + адрес
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          point.clientName,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isCompleted
                                                                ? Colors.grey
                                                                    .shade700
                                                                : Colors
                                                                    .black87,
                                                            decoration: isCompleted
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (point
                                                            .address.isNotEmpty)
                                                          Text(
                                                            point.address,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade800,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Статус / кнопка
                                                  _buildTrailingWidget(
                                                      context,
                                                      point,
                                                      isActive,
                                                      l10n,
                                                      points),
                                                ],
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

  Widget _buildTrailingWidget(
    BuildContext context,
    DeliveryPoint point,
    bool isActive,
    AppLocalizations l10n,
    List<DeliveryPoint> allPoints,
  ) {
    if (point.status == DeliveryPoint.statusCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }

    if (point.status == DeliveryPoint.statusCancelled) {
      return const Icon(Icons.cancel, color: Colors.grey, size: 22);
    }

    // Кнопки "Waze" и "Выполнено" для каждой незавершённой точки
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка Waze
        SizedBox(
          height: 32,
          width: 32,
          child: IconButton(
            onPressed: () async {
              final lat = point.latitude;
              final lng = point.longitude;
              final url =
                  Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
              // Открываем Waze
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка открытия Waze: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.navigation, color: Colors.blue, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Waze',
          ),
        ),
        const SizedBox(width: 4),
        // Кнопка "Выполнено"
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () async {
              if (_routeService == null) return;
              final authService = context.read<AuthService>();
              final messenger = ScaffoldMessenger.of(context);
              await _routeService!.updatePointStatus(
                point.id,
                DeliveryPoint.statusCompleted,
                updatedByUid: authService.currentUser?.uid,
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('✅ ${l10n.pointCompleted}: ${point.clientName}'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isActive ? Colors.green : Colors.blueGrey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: Text(l10n.pointDone),
          ),
        ),
      ],
    );
  }

  /// Android fallback UI when Google Maps is not available
  Widget _buildAndroidMapFallback(
      List<DeliveryPoint> points, AppLocalizations l10n) {
    final completedCount =
        points.where((p) => p.status == DeliveryPoint.statusCompleted).length;
    final totalCount = points.length;
    final remainingCount = totalCount - completedCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Заголовок
            Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Маршрут водителя',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (remainingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$remainingCount${_getPlural(remainingCount, ' точка', ' точки', ' точек')}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Статистика
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Всего', totalCount, Colors.blue),
                      _buildStatItem('Выполнено', completedCount, Colors.green),
                      _buildStatItem('Осталось', remainingCount, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Прогресс-бар
                  LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(totalCount > 0 ? (completedCount / totalCount * 100) : 0).toInt()}% выполнено',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Список следующих точек
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: points.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noActivePoints,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: points.length,
                        itemBuilder: (context, index) {
                          final point = points[index];
                          final isCompleted =
                              point.status == DeliveryPoint.statusCompleted;
                          final isNext = !isCompleted &&
                              index ==
                                  points.indexWhere((p) =>
                                      p.status !=
                                      DeliveryPoint.statusCompleted);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade50
                                  : (isNext
                                      ? Colors.blue.shade50
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.green.shade200
                                    : (isNext
                                        ? Colors.blue.shade200
                                        : Colors.grey.shade200),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isCompleted
                                    ? Colors.green
                                    : (isNext ? Colors.blue : Colors.grey),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                point.clientName,
                                style: TextStyle(
                                  fontWeight: isNext
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCompleted
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    point.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (point.eta != null)
                                    Text(
                                      'ETA: ${point.eta}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isCompleted
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20)
                                  : (isNext
                                      ? Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.navigation,
                                              color: Colors.white, size: 16),
                                        )
                                      : null),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getPlural(int count, String one, String few, String many) {
    if (count == 1) return one;
    if (count >= 2 && count <= 4) return few;
    return many;
  }
}
