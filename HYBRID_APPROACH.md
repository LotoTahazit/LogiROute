# 🎯 Гибридный подход: Виртуальный CompanyId

## ✅ Что сделано

### Ключевое изменение: Виртуальный CompanyId в AuthService

Вместо передачи `companyId` через все методы и диалоги, мы используем **виртуальный companyId** в `AuthService`.

```dart
class AuthService {
  String? _virtualCompanyId; // Виртуальный companyId для super_admin
  
  UserModel? get userModel {
    if (_userModel == null) return null;
    
    // Если super_admin выбрал компанию - возвращаем виртуальную модель
    if (_userModel!.isSuperAdmin && _virtualCompanyId != null) {
      return UserModel(
        ...
        companyId: _virtualCompanyId!, // ✅ Подменяем companyId
        ...
      );
    }
    
    return _userModel;
  }
  
  void setVirtualCompanyId(String? companyId) {
    if (_userModel?.isSuperAdmin == true) {
      _virtualCompanyId = companyId;
      notifyListeners(); // ✅ Уведомляем всех слушателей!
    }
  }
}
```

**Результат:**
- Когда super_admin выбирает компанию, `authService.userModel?.companyId` автоматически возвращает выбранную компанию
- Весь существующий код работает БЕЗ изменений!
- Не нужно передавать `companyId` через параметры

---

## 📁 Структура файлов

### ✅ Обновлённые файлы (гибридный подход)

**Ключевые изменения:**
1. `lib/services/auth_service.dart` - добавлен виртуальный companyId
2. `lib/widgets/company_selector_widget.dart` - вызывает `setVirtualCompanyId()`
3. `lib/screens/admin/admin_dashboard.dart` - устанавливает начальный виртуальный companyId

**Сложные экраны (отслеживают смену компании):**
4. `lib/screens/dispatcher/dispatcher_dashboard.dart` - пересоздаёт стримы при смене
5. `lib/screens/dispatcher/price_management_screen.dart` - отслеживает смену компании
6. `lib/screens/dispatcher/invoice_management_screen.dart` - отслеживает смену компании

**Простые диалоги (используют authService напрямую):**
7. `lib/screens/dispatcher/create_invoice_dialog.dart` - берёт companyId из authService
8. `lib/screens/dispatcher/add_point_dialog.dart` - берёт companyId из authService

**Полезные хелперы (оставлены):**
9. `lib/services/firestore_paths.dart` - централизованные пути к коллекциям
10. `lib/services/company_selection_service.dart` - управление списком компаний

---

## 🎨 Паттерны использования

### Паттерн 1: Простые диалоги (большинство случаев)

```dart
class MyDialog extends StatefulWidget {
  // ❌ НЕ нужен параметр companyId!
  const MyDialog({super.key});
}

class _MyDialogState extends State<MyDialog> {
  Future<void> _saveData() async {
    // ✅ Просто берём из authService
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    final userName = authService.userModel?.name ?? 'Unknown';
    
    final myService = MyService(companyId: companyId);
    await myService.save(...);
  }
}
```

### Паттерн 2: Экраны со стримами (сложные случаи)

```dart
class _MyScreenState extends State<MyScreen> {
  Stream<List<Data>>? _dataStream;
  String? _currentCompanyId;

  @override
  Widget build(BuildContext context) {
    // ✅ Отслеживаем смену компании
    final authService = context.watch<AuthService>();
    final effectiveCompanyId = authService.userModel?.companyId ?? '';

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
}
```

### Паттерн 3: Простые экраны (без стримов)

```dart
class _MyScreenState extends State<MyScreen> {
  Future<void> _loadData() async {
    // ✅ Просто берём из authService
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    
    final myService = MyService(companyId: companyId);
    final data = await myService.getData();
    
    setState(() => _data = data);
  }
}
```

---

## 🚀 Преимущества гибридного подхода

1. **Простота для большинства случаев**
   - Диалоги и простые экраны просто берут `companyId` из `authService`
   - Не нужно передавать параметры

2. **Гибкость для сложных случаев**
   - Экраны со стримами явно отслеживают смену компании
   - Полный контроль над обновлением данных

3. **Автоматическое обновление**
   - `authService.notifyListeners()` обновляет всех слушателей
   - `context.watch<AuthService>()` автоматически перестраивает UI

4. **Минимум изменений**
   - Большая часть существующего кода работает без изменений
   - Только сложные экраны требуют явного отслеживания

---

## 📊 Статистика

- ✅ Обновлено файлов: 10
- ✅ Сложных экранов со стримами: 3
- ✅ Простых диалогов: 2
- ✅ Ключевых изменений: 1 (AuthService)

---

## 🎯 Следующие шаги

Для новых экранов и диалогов:

1. **Если это простой диалог/экран** → используйте Паттерн 1 или 3
2. **Если это экран со стримами** → используйте Паттерн 2
3. **Всегда берите companyId из `authService.userModel?.companyId`**

Не нужно:
- ❌ Передавать `companyId` как параметр конструктора
- ❌ Использовать `CompanyContext` (избыточен)
- ❌ Создавать сложные цепочки передачи данных

Нужно:
- ✅ Использовать `authService.userModel?.companyId`
- ✅ Для сложных экранов - отслеживать смену через `context.watch<AuthService>()`
- ✅ Пересоздавать стримы при смене компании
