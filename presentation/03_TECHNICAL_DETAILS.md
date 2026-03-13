# 🔧 Технические детали

## Технологический стек

### Frontend
- **Flutter 3.x** - кроссплатформенный фреймворк
- **Dart** - язык программирования
- **Provider** - управление состоянием
- **Material Design** - дизайн-система

### Backend
- **Firebase Authentication** - авторизация пользователей
- **Cloud Firestore** - NoSQL база данных
- **Firebase Storage** - хранение файлов
- **Firebase Hosting** - хостинг веб-версии
- **Firebase Cloud Messaging** - push-уведомления
- **Firebase App Check** - защита от злоупотребления API

### Карты и навигация
- **Google Maps Flutter** - отображение карт
- **Google Maps API** - маршрутизация
- **Geolocator** - GPS-позиционирование
- **Geocoding** - преобразование адресов в координаты

### Дополнительные библиотеки
- **flutter_local_notifications** - локальные уведомления
- **android_alarm_manager_plus** - фоновые задачи
- **shared_preferences** - локальное хранилище
- **pdf** - генерация PDF
- **printing** - печать документов
- **csv** - экспорт в CSV
- **url_launcher** - открытие внешних ссылок

---

## Архитектура приложения

### Структура проекта

```
lib/
├── config/              # Конфигурация
│   ├── api_constants.dart
│   └── app_config.dart
├── l10n/                # Локализация
│   ├── app_en.arb       # Английский
│   ├── app_ru.arb       # Русский
│   └── app_he.arb       # Иврит
├── models/              # Модели данных
│   ├── user_model.dart
│   ├── delivery_point.dart
│   ├── route_model.dart
│   ├── invoice.dart
│   └── ...
├── screens/             # Экраны
│   ├── auth/            # Авторизация
│   ├── admin/           # Админ панель
│   ├── dispatcher/      # Диспетчер
│   ├── driver/          # Водитель
│   ├── warehouse/       # Кладовщик
│   └── shared/          # Общие экраны
├── services/            # Бизнес-логика
│   ├── auth_service.dart
│   ├── route_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── ...
├── widgets/             # Переиспользуемые виджеты
│   ├── delivery_map_widget.dart
│   ├── navigation_widget.dart
│   └── ...
├── utils/               # Утилиты
│   ├── distance_calculator.dart
│   ├── time_formatter.dart
│   └── ...
└── main.dart            # Точка входа
```

---

## Модели данных

### 1. UserModel (Пользователь)
```dart
{
  uid: String,              // Уникальный ID
  email: String,            // Email
  name: String,             // Имя
  role: String,             // Роль (admin/dispatcher/driver/warehouse_keeper)
  companyId: String?,       // ID компании
  palletCapacity: int?,     // Вместимость паллет (для водителей)
  truckWeight: double?,     // Вес грузовика (для водителей)
  vehicleNumber: String?,   // Номер машины (для водителей)
  isSuperAdmin: bool,       // Флаг суперадмина
  isDriver: bool,           // Флаг водителя
  isAdmin: bool             // Флаг админа
}
```

### 2. DeliveryPoint (Точка доставки)
```dart
{
  id: String,               // Уникальный ID
  clientName: String,       // Имя клиента
  address: String,          // Адрес
  latitude: double,         // Широта
  longitude: double,        // Долгота
  status: String,           // Статус (pending/assigned/in_progress/completed/cancelled)
  driverId: String?,        // ID водителя
  driverName: String?,      // Имя водителя
  driverCapacity: int?,     // Вместимость водителя
  routeId: String?,         // ID маршрута
  orderInRoute: int?,       // Порядок в маршруте
  eta: String?,             // Расчетное время прибытия
  urgency: String,          // Срочность (normal/urgent)
  pallets: int,             // Количество паллет
  createdAt: Timestamp,     // Дата создания
  updatedAt: Timestamp      // Дата обновления
}
```

### 3. Invoice (Счет)
```dart
{
  id: String,               // Уникальный ID
  invoiceNumber: String,    // Номер счета
  clientName: String,       // Имя клиента
  clientAddress: String,    // Адрес клиента
  items: List<InvoiceItem>, // Товары
  totalAmount: double,      // Общая сумма
  status: String,           // Статус (draft/sent/paid/cancelled)
  createdAt: Timestamp,     // Дата создания
  driverId: String,         // ID водителя
  driverName: String        // Имя водителя
}
```

### 4. InventoryItem (Товар на складе)
```dart
{
  id: String,               // Уникальный ID
  name: String,             // Название
  quantity: int,            // Количество
  unit: String,             // Единица измерения
  minQuantity: int?,        // Минимальное количество
  lastUpdated: Timestamp    // Последнее обновление
}
```

---

## Ключевые сервисы

### 1. AuthService (Авторизация)
**Функции:**
- Вход/выход пользователей
- Создание новых пользователей
- Обновление данных пользователей
- Удаление пользователей
- Сброс пароля
- Управление ролями
- Режим "View As" для админов

**Методы:**
```dart
Future<String?> signIn(String email, String password)
Future<void> signOut()
Future<String?> createUser({...})
Future<String?> updateUser({...})
Future<String?> deleteUser(String uid)
Future<List<UserModel>> getAllUsers()
void setViewAsRole(String? role)
```

### 2. RouteService (Управление маршрутами)
**Функции:**
- Создание оптимизированных маршрутов
- Автоматическое распределение по водителям
- Обновление статусов точек
- Изменение порядка точек
- Отмена маршрутов
- Смена водителя

**Методы:**
```dart
Future<void> createOptimizedRoute(...)
Future<void> autoDistributePalletsToDrivers(...)
Future<void> updatePointStatus(String pointId, String status)
Future<void> cancelRoute(String driverId, String? routeId)
Future<void> changeRouteDriver(...)
Stream<List<DeliveryPoint>> getAllPendingPoints()
Stream<List<DeliveryPoint>> getAllRoutes()
Stream<List<DeliveryPoint>> getDriverPoints(String driverId)
```

### 3. LocationService (GPS-трекинг)
**Функции:**
- Отслеживание позиции водителя
- Обновление позиции в Firestore
- Автоматическое завершение точек
- Оптимизация батареи

**Методы:**
```dart
void startTracking(String driverId, Function(double, double) onUpdate)
void stopTracking()
void checkPointCompletion(DeliveryPoint point, double lat, double lon, Function callback)
```

### 4. NotificationService (Уведомления)
**Функции:**
- Локальные уведомления
- Ежедневные напоминания
- Уведомления о завершении точек
- Push-уведомления (Firebase)

**Методы:**
```dart
Future<void> initialize()
Future<void> scheduleDailyWorkReminder()
Future<void> showNotification(String title, String body)
```

### 5. PrintService (Печать)
**Функции:**
- Печать маршрутов
- Генерация PDF
- Печать счетов (חשבונית)
- Экспорт в CSV

**Методы:**
```dart
static Future<void> printRoute({required UserModel driver, required List<DeliveryPoint> points})
static Future<void> printInvoice(Invoice invoice, {required InvoiceCopyType copyType})
```

---

## База данных Firestore

### Коллекции:

#### 1. users
```
users/
  {userId}/
    - email: string
    - name: string
    - role: string
    - companyId: string
    - palletCapacity: number
    - truckWeight: number
    - vehicleNumber: string
    - isSuperAdmin: boolean
```

#### 2. delivery_points
```
delivery_points/
  {pointId}/
    - clientName: string
    - address: string
    - latitude: number
    - longitude: number
    - status: string
    - driverId: string
    - routeId: string
    - orderInRoute: number
    - eta: string
    - urgency: string
    - pallets: number
    - createdAt: timestamp
    - updatedAt: timestamp
```

#### 3. driver_locations
```
driver_locations/
  {driverId}/
    - latitude: number
    - longitude: number
    - timestamp: timestamp
    - isActive: boolean
```

#### 4. invoices
```
invoices/
  {invoiceId}/
    - invoiceNumber: string
    - clientName: string
    - items: array
    - totalAmount: number
    - status: string
    - createdAt: timestamp
    - driverId: string
```

#### 5. inventory
```
inventory/
  {itemId}/
    - name: string
    - quantity: number
    - unit: string
    - minQuantity: number
    - lastUpdated: timestamp
```

#### 6. settings
```
settings/
  warehouse_location/
    - latitude: number
    - longitude: number
    - updatedAt: timestamp
    - updatedBy: string
```

### Индексы Firestore:
```
delivery_points:
  - status + driverId + orderInRoute
  - driverId + status + createdAt
  - routeId + orderInRoute
```

---

## Безопасность

### Firebase Security Rules

#### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Только авторизованные пользователи
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Пользователи могут читать только свои данные
    match /users/{userId} {
      allow read: if request.auth.uid == userId 
                  || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Водители могут обновлять только свои точки
    match /delivery_points/{pointId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'dispatcher'];
      allow update: if request.auth.uid == resource.data.driverId;
    }
  }
}
```

### Firebase App Check
- Защита от злоупотребления API
- Проверка подлинности приложения
- Ограничение доступа к Firebase

### Google Maps API Restrictions
- Ограничение по Bundle ID: `com.logiroute.app`
- Ограничение по HTTP Referrer для Web
- API Key защищен

---

## Оптимизация

### Производительность
- **Кеширование** - кеш маршрутов для предотвращения мерцания
- **Lazy Loading** - загрузка данных по требованию
- **Stream Builders** - реактивное обновление UI
- **Debouncing** - ограничение частоты обновлений GPS

### Батарея (для водителей)
- GPS-трекинг только в рабочее время (08:00-18:00)
- Обновление позиции каждые 30 секунд
- Автоматическая остановка трекинга вне рабочего времени

### Сеть
- Оптимизация запросов к Firestore
- Использование индексов
- Batch операции для множественных обновлений

---

## Локализация

### Поддерживаемые языки:
1. **Иврит (עברית)** - основной язык
2. **Русский** - полная поддержка
3. **English** - полная поддержка

### Файлы локализации:
- `lib/l10n/app_he.arb` - ~150 ключей
- `lib/l10n/app_ru.arb` - ~150 ключей
- `lib/l10n/app_en.arb` - ~150 ключей

### Примеры ключей:
```json
{
  "appTitle": "LogiRoute",
  "login": "Вход",
  "email": "Email",
  "password": "Пароль",
  "dispatcher": "Диспетчер",
  "driver": "Водитель",
  "admin": "Администратор",
  "deliveryPoints": "Точки доставки",
  "routes": "Маршруты",
  "map": "Карта",
  ...
}
```

---

## Сборка и развертывание

### Android APK
```bash
# Сборка release APK
flutter build apk --release

# Результат
build/app/outputs/flutter-apk/app-release.apk
```

### Web
```bash
# Сборка web версии
flutter build web --release

# Развертывание на Firebase
firebase deploy --only hosting
```

### Конфигурация
- **Bundle ID**: `com.logiroute.app`
- **Минимальная версия Android**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)

### Keystore (для подписи APK)
- Файл: `android/release-keystore.jks`
- Конфигурация: `android/key.properties`

---

## Мониторинг и отладка

### Логирование
```dart
print('🚛 [Driver] Loaded ${points.length} points');
print('📍 [GPS] Position updated: $lat, $lon');
print('✅ [Route] Route created successfully');
print('❌ [Error] Failed to load users: $error');
```

### Firebase Analytics
- Отслеживание событий
- Статистика использования
- Crash reporting

---

**Следующий раздел**: [Рабочие процессы](04_WORKFLOWS.md)
