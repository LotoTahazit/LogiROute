# LogiRoute — техническая структура проекта

> **Версия:** 2026-06-21  
> **Назначение:** due diligence, разработка, аудит соответствия коду  
> **Источник истины:** репозиторий LogiRoute3 (`lib/`, `functions/`)  
> **Позиционирование и сравнение с рынком:** [`competitive-analysis.md`](competitive-analysis.md)

---

## 1. Стек и платформы

| Компонент | Реализация |
|-----------|------------|
| Frontend | Flutter (Web, Android) |
| Backend | Firebase: Auth, Firestore, Functions, Hosting, FCM, Storage |
| Маршруты | OSRM (`osrm_directions_service`, `osrm_navigation_service`) |
| Карты | Google Maps |
| Платежи | Stripe (`createCheckoutSession` CF) |
| Локализация | he, ru, en (`lib/l10n/`) |

**Production (web):** https://logiroute-app.web.app

---

## 2. Роли и точка входа

Маршрутизация после login: `lib/widgets/role_router.dart`.

| Роль | Экран | ModuleGuard | BillingGuard |
|------|-------|-------------|--------------|
| `super_admin` | `AdminDashboard` | нет | нет |
| `admin` | `AdminDashboard` | нет | нет |
| `owner` | `OwnerDashboardShell` | нет | да |
| `accountant` | `OwnerDashboardShell` | нет | да |
| `dispatcher` | `DispatcherDashboard` | `logistics` | да |
| `driver` | `DriverDashboard` | `logistics` | да |
| `warehouse_keeper` | `WarehouseDashboard` | `warehouse` | да |
| `pending` | экран ожидания одобрения | — | — |
| `viewer` | экран «нет рабочего экрана» (`_NoWorkspaceScreen`) | — | — |

**Замечание по `viewer`:** роль **отключена** до реализации read-only dashboard. Назначение в UI запрещено (`PermissionsService.canAssignRole(viewer) == false`). Существующие viewer видят экран с просьбой обратиться к администратору; Firestore read по компании для viewer заблокирован.

**View-as:** admin/super_admin могут просматривать UI от имени другой роли (`authService.viewAsRole`).

---

## 3. Модули SaaS и ModuleGuard

Идентификаторы модулей (`ModuleEntitlements`): `warehouse`, `logistics`, `dispatcher`, `accounting`, `reports`.

Проверка: `lib/widgets/module_guard.dart`, `lib/services/module_manager.dart`.

> **Правило для guards (обязательно):** entitlements для `ModuleGuard`, `ModuleManager`, Firestore rules и любой проверки доступа к модулю читаются **только** из **`companies/{companyId}.modules`** на root company doc.  
> **`companies/{companyId}/settings/settings.modules` — deprecated mirror.** Его **нельзя** использовать для guards, rules или решений deny/allow. Mirror синхронизируется при `CompanyModulesService.applyPlan()` только для обратной совместимости UI/отладки.

| Правило | Код |
|---------|-----|
| `dispatcher` требует `logistics` | `ModuleManager.checkDependencies` |
| При `billingStatus = blocked` модули недоступны | `ModuleManager.hasModule` |
| Активный billing: `active`, `grace`, или `trial` (не истёк) | `ModuleManager.isBillingActive` |
| Entitlements для guard | root `companies/{id}.modules` через `CompanySettingsService.getSettings()` (root overlay) |

**Привязка ролей к ModuleGuard:**

- `dispatcher`, `driver` → `requiredModule: 'logistics'`
- `warehouse_keeper` → `requiredModule: 'warehouse'`

---

## 4. Тарифные планы

Источники: `functions/config/billing_pricing.json`, `lib/screens/admin/module_toggle_screen.dart`, `lib/services/plan_limits_service.dart`.

### 4.1. Цены (₪/мес, промо 3 месяца)

| План | promo | regular | setup |
|------|-------|---------|-------|
| `warehouse_only` | 990 | 1,290 | 1,500 |
| `logistics` | 1,490 | 1,990 | 2,000 |
| `ops` | 2,290 | 2,990 | 3,000 |
| `full` | 2,990 | 3,990 | 5,000 |

### 4.2. Модули по плану

| План | warehouse | logistics | dispatcher | accounting | reports |
|------|-----------|-----------|------------|------------|---------|
| `warehouse_only` | ✓ | — | — | — | — |
| `logistics` | — | ✓ | ✓ | — | ✓ |
| `ops` | ✓ | ✓ | ✓ | — | ✓ |
| `full` | ✓ | ✓ | ✓ | ✓ | ✓ |

### 4.3. Лимиты по умолчанию (`PlanLimits.fromMap` / `applyPlan`)

| План | maxUsers | maxDocsPerMonth | maxRoutesPerDay |
|------|----------|-----------------|-----------------|
| `warehouse_only` | 5 | 500 | 10 |
| `logistics` | 10 | 1,000 | 40 |
| `ops` | 15 | 2,000 | 50 |
| `full` | 50 | 10,000 | 200 |

**Источник:** `companies/{id}.limits` на root (пишется через `applyPlan`). Fallback — таблица выше по полю `plan`. Magic defaults `999/99999` **удалены** (H5).

### 4.3.1. Enforcement лимитов (H5 — pilot)

| Лимит | Pilot | UI | Server enforce |
|-------|-------|-----|----------------|
| `maxUsers` | **soft** (warning) | Billing Portal, Owner Billing/Users | нет (rules/CF) |
| `maxDocsPerMonth` | **soft** (warning) | Billing Portal, Owner Overview/Billing | нет — `issueInvoice.js` комментарий |
| `maxRoutesPerDay` | **not enforced** | лимит показан, usage не считается | нет |
| Addons (drivers, warehouse locations, export) | **commercial only** | pricing metadata | нет |

Политика: `lib/models/plan_limit_policy.dart`. Переключение soft→hard — одна точка (`PlanLimitPolicy.enforcement`).

`PlanLimitsService` — usage + предупреждения 80%/100%, **не блокирует** операции на пилоте.

### 4.4. Addons (`billing_pricing.json`)

| Addon | included | pricePerMonth |
|-------|----------|---------------|
| driver | 5 | ₪99 |
| warehouseLocation | 1 | ₪199 |
| dedicatedExport (Firestore→GCS) | — | ₪149 |

### 4.5. Billing status (C3 — единая state machine)

**Stored statuses** (поле `companies/{id}.billingStatus`): `active`, `trial`, `grace`, `suspended`, `cancelled`.

| Status | Доступ (read/write) | UI |
|--------|---------------------|-----|
| `active` | ✅ | dashboard |
| `trial` + `now < trialUntil` | ✅ | trial banner |
| `trial` + trial expired, `now < graceUntil` | ✅ | grace banner (effective grace) |
| `grace` + `now < paidUntil + gracePeriodDays` | ✅ | grace banner |
| `suspended` / `cancelled` / `blocked`* | ❌ | blocked + pay/support |
| grace expired (до cron → suspended) | ❌ | blocked + pay/support |

\* `blocked` — **legacy alias** для `suspended` (не писать в новые документы).  
`trial_expired` / `past_due` — **не stored**; только UI labels.

**Grace:** `graceUntil = anchor + gracePeriodDays` (default 7). Anchor: `trialUntil` (expired trial) или `paidUntil` (status `grace`).

**Обязательные поля:**

| Status | Поля |
|--------|------|
| `trial` | `trialUntil` |
| `grace` | `paidUntil` (или fallback `trialUntil`) |
| all | `gracePeriodDays` optional (default 7) |

**Кто меняет `billingStatus`:** `billingEnforcer` (cron), payment webhooks, `billing_locks_screen` / super_admin, provision (`trial` при создании). Клиент **не** пишет произвольно (rules).

**Единая логика:** `lib/services/billing_state.dart`, `functions/lib/billingState.js`, `firestore.rules` (`billingAllowsAccess`), `BillingGuard`, `ModuleManager`, `issueInvoice`.

**Transitions (cron):** trial expired → `grace`; active + paidUntil expired → `grace`; grace expired → `suspended`. `cancelled` — terminal.

`EntitlementsService.getVisibleSectionsForCompany`: без доступа — только `billing`, `settings`.

---

## 5. Архитектура модулей

```
LogiRoute
│
├── Доступ
│   ├── Firebase Auth
│   ├── RoleRouter · BillingGuard · ModuleGuard
│   └── Stripe checkout · billingEnforcer (CF)
│
├── Admin (admin / super_admin)
│   └── users · grouped AppBar menus (reports, warehouse, company, billing, platform)
│
├── Owner Dashboard (owner / accountant)
│   ├── overview · users_roles · billing · settings
│   ├── audit · ops_health · reports · create_document · clients · accounting
│   ├── PermissionsService — права по **effectiveRole** (`viewAsRole ?? userModel.role`)
│   └── **View-as** (admin/super_admin): UI-симуляция роли; **не** меняет Firestore claims — rules проверяют реальную роль
│
├── Dispatcher
│   ├── tabs: delivery points · routes · map
│   └── invoices/credit notes per point · route print · merge routes
│
├── Driver
│   ├── delivery points stream · map
│   ├── GPS (RealtimeGpsService, OptimizedLocationService, BackgroundLocationService on Android)
│   ├── auto-close by GPS (AppConfig.autoCompleteRadius = 100 m)
│   ├── Proof of Delivery (photo)
│   └── FCM · navigation (Waze / Maps / OSRM)
│
├── Warehouse
│   ├── inventory list · add item · box type catalog
│   ├── inventory count · import/export Excel (web export)
│   └── computerized warehouse (flag computerizedWarehouseEnabled): USB barcode in/out
│
├── Customer Master Data (справочник клиентов)
│   └── см. раздел 6
│
├── Accounting (module accounting, plan full)
│   └── см. раздел 7
│
├── Reports & Analytics
│   ├── Owner ReportsSection (revenue, VAT, clients, stock if warehouse module)
│   └── Admin AnalyticsScreen
│
├── Notifications
│   ├── FCM (FcmService, onPointAssigned CF)
│   ├── Email CF · sendCompanyEmail
│   └── WhatsApp CF (sendWhatsApp) — test from integration settings
│
├── Archive & retention
│   ├── route archive · archive management
│   └── cleanupPodPhotos (90d) · cleanupDeliveryLogs (30d) — CF scheduled
│
└── Cloud Functions (functions/index.js)
    └── см. раздел 10
```

---

## 6. Справочник клиентов (Customer Master Data)

**Определение:** единая база клиентов для логистики, маршрутов и бухгалтерских документов.  
**Это не CRM.**

**Код:** `lib/models/client_model.dart`, `lib/services/client_service.dart`, `lib/screens/shared/client_management_screen.dart`, Owner section `clients_section.dart` (embedded `ClientManagementScreen`).

### 6.1. Поля записи клиента

| Поле | Поле в коде |
|------|-------------|
| Номер клиента | `clientNumber` |
| Название | `name` |
| Адрес | `address` |
| Координаты | `latitude`, `longitude` |
| Телефон | `phone` (optional) |
| Контактное лицо | `contactPerson` (optional) |
| VAT ID (ח.פ) | `vatId` (optional) |
| Зоны доставки | `zones` |
| Способ оплаты по умолчанию | `paymentMethod` (optional) |

Firestore: `companies/{companyId}/clients/`.

### 6.2. Реализованные операции

- CRUD (`ClientService`)
- Поиск по имени, номеру, адресу (`ClientManagementScreen._filterClients`)
- Excel import/export (`ClientImportService`, export в том же экране)
- Массовый re-geocode (`ClientRegeocodeService`)
- При изменении адреса/координат — обновление **активных** точек доставки (`status` ∈ `pending`, `assigned`, `in_progress`) с тем же `clientNumber`
- `ClientLearningService` — накопление `navigation_point` и `service_time` после завершённых доставок (≥5 доставок для обновления клиента)

### 6.3. Использование в других модулях

- Создание точек доставки (dispatcher)
- Выставление счетов / накладных (поля клиента в invoice)
- Owner Dashboard → секция «Клиенты»

### 6.4. Что НЕ входит

- ❌ сделки (Leads)
- ❌ Sales Pipeline
- ❌ история звонков
- ❌ напоминания менеджеру
- ❌ коммерческие предложения
- ❌ задачи отдела продаж
- ❌ полноценная CRM

> **Примечание:** `taskNote` на точке доставки — задание **водителю** (без товара), не sales task.

### 6.5. Roadmap

Полноценная CRM рассматривается как **отдельный модуль будущих версий** и **не входит в текущий scope** проекта.

---

## 7. Бухгалтерия (фактическая реализация)

**Код:** `lib/features/owner_dashboard/models/accounting_doc.dart`, `lib/services/invoice_service.dart`, CF `issueInvoice`, `functions/accounting/`.

### 7.1. Типы документов

| Тип | `AccountingDocType` |
|-----|---------------------|
| חשבונית מס | `tax_invoice` |
| קבלה | `receipt` |
| חשבונית מס / קבלה | `tax_invoice_receipt` |
| זיכוי | `credit_note` |
| תעודת משלוח | `delivery_note` |

Статусы: `draft`, `issued`, `locked`, `credited`, `voided_before_delivery`.

### 7.2. Compliance и интеграции

| Функция | Реализация |
|---------|------------|
| PDF | `invoice_pdf_layout.dart`, print services |
| BKMV export | `lib/services/bkmv/` |
| Israel Invoice (מספר הקצאה) | CF `israelInvoice*` |
| Integrity chain | CF `verifyIntegrityChain`, `scheduledIntegrityCheck` |
| Period lock | `accounting_period_lock_panel.dart` |
| VAT / עוסק פטור | `company_settings.dart` (`vatRegime`) |
| Cross-module audit | `CrossModuleAuditService`, `audit_section.dart` |
| Sync с GreenInvoice / iCount | **исходящий** push документа (`sync_external_document.js`, `batchAccountingSync`) |
| File export adapter | `file_export` adapter |

**Не заявлять «двусторонний sync»:** в коде реализована отправка документов во внешние системы и запись `externalId` / PDF URL; импорт документов из провайдера — отдельный сценарий, не полноценный bi-directional CRM-style sync.

---

## 8. Склад и מחסן ממוחשב

Подробно: [`computerized-warehouse.md`](computerized-warehouse.md).

| Функция | Условие |
|---------|---------|
| Остатки, каталог מק"ט | модуль `warehouse` |
| Инвентаризация | `InventoryCountScreen` |
| USB barcode scan | `computerizedWarehouseEnabled = true` |
| Журнал | `inventory_history`, actions `barcode_in` / `barcode_out` |
| Количество по умолчанию при вводе | `0` (блокировка submit при ≤ 0) |

**Не реализовано:** камера телефона для QR; Wi‑Fi scanner server mode.

---

## 9. Ограничения текущей реализации (MVP)

Только подтверждённые кодом ограничения:

| Область | Факт |
|---------|------|
| Barcode | USB keyboard-wedge; `autofocus` на поле кода |
| Camera QR | нет (`mobile_scanner` не подключён) |
| Wi‑Fi scanner | нет |
| Customer module | справочник, не CRM (раздел 6.4) |
| External API | CF `validateApiKey`, `apiKeyAction`; нет публичного REST CRUD |
| `viewer` role | отключена: экран «нет workspace», назначение в UI запрещено |
| Warehouse locations | одна координата склада в UI; addon `warehouseLocation` — billing metadata |
| iOS | конфигурация/гайд есть; основной driver UX — Android + Web |
| Offline | Firestore streams; локально — prefs/кэш настроек driver, не full offline warehouse |
| Computerized warehouse tax audit | журнал движений есть; формальный audit под רשות המסים — не реализован |
| Plan limits | предупреждения (H5: soft/notEnforced), не hard block — см. §4.3.1 |

### Roadmap (не в текущем коде)

1. Camera QR для מחסן ממוחשב  
2. Привязка barcode-операций к документам доставки  
3. Формальный tax audit trail computerized warehouse  
4. Расширение external API  
5. Полноценная CRM — отдельный модуль  

---

## 10. Меню по ролям

### Admin AppBar (`admin_app_bar_actions.dart`)

| Группа | Пункты |
|--------|--------|
| Отчёты | analytics, reports, inventory_report, inventory_counts, activity_log |
| Склад | warehouse, products |
| Компания | company_settings, terminology, route_archive, archive, client_management |
| Биллинг | billing_portal, subscription |
| Platform (super_admin) | billing_locks, module_toggle, backup, data_retention, integrity_check, **create_company** (4-step flow), create_company_legacy, demo_company, customer_health, **error_center**, support_console |

### Owner Dashboard (`owner_dashboard_shell.dart`)

| Группа | section keys |
|--------|--------------|
| Обзор | overview |
| Управление | users_roles, billing, settings |
| Операции | ops_health, reports, create_document, clients, accounting |
| Комплаенс | audit |

### Dispatcher

**Tabs:** delivery points · routes · map  
**Menu (logistics):** clients, import delivery points, prices, warehouse location, shift settings, route archive, archive, data retention (info)  
**Menu (warehouse — read-only, C6):** warehouse inventory (остатки/поиск/low stock), inventory changes report  
**Не доступно dispatcher:** FAB добавить товар, barcode in/out, инвентаризация, import, edit/delete, approve count — `WarehouseAccess.canWriteWarehouse` = false (совпадает с Firestore `canWriteModule(warehouse)`).

### Warehouse keeper

**Operations:** barcode_scan*, inventory_count, manage_types, add_type  
**Reports:** history  
**Import/export:** import, export (web)  
\* при `computerizedWarehouseEnabled`

### Driver

route history · POD info · Android setup (Android only)

---

## 11. Структура репозитория

```
lib/
├── config/
├── core/
├── features/owner_dashboard/
├── models/
├── screens/   admin · auth · dispatcher · driver · shared · warehouse
├── services/
├── widgets/
└── l10n/

functions/
├── index.js
├── config/billing_pricing.json
└── accounting/
```

### Ключевые entry points

| Файл | Назначение |
|------|------------|
| `lib/main.dart` | App bootstrap |
| `lib/widgets/role_router.dart` | Role routing |
| `lib/features/owner_dashboard/widgets/owner_dashboard_shell.dart` | Owner UI |
| `lib/screens/dispatcher/dispatcher_dashboard.dart` | Dispatcher |
| `lib/screens/driver/driver_dashboard.dart` | Driver |
| `lib/screens/warehouse/warehouse_dashboard.dart` | Warehouse |
| `lib/services/firestore_paths.dart` | Firestore paths |
| `functions/index.js` | Cloud Functions exports |

### Firestore (упрощённо)

```
companies/{companyId}/
├── logistics/_root/
│   ├── clients/{clientId}/
│   │   └── delivery_history/{entryId}   ← GPS learning (driver create, logistics read)
│   ├── delivery_points/{pointId}/
│   │   └── visit_logs/{logId}           ← GPS visit on complete (assigned driver)
│   ├── routes/                          ← **актуальный path** (FirestorePaths.routes)
│   └── …
├── settings/                            ← profile UI (name, taxId, …); **не** source of truth для modules
│   └── remote_config                    ← **Company Remote Config** (pilot tunables без rebuild)
├── warehouse/_root/inventory/
├── accounting/_root/invoices/
├── metrics/daily/days/{YYYY-MM-DD}   ← Owner KPI (CF writer)
├── driver_locations/{driverId}       ← **live GPS** (writer + health/onboarding/dispatcher; поле `timestamp`)
├── integrity_checks/{checkId}        ← **Data Integrity** прогоны (CF writer, read owner+)
├── integrity_issues/{issueId}        ← **Data Integrity** проблемы (CF create; owner+ меняет status)
└── audit/

users/{uid}
```

**Rules (learning):** `visit_logs` — create только назначенный driver (parent `driverId`) или admin/dispatcher write; read — `canUseModule(logistics)`; delete запрещён. `delivery_history` — create driver/admin; read logistics roles; viewer без доступа.

### Company Remote Config (`settings/remote_config`)

| Компонент | Путь |
|-----------|------|
| Model | `lib/models/company_remote_config.dart` |
| Service | `lib/services/company_remote_config_service.dart` |
| Validator | `lib/services/company_remote_config_validator.dart` |
| Admin UI | `lib/screens/admin/company_remote_config_screen.dart` (+ Owner Settings card) |
| Support read-only | `RemoteConfigReadonlyBlock` в Support Console |

**Поля:** auto-close radius/wait/reset, undo seconds, GPS stale, session heartbeat/stale, background auto-close, session lock, prefer Waze, import preview rows. Defaults = `AppConfig`. Invalid values → default + Platform Error Center warning. Audit: `remote_config_changed`.

### Data Integrity Checker (`integrity_checks` / `integrity_issues`)

| Компонент | Путь |
|-----------|------|
| Чистая логика проверок | `functions/lib/integrityChecks.js` |
| Cloud Function (callable + nightly) | `functions/generateIntegrityCheck.js` (`generateIntegrityCheck`, `scheduledDataIntegrityCheck`) |
| Model | `lib/models/integrity_issue.dart` (`IntegrityIssue`, `IntegrityCheck`) |
| Service | `lib/services/data_integrity_service.dart` |
| UI | `lib/screens/admin/data_integrity_screen.dart` (меню Company + Owner Settings card) |
| Support read-only | `DataIntegrityReadonlyBlock` в Support Console |

**Проверки (P0):** users/members (orphan, роли), delivery points (cross-tenant, водитель/маршрут, координаты), routes (без водителя/точек, все закрыты), invoices (cross-tenant, без даты выписки, отрицательная сумма, credit note без ссылки, sync), inventory (отрицательный остаток, тип товара), driver sessions/GPS (зависшие, нулевые координаты), accounting sync (failed), remote_config (вне диапазона). Severity: critical/high/medium/low. Дедуп по fingerprint (SHA-256), auto-resolve исчезнувших, reopen вернувшихся. CF пишет admin SDK; клиент только меняет `status`. Audit: `integrity_check_started/completed`, `integrity_issue_ignored/resolved`. Доступ: super_admin / owner / admin.

### Modules / entitlements (source of truth)

**Читать для guards — только root:** `companies/{companyId}.modules` (не `settings/settings.modules`).

| | |
|---|---|
| **Source of truth** | `companies/{companyId}.modules` + `plan` + `limits` на **root** company doc |
| **Firestore rules** | `hasModule()` читает root — guards обязаны совпадать |
| **Dart service** | `CompanyModulesService.applyPlan()` — **единственная** точка записи plan/modules/limits (клиент) |
| **CF service** | `functions/lib/companyModules.js` → `applyPlanToCompany()` — server mirror |
| **Guards** | `ModuleGuard` → `CompanySettingsService.getSettings()` — **overlay entitlements с root**; fail-closed |
| **Writers** | `module_toggle_screen`, `subscription_screen`, `CompanyProvisionService`, CF `onCompanyCreated`, `createCheckoutSession` (planId), `demoSeed` |
| **Deprecated mirror** | `settings/settings.modules` (+ `plan`) — пишется только через `applyPlan()` / `applyPlanToCompany()` |
| **Запрещено** | Прямой `company.update({ plan })` без синхронного modules/limits |

**Anti-pattern (не делать):** `settings/settings.modules` в `ModuleGuard`, `hasModule()` rules, route guards, Firestore client checks.

### Daily Metrics (Owner Dashboard → Обзор)

| | |
|---|---|
| **Reader** | `MetricsService` → `companies/{companyId}/metrics/daily/days/{YYYY-MM-DD}` |
| **Writer** | Cloud Functions: `recalculateDailyMetrics` (callable), `scheduledDailyMetrics` (01:00 Asia/Jerusalem — сегодня + вчера) |
| **Клиент** | read-only; кнопка «Пересчитать метрики» — owner/admin/super_admin |
| **Legacy (C5 CLOSED)** | root `daily_summaries` + `SummaryService` **удалены** — не питали Owner Overview, writes без rules |
| **Source of truth KPI** | `companies/{companyId}/metrics/daily/days/{YYYY-MM-DD}` |

**Поля KPI:** `deliveriesToday`, `invoicesThisMonth`, `warehouseMovements`, `activeDrivers`, `printEventsToday`, `printErrorsToday`, `recordsCreatedToday`, `updatedAt`.

---

## 12. Cloud Functions (exports из index.js)

| Function | Назначение |
|----------|------------|
| `issueInvoice` | выпуск счёта |
| `syncUserClaims` / `ensureMyClaims` | custom claims |
| `israelInvoiceAuthUrl`, `israelInvoiceOAuthCallback`, `requestAllocationNumber`, `israelInvoiceStatus` | Israel Invoice |
| `verifyIntegrityChain`, `scheduledIntegrityCheck` | integrity |
| `billingEnforcer` | billing enforcement |
| `processPaymentWebhook`, `registerManualPayment`, `createCheckoutSession` | payments |
| `batchAccountingSync`, `retryAccountingSync`, `testAccountingCredentials` | accounting sync |
| `sendPushNotification`, `sendEmailNotification`, `sendPasswordResetEmail`, `sendCompanyEmail`, `sendWhatsApp` | notifications |
| `validateApiKey`, `apiKeyAction` | API keys |
| `onCompanyCreated`, `onUserRegistered` | lifecycle triggers |
| `archiveOldRoutes`, `cleanupDriverHistory`, `cleanupPodPhotos`, `cleanupDeliveryLogs` | scheduled maintenance |
| `onPointAssigned`, `onRoutePointChanged` | delivery triggers |
| `recalculateDailyMetrics`, `scheduledDailyMetrics` | Owner Dashboard KPI (bounded daily metrics) |
| `migrateAccountingCounters`, `seedBillingPricing` | admin/migration |

---

## 12b. Create Company Flow (super_admin)

| | |
|---|---|
| **Экран** | `lib/screens/admin/create_company_flow_screen.dart` — 4 шага: компания → первый owner/admin → режим внедрения → подтверждение |
| **Success** | `create_company_success_screen.dart` — без auto-push Setup Wizard |
| **Оркестрация** | `CreateCompanyFlowService` → `CompanyProvisionService.createCompany` + `applyPlan` + `settings/config` + `AuthService.createUser` / `linkUserToCompany` + password reset + audit |
| **Режимы** | `CompanyOnboardingMode`: `self_setup` (owner → **Launch Center** / `OnboardingCenterScreen`) · `done_for_you` (super_admin настраивает через Launch Center) |
| **Legacy** | `CreateCompanyScreen` — меню `create_company_legacy` (старый wizard сразу после создания) |
| **Demo** | `DemoCompanyScreen` / CF `createDemoCompany` — отдельный путь, не затрагивается |
| **Audit** | `company_created`, `initial_owner_created`, `onboarding_mode_selected` → `companies/{id}/audit` + `correlationId` |

**Defaults при provision:** `country=Israel`, `defaultLanguage=he`, `timezone=Asia/Jerusalem`, `trialDays=14`, plan из шага 1.

---

## 12c. Launch Center (гибкий онбординг)

| | |
|---|---|
| **UI** | `lib/screens/setup/onboarding_center_screen.dart` — **Launch Center** (карточки в любом порядке) |
| **Legacy** | `CompanySetupWizardScreen` — линейный мастер (внутренний механизм прогресса, кнопка «Пошаговый мастер») |
| **Карточки** | 11 задач: реквизиты · первый owner/admin · водители · клиенты · SKU · склад · бухгалтерия · GPS · первый маршрут · тестовая доставка · Go Live |
| **Прогресс** | `companies/{id}/settings/setup_wizard` — `steps` (wizard) + `cardMeta` (assignedRole / assignedUserId / notes) + `onboardingMode` |
| **Логика** | `LaunchCenterLogic` · `OnboardingSectionId` · `OnboardingStepSignals.checkCardSignals()` |
| **Делегирование** | owner / admin / super_admin назначают роль (owner, dispatcher, warehouse_keeper, accountant) |
| **Доступ** | owner, admin, super_admin; **driver не видит** Launch Center |
| **Режимы** | `self_setup` (owner) · `done_for_you` (super_admin через view-as / admin menu) |
| **Авто-сигналы** | clients/products imported · driver exists · fresh GPS · route exists · completed delivery · owner/admin exists |
| **Готовность** | «Компания готова» когда все **обязательные** карточки completed/skipped |

---

## 12d. Platform Error Center (super_admin)

| | |
|---|---|
| **Экран** | `platform_error_center_screen.dart` · `platform_error_detail_screen.dart` |
| **Хранилище** | `platform/system/errors/{fingerprint}` · stack в `platform/system/error_private/{id}` |
| **Клиент** | `PlatformErrorService` · hooks в `main.dart` · `CorrelationContext.logError` |
| **CF** | `reportPlatformError` · `instrumentCloudExports` · `cleanupSystemErrors` (90d) |
| **Группировка** | SHA256(`errorType` + stack line 2 + `operation`) → `occurrences++` |
| **Badge** | Platform menu — open `critical` count |

---

## 12a. Customer Health Dashboard (super_admin)

| | |
|---|---|
| **Экран** | `lib/screens/admin/customer_health_dashboard_screen.dart` |
| **Сервис списка** | `CustomerHealthDashboardService` — `companies` paginated (50/page) |
| **Tenant snapshot** | `CompanyHealthService.fetchTenantSnapshot()` — **без** OnboardingStepSignals |
| **Strip (owner)** | `CompanyHealthStrip` → `fetch()` — без изменений |
| **Доступ** | только `super_admin` (Platform → Customer Health) |
| **Клик по строке** | `SupportConsoleScreen(initialCompanyId)` + company switch |

**Pagination:** `companies.orderBy(documentId).limit(50).startAfterDocument(...)`

**Bounded reads на компанию (не читаем clients/invoices/delivery_points/inventory):**

| Данные | Запрос |
|--------|--------|
| Company profile | `companies/{id}` (из page query) |
| Setup % | `settings/setup_wizard` (1 doc) |
| Metrics | `metrics/daily/days/{YYYY-MM-DD}` (1 doc) |
| Sync status | `sync_ledger` orderBy updatedAt **limit 1** |
| Failed sync count | `sync_ledger` where status=failed **count()** |
| Drivers / routes | `members` count + `routes` active **count()** |
| Stale GPS | `companies/{id}/driver_locations` — **GpsHealth** (поле `timestamp`, fallback `updatedAt`; on-shift без fresh fix за 48h) |
| Last activity | `audit` orderBy createdAt desc **limit 1** |

**Health rules (`computeCustomerHealthLevel`):**

| Level | Условия |
|-------|---------|
| **Critical** | billing suspended/cancelled, или problems≥2, или failed sync≥3 |
| **Warning** | grace, или problems&gt;0, или failed sync&gt;0, или stale GPS&gt;0, или setup&lt;100% |
| **Healthy** | иначе |
| **Unknown** | ошибка чтения company doc |

---

## 13. Связанные документы

| Документ | Содержание |
|----------|------------|
| [`go-live-decision.md`](go-live-decision.md) | 22 пункта gate для первого клиента |
| [`readiness-backlog.md`](readiness-backlog.md) | сверка tech-audit, backlog по фазам |
| [`customer-readiness.md`](customer-readiness.md) | вопросы директора, процесс внедрения |
| [`competitive-analysis.md`](competitive-analysis.md) | позиционирование, сравнение, экономика (оценочно) |
| [`computerized-warehouse.md`](computerized-warehouse.md) | מחסן ממוחשב |
| [`delivery_points_import_template.csv`](delivery_points_import_template.csv) | шаблон импорта точек |
| `ISRAELI_TAX_COMPLIANCE.md` | налоговое compliance (детали) |
| `ARCHITECTURE.md` | правила FirestorePaths для разработчиков |

---

*При расхождении документа и кода приоритет у кода. Тарифы — у `functions/config/billing_pricing.json`.*
