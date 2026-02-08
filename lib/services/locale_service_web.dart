// lib/services/locale_service_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Сохраняет язык в localStorage для веба
void saveLocaleToWeb(String languageCode) {
  try {
    html.window.localStorage['app_locale'] = languageCode;
  } catch (e) {
    // Игнорируем ошибки
  }
}

/// Сохраняет статус логина в localStorage для веба
void saveLoginStatusToWeb(bool isLoggedIn) {
  try {
    html.window.localStorage['user_logged_in'] = isLoggedIn.toString();
  } catch (e) {
    // Игнорируем ошибки
  }
}
