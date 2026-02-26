// lib/services/work_schedule_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Сервис управления рабочим расписанием водителя
/// Автоматически включает/выключает отслеживание GPS по расписанию
class WorkScheduleService {
  Timer? _scheduleCheckTimer;
  bool _isTrackingActive = false;
  Function()? _onStartTracking;
  Function()? _onStopTracking;

  // Рабочее расписание
  static const int workStartHour = 7; // 7:00
  static const int workEndHour = 17; // 17:00
  static const List<int> weekendDays = [5, 6]; // Пятница (5), Суббота (6)

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
    // Проверяем день недели (1 = понедельник, 7 = воскресенье)
    if (weekendDays.contains(time.weekday)) {
      return false;
    }

    // Проверяем время
    final hour = time.hour;
    if (hour >= workStartHour && hour < workEndHour) {
      return true;
    }

    return false;
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
    final isWeekend = weekendDays.contains(now.weekday);

    String statusMessage;
    if (isWeekend) {
      statusMessage = weekendDayText ?? 'Weekend day';
    } else if (now.hour < workStartHour) {
      final minutesUntilStart = ((workStartHour - now.hour) * 60) - now.minute;
      statusMessage = workStartsInFn != null
          ? workStartsInFn(minutesUntilStart)
          : 'Work starts in $minutesUntilStart minutes';
    } else if (now.hour >= workEndHour) {
      statusMessage = workDayEndedText ?? 'Work day ended';
    } else {
      final minutesUntilEnd = ((workEndHour - now.hour) * 60) - now.minute;
      statusMessage = workEndsInFn != null
          ? workEndsInFn(minutesUntilEnd)
          : 'Work ends in $minutesUntilEnd minutes';
    }

    return {
      'isWorkTime': shouldBeTracking,
      'isTracking': _isTrackingActive,
      'statusMessage': statusMessage,
      'currentHour': now.hour,
      'isWeekend': isWeekend,
    };
  }

  void dispose() {
    stopScheduleMonitoring();
  }
}
