import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_service_stub.dart'
    if (dart.library.html) 'locale_service_web.dart';

class LocaleService extends ChangeNotifier {
  // Default language is Hebrew (he)
  Locale _locale = const Locale('he', '');

  Locale get locale => _locale;

  LocaleService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to Hebrew if no saved preference
    final languageCode = prefs.getString('language_code') ?? 'he';
    _locale = Locale(languageCode, '');
    
    // Сохраняем в localStorage для веба (для кнопки скачивания)
    saveLocaleToWeb(languageCode);
    
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode, '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    // Сохраняем в localStorage для веба (для кнопки скачивания)
    saveLocaleToWeb(languageCode);
    
    notifyListeners();
  }
}

