@echo off
REM Быстрый деплой веб-версии LogiRoute (без flutter clean)

echo ========================================
echo   LOGIROUTE - WEB DEPLOY (QUICK)
echo ========================================
echo.

echo [1/4] Генерация локализации...
call flutter gen-l10n

echo.
echo [2/4] Сборка веб-версии (RELEASE)...
flutter build web --release
if %errorlevel% neq 0 (
    echo ОШИБКА при сборке!
    pause
    exit /b 1
)

echo.
echo [3/4] Копирование APK в папку для скачивания...
if not exist "build\web\downloads" mkdir build\web\downloads
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "build\web\downloads\logiroute.apk"
    echo ✅ APK скопирован: build\web\downloads\logiroute.apk
) else (
    echo ⚠️ APK не найден. Сначала соберите Android версию: build_android.bat
)

echo.
echo [4/4] Деплой на Firebase Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ОШИБКА при деплое!
    pause
    exit /b 1
)

echo.
echo ========================================
echo   ✅ ГОТОВО!
echo ========================================
echo.
echo 🌐 Сайт обновлён на Firebase Hosting
echo 📱 APK доступен: /downloads/logiroute.apk
echo 🔍 Проверьте консоль браузера на ошибки
echo 🔄 Может потребоваться очистка кэша (Ctrl+Shift+R)
echo.
pause
