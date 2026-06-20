import 'package:shared_preferences/shared_preferences.dart';

/// Точки, для которых водитель выключил автозакрытие (нужно фото / без клиента).
class DriverAutoClosePrefs {
  static const _key = 'driver_autoclose_disabled_ids';

  static Future<Set<String>> loadDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  static Future<void> setDisabled(String pointId, bool disabled) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? {};
    if (disabled) {
      ids.add(pointId);
    } else {
      ids.remove(pointId);
    }
    await prefs.setStringList(_key, ids.toList());
  }

  static Future<bool> isDisabled(String pointId) async {
    final ids = await loadDisabled();
    return ids.contains(pointId);
  }

  // ── Политика компании: требовать POD-фото на каждую доставку ──
  // Зеркалится из CompanySettings.requirePodPhoto при загрузке у водителя,
  // чтобы фоновый сервис (другой изолят) тоже мог её учитывать.
  static const _photoRequiredKey = 'company_require_pod_photo';

  static Future<void> setPhotoRequired(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_photoRequiredKey, value);
  }

  static Future<bool> isPhotoRequired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_photoRequiredKey) ?? false;
  }
}
