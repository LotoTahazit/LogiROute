#!/bin/bash

# 🔍 Скрипт проверки конфигурации LogiRoute Android
# Автор: AI Assistant
# Дата: 15.10.2025

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       LOGIROUTE - ПРОВЕРКА КОНФИГУРАЦИИ ANDROID               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}[✓]${NC} $1"
    else
        echo -e "${RED}[✗]${NC} $1 - ОТСУТСТВУЕТ!"
        ERRORS=$((ERRORS + 1))
    fi
}

check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $3"
    else
        echo -e "${RED}[✗]${NC} $3 - НЕ НАЙДЕНО!"
        ERRORS=$((ERRORS + 1))
    fi
}

check_warning() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $3"
    else
        echo -e "${YELLOW}[!]${NC} $3 - ПРЕДУПРЕЖДЕНИЕ"
        WARNINGS=$((WARNINGS + 1))
    fi
}

echo "1. Проверка файлов проекта..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_file "pubspec.yaml"
check_file "lib/main.dart"
check_file "lib/firebase_options.dart"
check_file "android/app/google-services.json"
check_file "android/app/build.gradle"
check_file "android/build.gradle"
check_file "android/settings.gradle"
check_file "android/app/proguard-rules.pro"
echo ""

echo "2. Проверка Firebase конфигурации..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Проверка appId
FIREBASE_APP_ID=$(grep -o "1:1074583077721:android:[a-z0-9]*" lib/firebase_options.dart 2>/dev/null | head -1)
GOOGLE_APP_ID=$(grep -o "1:1074583077721:android:[a-z0-9]*" android/app/google-services.json 2>/dev/null | head -1)

if [ "$FIREBASE_APP_ID" = "$GOOGLE_APP_ID" ]; then
    echo -e "${GREEN}[✓]${NC} App ID совпадает: $FIREBASE_APP_ID"
else
    echo -e "${RED}[✗]${NC} App ID не совпадает!"
    echo "    firebase_options.dart: $FIREBASE_APP_ID"
    echo "    google-services.json:  $GOOGLE_APP_ID"
    ERRORS=$((ERRORS + 1))
fi

# Проверка API Key
FIREBASE_API_KEY=$(grep -o 'apiKey:.*AIza[^'"'"']*' lib/firebase_options.dart | head -1 | sed 's/.*AIza/AIza/' | sed "s/'.*//")
GOOGLE_API_KEY=$(grep -o 'AIza[A-Za-z0-9_-]*' android/app/google-services.json | head -1)

if [ -n "$FIREBASE_API_KEY" ] && [ -n "$GOOGLE_API_KEY" ]; then
    if [ "$FIREBASE_API_KEY" = "$GOOGLE_API_KEY" ]; then
        echo -e "${GREEN}[✓]${NC} API Key совпадает"
    else
        echo -e "${YELLOW}[!]${NC} API Key отличается (может быть норма для разных платформ)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}[!]${NC} Не удалось проверить API Key"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

echo "3. Проверка Android конфигурации..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_content "android/app/build.gradle" "multiDexEnabled true" "MultiDex включен"
check_content "android/app/build.gradle" "firebase-bom" "Firebase BOM настроен"
check_content "android/app/src/main/AndroidManifest.xml" "LogiRouteApplication" "Кастомный Application класс"
check_file "android/app/src/main/kotlin/com/logiroute/app/LogiRouteApplication.kt"
echo ""

echo "4. Проверка ProGuard правил..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_content "android/app/proguard-rules.pro" "com.google.firebase" "Firebase правила"
check_content "android/app/proguard-rules.pro" "flutter" "Flutter правила"
check_content "android/app/proguard-rules.pro" "google.android.gms" "Google Play Services правила"
echo ""

echo "5. Проверка Flutter плагинов..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_content "pubspec.yaml" "firebase_core:" "firebase_core"
check_content "pubspec.yaml" "firebase_auth:" "firebase_auth"
check_content "pubspec.yaml" "cloud_firestore:" "cloud_firestore"
check_warning "pubspec.yaml" "firebase_auth: \^6.2" "firebase_auth >=6.2 (рекомендуется)"
echo ""

echo "6. Проверка инициализации в коде..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_content "lib/main.dart" "WidgetsFlutterBinding.ensureInitialized" "WidgetsFlutterBinding.ensureInitialized()"
check_content "lib/main.dart" "Firebase.initializeApp" "Firebase.initializeApp()"
check_content "lib/main.dart" "FlutterError.onError" "Глобальный обработчик ошибок"
echo ""

echo "7. Проверка Flutter окружения..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}[✓]${NC} Flutter установлен: $(flutter --version | head -1)"
else
    echo -e "${RED}[✗]${NC} Flutter не найден!"
    ERRORS=$((ERRORS + 1))
fi
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      РЕЗУЛЬТАТ ПРОВЕРКИ                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ ВСЁ ОТЛИЧНО!${NC} Конфигурация корректна."
    echo ""
    echo "Можно собирать приложение:"
    echo "  flutter build apk --release"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️ ЕСТЬ ПРЕДУПРЕЖДЕНИЯ${NC}"
    echo "Ошибок: $ERRORS"
    echo "Предупреждений: $WARNINGS"
    echo ""
    echo "Можно попробовать собрать, но лучше исправить предупреждения."
    exit 0
else
    echo -e "${RED}❌ ЕСТЬ ОШИБКИ!${NC}"
    echo "Ошибок: $ERRORS"
    echo "Предупреждений: $WARNINGS"
    echo ""
    echo "Исправьте ошибки перед сборкой!"
    echo "См. документацию: ANDROID_BUILD_GUIDE.md"
    exit 1
fi

