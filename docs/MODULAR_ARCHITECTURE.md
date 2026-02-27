# 📘 MODULAR_ARCHITECTURE.md

## LogiRoute — Модульная SaaS архитектура

> Утверждено: 27.02.2026. Основа для реализации.

---

## 1️⃣ Принцип

Одна платформа, много модулей, включаемых через entitlements (права/лицензии).
Не отдельные приложения, не разные билды.

---

## 2️⃣ Уровни архитектуры

### Уровень 0 — Core Platform (обязательный для всех)

Это не модуль, это основа:
- Auth / Users / Roles
- Company context
- Feature flags / entitlements
- Billing status
- Audit platform-level
- Notifications
- File storage

Всегда включено.

### Уровень 1 — Бизнес-модули

| ID | Название | Коллекции | Зависимости |
|----|---------|-----------|-------------|
| `warehouse` | 📦 מחסן (Mahsan) | `product_types`, `inventory`, `stock_movements`, `box_types` | Только Core. Продаётся отдельно. |
| `logistics` | 🚚 Logistics | `clients`, `delivery_points`, `routes`, `route_assignments` | Core. Опционально Warehouse (если товары). Продаётся отдельно. |
| `dispatcher` | 🧭 Dispatcher | `live_tracking`, `driver_status`, `route_updates` | Logistics. Нельзя без Logistics. |
| `accounting` | 🧾 Accounting (СЕРТИФИЦИРУЕМЫЙ) | `accounting/invoices`, `accounting/receipts`, `accounting/credit_notes`, `accounting/counters`, `accounting/audit_log`, `accounting/integrity_chain`, `accounting/backups` | Core + Clients. НЕ зависит от Warehouse. Изолированный блок. |
| `reports` | 📊 Reports / BI | Читает из warehouse/logistics/accounting | Не создаёт данные. Overlay. |

---

## 3️⃣ Dependency Matrix

| Модуль | Требует |
|--------|---------|
| Warehouse | Core |
| Logistics | Core |
| Dispatcher | Logistics |
| Accounting | Core + Clients |
| Reports | Любые активные |

```
Core Platform (Auth, Users, Roles, Billing, Notifications)
    │
    ├── warehouse (standalone)
    │
    ├── logistics (standalone)
    │       │
    │       └── dispatcher (requires logistics)
    │
    ├── accounting (isolated, certifiable)
    │       └── uses: clients (shared)
    │
    └── reports (overlay, reads all)
```

---

## 4️⃣ Firestore структура (чистая и масштабируемая)

```
companies/{companyId}/
    settings/
    entitlements/
    users/

    warehouse/
        product_types/
        inventory/
        stock_movements/

    logistics/
        clients/
        delivery_points/
        routes/

    dispatcher/
        live_tracking/

    accounting/          ← ИЗОЛИРОВАННЫЙ БЛОК
        invoices/
        receipts/
        credit_notes/
        counters/
        audit_log/
        integrity_chain/
```

Почему так:
- Нет хаоса на одном уровне
- Accounting изолирован физически
- Rules проще писать
- Можно сказать регулятору: "Вот отдельный блок"

---

## 5️⃣ Entitlements (module flags)

### Документ: `companies/{companyId}`

```json
{
  "modules": {
    "warehouse": true,
    "logistics": false,
    "dispatcher": false,
    "accounting": true,
    "reports": true
  },
  "limits": {
    "maxUsers": 10,
    "maxDocsPerMonth": 2000,
    "maxRoutesPerDay": 50
  },
  "plan": "warehouse_only",
  "billingStatus": "active",
  "trialEndsAt": null
}
```

### Планы

| Plan ID | Модули | Целевая аудитория |
|---------|--------|-------------------|
| `warehouse_only` | warehouse | Малый склад |
| `ops` | warehouse + logistics + dispatcher | Логистическая компания |
| `full` | все модули | Enterprise |
| `custom` | произвольный набор | По запросу |

### Пакеты (продаваемая модель)

| Пакет | Состав | Ориентир |
|-------|--------|----------|
| 🟢 Warehouse Only | Core + Warehouse | ~1,300 ₪ |
| 🔵 Operations | Core + Warehouse + Logistics + Dispatcher | ~4,500 ₪ |
| 🟣 Full Business | Все модули | ~7,000–10,000 ₪ |

Accounting можно продавать как add-on к любому пакету.

---

## 6️⃣ Enforcement — 3 слоя

### Слой 1: UI
- Скрыть модуль/кнопки
- Показать "недоступно по тарифу"
- `ModuleManager.hasModule(companyId, 'warehouse')`

### Слой 2: Service
- Перед записью проверять entitlement
- Ловить ошибку до Firestore

### Слой 3: Firestore Security Rules
- Финальный замок (никакой обход через другой клиент)

```javascript
function hasModule(companyId, key) {
  return get(/databases/$(database)/documents/companies/$(companyId)).data.modules[key] == true
    && get(/databases/$(database)/documents/companies/$(companyId)).data.billingStatus in ["active", "trial"];
}

// Пример:
match /companies/{companyId}/invoices/{docId} {
  allow read, create, update: if isCompanyMember(companyId)
    && hasModule(companyId, "accounting");
}
```

---

## 7️⃣ Ценообразование (целевое)

### Структура: Platform fee + модули + лимиты

| Компонент | Цена (₪/мес) |
|-----------|-------------|
| Platform fee (инфра, безопасность, апдейты) | 300–500 |
| 📦 Mahsan (Warehouse) | 800–1,500 |
| 🚚 Logistics / Routes | 1,000–2,500 |
| 🧭 Dispatcher | 500–1,500 |
| 🧾 Accounting | 800–2,000 |
| 📊 Reports / Analytics | 400–800 |

### Надбавки

- Доп. пользователь: 50–100 ₪
- Доп. документы/месяц
- Доп. маршруты/день
- Интеграции/печать/шаблоны

### Пакеты (для простоты продаж)

| Пакет | Состав | Ориентир цены |
|-------|--------|--------------|
| Warehouse Only | Platform + Mahsan | ~1,300 ₪ |
| Operations | Platform + Mahsan + Logistics + Dispatcher | ~4,500 ₪ |
| Full | Все модули | ~7,000–10,000 ₪ |

### Целевой ARPA: ~$1,200/мес → 70 компаний = $1M ARR

---

## 8️⃣ Provisioning (инициализация компании)

При создании компании (через Cloud Functions / Admin SDK):

1. Создать документ `companies/{companyId}` с дефолтными settings
2. Создать counters с `nextNumber: 1` для каждого типа документа
3. Создать entitlements (trial или базовый план)
4. Клиент НЕ может сам включить модули

---

## 9️⃣ Billing

- Автоматический: entitlements меняет сервер (webhook оплаты)
- Ручной: super_admin меняет план через панель → серверный слой
- `billingStatus`: `active` | `past_due` | `trial` | `blocked`

---

## 🔟 Техническая реализация — ModuleManager

```dart
class ModuleManager {
  static bool hasModule(CompanySettings company, String moduleId) {
    if (company.billingStatus == 'blocked') return false;
    return company.modules[moduleId] == true;
  }
  
  static bool hasWarehouse(CompanySettings c) => hasModule(c, 'warehouse');
  static bool hasLogistics(CompanySettings c) => hasModule(c, 'logistics');
  static bool hasDispatcher(CompanySettings c) => hasModule(c, 'dispatcher');
  static bool hasAccounting(CompanySettings c) => hasModule(c, 'accounting');
  static bool hasReports(CompanySettings c) => hasModule(c, 'reports');
}
```

Использование:
```dart
if (!ModuleManager.hasWarehouse(company)) {
  return AccessDeniedScreen(module: 'warehouse');
}
```

---

## 1️⃣1️⃣ Стратегическое решение

**Подход: A — Один код-бейс, флаги включают/выключают.**

Микросервисы — потом, когда масштаб потребует. Для старта SaaS — монолит с feature flags оптимален.

**Ключевое правило для Accounting:**
- Технически независим
- Не ломается если отключить Warehouse
- Собственные counters / audit / integrity

---

## 1️⃣2️⃣ TODO — порядок реализации

1. [ ] Добавить `modules`, `limits`, `plan`, `billingStatus` в модель CompanySettings
2. [ ] Создать `ModuleManager` класс
3. [ ] Обернуть все экраны проверкой модулей (UI слой)
4. [ ] Обернуть сервисы проверкой (Service слой)
5. [ ] Обновить Firestore Security Rules (Rules слой)
6. [ ] Создать provisioning Cloud Function
7. [ ] Создать super_admin панель управления модулями
8. [ ] Тестирование: включение/выключение модулей
