# ⚡ Быстрый чеклист исправлений

## 🚨 КРИТИЧНО (сделать прямо сейчас):

### 1. Безопасность паролей
```bash
flutter pub add flutter_secure_storage
```

Заменить в `lib/services/biometric_service.dart`:
```dart
// БЫЛО:
await prefs.setString('biometric_password_$userId', password);

// СТАЛО:
final storage = FlutterSecureStorage();
await storage.write(key: 'biometric_password_$userId', value: password);
```

### 2. Удалить мусорные файлы
```bash
del fix_interpolation.dart
del methods_to_insert.dart
del temp_input.txt
del lib\screens\dispatcher\create_standalone_invoice_dialog.dart
del web\app-release.apk
del web\downloads\LogiRoute.apk
del build\web\app-release.apk
del build\web\downloads\LogiRoute.apk
```

### 3. Обновить .gitignore
Добавить:
```
# Build artifacts
build/
!build/app/outputs/flutter-apk/app-release.apk

# Temporary files
temp_*.txt
fix_*.dart
methods_to_insert.dart
```

---

## ⚠️ ВАЖНО (на этой неделе):

### 4. Firebase App Check
```bash
flutter pub add firebase_app_check
```

В `main.dart`:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
```

### 5. Исправить async gaps
Добавить проверки перед использованием context:
```dart
if (!mounted) return;
Navigator.of(context).pop();
```

Файлы:
- `lib/screens/auth/login_screen.dart:182`
- `lib/screens/dispatcher/add_point_dialog.dart:388,390`
- `lib/screens/dispatcher/dispatcher_dashboard.dart:160,320,326,402,465,511,517`

---

## 📦 ОПТИМИЗАЦИЯ (когда будет время):

### 6. Уменьшить размер APK
```bash
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/debug-info
```

Результат: 3 APK по ~12 MB вместо одного 34 MB

### 7. Очистка
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## ✅ Быстрая проверка

После исправлений запустить:
```bash
flutter analyze
flutter test
flutter build apk --release
```

Ожидаемый результат:
- ✅ 0 ошибок
- ✅ <5 предупреждений
- ✅ APK собирается успешно
