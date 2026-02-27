# 📘 MODULAR_ARCHITECTURE.md

## LogiRoute — Модульная SaaS архитектура

> Утверждено: 27.02.2026. Основа для реализации.

---

## 1️⃣ Принцип

Одна платформа, много модулей, включаемых через entitlements (права/лицензии).
Не отдельные приложения, не разные билды.

---

## 2️⃣ Модули

| ID | Название | Описание |
|----|---------|----------|
| `warehouse` | מחסן (Mahsan) | Товары, остатки, приходы/расходы, инвентаризация, сканер |
| `logistics` | Logistics | Клиенты, точки доставки, маршруты, ETA, водители |
| `dispatcher` | Dispatcher | Карта, назначение, статусы, чат/комментарии |
| `accounting` | Accounting | חשבוניות/קבלות/תעודות משלוח/זיכוי, печать, audit trail, counters |
| `reports` | Reports | Отчёты, экспорт, аналитика |

---

## 3️⃣ Dependency Matrix

```
warehouse     — автономен
logistics     — требует: clients, delivery_points
dispatcher    — требует: logistics
accounting    — требует: clients (+ желательно product_types)
reports       — не требует, но показывает только доступные домены
```

Граф:
```
warehouse (standalone)
    │
clients + delivery_points (shared core)
    │
logistics
    │
dispatcher
    
clients + product_types (shared core)
    │
accounting

reports → overlay поверх всего
```

---

## 4️⃣ Firestore модель entitlements

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

---

## 5️⃣ Enforcement — 3 слоя

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

## 6️⃣ Ценообразование (целевое)

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

## 7️⃣ Provisioning (инициализация компании)

При создании компании (через Cloud Functions / Admin SDK):

1. Создать документ `companies/{companyId}` с дефолтными settings
2. Создать counters с `nextNumber: 1` для каждого типа документа
3. Создать entitlements (trial или базовый план)
4. Клиент НЕ может сам включить модули

---

## 8️⃣ Billing

- Автоматический: entitlements меняет сервер (webhook оплаты)
- Ручной: super_admin меняет план через панель → серверный слой
- `billingStatus`: `active` | `past_due` | `trial` | `blocked`

---

## 9️⃣ Техническая реализация — ModuleManager

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

## 🔟 TODO — порядок реализации

1. [ ] Добавить `modules`, `limits`, `plan`, `billingStatus` в модель CompanySettings
2. [ ] Создать `ModuleManager` класс
3. [ ] Обернуть все экраны проверкой модулей (UI слой)
4. [ ] Обернуть сервисы проверкой (Service слой)
5. [ ] Обновить Firestore Security Rules (Rules слой)
6. [ ] Создать provisioning Cloud Function
7. [ ] Создать super_admin панель управления модулями
8. [ ] Тестирование: включение/выключение модулей
