# Настройка автоматической архивации

## Что делает система архивации

1. **Автоматическая архивация истории инвентаря**
   - Запускается: 1-го числа каждого месяца в 02:00 (время Израиля)
   - Архивирует: записи старше 3 месяцев
   - Сохраняет в: `archives/inventory_history/`

2. **Автоматическая архивация завершенных заказов**
   - Запускается: 1-го числа каждого месяца в 03:00 (время Израиля)
   - Архивирует: заказы завершенные более месяца назад
   - Сохраняет в: `archives/orders/`

3. **Очистка старых архивированных записей**
   - Запускается: 15-го числа каждого месяца в 02:00 (время Израиля)
   - Удаляет: записи, архивированные более 6 месяцев назад
   - Данные остаются в Firebase Storage

## Установка Cloud Functions

### 1. Установить Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Войти в Firebase

```bash
firebase login
```

### 3. Инициализировать Functions (если еще не сделано)

```bash
firebase init functions
```

Выбрать:
- Язык: JavaScript
- ESLint: No (или Yes, если хотите)
- Установить зависимости: Yes

### 4. Установить зависимости

```bash
cd functions
npm install
```

### 5. Развернуть функции

```bash
firebase deploy --only functions
```

## Проверка работы

### Просмотр логов

```bash
firebase functions:log
```

### Тестирование локально

```bash
cd functions
npm run serve
```

### Ручной запуск функции (для теста)

В Firebase Console:
1. Перейти в Functions
2. Выбрать функцию (например, `archiveInventoryHistory`)
3. Нажать "Test function"

## Мониторинг

### В Firebase Console

1. Перейти в **Functions** → **Dashboard**
2. Посмотреть статистику выполнения
3. Проверить логи ошибок

### В приложении

1. Админ → Иконка "архив"
2. Посмотреть статистику архивов
3. Проверить список созданных архивов

## Стоимость

### Cloud Functions (бесплатный план Spark)
- 2 миллиона вызовов/месяц
- 400,000 GB-секунд
- 200,000 CPU-секунд

**Наше использование:**
- 3 функции × 1 раз в месяц = 3 вызова/месяц ✅
- Каждая функция работает ~10-30 секунд
- **Полностью бесплатно!**

### Firebase Storage
- 5 GB бесплатно
- $0.026 за GB/месяц после лимита

**Наше использование:**
- ~10-20 MB в месяц
- **Хватит на годы бесплатно!**

## Настройка расписания

Если нужно изменить расписание, отредактируйте в `functions/index.js`:

```javascript
// Формат: 'минута час день месяц день_недели'
.schedule('0 2 1 * *')  // 02:00 1-го числа каждого месяца
```

Примеры:
- `'0 2 * * *'` - каждый день в 02:00
- `'0 2 * * 0'` - каждое воскресенье в 02:00
- `'0 2 1,15 * *'` - 1-го и 15-го числа в 02:00

## Восстановление данных

Если нужно восстановить данные из архива:

1. Админ → Архивы
2. Найти нужный архив
3. Нажать "Восстановить" (функция в разработке)

Или вручную:
1. Скачать JSON файл из Firebase Storage
2. Импортировать через Firestore Console

## Безопасность

### Правила Storage

Добавьте в `storage.rules`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Архивы доступны только админам
    match /archives/{allPaths=**} {
      allow read: if request.auth != null && 
                     request.auth.token.role == 'admin';
      allow write: if false; // Только через Cloud Functions
    }
  }
}
```

### Правила Firestore

Добавьте поле `archived` в правила:

```javascript
match /inventory_history/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
                  request.auth.token.role in ['admin', 'warehouse'];
}

match /delivery_points/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
                  request.auth.token.role in ['admin', 'dispatcher'];
}
```

## Мониторинг и алерты

### Настроить email уведомления

В Firebase Console:
1. Functions → Logs
2. Настроить алерты на ошибки
3. Указать email для уведомлений

### Проверка здоровья системы

Рекомендуется проверять раз в месяц:
1. Размер базы Firestore
2. Размер Storage
3. Логи Cloud Functions
4. Количество архивов

## Troubleshooting

### Функция не запускается

1. Проверить логи: `firebase functions:log`
2. Проверить биллинг (нужен Blaze план для scheduled functions)
3. Проверить часовой пояс

### Ошибка "Insufficient permissions"

1. Проверить Service Account permissions
2. Убедиться что Storage bucket существует
3. Проверить правила Storage

### Архивы не создаются

1. Проверить что есть данные для архивации
2. Проверить поле `archived` в документах (должно быть `false`)
3. Проверить даты в документах

## Обновление функций

После изменения кода:

```bash
cd functions
firebase deploy --only functions
```

Или конкретную функцию:

```bash
firebase deploy --only functions:archiveInventoryHistory
```

## Удаление функций

Если нужно удалить функцию:

```bash
firebase functions:delete archiveInventoryHistory
```

## Контакты

При проблемах проверьте:
1. Firebase Console → Functions → Logs
2. Firebase Console → Storage → archives/
3. Firestore → inventory_history (поле `archived`)
