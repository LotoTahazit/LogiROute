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
echo "[3/4] Сборка веб-версии (RELEASE)..."
flutter build web --release

echo ""
echo "[4/4] Деплой на Firebase Hosting..."
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

