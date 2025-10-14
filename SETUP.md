# Инструкция по настройке LogiRoute

## 1. Firebase Setup

### 1.1 Создать проект Firebase
1. Перейти на https://console.firebase.google.com/
2. Создать новый проект "LogiRoute"
3. Включить Authentication (Email/Password)
4. Создать базу данных Firestore

### 1.2 Настроить Firebase для Flutter
```bash
# Установить Firebase CLI
npm install -g firebase-tools

# Войти в Firebase
firebase login

# Настроить FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

### 1.3 Структура Firestore

**Коллекция: users**
```
{
  uid: string,
  email: string,
  name: string,
  role: 'admin' | 'dispatcher' | 'driver',
  palletCapacity?: number
}
```

**Коллекция: delivery_points**
```
{
  address: string,
  latitude: number,
  longitude: number,
  clientName: string,
  openingTime?: timestamp,
  urgency: number (1-5),
  pallets: number,
  status: 'pending' | 'assigned' | 'in_progress' | 'completed' | 'cancelled',
  arrivedAt?: timestamp,
  completedAt?: timestamp,
  orderInRoute: number
}
```

**Коллекция: routes**
```
{
  driverId: string,
  driverName: string,
  pointIds: string[],
  createdAt: timestamp,
  status: 'active' | 'completed',
  currentPointId?: string
}
```

### 1.4 Создать начальных пользователей

Через Firebase Console Authentication создайте:

**Админ:**
- Email: admin@logiroute.com
- Password: Admin123!

**Диспетчеры:**
- dispatcher1@logiroute.com
- dispatcher2@logiroute.com

**Водители:**
- amram@logiroute.com (14 палет)
- evgeny@logiroute.com (13 палет)
- yuda@logiroute.com (11 палет)
- roni@logiroute.com (9 палет)

Затем в Firestore добавить документы в коллекцию users с соответствующими данными.

## 2. Google Maps API

### 2.1 Получить API ключи
1. Перейти в https://console.cloud.google.com/
2. Создать новый проект или выбрать существующий
3. Включить APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API
   - Directions API
   - Geocoding API

4. Создать API ключи:
   - Android API Key
   - iOS API Key
   - Web API Key

### 2.2 Настроить ключи

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

**Web:** `web/index.html`
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY"></script>
```

## 3. Установка зависимостей

```bash
flutter pub get
```

## 4. Запуск

### Android
```bash
flutter run -d android
```

### Web
```bash
flutter run -d chrome
```

## 5. Правила безопасности Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /delivery_points/{pointId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'dispatcher' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'dispatcher' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## 6. Тестирование

1. Войти как admin@logiroute.com
2. Проверить переключение между ролями
3. Войти как диспетчер
4. Добавить точки доставки
5. Создать маршрут для водителя
6. Войти как водитель
7. Проверить отображение маршрута на карте
8. Тестировать геолокацию (приблизиться к точке)

## Примечания

- Для продакшена используйте реальные адреса в Израиле
- Настройте правильные часовые пояса
- Добавьте обработку ошибок сети
- Рассмотрите добавление push-уведомлений

