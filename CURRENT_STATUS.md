# 📊 Текущий статус обновления

## ✅ Полностью обновлены (3 файла)

1. **lib/screens/dispatcher/price_management_screen.dart** ✅ ЭТАЛОН
   - Использует `CompanyContext.watch()` в build()
   - Отслеживает смену компании через `_currentCompanyId`
   - Все сервисы создаются динамически с `companyId`
   - Диалоги получают `companyId` как параметр

2. **lib/screens/dispatcher/invoice_management_screen.dart** ✅
   - Применён эталонный паттерн
   - Автообновление при смене компании
   - Все методы обновлены

3. **lib/screens/dispatcher/create_invoice_dialog.dart** ✅
   - Получает `companyId` как параметр конструктора
   - Использует `CompanyContext.of(context)` для получения userName
   - Все сервисы создаются с правильным `companyId`

## 🔄 Частично обновлены (0 файлов)

Нет

## ❌ Не обновлены (требуют работы)

### Критически важные (ПРИОРИТЕТ 1)

1. **lib/screens/dispatcher/dispatcher_dashboard.dart** 🔴 СЛОЖНЫЙ
   - 1308 строк кода
   - Использует `late final RouteService _routeService`
   - Использует `late final Stream` которые нужно сделать динамическими
   - Множество методов работают с точками доставки
   - Прямой доступ к Firestore в некоторых местах
   - **Проблема**: При смене компании стримы не обновляются!
   - **Решение**: Нужно пересоздавать стримы при смене компании

2. **lib/screens/dispatcher/add_point_dialog.dart** 🔴 СЛОЖНЫЙ
   - Большой диалог с геокодингом
   - Использует `late final ClientService _clientService`
   - Использует `late final RouteService _routeService`
   - Получает `companyId` из `context.read<AuthService>()` в initState()
   - **Решение**: Передавать `companyId` как параметр конструктора

3. **lib/screens/warehouse/warehouse_dashboard.dart** 🟡 СРЕДНИЙ
   - Прямой доступ к Firestore без сервисов
   - Использует старую коллекцию `inventory` на root уровне
   - Нужно обновить на использование `FirestorePaths`

### Средний приоритет (ПРИОРИТЕТ 2)

4. **lib/screens/admin/company_settings_screen.dart** 🟡
   - Использует `CompanySettingsService` без `companyId`
   - Сервис работает со старой коллекцией `companySettings` на root
   - **Проблема**: Настройки не привязаны к компании!
   - **Решение**: Мигрировать в `/companies/{companyId}/settings/`

5. **lib/screens/warehouse/inventory_count_screen.dart** 🟡
   - Нужно проверить и обновить

6. **lib/screens/shared/inventory_report_screen.dart** 🟡
   - Нужно проверить и обновить

7. **lib/screens/shared/client_management_screen.dart** 🟡
   - Нужно проверить и обновить

### Низкий приоритет (ПРИОРИТЕТ 3)

8. **lib/screens/admin/analytics_screen.dart**
9. **lib/screens/admin/archive_management_screen.dart**
10. **lib/screens/admin/inventory_counts_list_screen.dart**
11. **lib/screens/admin/inventory_count_detail_screen.dart**

### Диалоги warehouse

12. **lib/screens/warehouse/dialogs/** - нужно проверить все диалоги

---

## 🎯 Рекомендуемый план действий

### Шаг 1: Обновить add_point_dialog.dart
- Добавить параметр `companyId` в конструктор
- Убрать `late final` сервисы
- Создавать сервисы динамически

### Шаг 2: Обновить dispatcher_dashboard.dart
- Это самый сложный файл!
- Нужно сделать стримы динамическими
- Добавить отслеживание смены компании
- Пересоздавать `_routeService` и стримы при смене

### Шаг 3: Обновить warehouse_dashboard.dart
- Заменить прямой доступ к Firestore на сервисы
- Использовать `FirestorePaths`

### Шаг 4: Мигрировать CompanySettingsService
- Обновить сервис для работы с nested коллекциями
- Мигрировать данные из `companySettings` в `/companies/{companyId}/settings/`

### Шаг 5: Обновить остальные экраны
- По одному, применяя эталонный паттерн

---

## 🚨 Критические проблемы

### Проблема 1: Стримы в dispatcher_dashboard
```dart
// ❌ ТЕКУЩИЙ КОД:
late final Stream<List<DeliveryPoint>> _pendingPointsStream;
late final Stream<List<DeliveryPoint>> _routesStream;

@override
void initState() {
  _routeService = RouteService(companyId: companyId);
  _pendingPointsStream = _routeService.getAllPendingPoints();
  _routesStream = _routeService.getAllRoutes();
}
```

**Проблема**: При смене компании стримы продолжают слушать старую компанию!

**Решение**:
```dart
// ✅ ПРАВИЛЬНЫЙ КОД:
Stream<List<DeliveryPoint>>? _pendingPointsStream;
Stream<List<DeliveryPoint>>? _routesStream;
String? _currentCompanyId;

@override
Widget build(BuildContext context) {
  final companyCtx = CompanyContext.watch(context);
  final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

  // Пересоздаём стримы при смене компании
  if (_currentCompanyId != effectiveCompanyId) {
    _currentCompanyId = effectiveCompanyId;
    final routeService = RouteService(companyId: effectiveCompanyId);
    _pendingPointsStream = routeService.getAllPendingPoints();
    _routesStream = routeService.getAllRoutes();
  }

  return StreamBuilder<List<DeliveryPoint>>(
    stream: _pendingPointsStream,
    ...
  );
}
```

### Проблема 2: Диалоги получают companyId из context
```dart
// ❌ НЕПРАВИЛЬНО:
@override
void initState() {
  final authService = context.read<AuthService>();
  final companyId = authService.userModel?.companyId ?? '';
  _clientService = ClientService(companyId: companyId);
}
```

**Проблема**: Для super_admin это вернёт `system_company`, а не выбранную компанию!

**Решение**: Передавать `companyId` как параметр конструктора диалога.

---

## 📈 Прогресс

- ✅ Инфраструктура: 100%
- ✅ Эталонный паттерн: 100%
- 🔄 Обновлённые экраны: 3 из ~15 (20%)
- ⏳ Осталось: ~12 файлов

**Следующий файл для обновления**: `add_point_dialog.dart`
