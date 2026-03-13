@echo off
REM Universal build script for LogiRoute

echo ========================================
echo LogiRoute Build Script
echo ========================================
echo.

:menu
echo Choose build type:
echo 1. Android APK (Release)
echo 2. Android APK (Debug)
echo 3. Web (Production)
echo 4. Clean project
echo 5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto android_release
if "%choice%"=="2" goto android_debug
if "%choice%"=="3" goto web
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto end
echo Invalid choice!
goto menu

:android_release
echo.
echo Building Android APK (Release)...
flutter build apk --release
echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
pause
goto end

:android_debug
echo.
echo Building Android APK (Debug)...
flutter build apk --debug
echo.
echo APK location: build\app\outputs\flutter-apk\app-debug.apk
pause
goto end

:web
echo.
echo Building Web (Production)...
flutter build web --release
echo.
echo Web build location: build\web
pause
goto end

:clean
echo.
echo Cleaning project...
flutter clean
flutter pub get
echo.
echo Project cleaned!
pause
goto menu

:end
echo.
echo Done!
