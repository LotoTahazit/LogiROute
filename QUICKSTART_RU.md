# 🚀 Быстрый старт LogiRoute

## Что реализовано

Полнофункциональная система управления логистикой грузоперевозок с:
- ✅ 3 ролями (Админ, Диспетчер, Водитель)
- ✅ Автоматической маршрутизацией с учетом всех параметров
- ✅ Геолокацией и автозавершением точек (≤50м, ≥2мин)
- ✅ Мультиязычностью (Hebrew RTL, Русский, English)
- ✅ Аналитикой для администратора
- ✅ Android + Web поддержкой

## Шаг 1: Установка Flutter

Если Flutter не установлен:
```bash
# Скачать с https://flutter.dev
# Добавить в PATH
flutter doctor
```

## Шаг 2: Установка зависимостей

```bash
cd LogiRoute
flutter pub get
```

## Шаг 3: Firebase настройка

### 3.1 Создать проект Firebase
1. Перейти на https://console.firebase.google.com/
2. Нажать "Добавить проект" → Назвать "LogiRoute"
3. Отключить Google Analytics (не обязательно)

### 3.2 Включить Authentication
1. В меню слева: Authentication
2. Нажать "Начать"
3. Включить "Email/Password"
4. Создать пользователей:
   - admin@logiroute.com / Admin123!
   - dispatcher1@logiroute.com / Disp123!
   - amram@logiroute.com / Driver123!
   - evgeny@logiroute.com / Driver123!
   - yuda@logiroute.com / Driver123!
   - roni@logiroute.com / Driver123!

### 3.3 Включить Firestore
1. В меню слева: Firestore Database
2. Нажать "Создать базу данных"
3. Выбрать "Тестовый режим" (временно)
4. Выбрать регион (europe-west)

### 3.4 Настроить FlutterFire

```bash
# Установить Firebase CLI
npm install -g firebase-tools

# Войти
firebase login

# Установить FlutterFire CLI
dart pub global activate flutterfire_cli

# Настроить проект
flutterfire configure
# Выбрать проект LogiRoute
# Выбрать платформы: android, web, ios
```

Это автоматически создаст `lib/firebase_options.dart` с настройками.

### 3.5 Создать документы пользователей в Firestore

В Firestore Console:
1. Создать коллекцию `users`
2. Добавить документы (ID = UID пользователя из Authentication):

**Админ:**
```json
{
  "email": "admin@logiroute.com",
  "name": "Администратор",
  "role": "admin"
}
```

**Диспетчер:**
```json
{
  "email": "dispatcher1@logiroute.com",
  "name": "Диспетчер 1",
  "role": "dispatcher"
}
```

**Водители:**
```json
{
  "email": "amram@logiroute.com",
  "name": "Амрам",
  "role": "driver",
  "palletCapacity": 14
}
```
```json
{
  "email": "evgeny@logiroute.com",
  "name": "Евгений",
  "role": "driver",
  "palletCapacity": 13
}
```
```json
{
  "email": "yuda@logiroute.com",
  "name": "Юда",
  "role": "driver",
  "palletCapacity": 11
}
```
```json
{
  "email": "roni@logiroute.com",
  "name": "Рони",
  "role": "driver",
  "palletCapacity": 9
}
```

## Шаг 4: Google Maps API

### 4.1 Получить ключи API
1. Перейти https://console.cloud.google.com/
2. Выбрать проект Firebase или создать новый
3. APIs & Services → Library
4. Включить:
   - Maps SDK for Android
   - Maps JavaScript API
   - Directions API
   - Geocoding API

5. APIs & Services → Credentials → Create Credentials → API Key
6. Создать 2 ключа:
   - Android (с ограничением по package name: com.logiroute.app)
   - Web (с ограничением по HTTP referrers)

### 4.2 Добавить ключи в проект

**Android:** `android/app/src/main/AndroidManifest.xml`
Замените `YOUR_GOOGLE_MAPS_API_KEY` на ваш Android ключ.

**Web:** `web/index.html`
Замените `YOUR_GOOGLE_MAPS_API_KEY` на ваш Web ключ.

## Шаг 5: Firestore Security Rules

В Firestore Console → Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isDispatcher() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'dispatcher';
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    match /delivery_points/{pointId} {
      allow read: if request.auth != null;
      allow write: if isAdmin() || isDispatcher();
    }
    
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if isAdmin() || isDispatcher();
    }
  }
}
```

## Шаг 6: Запуск

### Web
```bash
flutter run -d chrome
```

### Android (подключить устройство или эмулятор)
```bash
flutter run -d android
```

### Сборка для продакшена

**Android APK:**
```bash
flutter build apk --release
# APK будет в: build/app/outputs/flutter-apk/app-release.apk
```

**Web:**
```bash
flutter build web --release
# Файлы в: build/web/
# Можно деплоить на Firebase Hosting, Vercel, Netlify и т.д.
```

## Тестирование

### Сценарий 1: Администратор
1. Войти: admin@logiroute.com / Admin123!
2. Увидеть список пользователей
3. Переключить "Просмотр как" на Диспетчер → увидеть интерфейс диспетчера
4. Переключить на Водитель → увидеть интерфейс водителя
5. Нажать иконку аналитики → увидеть статистику

### Сценарий 2: Диспетчер
1. Войти: dispatcher1@logiroute.com / Disp123!
2. Нажать "+" → Добавить точку доставки:
   - Клиент: "Магазин Шалом"
   - Адрес: "Tel Aviv, Rothschild Boulevard 1"
   - Палеты: 5
   - Срочность: 3
3. Добавить еще 2-3 точки
4. Нажать "Создать маршрут"
5. Выбрать водителя (например, Амрам)
6. Маршрут создан!

### Сценарий 3: Водитель
1. Войти: amram@logiroute.com / Driver123!
2. Увидеть карту с маркерами точек
3. Увидеть список точек (активная выделена зеленым)
4. Если включить геолокацию и приблизиться к точке → через 2 минуты автозавершение

## Структура проекта

```
LogiRoute/
├── lib/
│   ├── constants/          # Константы
│   ├── l10n/              # Локализация (he, ru, en)
│   ├── models/            # Модели данных
│   ├── screens/
│   │   ├── admin/         # Админ панель + аналитика
│   │   ├── auth/          # Логин
│   │   ├── dispatcher/    # Диспетчер панель
│   │   └── driver/        # Водитель панель
│   ├── services/          # Бизнес-логика
│   │   ├── auth_service.dart
│   │   ├── route_service.dart
│   │   ├── location_service.dart
│   │   └── locale_service.dart
│   ├── utils/             # Утилиты
│   └── widgets/           # Виджеты
├── android/               # Android конфигурация
├── ios/                   # iOS конфигурация
├── web/                   # Web конфигурация
├── FEATURES.md           # Описание фич
├── SETUP.md              # Детальная инструкция
└── README.md             # Общее описание
```

## Частые проблемы

### 1. "Firebase not configured"
Запустите `flutterfire configure` заново.

### 2. "Google Maps не отображается"
Проверьте, что API ключи добавлены и APIs включены в Google Cloud Console.

### 3. "Геолокация не работает"
- Android: Дать разрешение на локацию в настройках приложения
- Web: Разрешить геолокацию в браузере

### 4. "Users collection is empty"
Вручную создайте документы в Firestore как описано в Шаге 3.5.

## Поддержка

Все основные требования реализованы и протестированы.
Для деталей смотрите FEATURES.md и SETUP.md.

**Важно:** Замените все `YOUR_*_API_KEY` на реальные ключи!

