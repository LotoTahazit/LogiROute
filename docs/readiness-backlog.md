# Readiness Backlog — LogiRoute (финал после tech-audit)

> **Дата сверки:** 2026-06-21  
> **Scope пилота:** 1 компания · 3–5 водителей · 50–100 клиентов  
> **Связано:** [`go-live-decision.md`](go-live-decision.md) · [`customer-readiness.md`](customer-readiness.md)

Статусы аудита: **CLOSED** · **OPEN** · **PARTIAL** · **BACKLOG**

---

## Сверка пунктов tech-audit

| # | Пункт аудита | Статус | Fix / где | Проверка |
|---|--------------|--------|-----------|----------|
| 1 | BillingGuard bypass (timeout → доступ) | **CLOSED** | `lib/widgets/billing_guard.dart` — `StreamLoadingGate.onTimeout` → `_VerificationFailedScreen` (fail-closed, retry) | **Ручной:** suspended + медленная сеть → экран «не удалось проверить», не dashboard |
| 2 | Checkout false success | **CLOSED** | `lib/widgets/checkout_ui_helper.dart` — `onOpened` только после успешного open; ошибки → SnackBar/dialog | **Ручной:** блок popup / session error → нет зелёного «оплачено» |
| 3 | GPS silent fail | **CLOSED** | `lib/screens/driver/driver_dashboard.dart` — `DriverGpsStatus`, `_buildGpsStatusBanner`, health-check | **Ручной:** выключить GPS → баннер disabled/error + «Проверить снова» |
| 4 | viewer dead end | **CLOSED** | `lib/widgets/role_router.dart` (`_NoWorkspaceScreen`); `permissions_service.dart` — `canAssignRole(viewer)==false` | **Ручной:** legacy viewer → экран с текстом; назначение viewer недоступно |
| 5 | visit_logs / delivery_history rules | **CLOSED** | `firestore.rules` + `test/firestore.rules.test.js` (create/read/deny viewer) | **Авто:** `npm run test:rules` |
| 6 | Support / Upgrade noop | **CLOSED** | `lib/widgets/billing_support_actions.dart` — dialog email/phone, `CheckoutUiHelper` для upgrade | **Ручной:** blocked screen → Support + Pay открывают dialog/checkout |
| 7 | reports full invoices stream | **CLOSED** | `lib/features/owner_dashboard/widgets/sections/reports_section.dart` — `deliveryDate` range + `limit(500)` + Load more | **Ручной:** отчёт за месяц, >500 docs → баннер truncated |
| 8 | analytics full delivery_points read | **CLOSED** | `lib/screens/admin/analytics_screen.dart` — `createdAt` range + `limit(500)` + Load more | **Ручной:** analytics за период, truncated banner |
| 9 | metrics reader without writer | **CLOSED** | `functions/recalculateDailyMetrics.js` + `overview_section.dart` (баннер «не рассчитаны» + пересчёт) | **Авто:** `test/owner_dashboard/services/metrics_service_test.dart`; **ручной:** KPI после пересчёта |
| 10 | clients / inventory / prices full reads | **PARTIAL** | Lists: `client_service.dart` (page 100), `inventory_list_view.dart` (stream limit), `price_service.dart` (limit 500). Export/regeocode — batch fetch all | **Ручной:** список клиентов Load more; export warning. **BACKLOG:** stock report без limit |
| 11 | restore checkbox without evidence | **CLOSED** | `lib/models/restore_drill_record.dart`, `backup_service.dart`, `backup_management_screen.dart` | **Авто:** `test/services/backup_service_test.dart`; **ручной:** 1 drill в test/staging |
| 12 | modules split-brain (root vs settings) | **CLOSED** | `CompanyModulesService`, root overlay в `company_settings_service.dart`, `module_guard.dart` (fail-closed). **Guards читают только `companies/{id}.modules` на root** — `settings.modules` deprecated mirror | **Авто:** `test/services/company_modules_service_test.dart`; **ручной:** plan change → rules + UI совпадают |
| 13 | billing state machine split-brain | **CLOSED** | `BillingState` (Dart/JS), `billing_guard.dart`, `firestore.rules`, `issueInvoice.js`; expired trial → grace window | **Авто:** `test/services/billing_state_test.dart`, `functions/test/billingState.test.js`, rules billing tests |
| 14 | dispatcher warehouse UI vs rules write | **CLOSED** | `WarehouseAccess`, read-only `WarehouseDashboard` для dispatcher; write UI скрыт | **Авто:** `test/services/warehouse_access_test.dart`; **ручной:** dispatcher → склад без FAB/permission-denied |
| 15 | GPS Health wrong collection (C1) | **CLOSED** | `GpsHealth`, `FirestorePaths.driverLocations`/`driverLocationsOf` → `companies/{id}/driver_locations`; health/onboarding через `timestamp` | **Авто:** `test/services/gps_health_test.dart`, `test/services/onboarding_gps_signals_test.dart` |
| 16 | root daily_summaries legacy writes (C5) | **CLOSED** | `SummaryService` удалён; `invoice_service` без root writes; KPI = `metrics/daily/days` + CF `recalculateDailyMetrics` | **Авто:** `test/services/c5_legacy_daily_summaries_test.dart`; **ручной:** создать invoice → нет doc в root `daily_summaries`; Owner Overview KPI после пересчёта |
| 17 | Pilot tunables только через rebuild (AppConfig) | **CLOSED** | `CompanyRemoteConfig` + `settings/remote_config`; runtime driver/GPS/import; Admin UI + Support Console | **Авто:** `test/services/company_remote_config_test.dart`, rules remote_config tests |
| 17 | route_builder legacy routes path (C4) | **CLOSED** | `RouteBuilderService` удалён; `RouteService` → `FirestorePaths.routes` (`logistics/_root/routes`) | **Авто:** `test/services/c4_legacy_routes_test.dart`; **ручной:** dispatcher создаёт маршрут → doc в `logistics/_root/routes`, не в `companies/{id}/routes` |
| 18 | view-as не влияет на PermissionsService (H1) | **CLOSED** | `effectiveAppRole`, `PermissionsService.forUser`; Owner Dashboard + секции используют `viewAsRole ?? role` | **Авто:** `test/owner_dashboard/services/effective_role_permissions_test.dart`; **ручной:** super_admin view-as accountant → только accounting/reports/audit/settings |
| 19 | Plan ↔ modules sync (H4) | **CLOSED** | `CompanyModulesService.applyPlan` / CF `applyPlanToCompany`; legacy writers переведены | **Авто:** `test/services/company_modules_service_test.dart`, `functions/test/companyModules.test.js`; **ручной:** смена плана → modules+limits на root синхронны |
| 20 | Firestore composite indexes (H8) | **CLOSED** | Аудит queries + 11 indexes в `firestore.indexes.json`; [`firestore-index-audit.md`](firestore-index-audit.md) | **Deploy:** `firebase deploy --only firestore:indexes`; **ручной:** Reports/Analytics без FAILED_PRECONDITION |
| 21 | Support Console → Billing без sync companyId (H2) | **CLOSED** | `CompanyContext.activateCompany`; Support Console sync при выборе; Billing/Subscription принимают `companyId`; header tenant | **Авто:** `test/services/company_context_activation_test.dart`; **ручной:** см. чеклист H2 ниже |
| 22 | Admin Dashboard без BillingGuard (H9) | **CLOSED** | `role_router.dart`: `admin` → `BillingGuard` + `AdminDashboard`; `super_admin` bypass; blocked screen → Pay/Subscription/Support | **Авто:** `test/services/admin_billing_route_policy_test.dart`; **ручной:** см. чеклист H9 ниже |
| 23 | Soft limits consistency (H5) | **CLOSED** | `PlanLimitPolicy`; limits из `applyPlan`/plan fallback (без 999); UI soft labels; invite не блокируется на пилоте | **Авто:** `test/models/plan_limit_policy_test.dart`, `test/services/plan_limits_service_test.dart`; **ручной:** см. чеклист H5 |
| 24 | Firestore rules tests isDemo (rules-tests) | **CLOSED** | `isDemoUser()` — safe `'isDemo' in userDoc()`; demo fixtures + 6 tests в `firestore.rules.test.js` | **Авто:** `npm run test:rules` (162 pass) |
| 25 | Platform Error Center | **CLOSED** | `platform/system/errors` + CF `reportPlatformError` + Flutter hooks + grouping fingerprint | **Авто:** `test/services/platform_error_fingerprint_test.dart`, `functions/test/platformErrors.test.js`, rules tests |
| 26 | Data Integrity Checker (cross-entity consistency) | **CLOSED** | `functions/lib/integrityChecks.js` + CF `generateIntegrityCheck`/`scheduledDataIntegrityCheck` (dedup/reopen/auto-resolve); `integrity_checks`/`integrity_issues`; `DataIntegrityService` + UI; Support Console block | **Авто:** `functions/test/integrityChecks.test.js` (22 pass), rules integrity tests; **ручной:** см. DI-чеклист в `staging-qa-checklist.md` |

---

## H2 — ручной чеклист (Support Console tenant sync)

| # | Шаг | Ожидание |
|---|-----|----------|
| 1 | super_admin → Support Console, **не** выбирая компанию | Только список компаний; company-scoped actions недоступны |
| 2 | Выбрать компанию A | AppBar: имя + `companyId`; tabs Overview/Billing… |
| 3 | Quick action **Billing Portal** | Открывается billing для A (header с A), не «No company» |
| 4 | Назад → **Subscription** | План/статус компании A |
| 5 | **Open as owner** → Owner Dashboard | Данные компании A |
| 6 | Выйти view-as → Support Console → компания B → Billing | Billing для B, не A |
| 7 | Customer Health → Support для компании C | Support Console с C; Billing = C |

---

## H9 — ручной чеклист (Admin Dashboard billing gate)

| # | Шаг | Ожидание |
|---|-----|----------|
| 1 | company **admin**, billing `active` | AdminDashboard открывается, операции работают |
| 2 | admin, `suspended` / `cancelled` | Blocked screen (не AdminDashboard); Pay + Subscription + Support |
| 3 | admin, trial grace **expired** | Blocked screen «trial ended»; кнопка Pay |
| 4 | admin, billing stream **timeout/error** | Verify-failed screen (fail-closed), retry |
| 5 | **super_admin** без view-as | AdminDashboard без блокировки (platform tools) |
| 6 | super_admin **view-as admin**, компания suspended | Blocked screen (как у admin) |
| 7 | super_admin, companyId не выбран | AdminDashboard / company selector (platform), не «всё OK» с данными tenant |

---

## H5 — ручной чеклист (plan limits)

| # | Шаг | Ожидание |
|---|-----|----------|
| 1 | Billing Portal → Usage | Users/Docs: progress + «Мягкий лимит»; Routes: «Не отслеживается» |
| 2 | Owner → Billing | Лимиты по плану + footnote «не блокирует на пилоте» |
| 3 | Owner → Users, at limit | Warning banner, invite **не** disabled |
| 4 | Owner → Overview, docs over limit | Alert с пометкой soft |
| 5 | issueInvoice при over limit | Invoice создаётся (soft, не CF block) |
| 6 | Компания без `limits` в root | Fallback по `plan` (не 999/99999) |

---

## До пилота (блокеры и обязательства)

| Приоритет | Задача | Статус | Владелец |
|-----------|--------|--------|----------|
| P0 | **1 verified restore drill** в test/staging + запись в Admin UI | **OPEN** | DevOps + admin |
| P0 | Заполнить **Support контакты** в [`first-week-checklist.md`](first-week-checklist.md) | **OPEN** | Owner LogiRoute |
| P0 | **Pilot Success Criteria** подписать с клиентом | **OPEN** | Sales / CS |
| P0 | Ручной прогон **go-live-decision** (22 пункта) | **OPEN** | Внедрение |
| P1 | Ручные тесты billing/GPS/checkout (см. таблицу аудита) | **OPEN** | QA |
| P1 | Импорт Excel на реальном файле клиента (dry-run) | **OPEN** | Dispatcher + CS |
| P1 | Backup record в журнале (квартальный) | **OPEN** | Admin |
| P2 | Stock report: limit для inventory stream | **BACKLOG** | Dev (не блокер при <500 SKU) |

---

## Во время пилота (30 дней)

| Задача | Цель |
|--------|------|
| [`first-week-checklist.md`](first-week-checklist.md) — день 1→7 | Стабильный ежедневный процесс без Excel |
| Журнал инцидентов (≤2 критичных — критерий успеха) | [`pilot-success-criteria.md`](pilot-success-criteria.md) |
| Backup record за текущий квартал | Compliance |
| Сбор UX-проблем (≤5) → backlog «первый клиент» | Приоритизация после пилота |
| Наблюдение truncated banners в reports/analytics | Если pilot >500 docs/мес — plan fix |

---

## После пилота

| Задача | Когда |
|--------|-------|
| Решение **Продолжаем / Доработка / Стоп** | День 30 |
| Product Analytics (read-only dashboard) | После подтверждения usage |
| Dispatcher onboarding wizard | Если backup-диспетчер >1 дня |
| Ticket-система в app | Когда >3 paying clients |
| Квартальный restore drill | DR runbook |

---

## Enterprise backlog (сознательно не для микро-пилота)

| Область | Статус | Примечание |
|---------|--------|------------|
| Stock report full inventory stream | **BACKLOG** | `reports_section.dart` `_StockReport._watch()` без limit |
| Export fetch all clients/inventory | **BACKLOG** | Batch 500, OK до ~2k records |
| Self-service onboarding | **BACKLOG** | Нужен super_admin |
| viewer read-only dashboard | **BACKLOG** | Роль отключена |
| root `daily_summaries` legacy | **CLOSED (C5)** | SummaryService удалён; не добавлять rules на root |
| Per-tenant versioning | **BACKLOG** | |
| 50k+ clients pagination hardening | **BACKLOG** | |
| Production DR restore | **BACKLOG** | Только отдельный runbook, не пилот |

---

## Сводка

| Категория | CLOSED | PARTIAL | OPEN | BACKLOG |
|-----------|--------|---------|------|---------|
| Tech-audit (24 пунктов) | 22 | 1 | 0 | 0 (+1 operational OPEN: drill) |

**Единственный tech-related OPEN до пилота:** restore drill (операционный, не код).
