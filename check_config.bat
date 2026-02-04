@echo off
REM 🔍 Скрипт проверки конфигурации LogiRoute Android (Windows)
REM Автор: AI Assistant
REM Дата: 15.10.2025

setlocal enabledelayedexpansion

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║       LOGIROUTE - ПРОВЕРКА КОНФИГУРАЦИИ ANDROID               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

set ERRORS=0
set WARNINGS=0

echo 1. Проверка файлов проекта...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :check_file "pubspec.yaml"
call :check_file "lib\main.dart"
call :check_file "lib\firebase_options.dart"
call :check_file "android\app\google-services.json"
call :check_file "android\app\build.gradle"
call :check_file "android\build.gradle"
call :check_file "android\settings.gradle"
call :check_file "android\app\proguard-rules.pro"
echo.

echo 2. Проверка Firebase конфигурации...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Проверка наличия правильного App ID
findstr /C:"1:1074583077721:android:a116aed2af5efe6c284248" lib\firebase_options.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] App ID совпадает
) else (
    echo [✗] App ID не совпадает или не найден!
    set /a ERRORS+=1
)

REM Проверка API Key
findstr /C:"AIzaSyDk2nSSpu0DhJ_Yu9esVwMFSf5sRsRulsY" lib\firebase_options.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] API Key правильный
) else (
    echo [!] API Key может отличаться
    set /a WARNINGS+=1
)
echo.

echo 3. Проверка Android конфигурации...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :check_content "android\app\build.gradle" "multiDexEnabled true" "MultiDex включен"
call :check_content "android\app\build.gradle" "firebase-bom" "Firebase BOM настроен"
call :check_content "android\app\src\main\AndroidManifest.xml" "LogiRouteApplication" "Кастомный Application класс"
call :check_file "android\app\src\main\kotlin\com\logiroute\app\LogiRouteApplication.kt"
echo.

echo 4. Проверка ProGuard правил...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :check_content "android\app\proguard-rules.pro" "com.google.firebase" "Firebase правила"
call :check_content "android\app\proguard-rules.pro" "flutter" "Flutter правила"
call :check_content "android\app\proguard-rules.pro" "google.android.gms" "Google Play Services правила"
echo.

echo 5. Проверка Flutter плагинов...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :check_content "pubspec.yaml" "firebase_core:" "firebase_core"
call :check_content "pubspec.yaml" "firebase_auth:" "firebase_auth"
call :check_content "pubspec.yaml" "cloud_firestore:" "cloud_firestore"
echo.

echo 6. Проверка инициализации в коде...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :check_content "lib\main.dart" "WidgetsFlutterBinding.ensureInitialized" "WidgetsFlutterBinding.ensureInitialized()"
call :check_content "lib\main.dart" "Firebase.initializeApp" "Firebase.initializeApp()"
call :check_content "lib\main.dart" "FlutterError.onError" "Глобальный обработчик ошибок"
echo.

echo 7. Проверка Flutter окружения...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

where flutter >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] Flutter установлен
) else (
    echo [✗] Flutter не найден!
    set /a ERRORS+=1
)
echo.

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                      РЕЗУЛЬТАТ ПРОВЕРКИ                       ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

if %ERRORS% equ 0 (
    if %WARNINGS% equ 0 (
        echo ✅ ВСЁ ОТЛИЧНО! Конфигурация корректна.
        echo.
        echo Можно собирать приложение:
        echo   flutter build apk --release
    ) else (
        echo ⚠️ ЕСТЬ ПРЕДУПРЕЖДЕНИЯ
        echo Ошибок: %ERRORS%
        echo Предупреждений: %WARNINGS%
        echo.
        echo Можно попробовать собрать, но лучше исправить предупреждения.
    )
) else (
    echo ❌ ЕСТЬ ОШИБКИ!
    echo Ошибок: %ERRORS%
    echo Предупреждений: %WARNINGS%
    echo.
    echo Исправьте ошибки перед сборкой!
    echo См. документацию: ANDROID_BUILD_GUIDE.md
)

echo.
pause
exit /b %ERRORS%

REM ═══════════════════════════════════════════════════════════════
REM Функции
REM ═══════════════════════════════════════════════════════════════

:check_file
if exist "%~1" (
    echo [✓] %~1
) else (
    echo [✗] %~1 - ОТСУТСТВУЕТ!
    set /a ERRORS+=1
)
goto :eof

:check_content
findstr /C:"%~2" "%~1" >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] %~3
) else (
    echo [✗] %~3 - НЕ НАЙДЕНО!
    set /a ERRORS+=1
)
goto :eof

