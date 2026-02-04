@echo off
echo 🍎 Building iOS app for LogiRoute...

REM Проверяем наличие Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter не найден в PATH
    exit /b 1
)

REM Переходим в директорию iOS
cd ios

echo 📦 Installing CocoaPods dependencies...
pod install

if %errorlevel% neq 0 (
    echo ❌ Ошибка установки CocoaPods зависимостей
    echo Установите CocoaPods: sudo gem install cocoapods
    exit /b 1
)

REM Возвращаемся в корневую директорию
cd ..

echo 🔨 Building iOS app...
flutter build ios --release

if %errorlevel% equ 0 (
    echo ✅ iOS приложение успешно собрано!
    echo 📱 Файл: build/ios/iphoneos/Runner.app
    echo 📋 Для создания IPA файла откройте проект в Xcode:
    echo    ios/Runner.xcworkspace
) else (
    echo ❌ Ошибка сборки iOS приложения
    exit /b 1
)

pause
