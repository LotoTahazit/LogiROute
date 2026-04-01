import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Две оси (карта / мониторинг):
/// 1. **Факт от водителя** — `driver_locations.isOnShift` (или эквивалент).
/// 2. **Разрешённый слот** — [ShiftScheduleConfig] из `settings/shifts`.
///
/// **Целевая формула (когда объедините оси на UI):**
/// `FINAL_ON_SHIFT = driverClaimsOnShift && schedule.allows(now)`
///
/// Сейчас виджет карты может опираться в основном на график; используйте
/// [effectiveOnShift] при подключении поля водителя.
bool effectiveOnShift({
  required bool driverClaimsOnShift,
  required bool scheduleAllowsNow,
}) =>
    driverClaimsOnShift && scheduleAllowsNow;

/// Расписание смен из `companies/{companyId}/settings/shifts`.
///
/// Поля документа (пример):
/// ```json
/// {
///   "workingDays": [1, 2, 3, 4, 5, 6],
///   "startHour": 6,
///   "endHour": 20
/// }
/// ```
/// `workingDays`: 1 = пн … 7 = вс ([DateTime.weekday]).
/// Часы — локальное время устройства (как и раньше на карте).
@immutable
class ShiftScheduleConfig {
  const ShiftScheduleConfig({
    required this.workingDays,
    required this.startHour,
    required this.endHour,
    this.holidays = const [],
  });

  /// Поведение как у старого [shouldShowDriver]: пн–пт, 6–20.
  static const ShiftScheduleConfig defaults = ShiftScheduleConfig(
    workingDays: [1, 2, 3, 4, 5],
    startHour: 6,
    endHour: 20,
  );

  final List<int> workingDays;
  final int startHour;
  final int endHour;

  /// Список праздничных дат в формате 'yyyy-MM-dd'. GPS не работает в эти дни.
  final List<String> holidays;

  /// Проверяет является ли дата праздником
  bool isHoliday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return holidays.contains(key);
  }

  bool isWithin(DateTime now) {
    if (isHoliday(now)) return false;
    if (!workingDays.contains(now.weekday)) return false;
    final h = now.hour;
    return h >= startHour && h < endHour;
  }

  /// Синоним [isWithin] — «график разрешает сейчас» (`schedule.allows(now)`).
  bool allows(DateTime now) => isWithin(now);

  static ShiftScheduleConfig fromFirestore(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;

    List<int> days = defaults.workingDays;
    final rawDays = data['workingDays'];
    if (rawDays is List) {
      final parsed = rawDays
          .map((e) => e is int ? e : (e is num ? e.toInt() : null))
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toList();
      if (parsed.isNotEmpty) days = parsed;
    }

    int sh = _hour(data['startHour'], defaults.startHour);
    int eh = _hour(data['endHour'], defaults.endHour);
    if (eh < sh) (sh, eh) = (eh, sh);

    return ShiftScheduleConfig(
      workingDays: days,
      startHour: sh.clamp(0, 23),
      endHour: eh.clamp(0, 23),
      holidays: _parseHolidays(data['holidays']),
    );
  }

  static List<String> _parseHolidays(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .where((s) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s))
        .toList();
  }

  /// Сериализация для SharedPreferences (BGService кеш)
  Map<String, dynamic> toMap() => {
        'workingDays': workingDays,
        'startHour': startHour,
        'endHour': endHour,
        'holidays': holidays,
      };

  // ── SharedPreferences кеш (для BackgroundLocationService) ──

  static const String _prefKey = 'shift_schedule_config';

  /// Сохранить в SharedPreferences (вызывается из Firestore listener)
  static Future<void> saveToPrefs(ShiftScheduleConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(config.toMap()));
  }

  /// Загрузить из SharedPreferences (вызывается BGService при старте)
  static Future<ShiftScheduleConfig> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return defaults;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromFirestore(map);
    } catch (_) {
      return defaults;
    }
  }

  static int _hour(dynamic v, int fallback) {
    if (v is int) return v.clamp(0, 23);
    if (v is num) return v.toInt().clamp(0, 23);
    if (v is String) {
      final parts = v.trim().split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]);
        if (h != null) return h.clamp(0, 23);
      }
    }
    return fallback;
  }
}
