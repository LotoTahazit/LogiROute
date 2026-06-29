# Staging QA Checklist — микро-пилот LogiRoute

> **Для кого:** QA / внедрение / support LogiRoute перед микро-пилотом.  
> **Среда:** **staging only** (не production).  
> **Код не менять** — только фиксация результатов ручной проверки.

**Автоматические gate (на момент создания чеклиста):**

| Gate | Статус |
|------|--------|
| `flutter analyze` | 0 errors |
| `flutter test` | 332/332 |
| Firestore rules | 182/182 |
| Cloud Functions tests | PASS |

**Связанные документы:** [`pilot-runbook.md`](pilot-runbook.md) · [`first-week-checklist.md`](first-week-checklist.md) · [`pilot-success-criteria.md`](pilot-success-criteria.md) · [`go-live-decision.md`](go-live-decision.md)

---

## Мета прогона

| Поле | Значение |
|------|----------|
| Дата прогона | __.__.____ |
| Staging project / URL | _________________________ |
| Build / commit | _________________________ |
| QA-инженер | _________________________ |
| Тестовая компания (`companyId`) | _________________________ |
| Demo company (`demo-foods-israel`) | ☐ не использовалась для пилота |

**Легенда:** Pass ☑ · Fail ☐ · Blocked ☐ (с указанием блокера в Notes)

---

## Как заполнять

Для **каждого** пункта ниже заполните:

| Expected Result | Actual Result | Pass / Fail | Notes |
|-----------------|---------------|-------------|-------|

- **Expected Result** — уже указан в таблице (эталон).
- **Actual Result** — что реально произошло на staging.
- **Pass / Fail** — одно из: `Pass` · `Fail` · `Blocked`.
- **Notes** — скрин, correlation ID, шаг воспроизведения, ссылка на issue.

---

# Owner

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Login | Owner входит по email/password; попадает в Owner Dashboard без ошибок auth | | | |
| 2 | □ Dashboard | Overview открывается; KPI и навигация по 11 секциям доступны при active/trial billing | | | |
| 3 | □ Billing | Секция Billing видна; статус подписки, plan, лимиты отображаются корректно | | | |
| 4 | □ Reports | Reports открывается; данные за период загружаются без permission denied | | | |
| 5 | □ Metrics | Метрики usage / операционные показатели отображаются (или явный empty state) | | | |
| 6 | □ Customer Health | Customer Health (tenant health) доступен owner/super_admin view; статус Healthy/Warning понятен | | | |
| 7 | □ Launch Center | 11 карточек задач; % прогресса; делегирование; авто-сигналы; driver **не** видит секцию | | | |
| 8 | □ Company Health | Company Health / ops indicators без crash; предупреждения соответствуют данным компании | | | |
| 9 | □ Logout | Logout завершает сессию; повторный доступ требует login | | | |

---

# Dispatcher

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Login | Dispatcher входит; попадает в dispatcher UI (не owner-only экраны) | | | |
| 2 | □ Создать маршрут | Новый маршрут создаётся с точками; сохраняется в Firestore | | | |
| 3 | □ Назначить водителя | Водитель назначается на маршрут; водитель видит маршрут после sync | | | |
| 4 | □ Переставить точки | Порядок остановок меняется drag/reorder; порядок сохраняется | | | |
| 5 | □ Карта | Карта показывает точки/маршрут; geocode отображается без пустой карты | | | |
| 6 | □ Warehouse ReadOnly | Складские остатки **только чтение**; write-actions недоступны или отклонены | | | |
| 7 | □ Invoice | Создание/просмотр invoice (plan full) — документ создаётся, статус корректен | | | |
| 8 | □ Logout | Logout работает; protected routes недоступны без auth | | | |

---

# Driver

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Login | Driver входит; видит назначенные маршруты/точки | | | |
| 2 | □ Получить маршрут | Актуальный маршрут подтягивается после назначения dispatcher | | | |
| 3 | □ GPS Active | При разрешённой геолокации координаты отправляются; статус «active» в UI/логах | | | |
| 4 | □ GPS Disabled | При отключённом GPS — понятное предупреждение; нет silent fail / crash | | | |
| 5 | □ POD | Proof of delivery (фото/подпись/статус) сохраняется и виден dispatcher | | | |
| 6 | □ Автозакрытие | Точка/маршрут автозакрывается по правилам (proximity / manual complete) | | | |
| 7 | □ История | История выполненных доставок доступна и совпадает с completed в backend | | | |
| 8 | □ Logout | Logout; offline cache не даёт доступ к чужим данным после смены user | | | |

---

# Warehouse

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Login | Warehouse keeper входит; складской UI доступен | | | |
| 2 | □ Остатки | Список остатков загружается; qty соответствует тестовым данным | | | |
| 3 | □ Search | Поиск по SKU/названию фильтрует список корректно | | | |
| 4 | □ Export | Export (Excel/CSV) скачивается; файл открывается, данные не пустые | | | |
| 5 | □ Barcode | Сканирование штрихкода находит товар / добавляет в операцию | | | |
| 6 | □ Inventory | Инвентаризация (count) сохраняется; расхождения видны после submit | | | |
| 7 | □ Logout | Logout работает | | | |

---

# Admin

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Users | CRUD пользователей компании; invite / role assign работает | | | |
| 2 | □ Company Settings | Профиль компании сохраняется; изменения видны после reload | | | |
| 3 | □ Module Toggle | Включение/выключение модулей скрывает/показывает UI (warehouse, logistics, …) | | | |
| 4 | □ Billing | Admin видит Billing (BillingGuard); suspended → только billing/settings | | | |
| 5 | □ Subscription | Subscription status / plan sync с Support Console / Stripe sandbox | | | |

---

# Super Admin

| # | Проверка | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| 1 | □ Customer Health | Global Customer Health: фильтры, tenant list, drill-down без permission error | | | |
| 2 | □ Support Console | Support Console открывается; `companyId` context синхронизирован | | | |
| 3 | □ View As | View As (owner/accountant/…) меняет effective permissions без logout | | | |
| 4 | □ Demo Company | Demo tenant изолирован; demo-данные не смешиваются с pilot company | | | |
| 5 | □ Company Wizard | Создание новой компании через wizard завершается успешно | | | |
| 6 | □ Billing Portal | Stripe Customer Portal / billing link открывается для test customer | | | |
| 7 | □ Subscription | Изменение plan/trial/paidUntil в Support Console отражается в app | | | |
| 8 | □ Restore Drill | Restore drill на staging выполнен; evidence записан (см. раздел Restore Drill) | | | |

---

## Billing

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| B1 | Trial → active | После оплаты / активации billing status = active; все секции owner dashboard доступны | | | |
| B2 | Grace period | В grace UI показывает предупреждение; доступ сохранён | | | |
| B3 | Suspended | При suspended видны **только** Billing + Settings; остальные секции скрыты | | | |
| B4 | Cancelled | При cancelled — тот же restricted mode; нет write в ops-модули | | | |
| B5 | Plan limits (soft) | При превышении soft limit — предупреждение в UI, **без** hard block 999/99999 | | | |
| B6 | Admin BillingGuard | Admin без active billing не попадает в ops-экраны | | | |

---

## Company Remote Config

| # | Check | Expected Result | Actual Result | Pass / Fail | Notes |
|---|-------|-----------------|---------------|-------------|-------|
| RC1 | Owner opens Pilot Config | Экран с полями auto-close, GPS stale, session lock, import rows; defaults показаны | | | |
| RC2 | Change auto-close radius | Save OK; audit `remote_config_changed`; водитель получает новое значение после reload | | | |
| RC3 | Invalid value (radius 5) | Validation error on save; runtime ignores invalid Firestore value → default | | | |
| RC4 | Driver write denied | Driver cannot write `settings/remote_config` (rules) | | | |
| RC5 | Support Console block | Overview shows radius/wait/GPS stale/background/session lock/preview rows | | | |

## Data Integrity Checker

| # | Check | Expected Result | Actual Result | Pass / Fail | Notes |
|---|-------|-----------------|---------------|-------------|-------|
| DI1 | Owner/Admin opens Data Integrity | Экран с кнопкой «Запустить проверку» и сводкой последнего прогона | | | |
| DI2 | Run check on clean tenant | `foundIssues=0`, «Проблем не найдено» | | | |
| DI3 | Seed inconsistency (orphan member / negative invoice) | После прогона issue с нужным severity и описанием | | | |
| DI4 | Ignore / Resolve / Reopen | Статус меняется; audit `integrity_issue_ignored/resolved`; reopen возвращает в open | | | |
| DI5 | Export CSV | CSV копируется в буфер с колонками severity/status/entity/issueCode | | | |
| DI6 | Driver access denied | Driver cannot read/update `integrity_*` (rules) | | | |
| DI7 | Nightly run | `scheduledDataIntegrityCheck` создаёт прогон, дедуп/auto-resolve работает | | | |

## GPS (driver)

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| G1 | Foreground tracking | Координаты обновляются при активном приложении | | | |
| G2 | Background (Android) | При свёрнутом app tracking продолжается (battery unrestricted) | | | |
| G3 | Permission denied | UI объясняет, как включить; dispatcher видит offline/stale indicator | | | |
| G4 | Route proximity | Автособытия proximity не дублируются и не теряются | | | |

---

## Checkout

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| C1 | Stripe Checkout (sandbox) | Test payment проходит; webhook обновляет subscription | | | |
| C2 | Failed payment | Decline card → grace/suspended по политике; UI показывает статус | | | |
| C3 | Portal return | После Billing Portal user возвращается в app с актуальным статусом | | | |

---

## Demo

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| D1 | Demo tenant isolation | `isDemo` / demo company не пишет в prod pilot data | | | |
| D2 | Demo reset | Demo data восстанавливается / не ломает пилотную компанию | | | |
| D3 | Sales demo flow | Super admin может провести demo без влияния на staging pilot | | | |

---

## Customer Health

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| CH1 | Healthy tenant | Pilot company = Healthy при нормальном usage/billing/GPS | | | |
| CH2 | Warning triggers | Искусственный warning (просрочка, низкий GPS) отображается с причиной | | | |
| CH3 | Drill-down | Из списка → карточка компании → actionable items | | | |

---

## Support Console

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| SC1 | Company context | Переключение company обновляет все вкладки (billing, subscription, users) | | | |
| SC2 | Plan edit | Изменение plan сохраняется и видно owner/admin в app | | | |
| SC3 | Impersonation guard | View As не даёт super_admin write там, где не положено | | | |

---

## Create Company Flow (super_admin)

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| CC1 | Self Setup | 4 шага → success без auto-wizard; owner получает reset email; кнопки view-as owner / copy invite | | | |
| CC2 | Done-for-you | Success с кнопкой **Launch Center** + view-as owner/dispatcher | | | |
| CC3 | Missing owner | Нельзя создать без имени/email первого пользователя | | | |
| CC4 | Existing email | Email в другой компании → понятная ошибка; свободный email → link или create | | | |
| CC5 | Plan/modules | `companies/{id}` plan + modules + limits через applyPlan (не ручной patch) | | | |
| CC6 | Audit | `company_created`, `initial_owner_created`, `onboarding_mode_selected` + correlationId | | | |
| CC7 | Email failure | При сбое sendPasswordReset — banner на success, не «всё готово» молча | | | |
| CC8 | Demo unaffected | `demo-foods-israel` / Demo Company menu работает как раньше | | | |

---

## Correlation ID

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| CID1 | Error surface | При ошибке UI/лог показывает correlation ID | | | |
| CID2 | Support lookup | ID из UI находится в logs / support workflow | | | |
| CID3 | CF errors | Cloud Function error возвращает тот же correlation ID | | | |

---

## Usage Events

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| UE1 | Route created | Event `route_created` (или экв.) пишется в usage_events | | | |
| UE2 | Delivery completed | Event delivery/complete фиксируется | | | |
| UE3 | Invoice created | Event invoice фиксируется (plan full) | | | |
| UE4 | Owner overview | Usage metrics в dashboard соответствуют events | | | |

---

## Excel Import

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| XI1 | Clients import | Excel клиентов импортируется; дубликаты обрабатываются | | | |
| XI2 | Products / templates | Import шаблонов → `warehouse/_root/product_types` | | | |
| XI3 | Validation errors | Невалидные строки в отчёте import; valid rows сохранены | | | |
| XI4 | Large file (pilot scale) | 50–100 rows без timeout на staging | | | |

---

## Excel Export

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| XE1 | Reports export | Export отчёта скачивается; колонки и totals корректны | | | |
| XE2 | Warehouse export | Export остатков совпадает с UI | | | |
| XE3 | Hebrew / RTL | Имена и адреса в файле читаемы (encoding UTF-8) | | | |

---

## FCM

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| F1 | Token registration | FCM token сохраняется при login на device | | | |
| F2 | Route assigned | Push «новый маршрут» приходит водителю | | | |
| F3 | Background delivery | Push приходит при закрытом app (Android) | | | |
| F4 | Opt-out / permission | Без разрешения — in-app fallback, без crash | | | |

---

## Accounting Sync

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| AS1 | Invoice → accounting | Счёт появляется в accounting module | | | |
| AS2 | VAT regime (עוסק פטור) | PDF/поля соответствуют режиму компании | | | |
| AS3 | Israel Invoice status | Status CF обновляет document status | | | |
| AS4 | Accountant role | Accountant видит accounting/reports/audit/settings only | | | |

---

## Stripe Sandbox

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| SS1 | Test keys only | Staging использует sandbox keys; live keys не в staging | | | |
| SS2 | Webhook staging | Stripe webhook endpoint staging получает events | | | |
| SS3 | Customer create | Stripe customer создаётся при checkout/onboarding | | | |
| SS4 | Subscription lifecycle | create → update → cancel отражается в Firestore | | | |

---

## Restore Drill

| # | Сценарий | Expected Result | Actual Result | Pass / Fail | Notes |
|---|----------|-----------------|---------------|-------------|-------|
| RD1 | Backup exists | Scheduled/manual backup для staging project доступен | | | |
| RD2 | Restore to isolated env | Restore выполнен **не** в prod pilot tenant | | | |
| RD3 | Data integrity | После restore: users, companies, routes читаются | | | |
| RD4 | Evidence recorded | Restore drill record в Admin UI + дата/исполнитель | | | |
| RD5 | RTO/RPO note | Фактическое время восстановления зафиксировано | | | |

---

## Итоговая таблица

Заполнить **после** завершения всех разделов.

| Категория | Количество | Комментарий |
|-----------|------------|-------------|
| **Passed** | _____ / _____ | |
| **Failed** | _____ / _____ | Список: _________________________ |
| **Blocked** | _____ / _____ | Блокеры: _________________________ |

### Решение

| Критерий | Да / Нет | Подпись / дата |
|----------|----------|----------------|
| **Ready for Pilot** — все P0 сценарии Pass; Failed только P2+ с workaround | ☐ Да ☐ Нет | __________ |
| **Ready for Production** — все разделы Pass; Restore Drill + Stripe live checklist отдельно | ☐ Да ☐ Нет | __________ |

**P0 для микро-пилота (минимум):** Owner Login/Dashboard/Billing · Dispatcher маршрут+водитель+карта · Driver маршрут+GPS+POD · Warehouse остатки · Admin Users · Billing suspended/grace · GPS Active · Excel Import clients · FCM route assigned · Restore Drill evidence.

**Open items → backlog:** [`readiness-backlog.md`](readiness-backlog.md)

---

*Staging QA Checklist — ручная верификация после green automated gates. Не заменяет [`pilot-runbook.md`](pilot-runbook.md) и [`first-week-checklist.md`](first-week-checklist.md).*
