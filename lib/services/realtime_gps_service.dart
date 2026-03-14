import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// Сервис реального времени GPS через WebSocket.
/// Заменяет Firestore для live-трекинга водителей.
///
/// Driver: отправляет GPS каждые 5 сек
/// Dispatcher: получает обновления всех водителей
class RealtimeGpsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _disposed = false;

  // Callback для диспетчера: получение обновлений водителей
  void Function(Map<String, dynamic> driverUpdate)? onDriverUpdate;
  // Callback для snapshot (все водители при подключении)
  void Function(Map<String, dynamic> allDrivers)? onSnapshot;

  String get _wsUrl => AppConfig.gpsWebSocketUrl;

  /// Подключиться как водитель
  void connectAsDriver() {
    _connect();
  }

  /// Подключиться как диспетчер
  void connectAsDispatcher({
    required void Function(Map<String, dynamic>) onUpdate,
    required void Function(Map<String, dynamic>) onSnapshotReceived,
  }) {
    onDriverUpdate = onUpdate;
    onSnapshot = onSnapshotReceived;
    _connect();
    // После подключения отправляем тип
    _sendWhenReady({'type': 'dispatcher'});
  }

  void _connect() {
    if (_disposed || _wsUrl.isEmpty) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            if (data['type'] == 'driver_update') {
              onDriverUpdate?.call(data);
            } else if (data['type'] == 'snapshot') {
              final drivers = data['drivers'] as Map<String, dynamic>? ?? {};
              onSnapshot?.call(drivers);
            }
          } catch (e) {
            debugPrint('⚠️ [WS] Parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ [WS] Error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔌 [WS] Connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      debugPrint('✅ [WS] Connected to $_wsUrl');
    } catch (e) {
      debugPrint('❌ [WS] Connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('🔄 [WS] Reconnecting...');
      _connect();
      // Если диспетчер — переподписываемся
      if (onDriverUpdate != null) {
        _sendWhenReady({'type': 'dispatcher'});
      }
    });
  }

  void _sendWhenReady(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      // Retry after short delay
      Timer(const Duration(milliseconds: 500), () {
        if (_isConnected && _channel != null) {
          _channel!.sink.add(jsonEncode(data));
        }
      });
    }
  }

  /// Отправить GPS (вызывается водителем каждые 5–10 сек)
  void sendGps({
    required String driverId,
    required String driverName,
    required double lat,
    required double lng,
    double speed = 0,
  }) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'gps',
      'driverId': driverId,
      'driverName': driverName,
      'lat': lat,
      'lng': lng,
      'speed': speed,
    }));
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}
