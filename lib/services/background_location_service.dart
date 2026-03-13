// lib/services/background_location_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_paths.dart';

/// Фоновый foreground-сервис: GPS трекинг + автозакрытие точек.
/// Работает даже когда приложение свёрнуто или экран выключен.
/// ✅ Автозапуск после перезагрузки телефона (данные в SharedPreferences).
class BackgroundLocationService {
  static const String notificationChannelId = 'location_tracking_channel';
  static const String notificationChannelName = 'Location Tracking';
  static const int notificationId = 888;

  static const double _autoCompleteRadius = 100.0; // метров
  static const int _autoCompleteMinutes = 2; // минут стоянки

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
        autoStart: false, // НЕ стартуем при обычном запуске приложения
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
    await _clearDriverData();
    FlutterBackgroundService().invoke('stopService');
    debugPrint('🛑 [BGService] Stopped');
  }

  static Future<bool> isRunning() async =>
      FlutterBackgroundService().isRunning();

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    String? driverId;
    String? driverName;
    String? companyId;

    // ✅ Пробуем загрузить данные из SharedPreferences (после перезагрузки)
    bool restoredFromPrefs = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDriverId = prefs.getString(_prefDriverId);
      final savedDriverName = prefs.getString(_prefDriverName);
      final savedCompanyId = prefs.getString(_prefCompanyId);
      final wasActive = prefs.getBool(_prefTrackingActive) ?? false;

      // Есть сохранённые данные водителя — проверяем расписание
      if (savedDriverId != null &&
          savedDriverName != null &&
          savedCompanyId != null) {
        final now = DateTime.now();
        final isWorkTime = _isWorkTime(now);

        if (wasActive || isWorkTime) {
          driverId = savedDriverId;
          driverName = savedDriverName;
          companyId = savedCompanyId;
          restoredFromPrefs = true;
          await prefs.setBool(_prefTrackingActive, true);
          debugPrint(
              '📍 [BGService] Restored: $driverName (wasActive=$wasActive, isWorkTime=$isWorkTime)');
        } else {
          // Не рабочее время, но данные водителя есть
          final isWeekend = now.weekday == 5 || now.weekday == 6;
          if (isWeekend) {
            // Выходной — не ждём, выходим
            debugPrint('📍 [BGService] Weekend, stopping');
            service.stopSelf();
            return;
          }
          // Будний день вне часов (до 7 или после 17) — ждём 7:00
          driverId = savedDriverId;
          driverName = savedDriverName;
          companyId = savedCompanyId;
          restoredFromPrefs = true;
          debugPrint('📍 [BGService] Outside work hours, waiting for 7:00');
          // Обновляем notification чтобы водитель не путался
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'LogiRoute',
              content: 'Ожидание начала рабочего дня (7:00)',
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
      final isWorkTime = _isWorkTime(now);

      if (!isWorkTime) {
        // Рабочий день кончился (после 17) — останавливаемся
        if (now.hour >= 17) {
          debugPrint('🛑 [BGService] Past 17:00, stopping');
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_prefTrackingActive, false);
          } catch (e) {
            debugPrint('⚠️ [BGService] Error updating tracking pref: $e');
          }
          service.stopSelf();
          timer.cancel();
          return;
        }
        // Утро до 7:00 или выходной — просто ждём
        return;
      }

      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) return;
      }

      try {
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

        final db = FirebaseFirestore.instance;
        final now = DateTime.now();

        // 1. Сохраняем координаты водителя
        await FirestorePaths.driverLocationsOf(companyId!).doc(driverId).set({
          'driverId': driverId,
          'driverName': driverName,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
          'speed': position.speed,
          'role': 'driver',
        }, SetOptions(merge: true));

        // 1b. Сохраняем в history для треков
        try {
          await FirestorePaths.driverLocationsOf(companyId!)
              .doc(driverId)
              .collection('history')
              .add({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'accuracy': position.accuracy,
          });
        } catch (e) {
          debugPrint('⚠️ [BGService] Error saving location to Firestore: $e');
        }

        // 2. Проверяем все незавершённые точки водителя
        final pointsSnap = await db
            .collection('companies')
            .doc(companyId)
            .collection('logistics')
            .doc('_root')
            .collection('delivery_points')
            .where('driverId', isEqualTo: driverId)
            .where('status', whereIn: ['assigned', 'in_progress']).get();

        for (final doc in pointsSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          final pointId = doc.id;
          final pointLat = (data['latitude'] as num).toDouble();
          final pointLng = (data['longitude'] as num).toDouble();
          final clientName = data['clientName'] as String? ?? '';

          final dist = _distance(
              position.latitude, position.longitude, pointLat, pointLng);

          if (dist <= _autoCompleteRadius) {
            final arrived = arrivalTimes[pointId] ?? now;
            if (!arrivalTimes.containsKey(pointId)) {
              arrivalTimes[pointId] = now;
              debugPrint(
                  '📍 [BGService] Arrived at $clientName, timer started');
            } else if (now.difference(arrived).inMinutes >=
                _autoCompleteMinutes) {
              await doc.reference.update({
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
                'autoCompleted': true,
                'updatedByUid': driverId,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              arrivalTimes.remove(pointId);
              debugPrint('✅ [BGService] Auto-completed: $clientName');
            }
          } else {
            if (arrivalTimes.containsKey(pointId)) {
              arrivalTimes.remove(pointId);
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

  /// Проверяет рабочее время (Вс-Чт 7:00-17:00, Израиль)
  static bool _isWorkTime(DateTime time) {
    // Пятница (5) и Суббота (6) — выходные
    if (time.weekday == 5 || time.weekday == 6) return false;
    return time.hour >= 7 && time.hour < 17;
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
}
