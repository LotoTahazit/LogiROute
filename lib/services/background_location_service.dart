// lib/services/background_location_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/correlation/correlation_context.dart';
import '../models/company_remote_config.dart';
import '../models/delivery_point.dart';
import '../models/shift_schedule_config.dart';
import 'company_remote_config_service.dart';
import 'driver_auto_close_logic.dart';
import 'driver_auto_close_prefs.dart';
import 'driver_auto_close_state.dart';
import 'driver_session_service.dart';
import 'firestore_paths.dart';

/// Фоновый foreground-сервис: GPS трекинг + автозакрытие точек.
/// Работает даже когда приложение свёрнуто или экран выключен.
/// ✅ Автозапуск после перезагрузки телефона (данные в SharedPreferences).
class BackgroundLocationService {
  static const String notificationChannelId = 'location_tracking_channel';
  static const String notificationChannelName = 'Location Tracking';
  static const int notificationId = 888;

  // SharedPreferences keys
  static const String _prefDriverId = 'bg_driver_id';
  static const String _prefDriverName = 'bg_driver_name';
  static const String _prefCompanyId = 'bg_company_id';
  static const String _prefTrackingActive = 'bg_tracking_active';

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'GPS tracking',
      importance: Importance.low,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true, // ✅ Автостарт foreground-service
        autoStartOnBoot: true, // ✅ Стартуем после перезагрузки телефона
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'LogiRoute',
        initialNotificationContent: 'GPS активен',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Сохраняет данные водителя в SharedPreferences для автозапуска
  static Future<void> _saveDriverData(
      String driverId, String driverName, String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDriverId, driverId);
    await prefs.setString(_prefDriverName, driverName);
    await prefs.setString(_prefCompanyId, companyId);
    await prefs.setBool(_prefTrackingActive, true);
  }

  /// Очищает данные при остановке трекинга
  static Future<void> _clearDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTrackingActive, false);
  }

  static Future<void> start(
      String driverId, String driverName, String companyId) async {
    // Сохраняем данные для автозапуска после перезагрузки
    await _saveDriverData(driverId, driverName, companyId);

    final service = FlutterBackgroundService();
    await service.startService();
    await Future.delayed(const Duration(milliseconds: 500));
    service.invoke('setDriverData', {
      'driverId': driverId,
      'driverName': driverName,
      'companyId': companyId,
    });
    debugPrint('✅ [BGService] Started for $driverName');
  }

  static Future<void> stop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString(_prefDriverId);
      final driverName = prefs.getString(_prefDriverName);
      final companyId = prefs.getString(_prefCompanyId);
      if (driverId != null && companyId != null) {
        await FirestorePaths.driverLocationsOf(companyId).doc(driverId).set({
          'driverId': driverId,
          if (driverName != null) 'driverName': driverName,
          'role': 'driver',
          'isOnShift': false,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('⚠️ [BGService] Failed to mark off-shift on stop: $e');
    }
    await _clearDriverData();
    FlutterBackgroundService().invoke('stopService');
    debugPrint('🛑 [BGService] Stopped');
  }

  static Future<bool> isRunning() async =>
      FlutterBackgroundService().isRunning();

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    DartPluginRegistrant.ensureInitialized();

    // ✅ Инициализация Firebase в фоновом isolate (критично после перезагрузки телефона)
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Уже инициализирован (нормальный запуск из приложения)
    }

    String? driverId;
    String? driverName;
    String? companyId;

    // ✅ Загружаем расписание смен из SharedPreferences (кешируется приложением)
    ShiftScheduleConfig shiftConfig = ShiftScheduleConfig.defaults;
    int? lastCheckedDay; // Перечитываем конфиг только при смене дня

    // ✅ Пробуем загрузить данные из SharedPreferences (после перезагрузки)
    bool restoredFromPrefs = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDriverId = prefs.getString(_prefDriverId);
      final savedDriverName = prefs.getString(_prefDriverName);
      final savedCompanyId = prefs.getString(_prefCompanyId);
      final wasActive = prefs.getBool(_prefTrackingActive) ?? false;

      shiftConfig = await ShiftScheduleConfig.loadFromPrefs();
      lastCheckedDay = DateTime.now().day;
      debugPrint('🕐 [BGService] Shift config: days=${shiftConfig.workingDays} '
          'start=${shiftConfig.startHour} end=${shiftConfig.endHour}');

      // Есть сохранённые данные водителя — проверяем расписание
      if (savedDriverId != null &&
          savedDriverName != null &&
          savedCompanyId != null) {
        final now = DateTime.now();
        final isWorkTime = shiftConfig.isWithin(now);

        if (wasActive || isWorkTime) {
          driverId = savedDriverId;
          driverName = savedDriverName;
          companyId = savedCompanyId;
          restoredFromPrefs = true;
          await prefs.setBool(_prefTrackingActive, true);
          debugPrint(
              '📍 [BGService] Restored: $driverName (wasActive=$wasActive, isWorkTime=$isWorkTime)');
        } else {
          // Не рабочее время — ждём начала смены
          driverId = savedDriverId;
          driverName = savedDriverName;
          companyId = savedCompanyId;
          restoredFromPrefs = true;
          debugPrint(
              '📍 [BGService] Outside work hours, waiting for shift start');
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'LogiRoute',
              content: 'Ожидание начала смены (${shiftConfig.startHour}:00)',
            );
          }
        }
      } else {
        // Нет данных водителя вообще (не водитель) — выходим сразу
        debugPrint('🛑 [BGService] No driver data in prefs, stopping');
        service.stopSelf();
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [BGService] Error reading prefs: $e');
    }

    final Map<String, DateTime> arrivalTimes = {};
    final restoredPending = await DriverAutoCloseState.loadPending();
    if (restoredPending != null) {
      arrivalTimes[restoredPending.pointId] = restoredPending.startedAt;
      debugPrint(
          '📍 [BGService] Restored auto-close timer for ${restoredPending.pointId}');
    }

    /// Последняя записанная ячейка (~11 м) — для history и детекции движения.
    String? lastGeoBucket;

    /// Чтобы при стоянке в той же ячейке всё же обновлять `timestamp` в Firestore.
    DateTime? lastFirestoreWrite;
    bool? lastReportedOnShift;

    Future<void> syncOnShiftFlag(bool isOnShift) async {
      if (driverId == null || companyId == null) return;
      if (lastReportedOnShift == isOnShift) return;
      await FirestorePaths.driverLocationsOf(companyId!).doc(driverId).set({
        'driverId': driverId,
        'driverName': driverName,
        'role': 'driver',
        'isOnShift': isOnShift,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      lastReportedOnShift = isOnShift;
    }

    final driverDataSub = service.on('setDriverData').listen((event) {
      driverId = event?['driverId'] as String?;
      driverName = event?['driverName'] as String?;
      companyId = event?['companyId'] as String?;
      debugPrint('📍 [BGService] Driver data set: $driverName / $companyId');
    });

    late final StreamSubscription<Map<String, dynamic>?> stopSub;
    stopSub = service.on('stopService').listen((_) {
      driverDataSub.cancel();
      stopSub.cancel();
      service.stopSelf();
    });

    // Нет данных и не восстановлено из prefs → не водитель, выходим сразу
    if (!restoredFromPrefs) {
      // Ждём 5 сек на setDriverData (нормальный запуск через start())
      Future.delayed(const Duration(seconds: 5), () {
        if (driverId == null || driverName == null || companyId == null) {
          debugPrint('🛑 [BGService] No driver data, stopping immediately');
          service.stopSelf();
        }
      });
    }

    // Основной цикл — каждые 30 секунд
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (driverId == null || driverName == null || companyId == null) return;

      final now = DateTime.now();

      // Перечитываем конфиг из SharedPreferences при смене дня (1 раз в сутки)
      if (lastCheckedDay != now.day) {
        lastCheckedDay = now.day;
        try {
          shiftConfig = await ShiftScheduleConfig.loadFromPrefs();
          debugPrint(
              '🕐 [BGService] Shift config reloaded: days=${shiftConfig.workingDays} '
              'start=${shiftConfig.startHour} end=${shiftConfig.endHour}');
        } catch (e) {
          debugPrint('⚠️ [BGService] Error reloading shift config: $e');
        }
      }

      final isWorkTime = shiftConfig.isWithin(now);

      if (!isWorkTime) {
        // ВАЖНО: не убиваем сервис после смены, иначе утром некому будет
        // автоматически возобновить GPS и автозакрытие точек.
        try {
          await syncOnShiftFlag(false);
        } catch (e) {
          debugPrint('⚠️ [BGService] Failed to mark off-shift: $e');
        }
        debugPrint('⏸️ [BGService] Outside work hours, idle');
        if (service is AndroidServiceInstance) {
          final isDayOff = !shiftConfig.workingDays.contains(now.weekday);
          final waitText = isDayOff
              ? 'Нерабочий день, ожидание смены'
              : (now.hour >= shiftConfig.endHour
                  ? 'Смена завершена, ожидание ${shiftConfig.startHour}:00'
                  : 'Ожидание начала смены (${shiftConfig.startHour}:00)');
          service.setForegroundNotificationInfo(
            title: 'LogiRoute',
            content: waitText,
          );
        }
        return;
      }

      try {
        final ownsSession = await DriverSessionService.verifyOwnership(
          companyId: companyId!,
          driverId: driverId!,
        );
        if (!ownsSession) {
          await DriverSessionService.markSessionLostFlag();
          debugPrint('🛑 [BGService] Session lost — stopping GPS');
          await _clearDriverData();
          service.stopSelf();
          return;
        }

        // Сначала пробуем getCurrentPosition с коротким timeout
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 8));
        } catch (_) {
          // Fallback: последняя известная позиция (не зависает)
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            debugPrint('📍 [BGService] Using last known position (fallback)');
          }
        }

        if (position == null) {
          debugPrint('⚠️ [BGService] No position available, skipping');
          return;
        }

        await DriverAutoCloseState.saveLastLocation(
          position.latitude,
          position.longitude,
        );

        final now = DateTime.now();

        final geoBucket =
            _buildGeoBucket(position.latitude, position.longitude);
        // Смена ячейки — явное движение. Иначе «пульс» раз в 60 с: тот же geoBucket,
        // но свежий timestamp (диспетчер не видит вечно устаревший GPS на стоянке).
        final hasMovedBucket =
            lastGeoBucket != null && geoBucket != lastGeoBucket;
        final needHeartbeat = lastFirestoreWrite == null ||
            now.difference(lastFirestoreWrite!).inSeconds >= 60;
        final shouldWriteMainDoc = hasMovedBucket || needHeartbeat;

        await syncOnShiftFlag(true);

        if (shouldWriteMainDoc) {
          await FirestorePaths.driverLocationsOf(companyId!).doc(driverId).set({
            'driverId': driverId,
            'driverName': driverName,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'accuracy': position.accuracy,
            'speed': position.speed,
            'role': 'driver',
            'geoBucket': geoBucket,
          }, SetOptions(merge: true));
          lastGeoBucket = geoBucket;
          lastFirestoreWrite = now;
        }

        // 1b. В history — только при смене ячейки (без спама каждые 60 с)
        try {
          if (hasMovedBucket) {
            await FirestorePaths.driverLocationsOf(companyId!)
                .doc(driverId)
                .collection('history')
                .add({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
              'accuracy': position.accuracy,
            });
          }
        } catch (e) {
          debugPrint('⚠️ [BGService] Error saving location to Firestore: $e');
        }

        // 2. Проверяем все незавершённые точки водителя
        final pointsSnap = await FirestorePaths.deliveryPointsOf(companyId!)
            .where('driverId', isEqualTo: driverId)
            .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
            .get();

        final disabledAuto = await DriverAutoClosePrefs.loadDisabled();
        // Политика компании «POD-фото обязательно» — автозакрытие отключено.
        final photoRequired = await DriverAutoClosePrefs.isPhotoRequired();
        final rc = companyId != null && companyId!.isNotEmpty
            ? await CompanyRemoteConfigService.fromPrefs(companyId!)
            : CompanyRemoteConfig.defaults;
        final autoCloseEnabled = rc.backgroundAutoCloseEnabled &&
            await DriverAutoClosePrefs.isAutoCloseEnabled();

        if (photoRequired || !autoCloseEnabled) {
          if (arrivalTimes.isNotEmpty) {
            arrivalTimes.clear();
            await DriverAutoCloseState.clearPending();
          }
        } else {
          final points = pointsSnap.docs
              .map((doc) =>
                  DeliveryPoint.fromMap(doc.data(), doc.id))
              .toList();

          final target = selectNearestDriverAutoCloseTarget(
            driverLat: position.latitude,
            driverLng: position.longitude,
            points: points,
            driverId: driverId!,
            disabledPointIds: disabledAuto,
            enterRadiusM: rc.autoCloseRadiusMeters,
          );

          if (target == null ||
              shouldResetDriverAutoCloseTimer(
                distanceMeters: target.distanceMeters,
                resetRadiusM: rc.autoCloseResetRadiusMeters,
              )) {
            if (arrivalTimes.isNotEmpty) {
              arrivalTimes.clear();
              await DriverAutoCloseState.clearPending();
            }
          } else {
            final point = target.point;
            final pointId = point.id;
            arrivalTimes.removeWhere((id, _) => id != pointId);

            if (!arrivalTimes.containsKey(pointId)) {
              arrivalTimes[pointId] = now;
              await DriverAutoCloseState.savePending(
                pointId: pointId,
                startedAt: now,
              );
              await DriverAutoCloseState.markInProgressIfNeeded(
                companyId: companyId!,
                pointId: pointId,
                driverId: driverId!,
                currentStatus: point.status,
              );
              debugPrint(
                '🔎 [BGService][AutoClose] ${jsonEncode({
                  'phase': 'timer_started',
                  'driverId': driverId,
                  'selectedPointId': pointId,
                  'selectedPointName': point.clientName,
                  'distanceMeters': target.distanceMeters.round(),
                  'radiusMeters': rc.autoCloseRadiusMeters.round(),
                  'waitSeconds': rc.autoCloseWaitSeconds,
                })}',
              );
              debugPrint(
                  '📍 [BGService] Стоит у ${point.clientName}, таймер запущен');
            } else if (driverAutoCloseWaitComplete(arrivalTimes[pointId]!, now,
                waitDuration: rc.autoCloseWait)) {
              final correlationId = CorrelationContext.resolveId();
              final closed = await DriverAutoCloseState.tryCompletePoint(
                companyId: companyId!,
                pointId: pointId,
                driverId: driverId!,
                lat: position.latitude,
                lng: position.longitude,
                distanceMeters: target.distanceMeters,
                correlationId: correlationId,
              );
              arrivalTimes.remove(pointId);
              if (closed) {
                debugPrint(
                  '🔎 [BGService][AutoClose] ${jsonEncode({
                    'phase': 'closed',
                    'driverId': driverId,
                    'selectedPointId': pointId,
                    'selectedPointName': point.clientName,
                    'distanceMeters': target.distanceMeters.round(),
                    'correlationId': correlationId,
                  })}',
                );
                debugPrint('✅ [BGService] Auto-completed: ${point.clientName}');
              }
            }
          }
        }

        // 3. Обновляем уведомление
        if (service is AndroidServiceInstance) {
          final h = now.hour.toString().padLeft(2, '0');
          final m = now.minute.toString().padLeft(2, '0');
          service.setForegroundNotificationInfo(
            title: 'LogiRoute — GPS активен',
            content: 'Обновлено: $h:$m',
          );
        }
      } catch (e) {
        debugPrint('❌ [BGService] Error: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String _buildGeoBucket(double lat, double lng) {
    final latBucket = (lat * 10000).floor() / 10000;
    final lngBucket = (lng * 10000).floor() / 10000;
    return '${latBucket}_$lngBucket';
  }
}
