// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Сервис для отправки локальных уведомлений водителю
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Инициализируем timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem')); // Израиль
      
      // Настройки для Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Настройки для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      _isInitialized = true;
      debugPrint('✅ [Notifications] Service initialized');
      
      // Запрашиваем разрешения
      await _requestPermissions();
    } catch (e) {
      debugPrint('❌ [Notifications] Initialization error: $e');
    }
  }
  
  /// Запрашивает разрешения на уведомления
  Future<void> _requestPermissions() async {
    // Android 13+ требует явного разрешения
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    // iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
  
  /// Обработчик нажатия на уведомление
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 [Notifications] Notification tapped: ${response.payload}');
    // Здесь можно открыть нужный экран приложения
  }
  
  /// Планирует ежедневное уведомление "Пора на работу!"
  Future<void> scheduleDailyWorkReminder() async {
    if (!_isInitialized) await initialize();
    
    try {
      // Отменяем предыдущее уведомление если было
      await _notifications.cancel(1);
      
      // Настраиваем время: 6:50 утра
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        6, // час
        50, // минута
      );
      
      // Если время уже прошло сегодня, планируем на завтра
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Пропускаем пятницу (5) и субботу (6)
      while (scheduledDate.weekday == DateTime.friday || 
             scheduledDate.weekday == DateTime.saturday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notifications.zonedSchedule(
        1, // ID уведомления
        '🚛 Пора на работу!',
        'Не забудьте открыть приложение LogiRoute для отслеживания GPS',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'work_reminder',
            'Напоминания о работе',
            channelDescription: 'Ежедневные напоминания о начале рабочего дня',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            sound: RawResourceAndroidNotificationSound('notification'),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'notification.aiff',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Повторять каждый день
      );
      
      debugPrint('✅ [Notifications] Daily reminder scheduled for ${scheduledDate.hour}:${scheduledDate.minute}');
    } catch (e) {
      debugPrint('❌ [Notifications] Error scheduling reminder: $e');
    }
  }
  
  /// Отправляет немедленное уведомление
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Уникальный ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general',
            'Общие уведомления',
            channelDescription: 'Общие уведомления приложения',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      debugPrint('✅ [Notifications] Immediate notification sent: $title');
    } catch (e) {
      debugPrint('❌ [Notifications] Error sending notification: $e');
    }
  }
  
  /// Отменяет все запланированные уведомления
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ [Notifications] All notifications cancelled');
  }
}
