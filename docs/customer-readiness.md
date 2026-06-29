# Customer Readiness — LogiRoute

> **Не Release Readiness.** Вопрос не «готов ли deploy», а **«готов ли клиент работать и платить дальше»**.

Связанные документы:

- [`first-week-checklist.md`](first-week-checklist.md) — первая неделя клиента (день 1 → день 7)
- [`pilot-success-criteria.md`](pilot-success-criteria.md) — когда пилот считается успешным
- [`go-live-decision.md`](go-live-decision.md) — 22 пункта: можно продавать или нет
- [`readiness-backlog.md`](readiness-backlog.md) — финальная сверка tech-audit + backlog по фазам

Технический контекст (для команды): [`project-structure.md`](project-structure.md), product/SaaS audits в истории чата.

---

## Пять вопросов директора (честные ответы на сегодня)

### 1. «В понедельник купил. Когда мои машины поедут?»

| Режим | Срок |
|-------|------|
| **С сопровождением LogiRoute (white-glove)** | **2–3 рабочих дня** до первых реальных маршрутов: день 1 — компания, пользователи, импорт; день 2 — водители, тестовый маршрут; день 3 — боевые доставки |
| **Self-service (клиент сам)** | **Частично готов:** super_admin создаёт компанию через **Create Company Flow** (4 шага) + первого owner/admin; режим **Self Setup** — owner проходит **Launch Center** (`OnboardingCenterScreen`): 11 карточек, любой порядок, делегирование ролям |
| **Done-for-you** | super_admin / LogiRoute настраивает через Launch Center (режим `done_for_you` в `setup_wizard`); письмо owner + view-as |

**Не блокеры для «машины поехали»:** metrics writer, rollback за 2 мин, 50k clients.  
**Блокеры:** обучение, импорт данных, первый водитель в системе, координаты склада.

---

### 2. «Сколько человек нужно обучать?»

| Роль | Кто | Минимум обучения |
|------|-----|------------------|
| **Owner / директор** | 1 | 1–2 ч: обзор, отчёты, billing (не ежедневная работа) |
| **Диспетчер** | 1 (критично) | **4–6 ч** + 2–3 дня практики: точки, маршруты, карта, водители |
| **Кладовщик** | 0–1 | 2–3 ч (если модуль склад) |
| **Водители** | 3–5 на пилот | **30–45 мин** каждый: приложение, GPS, POD, «доставлено» |
| **Бухгалтер** | 0–1 | 2–4 ч (если full + счета в системе) |

**Итого для пилота:** минимум **1 сильный диспетчер** + **краткий инструктаж водителей**. Owner может быть тем же диспетчером на старте.

---

### 3. «Диспетчер заболел. Новый — через сколько часов?»

| Если | Срок |
|------|------|
| Замена **уже есть** user с ролью dispatcher, базовый инструктаж был | **2–4 часа** до самостоятельного планирования (не эксперт, но рабочий день) |
| Нужно **создать нового user** (admin/super_admin доступен) | +30–60 мин |
| Нет документации / не было backup-диспетчера | **1–2 дня** хаоса (типично для любой TMS без SOP) |

**Пробел продукта:** нет встроенного «режима обучения» / wizard для нового диспетчера — только живой человек или [`first-week-checklist.md`](first-week-checklist.md).

---

### 4. «Завтра 5 машин → 12. Что менять?»

| Что | Нужно менять? |
|-----|----------------|
| Тариф / addon водители | План **full** включает 5; с 6-го — addon ₪99/водитель (billing) |
| Настройки системы | **Нет** — добавить users role driver |
| Новый сервер / «мощнее» | **Нет** на этапе 12 машин |
| Процесс диспетчера | Возможно второй экран / второй диспетчер при >8–10 активных маршрутах одновременно — **организационно**, не технически |

---

### 5. «Как быстро отвечает поддержка?»

| Сегодня | Целевое для первого клиента |
|---------|----------------------------|
| Нет SLA в продукте; Support Console — **super_admin вручную** | **Критичное:** ответ ≤ 2 ч в рабочие часы; **остальное:** ≤ 24 ч |
| Нет ticket-системы в app | WhatsApp/телефон + Support Console export JSON |
| **Customer Health Dashboard** (super_admin) | Таблица всех tenant: billing, setup %, GPS/routes/sync — bounded reads, фильтры Healthy/Warning/Critical/Demo |
| **Company Remote Config** | Живые pilot-параметры (auto-close, GPS stale, session lock, import preview) без rebuild — Owner Settings / Admin menu |
| **Support Console — Diagnostic Center** (super_admin) | Одна компания за 1–2 мин: billing, onboarding %, users/drivers, routes, accounting sync, notifications, recent errors + correlationId filter |
| **Platform Error Center** (super_admin) | Все ошибки платформы: группировка по fingerprint, severity, correlationId → Support Console / Customer Health |
| **Data Integrity Checker** (super_admin / owner / admin) | Поиск рассогласований между users/points/routes/invoices/inventory/GPS/sync/remote_config; severity, ignore/resolve, CSV, nightly + ручной запуск |

**Честно:** support — **ваш процесс**, не функция кнопки в приложении (пока). Customer Health Dashboard сокращает triage по всем tenant; Support Console — полный bounded snapshot одной компании до звонка/во время звонка.

### Support Console — Diagnostic Center (super_admin)

**Путь:** Admin → Platform → Support Console (или клик из Customer Health).

| Панель | Источник | Reads |
|--------|----------|-------|
| Billing | `CompanySettings`, `paymentEvents` limit 20 | plan, status, trial/paid/grace, last ok/fail payment |
| Setup | `setup_wizard`, `CompanyHealthService` | setup %, next required onboarding section |
| Users / Drivers | `users` count, `members` count, `metrics/daily`, stale GPS count | total users, drivers, active today, stale GPS |
| Routes | routes count, delivery_points count, daily metrics | active routes, pending/cancelled points, completed today |
| Accounting | sync_ledger limit 1 + failed count | status, last error, **Retry** (existing CF) |
| Notifications | FCM users count, push/email logs limit 20 | tokens ratio, last push/email log |
| Recent Errors | audit + systemEvents limit 20 each | merge + filter by correlationId |
| Quick Actions | — | Refresh, view-as owner/dispatcher, recalculate metrics, billing portal, subscription |

**Read-only по умолчанию.** Недestructive: retry sync и recalculate metrics — существующие CF; integrity check / migrate counters — как раньше в app bar.

**Креатив:** кнопка «Copy summary» — однострочное резюме tenant в буфер (Slack/WhatsApp).

---

## Правило приоритизации (ближайшие недели)

> **Любое исправление должно отвечать: уменьшает ли вероятность потерять первого клиента?**

| Исправлять | Не сейчас |
|------------|-----------|
| ~~Stripe ложный success~~ → CLOSED | 50 000 clients pagination |
| ~~GPS «активен» при выключенном GPS~~ → CLOSED | 300 водителей на карте |
| ~~viewer dead end~~ → CLOSED | Product Analytics (read-only dashboard — backlog) |
| ~~visit_logs rules~~ → CLOSED | Per-tenant versioning |
| **Restore drill (test/staging)** — OPEN | Stock report inventory без limit |
| First-week SOP + go-live gate | Export fetch-all (batch) |

---

## Порядок работ (не код — процесс)

1. **Go-Live Decision** — все пункты A–E → 🟢 для *одного* пилота (см. [`readiness-backlog.md`](readiness-backlog.md))  
2. **First Week** — провести с первым клиентом по чеклисту  
3. **Pilot Success Criteria** — через 30 дней: продолжает или нет  
4. Только потом: Product Analytics, масштаб SaaS

---

*Customer Readiness — это контракт с первым клиентом, не с Firebase.*
