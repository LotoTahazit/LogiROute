# 🏢 Миграция данных для изоляции компаний

## Проблема
Товары (box_types) и другие данные не изолированы по компаниям. Все компании видят товары друг друга.

## Решение
Добавлен `companyId` к модели `BoxType` и сервису `BoxTypeService`.

---

## ✅ Что уже сделано

### 1. Модель BoxType
- ✅ Добавлено поле `companyId: String`
- ✅ Обновлены методы `toMap()` и `fromMap()`

### 2. Сервис BoxTypeService  
- ✅ Добавлен конструктор с параметром `companyId`
- ✅ Обновлены методы для фильтрации по `companyId`:
  - `getAllBoxTypes([String? overrideCompanyId])`
  - `getBoxTypesStream([String? overrideCompanyId])`
  - `getNumbersForType(String type, [String? overrideCompanyId])`
  - `getUniqueTypes([String? overrideCompanyId])`
  - `addBoxType({..., String? companyId})`

---

## 🔧 Что нужно сделать

### Шаг 1: Миграция существующих данных в Firestore

Все существующие записи в коллекции `box_types` нужно обновить, добавив поле `companyId`.

**Вариант A: Через Firebase Console (вручную)**
```
1. Открыть Firebase Console
2. Firestore Database → box_types
3. Для каждого документа добавить поле:
   - companyId: "company1" (или ID вашей компании)
```

**Вариант B: Через скрипт миграции (рекомендуется)**

Создать экран миграции в админ-панели:

```dart
// lib/screens/admin/migrate_box_types_screen.dart
Future<void> migrateBoxTypesToCompany(String companyId) async {
  final firestore = FirebaseFirestore.instance;
  
  // Получаем все box_types без companyId
  final snapshot = await firestore
      .collection('box_types')
      .where('companyId', isNull: true)
      .get();
  
  print('Found ${snapshot.docs.length} box types to migrate');
  
  // Обновляем каждый документ
  for (final doc in snapshot.docs) {
    await doc.reference.update({'companyId': companyId});
    print('✅ Migrated: ${doc.id}');
  }
  
  print('✅ Migration complete!');
}
```

### Шаг 2: Обновить все места использования BoxTypeService

Нужно передавать `companyId` при создании экземпляра сервиса.

**Где обновить:**

1. **lib/widgets/box_type_selector.dart**
```dart
// Было:
final BoxTypeService _boxTypeService = BoxTypeService();

// Стало:
late final BoxTypeService _boxTypeService;

@override
void initState() {
  super.initState();
  final authService = context.read<AuthService>();
  final companyId = authService.userModel?.companyId ?? '';
  _boxTypeService = BoxTypeService(companyId: companyId);
  _loadBoxTypes();
}
```

2. **lib/screens/warehouse/dialogs/add_box_type_dialog.dart**
3. **lib/screens/warehouse/dialogs/edit_box_type_dialog.dart**
4. **lib/screens/warehouse/dialogs/box_types_manager_dialog.dart**
5. **lib/screens/warehouse/dialogs/add_inventory_dialog.dart**
6. **lib/screens/dispatcher/price_management_screen.dart**

Во всех этих файлах нужно:
- Добавить `import 'package:provider/provider.dart';`
- Добавить `import '../../services/auth_service.dart';`
- Получить `companyId` из `AuthService`
- Передать `companyId` в конструктор `BoxTypeService`

### Шаг 3: Создать индексы в Firestore

Для оптимизации запросов создать составные индексы:

```
Коллекция: box_types
Индексы:
1. companyId (Ascending) + type (Ascending) + number (Ascending)
2. companyId (Ascending) + productCode (Ascending)
```

Firebase автоматически предложит создать эти индексы при первом запросе.

---

## 📋 Аналогичные изменения для других данных

### Inventory (Склад)
Модель `InventoryItem` уже имеет `companyId` ✅

### DeliveryPoint (Точки доставки)
Нужно добавить `companyId` к модели `DeliveryPoint`

### Routes (Маршруты)
Нужно добавить `companyId` к модели маршрутов

### Invoices (Счета)
Нужно добавить `companyId` к модели `Invoice`

---

## 🎯 Приоритет

1. **Высокий**: box_types (товары) - СДЕЛАНО частично
2. **Высокий**: inventory (склад) - УЖЕ ЕСТЬ
3. **Средний**: delivery_points (точки доставки)
4. **Средний**: routes (маршруты)
5. **Низкий**: invoices (счета)

---

## ⚠️ Важно

После миграции:
- Каждая компания будет видеть только свои товары
- Суперадмин может видеть товары всех компаний (если нужно)
- Новые товары автоматически привязываются к компании пользователя

---

## 🧪 Тестирование

1. Создать 2 компании (company1, company2)
2. Создать админа для каждой компании
3. Добавить товары от имени каждого админа
4. Проверить, что админ company1 не видит товары company2
5. Проверить, что суперадмин видит все товары

---

**Статус**: В процессе  
**Дата**: 23.02.2026  
**Автор**: AI Assistant
