#!/bin/bash

# Очистка, сборка и деплой веб-версии LogiRoute

set -e

echo "========================================"
echo "  LOGIROUTE - WEB DEPLOY"
echo "========================================"
echo ""

echo "[1/4] Очистка проекта..."
flutter clean

echo ""
echo "[2/4] Генерация локализации..."
flutter gen-l10n

echo ""
echo "[3/5] Сборка веб-версии (RELEASE)..."
flutter build web --release

echo ""
echo "[4/5] Копирование APK в папку для скачивания..."
mkdir -p build/web/downloads
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk build/web/downloads/logiroute.apk
    echo "✅ APK скопирован: build/web/downloads/logiroute.apk"
else
    echo "⚠️ APK не найден. Сначала соберите Android версию: ./build_android.sh"
fi

echo ""
echo "[5/5] Деплой на Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "========================================"
echo "  ✅ ГОТОВО!"
echo "========================================"
echo ""
echo "🌐 Сайт обновлён на Firebase Hosting"
echo "🔍 Проверьте консоль браузера на ошибки"
echo "🔄 Может потребоваться очистка кэша (Ctrl+Shift+R)"
echo ""

