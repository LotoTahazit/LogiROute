import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Проверяет доступность биометрии на устройстве
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Получает список доступных биометрических методов
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Выполняет биометрическую аутентификацию
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Только биометрия, без PIN/пароля
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('❌ Biometric authentication error: ${e.code} - ${e.message}');
      // Коды ошибок:
      // - NotAvailable: биометрия недоступна
      // - NotEnrolled: не зарегистрирована биометрия
      // - LockedOut: слишком много попыток
      // - PermanentlyLockedOut: заблокировано навсегда
      // - PasscodeNotSet: не установлен пароль устройства
      return false;
    } catch (e) {
      print('❌ Unexpected biometric error: $e');
      return false;
    }
  }

  /// Проверяет, включена ли биометрия для пользователя
  Future<bool> isBiometricEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled_$userId') ?? false;
    } catch (e) {
      print('Error checking biometric enabled: $e');
      return false;
    }
  }

  /// Включает биометрию для пользователя
  Future<void> enableBiometric(
      String userId, String email, String password) async {
    try {
      print('🔒 Enabling biometric for user: $userId');
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('biometric_enabled_$userId', true);
      print('✅ Set biometric_enabled_$userId = true');

      await prefs.setString('biometric_email_$userId', email);
      print('✅ Set biometric_email_$userId = $email');

      // ВАЖНО: В продакшене используйте flutter_secure_storage для хранения пароля!
      await prefs.setString('biometric_password_$userId', password);
      print('✅ Set biometric_password_$userId = [HIDDEN]');

      print('✅ Biometric enabled for user: $userId');
    } catch (e) {
      print('❌ Error enabling biometric: $e');
      rethrow;
    }
  }

  /// Отключает биометрию для пользователя
  Future<void> disableBiometric(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_enabled_$userId');
      await prefs.remove('biometric_email_$userId');
      await prefs.remove('biometric_password_$userId');
      print('✅ Biometric disabled for user: $userId');
    } catch (e) {
      print('Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Получает сохранённые учётные данные для биометрического входа
  Future<Map<String, String>?> getSavedCredentials(String userId) async {
    try {
      print('🔒 Getting saved credentials for user: $userId');
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('biometric_email_$userId');
      final password = prefs.getString('biometric_password_$userId');

      print('🔒 Email found: ${email != null}');
      print('🔒 Password found: ${password != null}');

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      print('❌ No saved credentials found');
      return null;
    } catch (e) {
      print('❌ Error getting saved credentials: $e');
      return null;
    }
  }

  /// Получает ID последнего пользователя, который включил биометрию
  Future<String?> getLastBiometricUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_biometric_user_id');
    } catch (e) {
      print('Error getting last biometric user: $e');
      return null;
    }
  }

  /// Сохраняет ID последнего пользователя с биометрией
  Future<void> setLastBiometricUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_biometric_user_id', userId);
    } catch (e) {
      print('Error setting last biometric user: $e');
    }
  }

  /// Получает название биометрического метода для отображения
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Отпечаток пальца';
      case BiometricType.iris:
        return 'Сканер радужки';
      case BiometricType.strong:
        return 'Биометрия';
      case BiometricType.weak:
        return 'Биометрия (слабая)';
      default:
        return 'Биометрия';
    }
  }
}
