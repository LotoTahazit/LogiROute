#!/bin/bash

echo "========================================"
echo "  Проверка безопасности LogiRoute"
echo "========================================"
echo ""

# Проверка 1: .env не в Git
echo "[1/4] Проверка .env в Git..."
if git ls-files | grep -q "^.env$"; then
    echo "[FAIL] .env файл найден в Git! УДАЛИТЕ ЕГО НЕМЕДЛЕННО!"
    echo "       Выполните: git rm --cached .env"
else
    echo "[OK] .env не в Git"
fi
echo ""

# Проверка 2: .env в .gitignore
echo "[2/4] Проверка .gitignore..."
if grep -q "^\.env$" .gitignore; then
    echo "[OK] .env в .gitignore"
else
    echo "[FAIL] .env НЕ в .gitignore! Добавьте его!"
    echo "       Выполните: echo '.env' >> .gitignore"
fi
echo ""

# Проверка 3: .env существует локально
echo "[3/4] Проверка локального .env..."
if [ -f .env ]; then
    echo "[OK] .env файл существует локально"
    
    # Проверка на placeholder ключи
    if grep -q "your_web_api_key_here" .env; then
        echo "[WARN] .env содержит placeholder ключи!"
        echo "       Замените их на реальные ключи из Google Cloud Console"
    else
        echo "[OK] .env содержит реальные ключи"
    fi
else
    echo "[FAIL] .env файл НЕ существует!"
    echo "       Скопируйте: cp .env.example .env"
    echo "       И добавьте реальные ключи"
fi
echo ""

# Проверка 4: firebase_options.dart
echo "[4/4] Проверка firebase_options.dart..."
if [ -f lib/firebase_options.dart ]; then
    echo "[INFO] firebase_options.dart существует"
    echo "       Firebase ключи для клиентских приложений обычно не секретны"
    echo "       НО убедитесь что настроены Firebase Security Rules!"
else
    echo "[WARN] firebase_options.dart не найден"
fi
echo ""

echo "========================================"
echo "  Проверка завершена"
echo "========================================"
echo ""
echo "Рекомендации:"
echo "1. Убедитесь что .env НЕ в Git"
echo "2. Настройте ограничения для API ключей в Google Cloud Console"
echo "3. Проверьте Firebase Security Rules"
echo "4. Настройте квоты и алерты"
echo ""
echo "Подробнее: см. SECURITY_ALERT.md"
echo ""
