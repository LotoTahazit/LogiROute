#!/bin/bash

echo "🍎 Building iOS app for LogiRoute..."

# Проверяем наличие Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode не найден. Установите Xcode из App Store"
    exit 1
fi

# Проверяем наличие CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods не найден. Установите: sudo gem install cocoapods"
    exit 1
fi

# Переходим в директорию iOS
cd ios

echo "📦 Installing CocoaPods dependencies..."
pod install

if [ $? -ne 0 ]; then
    echo "❌ Ошибка установки CocoaPods зависимостей"
    exit 1
fi

# Возвращаемся в корневую директорию
cd ..

echo "🔨 Building iOS app..."
flutter build ios --release

if [ $? -eq 0 ]; then
    echo "✅ iOS приложение успешно собрано!"
    echo "📱 Файл: build/ios/iphoneos/Runner.app"
    echo "📋 Для создания IPA файла используйте Xcode или команду:"
    echo "   xcodebuild -exportArchive -archivePath build/ios/Runner.xcarchive -exportPath build/ios/ipa -exportOptionsPlist ios/ExportOptions.plist"
else
    echo "❌ Ошибка сборки iOS приложения"
    exit 1
fi
