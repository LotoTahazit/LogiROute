@echo off
REM 🚀 Скрипт автоматической сборки LogiRoute для Android (Windows)
REM Автор: AI Assistant
REM Дата: 15.10.2025

setlocal enabledelayedexpansion

echo ╔═══════════════════════════════════════════════════════════════╗
echo ║       LOGIROUTE - АВТОМАТИЧЕСКАЯ СБОРКА ANDROID               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM 1. Проверка Flutter
echo [STEP] Проверка Flutter окружения...
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [✗] Flutter не найден! Установите Flutter.
    pause
    exit /b 1
)
echo [✓] Flutter найден
echo.

REM 2. Очистка проекта
echo [STEP] Очистка проекта...
flutter clean >nul 2>&1
echo [✓] Flutter clean выполнен

if exist "android" (
    cd android
    call gradlew clean >nul 2>&1
    cd ..
    echo [✓] Gradle clean выполнен
)
echo.

REM 3. Получение зависимостей
echo [STEP] Получение зависимостей...
flutter pub get
if %errorlevel% neq 0 (
    echo [✗] Ошибка при получении зависимостей
    pause
    exit /b 1
)
echo [✓] Зависимости обновлены
echo.

REM 4. Проверка Firebase конфигурации
echo [STEP] Проверка Firebase конфигурации...
if not exist "lib\firebase_options.dart" (
    echo [✗] Файл firebase_options.dart не найден!
    pause
    exit /b 1
)
if not exist "android\app\google-services.json" (
    echo [✗] Файл google-services.json не найден!
    pause
    exit /b 1
)
echo [✓] Firebase конфигурация найдена
echo.

REM 5. Проверка устройств
echo [STEP] Проверка подключенных устройств...
flutter devices | find "No devices" >nul
if %errorlevel% equ 0 (
    echo [!] Устройства не найдены. Будет создан только APK.
    set INSTALL=false
) else (
    echo [✓] Устройства найдены
    set INSTALL=true
)
echo.

REM 6. Выбор типа сборки
echo Выберите тип сборки:
echo 1) Debug (с hot reload, быстрая)
echo 2) Release (оптимизированная, для тестирования)
echo 3) App Bundle (для Google Play)
echo.
set /p BUILD_TYPE="Ваш выбор [1-3]: "

if "%BUILD_TYPE%"=="1" (
    echo.
    echo [STEP] Сборка Debug версии...
    if "%INSTALL%"=="true" (
        flutter run --debug
    ) else (
        flutter build apk --debug
        echo [✓] Debug APK создан: build\app\outputs\flutter-apk\app-debug.apk
    )
) else if "%BUILD_TYPE%"=="2" (
    echo.
    echo [STEP] Сборка Release APK...
    flutter build apk --release --split-per-abi
    if %errorlevel% equ 0 (
        echo [✓] Release APK созданы:
        dir /b build\app\outputs\flutter-apk\app-*-release.apk
        
        if "%INSTALL%"=="true" (
            echo.
            set /p INSTALL_NOW="Установить на устройство? [y/N]: "
            if /i "!INSTALL_NOW!"=="y" (
                flutter install --release
                echo [✓] Приложение установлено
            )
        )
    ) else (
        echo [✗] Ошибка при сборке
        pause
        exit /b 1
    )
) else if "%BUILD_TYPE%"=="3" (
    echo.
    echo [STEP] Сборка App Bundle...
    flutter build appbundle --release
    if %errorlevel% equ 0 (
        echo [✓] App Bundle создан: build\app\outputs\bundle\release\app-release.aab
    ) else (
        echo [✗] Ошибка при сборке
        pause
        exit /b 1
    )
) else (
    echo [✗] Неверный выбор!
    pause
    exit /b 1
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                   СБОРКА ЗАВЕРШЕНА!                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Показать размер файлов
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        set SIZE=%%~zA
        set /a SIZE_MB=!SIZE! / 1048576
        echo 📦 Размер APK: !SIZE_MB! MB
    )
)

echo.
echo 💡 Советы:
echo   - Логи: flutter logs
echo   - Установка: flutter install
echo   - Устройства: flutter devices
echo.

pause
exit /b 0

