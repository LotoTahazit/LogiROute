// lib/services/work_schedule_service.dart
import 'dart:async';
import '../models/shift_schedule_config.dart';

/// Сервис управления рабочим расписанием водителя.
/// Текст статуса и логика «рабочий день» берутся из [ShiftScheduleConfig]
/// (`companies/{companyId}/settings/shifts`) — тот же источник, что экран לוח משמרות.
/// Включение/выключение GPS по расписанию сейчас отключено (трекинг всегда можно).
class WorkScheduleService {
  Timer? _scheduleCheckTimer;
  bool _isTrackingActive = false;
  Function()? _onStartTracking;
  Function()? _onStopTracking;

  /// Совпадает с [DeliveryMapWidget] / `settings/shifts`.
  ShiftScheduleConfig _shift = ShiftScheduleConfig.defaults;

  /// Подставлять из Firestore при загрузке/подписке на `settings/shifts`.
  void updateShiftSchedule(ShiftScheduleConfig config) {
    _shift = config;
  }

  /// Запускает мониторинг расписания
  void startScheduleMonitoring({
    required Function() onStartTracking,
    required Function() onStopTracking,
  }) {
    _onStartTracking = onStartTracking;
    _onStopTracking = onStopTracking;

    // Проверяем расписание каждую минуту
    _scheduleCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSchedule(),
    );

    // Проверяем сразу при запуске
    _checkSchedule();
  }

  /// Останавливает мониторинг расписания
  void stopScheduleMonitoring() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = null;
  }

  /// Проверяет нужно ли включить/выключить отслеживание
  void _checkSchedule() {
    final now = DateTime.now();
    final shouldBeTracking = _shouldBeTracking(now);

    if (shouldBeTracking && !_isTrackingActive) {
      _isTrackingActive = true;
      _onStartTracking?.call();
    } else if (!shouldBeTracking && _isTrackingActive) {
      _isTrackingActive = false;
      _onStopTracking?.call();
    }
  }

  /// Проверяет должно ли быть активно отслеживание в данный момент
  bool _shouldBeTracking(DateTime time) {
    // GPS работает ВСЕГДА (см. продуктовые требования)
    return true;
  }

  /// Возвращает информацию о текущем статусе расписания
  /// Принимает функции локализации для поддержки разных языков
  Map<String, dynamic> getScheduleStatus({
    String Function(int)? workStartsInFn,
    String Function(int)? workEndsInFn,
    String? weekendDayText,
    String? workDayEndedText,
  }) {
    final now = DateTime.now();
    final shouldBeTracking = _shouldBeTracking(now);
    final cfg = _shift;

    final isDayOff = !cfg.workingDays.contains(now.weekday);

    String statusMessage;
    if (isDayOff) {
      statusMessage = weekendDayText ?? 'Day off';
    } else if (cfg.allows(now)) {
      final end = DateTime(now.year, now.month, now.day, cfg.endHour, 59, 59);
      var minutesUntilEnd = end.difference(now).inMinutes;
      if (minutesUntilEnd < 0) minutesUntilEnd = 0;
      statusMessage = workEndsInFn != null
          ? workEndsInFn(minutesUntilEnd)
          : 'Work ends in $minutesUntilEnd minutes';
    } else {
      final start =
          DateTime(now.year, now.month, now.day, cfg.startHour, 0, 0);
      if (now.isBefore(start)) {
        final minutesUntilStart = start.difference(now).inMinutes;
        statusMessage = workStartsInFn != null
            ? workStartsInFn(minutesUntilStart)
            : 'Work starts in $minutesUntilStart minutes';
      } else {
        statusMessage = workDayEndedText ?? 'Work day ended';
      }
    }

    return {
      'isWorkTime': shouldBeTracking,
      'isTracking': _isTrackingActive,
      'statusMessage': statusMessage,
      'currentHour': now.hour,
      'isWeekend': isDayOff,
    };
  }

  void dispose() {
    stopScheduleMonitoring();
  }
}
