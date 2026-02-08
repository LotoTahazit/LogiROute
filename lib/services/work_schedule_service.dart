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
    
    debugPrint('📅 [Schedule] Starting schedule monitoring');
    debugPrint('📅 [Schedule] Work hours: $workStartHour:00 - $workEndHour:00');
    debugPrint('📅 [Schedule] Weekend days: Friday, Saturday');
    
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
    debugPrint('📅 [Schedule] Stopping schedule monitoring');
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = null;
  }
  
  /// Проверяет нужно ли включить/выключить отслеживание
  void _checkSchedule() {
    final now = DateTime.now();
    final shouldBeTracking = _shouldBeTracking(now);
    
    if (shouldBeTracking && !_isTrackingActive) {
      // Нужно включить отслеживание
      debugPrint('✅ [Schedule] Work time started - enabling tracking');
      _isTrackingActive = true;
      _onStartTracking?.call();
    } else if (!shouldBeTracking && _isTrackingActive) {
      // Нужно выключить отслеживание
      debugPrint('🛑 [Schedule] Work time ended - disabling tracking');
      _isTrackingActive = false;
      _onStopTracking?.call();
    }
  }
  
  /// Проверяет должно ли быть активно отслеживание в данный момент
  bool _shouldBeTracking(DateTime time) {
    // Проверяем день недели (1 = понедельник, 7 = воскресенье)
    if (weekendDays.contains(time.weekday)) {
      debugPrint('📅 [Schedule] Weekend day - tracking disabled');
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
  Map<String, dynamic> getScheduleStatus() {
    final now = DateTime.now();
    final shouldBeTracking = _shouldBeTracking(now);
    final isWeekend = weekendDays.contains(now.weekday);
    
    String statusMessage;
    if (isWeekend) {
      statusMessage = 'Выходной день';
    } else if (now.hour < workStartHour) {
      final minutesUntilStart = ((workStartHour - now.hour) * 60) - now.minute;
      statusMessage = 'Работа начнется через $minutesUntilStart минут';
    } else if (now.hour >= workEndHour) {
      statusMessage = 'Рабочий день закончен';
    } else {
      final minutesUntilEnd = ((workEndHour - now.hour) * 60) - now.minute;
      statusMessage = 'Работа закончится через $minutesUntilEnd минут';
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
