# 🚚 LogiRoute - Система управления логистикой

Система управления грузоперевозками для Y.C. Plast с поддержкой маршрутизации, отслеживания водителей и управления складом.

---

## 📱 Платформы

- ✅ **Android** (APK)
- ✅ **Web** (Firebase Hosting)
- ⏳ **iOS** (в разработке)

---

## 🚀 Быстрый старт

### Требования:
- Flutter SDK 3.x
- Firebase проект
- Google Maps API ключ

### Установка:

1. **Клонировать репозиторий**:
   ```bash
   git clone https://github.com/LotoTahazit/LogiROute.git
   cd LogiRoute2
   ```

2. **Установить зависимости**:
   ```bash
   flutter pub get
   ```

3. **Настроить переменные окружения**:
   - Скопировать `.env.example` в `.env`
   - Добавить Google Maps API ключи

4. **Запустить приложение**:
   ```bash
   flutter run
   ```

---

## � Сборка

### Android APK:
```bash
# Используйте универсальный скрипт
build.bat

# Или напрямую
flutter build apk --release
```

APK будет в: `build\app\outputs\flutter-apk\app-release.apk`

### Web:
```bash
flutter build web --release
firebase deploy
```

---

## 📚 Документация

### Архитектура и продукт:
- **[docs/project-structure.md](docs/project-structure.md)** - Техническая структура (факты, модули, тарифы, ограничения)
- **[docs/competitive-analysis.md](docs/competitive-analysis.md)** - Позиционирование и конкурентный анализ
- **[docs/computerized-warehouse.md](docs/computerized-warehouse.md)** - מחסן ממוחשב (штрихкоды)

### Настройка:
- **[SETUP.md](SETUP.md)** - Полная инструкция по настройке
- **[QUICK_START.md](QUICK_START.md)** - Быстрый старт
- **[QUICKSTART_RU.md](QUICKSTART_RU.md)** - Быстрый старт (русский)

### Сборка и развертывание:
- **[ANDROID_BUILD_GUIDE.md](ANDROID_BUILD_GUIDE.md)** - Сборка Android APK
- **[BUILD_README.md](BUILD_README.md)** - Общая информация о сборке

### Firebase и Google:
- **[FIREBASE_INDEX_SETUP.md](FIREBASE_INDEX_SETUP.md)** - Настройка индексов Firestore
- **[GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md)** - Настройка Google Maps API

### Безопасность:
- **[RELEASE_KEYSTORE_INFO.md](RELEASE_KEYSTORE_INFO.md)** - Информация о release keystore
- **[SECURITY_AND_REFACTORING_AUDIT.md](SECURITY_AND_REFACTORING_AUDIT.md)** - Аудит безопасности
- **[SECURITY_IMPROVEMENTS_COMPLETED.md](SECURITY_IMPROVEMENTS_COMPLETED.md)** - Выполненные улучшения

### Функциональность:
- **[FEATURES.md](FEATURES.md)** - Список функций
- **[CHANGELOG.md](CHANGELOG.md)** - История изменений
- **[WAREHOUSE_KEEPER_GUIDE.md](WAREHOUSE_KEEPER_GUIDE.md)** - Руководство для кладовщика

### Специальные темы:
- **[ISRAELI_TAX_COMPLIANCE.md](ISRAELI_TAX_COMPLIANCE.md)** - Соответствие налоговому законодательству Израиля
- **[FIRESTORE_OPTIMIZATION_GUIDE.md](FIRESTORE_OPTIMIZATION_GUIDE.md)** - Оптимизация Firestore
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Руководство по миграции

---

## 👥 Роли пользователей

- **Super Admin** - Полный доступ ко всем функциям
- **Admin** - Управление пользователями и настройками
- **Dispatcher** - Создание маршрутов, управление доставками
- **Driver** - Просмотр и выполнение маршрутов
- **Warehouse Keeper** - Управление складом и инвентарем

---

## 🔑 Основные функции

### Для диспетчера:
- ✅ Создание и редактирование точек доставки
- ✅ Автоматическое распределение по водителям
- ✅ Расчет ETA (время прибытия)
- ✅ Drag & Drop переупорядочивание точек
- ✅ Визуализация маршрутов на карте
- ✅ Печать маршрутов
- ✅ Управление счетами

### Для водителя:
- ✅ Просмотр назначенных маршрутов
- ✅ Навигация к точкам доставки
- ✅ Отметка выполненных доставок
- ✅ Отслеживание прогресса

### Для кладовщика:
- ✅ Управление инвентарем
- ✅ Типы коробок и товаров
- ✅ Отслеживание остатков

### Для администратора:
- ✅ Управление пользователями
- ✅ Настройка ролей и прав
- ✅ Просмотр аналитики
- ✅ Настройка системы

---

## 🔒 Безопасность

- ✅ Firebase Authentication
- ✅ Firebase App Check (защита от злоупотребления API)
- ✅ Google Maps API restrictions по Bundle ID
- ✅ Release keystore для production
- ✅ Firestore Security Rules
- ✅ Обфускация кода в release builds

---

## 🌍 Локализация

Поддерживаемые языки:
- 🇮🇱 עברית (Hebrew) - основной
- 🇷🇺 Русский (Russian)
- 🇬🇧 English

---

## 📦 Bundle ID / Package Name

```
com.logiroute.app
```

---

## 🔧 Технологии

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Storage, Hosting)
- **Maps**: Google Maps API
- **State Management**: Provider
- **Локализация**: flutter_localizations

---

## 📊 Статус проекта

- **Версия**: 1.2.0
- **Статус**: ✅ Production Ready
- **Последнее обновление**: 14 февраля 2026
- **Уровень безопасности**: A- (отлично)

---

## 🐛 Известные ограничения

1. Ctrl+scroll для зума на веб-карте (ограничение Flutter Web plugin)
2. iOS версия в разработке

---

## 📞 Поддержка

Для вопросов и поддержки обращайтесь к документации в папке проекта.

---

## 📄 Лицензия

Proprietary - Y.C. Plast

---

**Разработано с ❤️ для Y.C. Plast**
