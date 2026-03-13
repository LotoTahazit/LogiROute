# 🔥 Настройка Firestore индекса

## Проблема
Ошибка: `The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/logiroute-app/firestore/indexes?create_composite=...`

## Решение

### Вариант 1: Автоматическое создание (рекомендуется)
1. Откройте ссылку из ошибки в браузере
2. Нажмите "Create Index" 
3. Дождитесь создания индекса (2-3 минуты)

### Вариант 2: Ручное создание
1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект `logiroute-app`
3. Перейдите в **Firestore Database** → **Indexes**
4. Нажмите **Create Index**
5. Настройте индекс:
   - **Collection Group ID**: `delivery_points`
   - **Fields**:
     - `driverId` (Ascending)
     - `orderInRoute` (Ascending) 
     - `__name__` (Ascending)
6. Нажмите **Create**

### Вариант 3: Через Firebase CLI
```bash
firebase deploy --only firestore:indexes
```

## Проверка
После создания индекса ошибка должна исчезнуть, и запросы к `delivery_points` будут работать корректно.

## Техническая информация
Индекс требуется для запроса:
```dart
.where('driverId', isEqualTo: driverId)
.orderBy('orderInRoute')
.orderBy('__name__')
```
