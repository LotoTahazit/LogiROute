# 🎯 ЭТАЛОННЫЙ ПАТТЕРН для обновления экранов

## ✅ Готовый эталон
`lib/screens/dispatcher/price_management_screen.dart` - полностью обновлён по новому паттерну.

---

## 📋 Чек-лист обновления экрана

### 1️⃣ Импорты
```dart
import '../../services/company_context.dart';
// Убрать: import 'package:provider/provider.dart'; (если используется только для AuthService)
// Убрать: import '../../services/company_selection_service.dart';
```

### 2️⃣ Удалить late final сервисы
```dart
// ❌ УДАЛИТЬ:
late final PriceService _priceService;
late final BoxTypeService _boxTypeService;

// ✅ Сервисы создаются динамически в _loadData()
```

### 3️⃣ Добавить отслеживание компании
```dart
class _MyScreenState extends State<MyScreen> {
  // ... другие поля
  
  String? _currentCompanyId; // ✅ Для отслеживания смены компании
  
  @override
  void initState() {
    super.initState();
    // Первоначальная загрузка данных произойдёт в build() через CompanyContext
  }
```

### 4️⃣ Обновить метод _loadData()
```dart
// ❌ БЫЛО:
Future<void> _loadData() async {
  // использовали _priceService
}

// ✅ СТАЛО:
Future<void> _loadData(String companyId) async {
  if (companyId.isEmpty) {
    print('⚠️ [MyScreen] CompanyId is empty, skipping load');
    return;
  }

  setState(() => _isLoading = true);

  try {
    print('📊 [MyScreen] Loading data for company: $companyId');

    // ✅ Создаём сервисы с текущим companyId
    final myService = MyService(companyId: companyId);
    
    // Загружаем данные
    final data = await myService.getData();

    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
        _currentCompanyId = companyId; // ✅ Сохраняем текущую компанию
      });
    }

    print('✅ [MyScreen] Loaded ${data.length} items');
  } catch (e) {
    print('❌ [MyScreen] Error loading data: $e');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### 5️⃣ Обновить build() метод
```dart
@override
Widget build(BuildContext context) {
  // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Используем CompanyContext.watch() для автообновления
  final companyCtx = CompanyContext.watch(context);
  final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

  // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Отслеживаем смену компании
  if (_currentCompanyId != effectiveCompanyId) {
    // Компания изменилась - перезагружаем данные
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔄 [MyScreen] Company changed: $_currentCompanyId -> $effectiveCompanyId');
        _loadData(effectiveCompanyId);
      }
    });
  }

  return Scaffold(
    // ... остальной UI
  );
}
```

### 6️⃣ Обновить диалоги
```dart
// ❌ БЫЛО:
void _showEditDialog(String type, String number) {
  // companyId брали откуда-то из state
}

// ✅ СТАЛО:
void _showEditDialog(BuildContext context, String companyId, String type, String number) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      // ...
      actions: [
        ElevatedButton(
          onPressed: () async {
            // ✅ Получаем userName из контекста
            final companyCtx = CompanyContext.of(context);
            final userName = companyCtx.currentUser?.name ?? 'Unknown';

            // ✅ Создаём сервис с правильным companyId
            final myService = MyService(companyId: companyId);
            
            await myService.updateData(...);
            
            if (context.mounted) {
              _loadData(companyId); // ✅ Перезагружаем данные
            }
          },
          child: const Text('שמור'),
        ),
      ],
    ),
  );
}

// ✅ Вызов диалога:
onPressed: () => _showEditDialog(
  context,
  effectiveCompanyId, // ✅ Передаём из build()
  type,
  number,
),
```

---

## 🚫 ЗАПРЕТЫ

### ❌ НИКОГДА не берите companyId из:
- `userModel.companyId` напрямую
- Полей формы/UI
- Параметров конструктора экрана (если это не read-only экран)

### ✅ ВСЕГДА берите companyId из:
- `CompanyContext.watch(context).effectiveCompanyId` в build()
- `CompanyContext.of(context).effectiveCompanyId` в методах/диалогах

---

## 📊 Порядок обновления экранов

### Приоритет 1: Dispatcher (самые используемые)
- [x] `lib/screens/dispatcher/price_management_screen.dart` ✅ ЭТАЛОН
- [x] `lib/screens/dispatcher/invoice_management_screen.dart` ✅
- [x] `lib/screens/dispatcher/create_invoice_dialog.dart` ✅
- [x] `lib/screens/dispatcher/add_point_dialog.dart` ✅
- [x] `lib/screens/dispatcher/dispatcher_dashboard.dart` ✅ СЛОЖНЫЙ (стримы обновлены!)
- [x] `lib/screens/dispatcher/edit_point_dialog.dart` ✅ НЕ ТРЕБУЕТ ИЗМЕНЕНИЙ (нет сервисов)

### Приоритет 2: Warehouse
- [ ] `lib/screens/warehouse/warehouse_dashboard.dart`
- [ ] `lib/screens/warehouse/inventory_count_screen.dart`
- [ ] Диалоги в `lib/screens/warehouse/dialogs/`

### Приоритет 3: Admin
- [ ] `lib/screens/admin/company_settings_screen.dart`
- [ ] `lib/screens/admin/analytics_screen.dart`
- [ ] `lib/screens/admin/archive_management_screen.dart`
- [ ] `lib/screens/admin/inventory_counts_list_screen.dart`
- [ ] `lib/screens/admin/inventory_count_detail_screen.dart`

### Приоритет 4: Диалоги
После обновления всех экранов, проверить все диалоги:
- Они должны получать `companyId` как параметр
- Внутри диалога использовать `CompanyContext.of(context)` для получения user info

---

## 🧪 Как проверить что паттерн работает

1. Залогиниться как super_admin
2. Открыть экран
3. Выбрать компанию "Y.C. Plast" - должны загрузиться данные этой компании
4. Выбрать другую компанию - данные должны автоматически обновиться
5. В консоли должны быть логи:
   ```
   🔄 [MyScreen] Company changed: Y.C. Plast -> other_company
   📊 [MyScreen] Loading data for company: other_company
   ✅ [MyScreen] Loaded X items
   ```

---

## 💡 Почему этот паттерн правильный

1. **Единый источник правды**: `CompanyContext.getEffectiveCompanyId()` - одно место для всех
2. **Автообновление**: `CompanyContext.watch()` автоматически перестраивает UI при смене компании
3. **Безопасность**: Невозможно случайно использовать неправильный companyId
4. **Простота**: Один раз понял паттерн - копируешь на все экраны
5. **Отладка**: Все логи показывают какая компания используется

---

## 📝 Следующий шаг

Скопировать этот паттерн на следующий экран из списка приоритетов.
Начать с `invoice_management_screen.dart`.

---

## ⚠️ ОСОБЫЙ СЛУЧАЙ: Экраны со Stream

Если экран использует `Stream` (например, `dispatcher_dashboard.dart`), нужен особый подход:

### ❌ Проблема с late final Stream
```dart
late final Stream<List<Data>> _dataStream;

@override
void initState() {
  final companyId = context.read<AuthService>().userModel?.companyId ?? '';
  final service = MyService(companyId: companyId);
  _dataStream = service.getData();
}
```

**Проблема**: При смене компании стрим продолжает слушать старую компанию!

### ✅ Правильное решение
```dart
Stream<List<Data>>? _dataStream;
String? _currentCompanyId;

@override
Widget build(BuildContext context) {
  final companyCtx = CompanyContext.watch(context);
  final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

  // Пересоздаём стрим при смене компании
  if (_currentCompanyId != effectiveCompanyId) {
    _currentCompanyId = effectiveCompanyId;
    final service = MyService(companyId: effectiveCompanyId);
    _dataStream = service.getData();
  }

  return StreamBuilder<List<Data>>(
    stream: _dataStream,
    builder: (context, snapshot) {
      // ... UI
    },
  );
}
```

**Ключевые моменты**:
1. Стрим НЕ `late final`, а nullable `Stream?`
2. Пересоздаём стрим в `build()` при смене компании
3. Сервис тоже пересоздаём с новым `companyId`
