# Pilot Runbook — первая реальная компания LogiRoute

> **Для кого:** LogiRoute (super_admin, внедрение, support) + owner/диспетчер клиента.  
> **Не для разработчика.** Это операционный документ на 30 дней пилота.

**Связанные документы:**

- [`first-week-checklist.md`](first-week-checklist.md) — детальный чеклист дней 1–7
- [`pilot-success-criteria.md`](pilot-success-criteria.md) — метрики и пороги успеха
- [`customer-readiness.md`](customer-readiness.md) — готовность клиента и support-процесс
- [`go-live-decision.md`](go-live-decision.md) — gate перед продажей

---

## 1. Цель пилота

| Цель | Что проверяем | Что **не** проверяем |
|------|---------------|----------------------|
| Реальная работа | Ежедневные маршруты, GPS, POD, диспетчер без Excel | Enterprise-scale (50k клиентов, 300 водителей на карте) |
| UX | Диспетчер и водители **работают**, а не «терпят систему» | Каждый пиксель UI |
| Usage | [`usage_events`](../lib/services/usage_analytics_service.dart) — onboarding, import, route, delivery, invoice | Клик-трекинг каждого экрана |
| Firebase Usage | Reads/writes, CF invocations, billing tier vs факт нагрузки | Нагрузочное тестирование вне scope пилота |

**Главный вопрос через 30 дней:** клиент **готов платить дальше** и **не просит вернуть Excel**?

---

## 2. Ограничения пилота

| Параметр | Лимит | Комментарий |
|----------|-------|-------------|
| Компании | **1** | Один tenant, один договор |
| Водители | **3–5** | Не масштабируем процесс до «все машины» |
| Клиенты (справочник) | **50–100** | Импорт + geocode проверка выборочно |
| Доставки | **100–300 / день** | Типичный пилот distrib/logistics IL |
| Срок | **30 календарных дней** | День 0 = подготовка, день 1 = первая смена |

**Заполнить перед стартом:**

| Поле | Значение |
|------|----------|
| Название компании | _________________________ |
| `companyId` | _________________________ |
| Дата старта (день 1) | __.__.____ |
| Дата окончания (день 30) | __.__.____ |
| Ответственный LogiRoute | _________________________ |
| Ответственный клиент (диспетчер) | _________________________ |

---

## 3. Подготовка до старта (день 0)

Чеклист **до** первой боевой смены. Все пункты — ☐ / ☑.

### 3.1 Инфраструктура и безопасность

| # | Задача | Кто | Готово |
|---|--------|-----|--------|
| 1 | **Restore drill** — восстановление из backup на test/staging (не prod) | LogiRoute | ☐ |
| 2 | **Demo check** — убедиться, что пилот **не** на `demo-foods-israel` | LogiRoute | ☐ |
| 3 | **Billing mode** — sandbox или live (Stripe): режим __________ | LogiRoute | ☐ |
| 4 | Plan / trial / paidUntil зафиксированы в Support Console | LogiRoute | ☐ |
| 5 | Firebase project / quotas просмотрены (Blaze, alerts) | LogiRoute | ☐ |

### 3.1a Создание компании (super_admin)

| # | Задача | Кто | Готово |
|---|--------|-----|--------|
| 5a | **Create Company Flow** (Platform → Create company): company + taxId + plan + trial 14d | LogiRoute super_admin | ☐ |
| 5b | Первый **owner** (или admin) создан; письмо password reset получено (или явное предупреждение на success screen) | LogiRoute | ☐ |
| 5c | Режим: **Self Setup** (owner → Launch Center) или **Done-for-you** (LogiRoute → Launch Center) | LogiRoute | ☐ |
| 5d | Audit: `company_created`, `initial_owner_created`, `onboarding_mode_selected` в Support Console / audit | LogiRoute | ☐ |
| 5f | **Error Center** — критические ошибки видны super_admin (Platform → Error Center) | LogiRoute | ☐ |
| 5e | **Не** использовать legacy `create_company_legacy` для новых клиентов | LogiRoute | ☐ |

### 3.2 Люди и support

| # | Задача | Кто | Готово |
|---|--------|-----|--------|
| 6 | **Support contact** — канал клиента: WhatsApp / телефон __________ | LogiRoute | ☐ |
| 7 | **Support contact** — канал LogiRoute: __________ (рабочие часы __–__) | LogiRoute | ☐ |
| 8 | **Backup dispatcher** — второй user с ролью dispatcher, базовый инструктаж | Клиент + LogiRoute | ☐ |
| 9 | Owner/admin создан, billing guard проверен | LogiRoute | ☐ |

### 3.3 Данные и onboarding

| # | Задача | Кто | Готово |
|---|--------|-----|--------|
| 10 | **Импорт клиентов** (Excel) — ≥ 50 записей | Dispatcher | ☐ |
| 11 | Geocode: 10 ключевых адресов на карте | Dispatcher | ☐ |
| 12 | **Импорт товаров** / шаблоны (если склад или счета с SKU) | Admin / кладовщик | ☐ |
| 13 | **Создание водителей** (3–5), логины выданы | Admin | ☐ |
| 14 | Launch Center: обязательные карточки (реквизиты, owner/admin, водители, GPS, маршрут, тест-доставка) | Owner | ☐ |

### 3.4 Полевые проверки

| # | Задача | Кто | Готово |
|---|--------|-----|--------|
| 15 | **Android GPS** — у каждого водителя: разрешение «всегда», battery unrestricted | Водитель + dispatcher | ☐ |
| 16 | **Тестовый маршрут** — 1 точка, completed + POD (если включён) | Dispatcher + водитель | ☐ |
| 17 | Тестовый счёт / накладная (plan full) — 1 документ | Бухгалтер / dispatcher | ☐ |
| 18 | Customer Health Dashboard — tenant **Healthy** или известные Warning | LogiRoute | ☐ |

---

## 4. День 1 — первая смена

### 4.1 Запуск

| Время | Действие | Ответственный |
|-------|----------|---------------|
| До выезда | Точки на день загружены / импортированы | Dispatcher |
| До выезда | Маршруты созданы, водители назначены | Dispatcher |
| Старт смены | Водители в login, видят маршрут | Водители |
| +30 мин | Support Console: stale GPS = 0 по активным водителям | LogiRoute |
| Конец дня | ≥ 1 реальная доставка **completed** в системе | Все |

### 4.2 Кто отвечает за поддержку

| Уровень | Контакт | SLA (рабочие часы) |
|---------|---------|-------------------|
| **L1 — операции** | Dispatcher клиента → backup dispatcher | 15 мин (внутри клиента) |
| **L2 — LogiRoute** | _________________________ | Критичное ≤ **2 ч**, остальное ≤ **24 ч** |
| **L3 — эскалация** | _________________________ (tech lead) | По согласованию |

### 4.3 Playbook: что делать при сбое

#### GPS fail (водитель «не на карте» / stale GPS)

1. Водитель: Settings → Location → **Allow all the time**; отключить battery saver для LogiRoute.
2. Dispatcher: Driver Dashboard / карта — последний `updatedAt` локации.
3. LogiRoute: Support Console → **Users/Drivers** → stale GPS count; Customer Health.
4. Если не восстановилось за **30 мин** — диспетчер звонит водителю; LogiRoute фиксирует инцидент с `correlationId` (если был route assign).
5. **Workaround:** ручное закрытие точки dispatcher + POD фото; не отменять весь пилот из‑за одного телефона.

#### Invoice fail (счёт не выписался / sync failed)

1. Dispatcher/бухгалтер: повторить выдачу; проверить статус точки (completed?).
2. Owner Dashboard → Accounting → sync ledger; **Retry** (если failed).
3. LogiRoute: Support Console → **Accounting** panel; export diagnostic JSON.
4. Зафиксировать `correlationId` из Recent Errors; не править counters вручную.
5. **Workaround:** выписать документ позже; доставка **не блокируется** из‑за счёта (если так договорено с клиентом).

#### Route fail (маршрут не создался / водитель не видит точки)

1. Проверить billing status (suspended → BillingGuard).
2. Проверить координаты точек (invalid lat/lng — geocode).
3. Пересоздать маршрут; assign driver заново.
4. LogiRoute: Support Console → Routes + Recent Errors (`create_route` correlation).
5. **Workaround:** временно меньший маршрут (1 водитель, 5–10 точек); не параллельный Excel-маршрут без записи в LogiRoute.

---

## 5. Ежедневная проверка (LogiRoute, 10–15 мин)

Выполнять **каждый рабочий день** пилота (лучше утром до смены + вечером после).

| # | Инструмент | Путь | Что смотреть |
|---|------------|------|--------------|
| 1 | **Customer Health Dashboard** | Admin → Platform → Customer Health | Health ≠ Critical; stale GPS; failed sync |
| 2 | **Support Console** | Admin → Platform → Support Console | Billing, setup %, routes, accounting, last error |
| 3 | **Usage Summary** | Admin → Reports → Usage (пilot) / Owner Overview | События за 7 дней; active users; route/delivery counts |
| 4 | **Firebase Usage** | Firebase Console → Usage and billing | Reads/writes vs вчера; аномальные spikes |
| 5 | **Ошибки + correlationId** | Support Console → Recent Errors; Audit tab | Фильтр по `cid`; связать с инцидентом клиента |
| 6 | **Data Integrity** | Admin → Company → Целостность данных (или Owner Settings) | Critical/High = 0; запустить проверку при подозрении на рассогласование |

### Быстрая подстройка пилота (Remote Config)

Без новой сборки — Owner Settings → **Конфигурация пилота** или Admin → Company → Remote Config:

| Параметр | Когда менять |
|----------|--------------|
| Auto-close radius / wait | GPS «не закрывает» или закрывает слишком рано |
| GPS stale minutes | Support Console показывает ложный stale GPS |
| Session lock / heartbeat | Водитель «выбит» с другого телефона или наоборот |
| Import preview rows | Большой Excel — нужно больше строк превью |

Support Console → Overview → блок **Remote Config** (read-only).

**Дневной лог (копировать строку в Slack/Notion):**

```
[Пилот] {companyId} | {date} | health: {H/W/C} | deliveries: {N} | stale GPS: {N} | sync fail: {N} | incidents: {0/1}
```

**Заполнить:**

| Поле | Значение |
|------|----------|
| Slack / Notion канал пилота | _________________________ |
| Ответственный за daily check | _________________________ |

---

## 6. Метрики успеха (30 дней)

Согласовать пороги **до** дня 1. Детали — [`pilot-success-criteria.md`](pilot-success-criteria.md).

| # | Метрика | Порог | Источник данных |
|---|---------|-------|-----------------|
| 1 | Доставки через LogiRoute | **≥ 95%** | completed points / факт доставок клиента |
| 2 | Диспетчер без Excel | **Да** (наблюдение + опрос) | — |
| 3 | Спорные доставки с POD/trace | **100%** спорных | delivery_points + POD fields |
| 4 | Критические инцidents | **≤ _____** за 30 дней (рекомендация: **2**) | журнал инцидентов LogiRoute |
| 5 | Готовность продолжить | **Да** (оплата мес. 2 или письмо) | billing / owner |

**Критический инцидент** = полная остановка работы: все водители или весь рабочий день без возможности вести маршруты в LogiRoute.

**Заполнить лимит инцидентов:** **≤ ______** за 30 дней.

---

## 7. Go / No-Go критерии

### 7.1 Go — продолжаем пилот / переходим в платного клиента

- Все **обязательные** метрики из §6 выполнены **или** на траектории (≥ 90% coverage к дню 25).
- Нет **> 1** критического инцидента за последние 7 дней.
- Customer Health **не Critical** более 2 дней подряд без плана.
- Клиент **не ведёт** параллельный ежедневный Excel-маршрут.
- Owner подтверждает продление (устно → письмо/оплата).

### 7.2 No-Go — останавливаем пилот (без отката данных)

- **> 3** критических инцидента за 30 дней.
- **< 80%** coverage доставок без объяснимой причины к дню 21.
- Диспетчер **отказывается** работать в системе.
- Billing suspended / клиент не оплачивает после grace.
- Решение: **стоп пилота**, post-pilot review (§8), экспорт данных по запросу.

### 7.3 Rollback — откат на старый процесс

Использовать **редко** — только если Go/No-Go не спасает операционный день.

| Триггер | Действие |
|---------|----------|
| Полный простой **> 4 ч** в рабочий день | Клиент ведёт маршрут в Excel **временно**; LogiRoute фиксирует retro после восстановления |
| Потеря данных / integrity fail | Stop writes; restore drill; notify client |
| Массовый GPS fail (> 50% водителей) | Workaround + hotfix; если не решено за 24 ч — rollback дня |

**После rollback:** каждая доставка дня должна быть **внесена retro** в LogiRoute в течение 48 ч (dispatcher + LogiRoute support).

---

## 8. Post-pilot review (день 31–35)

Встреча **60–90 мин**: LogiRoute + owner + dispatcher.

### 8.1 Что исправить (bugs / блокеры)

| Проблема | Частота | Приоритет | Ticket |
|----------|---------|-----------|--------|
| | | P0 / P1 / P2 | |

### 8.2 Что убрать (шум / лишнее)

- Экраны/шаги, которыми **никто не пользовался** (Usage Summary).
- Дублирующие процессы (double entry).

### 8.3 Что добавить (backlog)

- Запросы клиента с частотой ≥ 3.
- Quick wins на 2–4 недели.

### 8.4 Тарифы

| Вопрос | Решение |
|--------|---------|
| Plan подтверждён (full / ops) | |
| Addon водители (с 6-го) | |
| Модули (warehouse, accounting) | |

### 8.5 Данные для продажи следующему клиенту

Собрать **анonymized** case study:

| Артефакт | Есть? |
|----------|-------|
| % доставок через систему | ☐ |
| Время внедрения (дни до day 1) | ☐ |
| Цитата диспетчера (1–2 предложения) | ☐ |
| Скрин Customer Health / Usage (без PII) | ☐ |
| Топ-3 «why LogiRoute» от owner | ☐ |
| Топ-3 возражения и как закрыли | ☐ |

**Итоговое решение:** ☐ Продолжаем · ☐ Доработка 30 дней · ☐ Стоп

**Подписи:** клиент __________ · LogiRoute __________ · дата __________

---

## Приложение A — журнал инцидентов (шаблон)

| Дата | Время | Тип (GPS / invoice / route / other) | Описание | correlationId | Решение | Downtime |
|------|-------|---------------------------------------|----------|---------------|---------|----------|
| | | | | | | |

## Приложение B — ссылки в продукте

| Задача | Где в UI |
|--------|----------|
| Здоровье всех tenant | Admin → Platform → **Customer Health** |
| Диагностика одной компании | **Support Console** (из Health или Platform) |
| Usage за 7/30 дней | Admin → Reports → **Usage (pilot)**; Owner → Overview |
| Onboarding | **Launch Center** (карточки) / Setup Wizard (legacy) |
| Export diagnostic | Support Console → Export JSON |
| Целостность данных | Admin → Company → **Целостность данных** (или Owner Settings) |

---

*Pilot Runbook — операционный контракт на 30 дней, не замена [`first-week-checklist.md`](first-week-checklist.md).*
