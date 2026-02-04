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
echo [3/4] Сборка веб-версии (RELEASE)...
flutter build web --release --web-renderer canvaskit
if %errorlevel% neq 0 (
    echo ОШИБКА при сборке!
    pause
    exit /b 1
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
echo 🔍 Проверьте консоль браузера на ошибки
echo 🔄 Может потребоваться очистка кэша (Ctrl+Shift+R)
echo.
pause

