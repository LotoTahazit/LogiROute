import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Обработчик фоновых сообщений — должен быть top-level функцией
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 [FCM] Фоновое сообщение: ${message.messageId}');
}

/// Сервис FCM — управление жизненным циклом токена и сообщениями на переднем плане.
/// Сохраняет токен в users/{uid}.fcmToken для отправки push через Cloud Function.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  String? _currentUid;

  /// Инициализация FCM: запрос разрешений, сохранение токена, подписка на сообщения.
  /// Вызывать один раз после логина с uid аутентифицированного пользователя.
  Future<void> initialize(String uid) async {
    if (_initialized && _currentUid == uid) return;
    _currentUid = uid;

    try {
      // Регистрация обработчика фоновых сообщений
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Запрос разрешений (iOS + Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ [FCM] Разрешение отклонено');
        return;
      }

      // Получение и сохранение токена
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(uid, token);
      }

      // Подписка на обновление токена
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(uid, newToken);
      });

      // Сообщения на переднем плане → показать локальное уведомление
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Нажатие на уведомление когда приложение было в фоне
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;
      debugPrint(
          '✅ [FCM] Инициализирован для пользователя $uid, токен: ${token?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ [FCM] Ошибка инициализации: $e');
    }
  }

  /// Save FCM token to user document as a map entry: fcmTokens.{token} = { platform, updatedAt }
  /// Also keeps legacy fcmToken for backward compat with existing CF code.
  Future<void> _saveToken(String uid, String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'web';

      await _firestore.collection('users').doc(uid).update({
        // New map format: multi-device support
        'fcmTokens.$token': {
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        // Legacy field for backward compat
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [FCM] Token saved for $uid ($platform)');
    } catch (e) {
      debugPrint('❌ [FCM] Token save error: $e');
    }
  }

  /// Handle foreground message — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 [FCM] Foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null) {
      NotificationService().showImmediateNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    }
  }

  /// Handle notification tap (app was in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 [FCM] Tap: ${message.data}');
    // Navigation can be handled here based on message.data['type']
  }

  /// Clean up token on logout — removes current device token from map + legacy field
  Future<void> clearToken() async {
    if (_currentUid != null) {
      try {
        // Get current token before deleting
        final currentToken = await _messaging.getToken();
        final updates = <String, dynamic>{
          'fcmToken': FieldValue.delete(),
        };
        // Remove specific token from map
        if (currentToken != null) {
          updates['fcmTokens.$currentToken'] = FieldValue.delete();
        }
        await _firestore.collection('users').doc(_currentUid).update(updates);
        await _messaging.deleteToken();
        debugPrint('🗑️ [FCM] Token cleared');
      } catch (e) {
        debugPrint('❌ [FCM] Clear token error: $e');
      }
    }
    _initialized = false;
    _currentUid = null;
  }
}
