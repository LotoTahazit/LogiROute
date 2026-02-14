# Итоговые исправления перед деплоем

## 1. ✅ Скидка в процентах
- Изменено поле скидки с абсолютной суммы (₪) на проценты (%)
- В PDF показывается: "הנחה 10%: -₪1000"
- Расчёт: `discountAmount = totalBeforeDiscount * (discount / 100)`

## 2. ✅ Таблица товаров в счёте
- Заголовок "כמות" → "קרטונים" (количество → коробки)
- Отображается только название товара (например, "כוס 218")

## 3. ✅ Нумерация точек в маршруте
- Первая точка теперь №1 (было №0)
- `orderInRoute` начинается с 1

## 4. ✅ Удаление маршрутов
- Исправлено кеширование `_lastNonEmptyRoutes`
- Теперь кеш обновляется всегда, даже когда маршруты пусты
- Отменённые маршруты корректно исчезают с экрана

## 5. ✅ ETA (расчётное время прибытия)
- Добавлено поле `eta` в модель `DeliveryPoint`
- ETA отображается в списке маршрутов у диспетчера
- Формат: "ETA: 15 min" под адресом точки

## 6. ✅ Исправление ошибок
- Добавлен параметр `id` в `Invoice.copyWith()`
- Исправлена ошибка с пустым ID при печати счёта
- Добавлена проверка `invoice.id.isNotEmpty` перед обновлением счётчиков

## 7. ✅ Firestore правила
- Добавлены правила для коллекций:
  - `prices` (цены)
  - `invoices` (счета)
  - `counters` (счётчики)
  - `daily_summaries` (дневные сводки)
  - `delivery_summaries` (сводки доставок)

## 8. ✅ Firestore индексы
- Убран ненужный индекс `status + deliveryDate`
- Оставлены только необходимые индексы

## 9. ✅ StreamBuilder оптимизации
- `inventory_list_view.dart` - конвертирован в StatefulWidget
- `inventory_service.dart` - добавлен limit(200)
- Предотвращены утечки подписок

## Файлы изменены:
1. `lib/models/invoice.dart` - скидка в процентах, copyWith с id
2. `lib/models/delivery_point.dart` - добавлено поле eta
3. `lib/services/invoice_print_service.dart` - таблица с קרטונים, скидка в %
4. `lib/services/route_service.dart` - orderInRoute начинается с 1
5. `lib/screens/dispatcher/create_invoice_dialog.dart` - скидка в %, исправлен ID
6. `lib/screens/dispatcher/dispatcher_dashboard.dart` - кеш маршрутов, отображение ETA
7. `lib/screens/warehouse/widgets/inventory_list_view.dart` - StatefulWidget
8. `lib/screens/warehouse/dialogs/box_types_manager_dialog.dart` - nullable volumeMl
9. `lib/services/inventory_service.dart` - limit на stream
10. `firestore.rules` - добавлены правила для новых коллекций
11. `firestore_indexes.json` - убран ненужный индекс

## Готово к деплою ✅
