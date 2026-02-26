// lib/services/background_location_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Фоновый сервис для отслеживания местоположения водителя
/// Работает даже когда приложение закрыто
class BackgroundLocationService {
  static const String notificationChannelId = 'location_tracking_channel';
  static const String notificationChannelName = 'Location Tracking';
  static const int notificationId = 888;

  /// Инициализация фонового сервиса
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Создаём канал уведомлений для Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'Отслеживание местоположения водителя',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Конфигурация сервиса
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Не запускаем автоматически
        isForegroundMode: true, // Foreground service с уведомлением
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'LogiRoute',
        initialNotificationContent: 'Отслеживание местоположения активно',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    debugPrint('✅ [BackgroundService] Initialized');
  }

  /// Запуск фонового сервиса
  static Future<void> start(String driverId, String driverName) async {
    final service = FlutterBackgroundService();

    // Сохраняем данные водителя для использования в фоновом сервисе
    await service.startService();

    // Передаём данные в фоновый сервис
    service.invoke('setDriverData', {
      'driverId': driverId,
      'driverName': driverName,
    });

    debugPrint('✅ [BackgroundService] Started for driver: $driverName');
  }

  /// Остановка фонового сервиса
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    debugPrint('🛑 [BackgroundService] Stopped');
  }

  /// Проверка работает ли сервис
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Точка входа для фонового сервиса (Android)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    String? driverId;
    String? driverName;

    // Слушаем команды из основного приложения
    service.on('setDriverData').listen((event) {
      driverId = event?['driverId'] as String?;
      driverName = event?['driverName'] as String?;
      debugPrint('📍 [BackgroundService] Driver data set: $driverName');
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Таймер для отслеживания местоположения
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Проверяем рабочее время
          final now = DateTime.now();
          final isWorkTime = _isWorkTime(now);

          if (!isWorkTime) {
            // Не рабочее время - обновляем уведомление
            service.setForegroundNotificationInfo(
              title: 'LogiRoute',
              content: 'Не рабочее время. Отслеживание приостановлено.',
            );
            return;
          }

          // Рабочее время - отслеживаем местоположение
          if (driverId != null && driverName != null) {
            try {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );

              // Сохраняем в Firestore
              await FirebaseFirestore.instance
                  .collection('driver_locations')
                  .doc(driverId)
                  .set({
                'driverId': driverId,
                'driverName': driverName,
                'latitude': position.latitude,
                'longitude': position.longitude,
                'timestamp': FieldValue.serverTimestamp(),
                'accuracy': position.accuracy,
                'speed': position.speed,
              });

              // Обновляем уведомление
              service.setForegroundNotificationInfo(
                title: 'LogiRoute - Отслеживание активно',
                content:
                    'Последнее обновление: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              );

              debugPrint(
                  '📍 [BackgroundService] Location updated: ${position.latitude}, ${position.longitude}');
            } catch (e) {
              debugPrint('❌ [BackgroundService] Error updating location: $e');
            }
          }
        }
      }
    });
  }

  /// Точка входа для iOS background
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Проверка рабочего времени
  static bool _isWorkTime(DateTime time) {
    // Пятница (5) и Суббота (6) - выходные
    if (time.weekday == 5 || time.weekday == 6) {
      return false;
    }

    // Рабочие часы: 7:00 - 17:00
    final hour = time.hour;
    return hour >= 7 && hour < 17;
  }
}
