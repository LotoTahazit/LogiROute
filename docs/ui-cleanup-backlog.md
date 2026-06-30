# UI Cleanup Backlog — LogiRoute

> Аудит проведён 30 июн 2026. Источник правды по токенам: `lib/theme/app_theme.dart`.
> Все строки кода указаны в формате `файл:строка`.

---

## 1. Top 10 проблем интерфейса

| № | Проблема | Файл | Пример из кода | Влияние |
|---|----------|------|----------------|---------|
| 1 | **GPS-баннер — 5 цветовых схем через хардкод** | `driver_dashboard.dart` | стр. 1970–2014: `bg = Colors.grey.shade200` / `Colors.green.shade100` / `Colors.amber.shade100` / `Colors.red.shade100` / `Colors.orange.shade100` | Тема не переключается; смена брендинга = ручная правка 15 строк |
| 2 | **Статусы маршрутов через Colors.*.shade*** | `active_routes_tab.dart` | стр. 403: `color: allClosed ? Colors.green.shade50 : null`, стр. 433–459: `Colors.red.shade50`, `Colors.amber.shade50` | Статус-токены (`AppTheme.green`, `AppTheme.warning`, `AppTheme.danger`) игнорируются |
| 3 | **"View-as" баннер — 3 разные реализации с 3 разными цветами** | `driver_dashboard.dart:2167`, `owner_dashboard_shell.dart:452`, `dispatcher_dashboard.dart:1447` | driver: `Colors.orange.shade100`; owner: `Colors.blue.shade100`; dispatcher: `AppTheme.surfaceHi` (правильно!) | Одинаковый смысл → 3 разных визуала; dispatcher корректен, остальные нет |
| 4 | **Chip'ы обзора в Support Console — вне палитры** | `support_console_screen.dart:654` | `_chip(l10n.chipPlan, plan, Colors.blue)`, `Colors.teal`, `Colors.indigo`, `Colors.deepPurple`, `Colors.orange` — 5 произвольных цветов в 6 строках | Диагностические chip'ы не связаны с семантикой статуса |
| 5 | **AppBar с Column-subtitle** | `support_console_screen.dart:464` | `title: Column(children: [Text(...), Text('$id', style: TextStyle(fontSize: 12))])` — subtitle как вложенный Text в title | Не масштабируется; на мобиле обрезается; вне `appBarTheme.titleTextStyle` |
| 6 | **Эмодзи вместо иконок** | `driver_dashboard.dart:1974,1982,1989,1998`, `active_routes_tab.dart:117,122,235,237` | `title = '⏸️ ${l10n.gpsTrackingStopped}'`, `'📍 ${l10n.gpsTrackingActive}'`, `'✅ ...'`, `'⚠️ ...'` | Нет RTL-поддержки, не красятся через IconTheme, не масштабируются |
| 7 | **RTL зависит от одного языка, не от `LocaleService`** | `dispatcher_dashboard.dart:1421` | `textDirection: localeService.locale.languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr` | При ru/en locale — зеркало отключается; новые экраны этого не наследуют |
| 8 | **Радиусы вне шкалы 8/12/14/16** | `driver_dashboard.dart:2849,2873` | `borderRadius: BorderRadius.circular(10)` | Нарушает визуальный ритм; должно быть 8 или 12 |
| 9 | **Таблицы без горизонтального sticky header и токен-цветов severity** | `platform_error_center_screen.dart:99`, `data_integrity_screen.dart:149` | `DataTable(columns: [...], rows: [...])` без sticky, без sort; severity через `Colors.amber.shade700` (data_integrity строка 85) | Не скроллится вертикально независимо от горизонтального scroll на мобиле |
| 10 | **Один breakpoint `< 600` вместо трёх** | `owner_dashboard_shell.dart:354`, `dispatcher_dashboard.dart:1378` | `final isNarrow = MediaQuery.of(context).size.width < 600` | Нет планшетного md-уровня; десктоп owner и десктоп dispatcher неотличимы |

---

## 2. Экран → Проблемы → Риск → Предложение

### 2.1 `driver_dashboard.dart`

**Файл:** `lib/screens/driver/driver_dashboard.dart` (2945 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| GPS-баннер — 5 цветовых схем через хардкод | `1970`: `bg = Colors.grey.shade200` / `1978`: `Colors.green.shade100` / `1985`: `Colors.amber.shade100` / `2001`: `Colors.red.shade100` / `2012`: `Colors.orange.shade100` | Нельзя обновить цвета из одного места | Заменить на `AppTheme.green.withValues(alpha:.12)`, `AppTheme.warning.withValues(alpha:.12)`, `AppTheme.danger.withValues(alpha:.12)`, `AppTheme.muted.withValues(alpha:.12)` |
| View-as баннер: хардкод orange | `2167`: `color: Colors.orange.shade100`, `2169`: `BorderSide(color: Colors.orange.shade300, width: 2)`, `2182`: `color: Colors.orange.shade900` | Не совпадает с dispatcher (там `AppTheme.surfaceHi`) | Заменить на ту же реализацию что в `dispatcher_dashboard.dart:1447` (`AppTheme.surfaceHi + AppTheme.accent`) |
| Эмодзи в title GPS-баннера | `1974`: `'⏸️ ${l10n.gpsTrackingStopped}'`, `1982`: `'📍 ${l10n.gpsTrackingActive}'`, `1989`: `'⏳ ${l10n.gpsStatusWaiting}'` | RTL: эмодзи не зеркалится, на части шрифтов выглядит по-разному | Убрать эмодзи из строк, использовать `Icon(icon, color: fg, size: 20)` (уже есть рядом) |
| "Other route" баннер: хардкод orange | `181`: `color: Colors.orange.shade50`, `190`: `color: Colors.orange.shade800`, `202`: `Colors.orange.shade700` | Визуально конфликтует с GPS-стало (`Colors.orange.shade100`) — разные оттенки одного состояния | `AppTheme.warning.withValues(alpha:.10)` + `AppTheme.warning` |
| Radii вне шкалы | `2849`: `BorderRadius.circular(10)`, `2873`: `BorderRadius.circular(10)` | Несоответствие шкале | Заменить на `8` или `12` |
| `backgroundColor: Colors.orange` в SnackBar | `763`: `backgroundColor: Colors.orange.shade800` | Обходит тему | `AppTheme.warning` |

---

### 2.2 `active_routes_tab.dart`

**Файл:** `lib/screens/dispatcher/widgets/active_routes_tab.dart` (975 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| Статус completed — хардкод green | `403`: `color: allClosed ? Colors.green.shade50 : null`, `406`: `Colors.green.shade700`, `419`: `Colors.green.shade800` | Не привязан к `AppTheme.green` | `AppTheme.green.withValues(alpha:.10)` / `AppTheme.green` / `AppTheme.greenSoft` |
| Статус просрочен/warn — хардкод red/amber | `433–459`: `Colors.red.shade50`, `Colors.amber.shade50`, `Colors.red.shade200`, `Colors.amber.shade200`, `Colors.red.shade800`, `Colors.amber.shade800/900` | 6 оттенков для двух состояний | `AppTheme.danger.withValues(alpha:.10)` / `AppTheme.warning.withValues(alpha:.10)` + full token для текста |
| Stale-cache баннер | `877`: `color: Colors.orange.shade50`, `879`: `Icon(..., color: Colors.orange.shade700)`, `884`: `color: Colors.orange.shade900` | Та же проблема orange | `AppTheme.warning.withValues(alpha:.10)` / `AppTheme.warning` |
| Эмодзи в timing-тексте | `117`: `'⏱ ...'`, `122`: `'✅ ...'` | RTL/доступность | `Icon(Icons.timer_outlined, size: 14)` / `Icon(Icons.check_circle_outline, size: 14)` |
| `foregroundColor: Colors.orange.shade800` на кнопке | `904`: `OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800)` | Вне темы | `AppTheme.warning` |

---

### 2.3 `dispatcher_dashboard.dart`

**Файл:** `lib/screens/dispatcher/dispatcher_dashboard.dart` (1905 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| RTL зависит от languageCode | `1421–1424`: `localeService.locale.languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr` | ru/en → нет RTL, арабоязычное расширение сломается | Вынести в `LocaleService.textDirection` или использовать `Localizations.localeOf(context).scriptCode` |
| SnackBar с `Colors.orange` | `486`: `backgroundColor: Colors.orange`, `752`: `backgroundColor: Colors.orange` | Обходит тему | `AppTheme.warning` |
| SnackBar с `Colors.green` / `Colors.red` | `1273`: `backgroundColor: changed ? Colors.green : null`, `1280`: `backgroundColor: Colors.red` | Обходит тему | `AppTheme.green` / `AppTheme.danger` |
| `confirmColor: Colors.red.shade700` в диалоге | `580`: `confirmColor: Colors.red.shade700` | Обходит `AppTheme.danger` | `AppTheme.danger` |
| `confirmColor: Colors.green` | `1132`: `confirmColor: Colors.green` | Обходит `AppTheme.green` | `AppTheme.green` |
| `backgroundColor: Colors.orange` на кнопке | `1059`: `ElevatedButton.styleFrom(backgroundColor: Colors.orange)` | Overload warning — другой стиль чем danger | `AppTheme.warning` |
| 2 FAB стопкой без gap-токена | `1732–1763`: `Column(children: [FloatingActionButton.small(...), const SizedBox(height: 12), FloatingActionButton(...)])` | `SizedBox(height: 12)` — нет токена | Использовать `AppSpacing.space3` (12dp на шкале — допустимо, но явно задокументировать) |

---

### 2.4 `owner_dashboard_shell.dart`

**Файл:** `lib/features/owner_dashboard/widgets/owner_dashboard_shell.dart` (928 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| View-as баннер через Colors.blue | `452`: `color: Colors.blue.shade100`, `454`: `BorderSide(color: Colors.blue.shade300, width: 2)`, `465`: `color: Colors.blue.shade900` | Конфликт с driver (orange) и dispatcher (AppTheme) | Унифицировать: `AppTheme.surfaceHi + Border(bottom: BorderSide(color: AppTheme.accent, width: 2))` |
| `_ErrorScreen` icon через Colors.red | `901`: `Icon(Icons.error_outline, size: 72, color: Colors.red[300])`, `906`: `color: Colors.red[700]` | Обходит `AppTheme.danger` | `AppTheme.danger` |
| `_NoCompanyScreen` icon через Colors.grey | `773`: `color: Colors.grey[400]`, `791`: `color: Colors.grey[600]` | Обходит `AppTheme.muted` | `AppTheme.muted` |
| Один breakpoint `< 600` | `354`: `final isNarrow = MediaQuery.of(context).size.width < 600` | Нет планшета md (900–1239) | `AppBreakpoints.narrow` константа; добавить `md` для sidebar-rail |
| `DrawerHeader` с `primaryContainer.withValues(alpha: 0.3)` | `562`: `color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3)` | Не привязан к `AppTheme.tile` | `AppTheme.tile` |
| Inline `TextStyle` в `_buildGroupedNavWidgets` | `536–537`: `TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? theme.primaryColor : null)` | Дублирует логику ListTileTheme | Использовать `ListTile(selected: selected, selectedColor: theme.primaryColor)` — эффект тот же через тему |

---

### 2.5 `warehouse_dashboard.dart`

**Файл:** `lib/screens/warehouse/warehouse_dashboard.dart` (696 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| SnackBar цвета напрямую | `153`: `backgroundColor: Colors.green`, `157`: `backgroundColor: Colors.orange`, `262`: `Colors.green`, `263`: `Colors.orange` | Обходит тему; по всем SnackBar'ам одна цветовая семантика | `AppTheme.green` / `AppTheme.warning`; или использовать `SnackbarHelper.showSuccess/showWarning` |
| `print()` в production-коде | `160`: `print('❌ Error exporting inventory: $e')` | Утечка в консоль в production | Заменить на `debugPrint` |
| AppBar actions не показаны (анализ структуры) | Нет — AppBar вынесен в `_handleWarehouseMenuAction` как PopupMenuButton | Пользователь не видит сразу ключевые действия | Вынести «Добавить тип» и «Сканер» как прямые `IconButton` |

---

### 2.6 `support_console_screen.dart`

**Файл:** `lib/screens/admin/support_console_screen.dart` (1162 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| AppBar subtitle как Column | `464–476`: `title: Column(children: [Text(title), Text('$id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))])` | Обрезается на мобиле, не через тему | Перенести ID в `appBar.bottom` (как уже есть TabBar bottom) или tooltip иконки компании |
| 5 IconButton в AppBar.actions | `480–500`: `IconButton` ×5 (`published_with_changes`, `verified_user`, `download`, `refresh`) | Перегружен AppBar | Собрать в один `PopupMenuButton` (overflowed menu) |
| Chip-цвета вне палитры | `653–661`: `Colors.blue`, `Colors.teal`, `Colors.indigo`, `Colors.deepPurple`, `Colors.orange` для KPI-чипов | Бессистемны; `Colors.indigo` и `Colors.teal` нет в AppPalette | Использовать только `AppTheme.accent`, `AppTheme.green`, `AppTheme.warning`, `AppTheme.muted` |
| SnackBar `backgroundColor: Colors.red/green` | `99`: `backgroundColor: Colors.red`, `148`: `backgroundColor: Colors.red`, `382`: `Colors.green`, `392`: `Colors.red` | Обходит тему | `SnackbarHelper.showError/showSuccess` |
| `const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)` inline | `629` | Обходит `textTheme` | `theme.textTheme.titleLarge` |
| `const TextStyle(fontSize: 12, color: AppTheme.muted)` правильно | `640,645` | Есть корректный пример — остальное исправлять по образцу | — |

---

### 2.7 `data_integrity_screen.dart`

**Файл:** `lib/screens/admin/data_integrity_screen.dart` (496 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| `Colors.amber.shade700` для severity medium | `85`: `return Colors.amber.shade700` | Обходит `AppTheme.warning` | `AppTheme.warning` |
| `Colors.red` / `Colors.orange` / `Colors.blueGrey` / `Colors.grey` для severity | `80–90`: весь `_severityColor` | Полный словарь вне токенов | `AppStatusColors.severityColor(s)` — будущий утилит |
| `backgroundColor: Colors.green / Colors.red` в SnackBar | `41`, `47` | Обходит тему | `SnackbarHelper.showSuccess/showError` |
| Фиксированный паддинг `EdgeInsets.all(12)` в Card дважды | `152`, `153` | Можно, на шкале | OK |

---

### 2.8 `platform_error_center_screen.dart`

**Файл:** `lib/screens/admin/platform_error_center_screen.dart` (168 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| Severity colors — хардкод | `30`: `Colors.red.shade700`, `32`: `Colors.orange.shade800`, `34`: `Colors.amber.shade800`, `36`: `Colors.blueGrey` | Разные оттенки чем в `data_integrity_screen` (30 = `red.700` vs там `Colors.red`) | Вынести в `AppStatusColors.severityColor` — единый метод для обоих экранов |
| `DataTable` без sticky/sort | `99–150` | На desktop — нельзя сортировать; на мобиле — горизонтальный scroll без закреплённых заголовков | Минимум: добавить `DataColumn(..., onSort: ...)` по `lastSeen` |
| `SizedBox(width: 220)` для ячейки error message | `128`: `SizedBox(width: 220, child: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis))` | Фиксированная ширина — сломается на мобиле | Убрать `SizedBox`, использовать `ConstrainedBox` или flex column |
| Фильтр-чипы без gap-токена | `65`: `const SizedBox(width: 6)` между чипами | Нестандартный gap | `6→8` (шкала: `space-2 = 8dp`) |

---

### 2.9 `import_mapping_wizard_screen.dart`

**Файл:** `lib/screens/shared/import_mapping_wizard_screen.dart` (712 строк)

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| Таблица preview через `TableBorder` с хардкодом | `527`: `TableBorder.all(color: Colors.grey.shade300)` | Обходит `AppTheme.border` | `TableBorder.all(color: AppTheme.border)` |
| Confidence colors — хардкод | `588`: `ImportConfidenceLevel.high => Colors.green.shade700`, `589`: `ImportConfidenceLevel.review => Colors.orange.shade800` | Вне токенов | `AppTheme.green` / `AppTheme.warning` |
| Подложки строк через `Colors.*.withValues()` | `594–596`: `BoxDecoration(color: Colors.green.withValues(alpha: 0.04))`, `Colors.red.withValues(alpha: 0.04)` | Обходит токены | `AppTheme.green.withValues(alpha:.05)` / `AppTheme.danger.withValues(alpha:.05)` |
| Нативный `Stepper` без стилизации под AppTheme | `320`: `Stepper(currentStep: _step.clamp(0,6), ...)` | Шаги в стандартном Material3 стиле, не в токенах проекта | Минимум: `Stepper(connectorThickness: 1, ...)` + `controlsBuilder` уже есть — добавить цвет прогресса через `ThemeData(stepperTheme: ...)` |
| `padding: const EdgeInsets.only(top: 16)` в controlsBuilder | `327`: | OK (на шкале) | — |

---

### 2.10 `onboarding_center_screen.dart` + `company_setup_wizard_screen.dart`

**Файлы:** `lib/screens/setup/onboarding_center_screen.dart`, `lib/screens/setup/company_setup_wizard_screen.dart`, `lib/screens/admin/create_company_flow_screen.dart`

| Проблема | Строки + цитата | Риск | Минимальное исправление |
|----------|-----------------|------|------------------------|
| `onboarding_center`: отсутствие `Directionality` | Весь файл — нет `Directionality(textDirection: TextDirection.rtl)` | Экран `embedded: false` наследует RTL от родителя; при direct push может не иметь RTL | Добавить `Directionality` или убедиться что родитель всегда RTL |
| `company_setup_wizard_screen` — нет хардкодов цветов | Чистый файл | — | — |
| `create_company_flow_screen.dart` — нативный `Stepper` | `152`: `Stepper(currentStep: _step, ...)` | Аналогично import wizard | Совместный виджет `AppStepper` вместо нативного |
| `onboarding_center:355`: `padding: const EdgeInsets.all(16)` | OK | — | — |
| `Chip(label: Text(..., style: TextStyle(fontSize: 11)))` | `373` | Inline fontSize | `theme.textTheme.labelSmall` (размер 13 в теме — меньше нет, можно скопировать стиль) |

---

## 3. P0 — перед пилотом

### ✅ CLOSED — Status colors / AppTheme tokens (2026-06-30)

Заменены `Colors.*` на `AppTheme` в критичных статусных элементах:

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/driver/driver_dashboard.dart` | GPS-баннер ~1969–2018 | P0-1 |
| `lib/screens/dispatcher/widgets/active_routes_tab.dart` | статусы маршрутов ~403–459 | P0-5, P0-6 |
| `lib/features/owner_dashboard/widgets/owner_dashboard_shell.dart` | view-as баннер | P0-9 |
| `lib/screens/admin/support_console_screen.dart` | chip colors ~653–661 | P0-14 |
| `lib/screens/admin/data_integrity_screen.dart` | `_severityColor` | P0-15 |
| `lib/screens/admin/platform_error_center_screen.dart` | `_severityColor` | P0-15 |

### ✅ CLOSED — View-as-driver banner + GPS emoji → Icons (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/driver/driver_dashboard.dart` | view-as-driver баннер ~2160–2202 | P0-2 |
| `lib/screens/driver/driver_dashboard.dart` | GPS title emoji → Material Icons ~1969–2017 | P0-3 |

### ✅ CLOSED — Stale-cache / auto-completed warning banner (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/dispatcher/widgets/active_routes_tab.dart` | auto-completed ExpansionTile ~874–912, helper `_dispatcherWarningBanner` | P0-7 |

### ✅ CLOSED — Emoji timing → Material Icons (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/dispatcher/widgets/active_routes_tab.dart` | `_buildTimingRow`, pallet advice ~117–122, 235–237 | P0-8 |

### ✅ CLOSED — BorderRadius 10 → 8 (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/driver/driver_dashboard.dart` | `_buildAndroidRouteSummary` panel + remaining-count badge | P0-4 (2/2 замены) |

### ✅ CLOSED — Dispatcher view-as banner unified (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/dispatcher/dispatcher_dashboard.dart` | view-as dispatcher banner ~1438–1497 | P0-9 |

### ✅ CLOSED — Owner error / no-company screens (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/features/owner_dashboard/widgets/owner_dashboard_shell.dart` | `_NoCompanyScreen` icon/subtitle, `_ErrorScreen` icon/title/body | P0-10 |

### ✅ CLOSED — Import wizard table borders + confidence colors (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/shared/import_mapping_wizard_screen.dart` | mapping `Table` border, `_mappingRow` confidence | P0-11, P0-12 |
| `lib/widgets/column_mapping_dialog.dart` | mapping `Table` border, `_buildFieldRow` confidence | P0-11, P0-12 |

### ✅ CLOSED — Support Console AppBar simplified (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/admin/support_console_screen.dart` | AppBar title + `_buildCompanyContextHeader` под AppBar | P0-13 |

### ✅ CLOSED — Platform Error Center adaptive error column (2026-06-30)

| Файл | Зона | P0-пункты |
|------|------|-----------|
| `lib/screens/admin/platform_error_center_screen.dart` | `LayoutBuilder` + `ConstrainedBox(maxWidth: …)` вместо `SizedBox(width: 220)` | P0-16 |

**Pilot P0 UI backlog закрыт.** Оставшиеся пункты — P1 (dark theme, table/form component library, responsive refactor) и мелкий хардкод вне pilot-scope.

### Driver Dashboard
| # | Задача | Файл:строки | Что заменить | На что |
|---|--------|-------------|--------------|--------|
| P0-1 | GPS-баннер: 5 цветовых схем → токены | `driver_dashboard.dart:1969–2018` | `Colors.grey.shade200/400/700`, `Colors.green.shade100/300/900`, `Colors.amber.shade100/300/900`, `Colors.red.shade100/300/900`, `Colors.orange.shade100/300/900` | `AppTheme.muted.withValues(alpha:.14)` / `.green.withValues(alpha:.12)` / `.warning.withValues(alpha:.12)` / `.danger.withValues(alpha:.12)` + full token для текста/border |
| P0-2 | "View-as-driver" баннер: orange → AppTheme | `driver_dashboard.dart:2167–2202` | `Colors.orange.shade100/300/900` | Скопировать структуру из `dispatcher_dashboard.dart:1440–1497` (`AppTheme.surfaceHi + AppTheme.accent`) |
| P0-3 | Эмодзи в GPS-title → Material Icons | `driver_dashboard.dart:1974,1982,1989,1998` | `'⏸️ ...'`, `'📍 ...'`, `'⏳ ...'`, `'⚠️ ...'` | Убрать из строк l10n; иконка уже рендерится рядом `Icon(icon, color: fg)` |
| P0-4 | Радиус 10 → 8 или 12 | `driver_dashboard.dart:2849,2873` | `BorderRadius.circular(10)` ×2 | `BorderRadius.circular(8)` |

### Dispatcher: Active routes tab
| # | Задача | Файл:строки | Что заменить | На что |
|---|--------|-------------|--------------|--------|
| P0-5 | Статус completed: Colors.green.* → AppTheme | `active_routes_tab.dart:403,406,419` | `Colors.green.shade50`, `Colors.green.shade700`, `Colors.green.shade800` | `AppTheme.green.withValues(alpha:.10)`, `AppTheme.green`, `AppTheme.greenSoft` |
| P0-6 | Статус late/warn: Colors.red/amber → AppTheme | `active_routes_tab.dart:433–459` | `Colors.red.shade50/200/800`, `Colors.amber.shade50/200/800/900` | `AppTheme.danger.withValues(alpha:.10)`, `AppTheme.danger`, `AppTheme.warning.withValues(alpha:.10)`, `AppTheme.warning` |
| P0-7 | Stale-cache баннер: orange → AppTheme | `active_routes_tab.dart:877,879,884` | `Colors.orange.shade50/700/900` | `AppTheme.warning.withValues(alpha:.10)` / `AppTheme.warning` |
| P0-8 | Эмодзи в timing-text | `active_routes_tab.dart:117,122,235,237` | `'⏱ ...'`, `'✅ ...'`, `'⚠️ ...'` | `Icon(Icons.timer_outlined, size: 14)` inline / убрать из строк |

### Owner dashboard
| # | Задача | Файл:строки | Что заменить | На что |
|---|--------|-------------|--------------|--------|
| P0-9 | View-as-owner баннер: blue → AppTheme | `owner_dashboard_shell.dart:452–476` | `Colors.blue.shade100`, `Colors.blue.shade300`, `Colors.blue.shade900` ×3 | `AppTheme.surfaceHi`, `AppTheme.accent`, `AppTheme.accentSoft` (как у dispatcher) |
| P0-10 | `_ErrorScreen` / `_NoCompanyScreen` цвета | `owner_dashboard_shell.dart:773,792,901,905,917` | `Colors.red[300/700]`, `Colors.grey[400/600]` | `AppTheme.danger`, `AppTheme.muted` |

### Import wizard
| # | Задача | Файл:строки | Что заменить | На что |
|---|--------|-------------|--------------|--------|
| P0-11 | Таблица preview: TableBorder хардкод | `import_mapping_wizard_screen.dart:527` | `TableBorder.all(color: Colors.grey.shade300)` | `TableBorder.all(color: AppTheme.border)` |
| P0-12 | Confidence row colors | `import_mapping_wizard_screen.dart:588–596` | `Colors.green.shade700`, `Colors.orange.shade800`, `Colors.green.withValues(alpha:0.04)`, `Colors.red.withValues(alpha:0.04)` | `AppTheme.green`, `AppTheme.warning`, `AppTheme.green.withValues(alpha:.05)`, `AppTheme.danger.withValues(alpha:.05)` |

### Support / Error / Integrity tables
| # | Задача | Файл:строки | Что заменить | На что |
|---|--------|-------------|--------------|--------|
| P0-13 | `SupportConsole` AppBar: убрать Column-subtitle | `support_console_screen.dart:464–476` | `title: Column(...)` | Перенести ID в `appBar.bottom` или в `Chip` в actions |
| P0-14 | `SupportConsole` chip цвета | `support_console_screen.dart:653–661` | `Colors.blue`, `Colors.teal`, `Colors.indigo`, `Colors.deepPurple`, `Colors.orange` | `AppTheme.accent`, `AppTheme.green`, `AppTheme.warning`, `AppTheme.muted` (убрать `teal/indigo/deepPurple`) |
| P0-15 | Severity colors: единый метод | `data_integrity_screen.dart:80–90`, `platform_error_center_screen.dart:27–37` | 8 разных `Colors.*.shade*` в двух файлах | Вынести в `AppStatusColors.severityColor(IntegritySeverity s)` |
| P0-16 | `SizedBox(width: 220)` в PlatformError DataTable | `platform_error_center_screen.dart:128` | `SizedBox(width: 220, ...)` | Убрать `SizedBox`, добавить `maxWidth` через `ConstrainedBox` или сделать колонку `Flexible` |

---

## 4. P1 — после пилота

### Архитектурные задачи

1. **Ввести `AppBreakpoints` константы**
   ```dart
   class AppBreakpoints {
     static const narrow = 600.0;   // текущий
     static const medium = 904.0;   // новый (планшет)
     static const wide   = 1240.0;  // новый (десктоп)
   }
   ```
   Заменить ~12 вхождений `MediaQuery...width < 600` по всему коду.

2. **Ввести `AppStatusColors` словарь**
   ```dart
   class AppStatusColors {
     static Color forStatus(String status) { ... }   // completed/failed/warning/pending
     static Color forSeverity(IntegritySeverity s) { ... }  // P0-15
     static Color forBillingStatus(String s) { ... } // support console
   }
   ```

3. **Ввести `AppSpacing` константы** (шкала §4 дизайн-системы)
   ```dart
   class AppSpacing {
     static const s1 = 4.0;
     static const s2 = 8.0;
     static const s3 = 12.0;
     static const s4 = 16.0;
     static const s5 = 24.0;
     static const s6 = 32.0;
   }
   ```

4. **Решение по типошкале** — прописать `fontSize` в `textTheme` в `AppTheme._build()`: все роли сейчас без `fontSize` → экраны задают вручную.

5. **Компонент `AppDataTable`** (desktop) — wrapper над `DataTable` с sticky header, сортировкой по заголовку, bulk-checkbox, hover строки через `surfaceHi`. Использовать на 3 admin-экранах (`support_console`, `data_integrity`, `platform_error_center`).

6. **Компонент `AppStepper`** — унифицировать `create_company_flow_screen` и `import_mapping_wizard_screen` (оба используют нативный `Stepper` с одинаковым `controlsBuilder`).

7. **`EmptyState` виджет** — уже упомянут в design-system; собрать из `_NoCompanyScreen`, `_ErrorScreen`, `noActivePoints` в один `EmptyState(icon, title, subtitle, action?)`.

8. **Полный responsive refactor** — добавить `md`-уровень (планшет) в `owner_dashboard_shell` (sidebar-rail вместо full sidebar) и `dispatcher_dashboard` (split map+list).

---

## 5. Что нельзя трогать сейчас

| Файл/компонент | Причина |
|----------------|---------|
| `lib/screens/driver/driver_dashboard.dart` — логика автозакрытия по GPS (`_autoCloseTimer`, `_autoClosePendingPoint`, `_autoClosePendingDistanceM`) | Сложная бизнес-логика с `_DriverSessionUi`, 4 вложенных таймера; UI-правки должны идти только в `_buildGpsStatusBanner`, `_buildOtherRouteBanner` |
| `lib/screens/driver/driver_dashboard.dart` — `_mergeVisibleRoutePoints` / `_filterDriverPointsToCurrentRoute` | Критичная логика merge кеша маршрута; не трогать в рамках UI-задач |
| `lib/services/invoice_service.dart` + `create_invoice_dialog.dart` | Логика печати `מקור`/`נאמן למקור`/`העתק` привязана к бухгалтерии (Фаза 2/3 консолидации); UI-правки диалога только после завершения консолидации |
| `lib/widgets/delivery_map_widget.dart` | Зависит от платформенного WebView + Google Maps; изменения могут сломать drag-assign и polyline |
| `lib/widgets/logi_route_tab_bar.dart` | Ключевой фирменный компонент со своим hover/press/RTL; не трогать без полного регрессионного теста |
| `lib/screens/admin/support_console_screen.dart` — вкладки Billing/Payments/Notifications | Используют `LogiRouteAppBarTabBar` внутри AppBar.bottom; вынос в отдельный экран требует рефактора роутинга |
| `functions/` весь код Cloud Functions | Деплой только вручную владельцем; изменения functions влияют на billing/integrity webhooks |
| `lib/core/correlation/correlation_context.dart` | Используется во всех диалогах ошибок; изменения требуют полного регресса |

---

## 6. UI Rules для новых экранов

Чеклист при создании любого нового экрана:

```
[ ] Directionality(textDirection: TextDirection.rtl) обёрнут вокруг Scaffold
[ ] Все цвета — только через AppTheme.* (не Colors.*.shade*)
[ ] Все отступы — значения 4/8/12/16/24/32 (не 6/10/13/14/etc)
[ ] BorderRadius только: circular(8), circular(12), circular(14), circular(16)
[ ] Нет эмодзи в UI-строках — только Material Icons с токен-цветом
[ ] AppBar: title — только Text или Row; subtitle — в appBar.bottom или в отдельном Chip
[ ] AppBar actions: ≤ 3 иконки; остальное в PopupMenuButton
[ ] Один primary ElevatedButton/FilledButton на экран/диалог
[ ] SnackBar: использовать SnackbarHelper.show*/showError/showSuccess (не ScaffoldMessenger напрямую)
[ ] MediaQuery breakpoint через AppBreakpoints.narrow (не магическое 600)
[ ] Нет print() в коде — только debugPrint
[ ] Статусы: только AppStatusColors.forStatus()/forSeverity() (когда будет готов)
[ ] ListView/Column внутри Column: всегда в Expanded или Flexible
[ ] Таблицы desktop: DataTable + SingleChildScrollView(scrollDirection: Axis.horizontal)
[ ] Форма: InputDecoration берёт стиль из inputDecorationTheme (не переопределять border/fill)
```

---

## 7. Быстрые победы — 1 день

Изменения, которые вносятся заменой 1–5 строк и не затрагивают логику:

1. **`owner_dashboard_shell.dart:452–455`** — View-as баннер цвет:
   ```dart
   // Было:
   color: Colors.blue.shade100,
   border: Border(bottom: BorderSide(color: Colors.blue.shade300, width: 2)),
   // Стало:
   color: AppTheme.surfaceHi,
   border: Border(bottom: BorderSide(color: AppTheme.accent, width: 2)),
   ```

2. **`owner_dashboard_shell.dart:465,471,473`** — иконка/текст View-as:
   ```dart
   // Было: color: Colors.blue.shade900
   // Стало: color: AppTheme.accentSoft
   ```

3. **`owner_dashboard_shell.dart:901`** — `_ErrorScreen` icon:
   ```dart
   // Было: color: Colors.red[300]
   // Стало: color: AppTheme.danger
   ```

4. **`import_mapping_wizard_screen.dart:527`** — TableBorder:
   ```dart
   // Было: TableBorder.all(color: Colors.grey.shade300)
   // Стало: TableBorder.all(color: AppTheme.border)
   ```

5. **`platform_error_center_screen.dart:128`** — убрать `SizedBox(width: 220)`:
   ```dart
   // Было: SizedBox(width: 220, child: Text(...))
   // Стало: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis)
   ```

6. **`data_integrity_screen.dart:85`** — severity medium color:
   ```dart
   // Было: return Colors.amber.shade700;
   // Стало: return AppTheme.warning;
   ```

7. **`driver_dashboard.dart:2849,2873`** — радиусы:
   ```dart
   // Было: BorderRadius.circular(10)
   // Стало: BorderRadius.circular(8)
   ```

8. **`dispatcher_dashboard.dart:486,752`** — SnackBar orange:
   ```dart
   // Было: backgroundColor: Colors.orange
   // Стало: backgroundColor: AppTheme.warning
   ```

9. **`dispatcher_dashboard.dart:1273,1280`** — SnackBar optimize:
   ```dart
   // Было: backgroundColor: changed ? Colors.green : null
   // Стало: backgroundColor: changed ? AppTheme.green : null
   ```

10. **`platform_error_center_screen.dart:30–36`** — severity colors (4 строки):
    ```dart
    // Было: Colors.red.shade700 / Colors.orange.shade800 / Colors.amber.shade800 / Colors.blueGrey
    // Стало: AppTheme.danger / AppTheme.warning / AppTheme.warning / AppTheme.muted
    ```

---

## 8. Большие переделки — на позже

1. **Единая компонент-библиотека `lib/widgets/app_components/`**
   - `AppDataTable` (sticky header, sort, bulk, hover)
   - `AppStepper` (вместо нативного Stepper)
   - `EmptyState` (иконка + title + body + кнопка)
   - `AppStatusChip` (токен-цвет по статусу/severity)
   - `ViewAsBanner` (унифицированный для driver/dispatcher/owner)

2. **Responsive система на 3 breakpoints**
   Ввести `AppBreakpoints.narrow/medium/wide`, добавить `md`-layout:
   - Owner sidebar: `md` → NavigationRail с коллапсом; `lg` → полный sidebar 220dp
   - Dispatcher: `md` → split map(60%) + list(40%); `sm` → вкладки (текущее)

3. **Типошкала в `textTheme`**
   Прописать `fontSize` в `AppTheme._build()` для всех ролей (сейчас 0 из 14 имеют `fontSize`). Это устранит сотни inline `TextStyle(fontSize: 14)` по всему коду.

4. **`SnackbarHelper` как единственный путь к SnackBar**
   Запретить прямой `ScaffoldMessenger.of(context).showSnackBar(...)` в экранах. Все 23+ прямых вызова в аудите — заменить через helper.

5. **RTL глобально через `MaterialApp.locale`**
   Вместо точечного `Directionality` на каждом экране — обрабатывать в `main.dart`/роутере; проверить что все 10 экранов корректно наследуют.

---

## 9. Рекомендация по тёмной теме

### Что есть сейчас

В `lib/theme/app_theme.dart`:
- `static const AppPalette darkPalette` — полная качественная палитра `(bg #0A1430 · surface #0E1A38 · …)` (строки 42–56)
- `static const AppPalette lightPalette` — активная (строки 58–72)
- `static bool _isDark = false` — флаг (строка 74)
- `static void setDark(bool value)` — метод переключения (строка 79)
- `static AppPalette get p => _isDark ? darkPalette : lightPalette` — геттер (строка 81)

Правило проекта (CLAUDE.md): **одна фиксированная тема** (светлая).

Механизм есть, но нигде не вызывается: `AppTheme.setDark(true)` не вызывается ни в одном месте кода (проверено через Grep). Тёмная тема — **«спящий» код**, но не мёртвый (все геттеры через `p` уже учитывают обе палитры).

### Три варианта

**Вариант A — Включить переключатель тёмной темы**
- Плюсы: тёмная палитра качественная (navy-premium), востребована в логистике (ночные смены водителей)
- Минусы: нужно `ThemeService` (хранить выбор), добавить toggle в UI (settings), проверить все экраны (46+ хардкодов в driver-screen сделают тёмную тему сломанной)
- **Условие**: сначала вычистить все `Colors.*.shade*` во всех файлах (P0 + P1), только потом включать

**Вариант B — Удалить `darkPalette/setDark/_isDark` как мёртвый код** *(рекомендуется сейчас)*
- Плюсы: упрощает AppTheme (-30 строк), убирает путаницу («есть, но не работает»), снижает риск случайного включения
- Минусы: при желании добавить тёмную тему потом — нужно восстанавливать
- Реализация: удалить строки 42–56 (`darkPalette`), 74–81 (`_isDark`, `setDark`, `p`, `isDark`), изменить `light()` на главный метод; `dark()` оставить как заглушку или удалить

**Вариант C — Оставить как есть (статус-кво)**
- Плюсы: ничего не трогать, нулевой риск
- Минусы: вводит разработчиков в заблуждение (есть код, который не работает)

### Рекомендация

> **B сейчас** → при желании добавить тёмную тему позже, переписать за 1 час (палитра задокументирована в `docs/design-system.md §5.2`).
>
> Главное условие для перехода к A: **сначала все 46+ хардкодов `Colors.*.shade*` в `driver_dashboard.dart` должны быть заменены на токены `AppTheme.*`** — иначе тёмная тема будет выглядеть сломанной на главном экране приложения.

---

*Конец отчёта. Файлы затронуты только аудитом (чтение), код не изменялся.*
