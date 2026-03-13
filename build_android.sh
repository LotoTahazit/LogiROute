#!/bin/bash

# 🚀 Скрипт автоматической сборки LogiRoute для Android
# Автор: AI Assistant
# Дата: 15.10.2025

set -e  # Остановка при ошибке

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       LOGIROUTE - АВТОМАТИЧЕСКАЯ СБОРКА ANDROID               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода статуса
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 1. Проверка Flutter
print_step "Проверка Flutter окружения..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter не найден! Установите Flutter."
    exit 1
fi
print_success "Flutter найден: $(flutter --version | head -n 1)"

# 2. Очистка проекта
print_step "Очистка проекта..."
flutter clean > /dev/null 2>&1
print_success "Flutter clean выполнен"

if [ -d "android" ]; then
    cd android
    ./gradlew clean > /dev/null 2>&1 || print_warning "Градл чистка пропущена"
    cd ..
    print_success "Gradle clean выполнен"
fi

# 3. Получение зависимостей
print_step "Получение зависимостей..."
flutter pub get
print_success "Зависимости обновлены"

# 4. Проверка Firebase конфигурации
print_step "Проверка Firebase конфигурации..."
if [ ! -f "lib/firebase_options.dart" ]; then
    print_error "Файл firebase_options.dart не найден!"
    exit 1
fi
if [ ! -f "android/app/google-services.json" ]; then
    print_error "Файл google-services.json не найден!"
    exit 1
fi
print_success "Firebase конфигурация найдена"

# 5. Проверка устройств
print_step "Проверка подключенных устройств..."
DEVICES=$(flutter devices --machine | grep -c '"id"' || echo "0")
if [ "$DEVICES" -eq "0" ]; then
    print_warning "Устройства не найдены. Будет создан только APK."
    INSTALL=false
else
    print_success "Найдено устройств: $DEVICES"
    INSTALL=true
fi

# 6. Выбор типа сборки
echo ""
echo "Выберите тип сборки:"
echo "1) Debug (с hot reload, быстрая)"
echo "2) Release (оптимизированная, для тестирования)"
echo "3) App Bundle (для Google Play)"
read -p "Ваш выбор [1-3]: " BUILD_TYPE

case $BUILD_TYPE in
    1)
        print_step "Сборка Debug версии..."
        if [ "$INSTALL" = true ]; then
            flutter run --debug
        else
            flutter build apk --debug
            print_success "Debug APK создан: build/app/outputs/flutter-apk/app-debug.apk"
        fi
        ;;
    2)
        print_step "Сборка Release APK..."
        flutter build apk --release --split-per-abi
        print_success "Release APK созданы:"
        ls -lh build/app/outputs/flutter-apk/app-*-release.apk | awk '{print "  - " $9 " (" $5 ")"}'
        
        if [ "$INSTALL" = true ]; then
            read -p "Установить на устройство? [y/N]: " INSTALL_NOW
            if [[ $INSTALL_NOW =~ ^[Yy]$ ]]; then
                flutter install --release
                print_success "Приложение установлено"
            fi
        fi
        ;;
    3)
        print_step "Сборка App Bundle..."
        flutter build appbundle --release
        print_success "App Bundle создан:"
        ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print "  " $9 " (" $5 ")"}'
        ;;
    *)
        print_error "Неверный выбор!"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   СБОРКА ЗАВЕРШЕНА!                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Показать размер файлов
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "📦 Размер APK: $SIZE"
fi

# Советы
echo ""
echo "💡 Советы:"
echo "  - Логи: flutter logs"
echo "  - Установка: flutter install"
echo "  - Устройства: flutter devices"

exit 0

