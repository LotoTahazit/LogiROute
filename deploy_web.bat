@echo off
REM Очистка, сборка и деплой веб-версии LogiRoute

echo ========================================
echo   LOGIROUTE - WEB DEPLOY
echo ========================================
echo.

echo [1/4] Очистка проекта...
flutter clean
if %errorlevel% neq 0 (
    echo ОШИБКА при очистке!
    pause
    exit /b 1
)

echo.
echo [2/4] Генерация локализации...
flutter gen-l10n
if %errorlevel% neq 0 (
    echo ОШИБКА при генерации локализации!
    pause
    exit /b 1
)

echo.
echo [3/5] Сборка веб-версии (RELEASE)...
flutter build web --release
if %errorlevel% neq 0 (
    echo ОШИБКА при сборке!
    pause
    exit /b 1
)

echo.
echo [4/5] Копирование APK в папку для скачивания...
if not exist "build\web\downloads" mkdir build\web\downloads
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "build\web\downloads\logiroute.apk"
    echo ✅ APK скопирован: build\web\downloads\logiroute.apk
) else (
    echo ⚠️ APK не найден. Сначала соберите Android версию: build_android.bat
)

echo.
echo [5/5] Деплой на Firebase Hosting...
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
echo 🔍 Проверьте консоль браузера на ошибки
echo 🔄 Может потребоваться очистка кэша (Ctrl+Shift+R)
echo.
pause

