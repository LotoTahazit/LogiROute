// lib/services/locale_service_web.dart
// Сохраняет язык в localStorage для веба
import 'package:web/web.dart';

/// Сохраняет язык в localStorage для веба
void saveLocaleToWeb(String languageCode) {
  try {
    window.localStorage.setItem('app_locale', languageCode);
  } catch (e) {
    // Игнорируем ошибки
  }
}

/// Сохраняет статус логина в localStorage для веба
void saveLoginStatusToWeb(bool isLoggedIn) {
  try {
    window.localStorage.setItem('user_logged_in', isLoggedIn.toString());
  } catch (e) {
    // Игнорируем ошибки
  }
}
