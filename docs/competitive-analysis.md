# LogiRoute — конкурентный анализ и позиционирование

> **Версия:** 2026-06-21  
> **Назначение:** инвестор, партнёр, продажи  
> **Не является технической спецификацией.** Факты реализации — в [`project-structure.md`](project-structure.md).

---

## 1. Для кого продукт (целевые сегменты)

| Сегмент | Характеристика |
|---------|----------------|
| Дистрибьюторы | паллетная/коробочная доставка по клиентам |
| SMB с полевой логистикой | 1 склад, несколько машин, диспетчер |
| Компании с счётами «на выезде» | счёт/накладная привязаны к точке доставки |
| Владелец + бухгалтер | нужен реестр документов и отчёты в одном tenant |

**География:** Израиль (иврит/русский/английский UI, израильские налоговые форматы).

---

## 2. Какие задачи закрывает (операционные)

| Задача | Модуль LogiRoute |
|--------|------------------|
| Очередь заказов / точек доставки | Dispatcher → delivery points |
| Планирование маршрутов | Routes + OSRM + map |
| Работа водителя в поле | Driver + GPS + POD |
| Учёт остатков | Warehouse |
| Счета и tax documents | Accounting (plan `full`) |
| Единый справочник клиентов | Customer Master Data |
| Журнал действий | Cross-module audit |

**Не закрывает:** pre-sale CRM, производство, ERP уровня SAP, полноценный WMS enterprise-класса.

---

## 3. Чем отличается от «набора отдельных систем»

LogiRoute объединяет в **одном Firebase-tenant**:

- диспетчеризацию и маршруты;
- мобильный экран водителя;
- склад и (опционально) barcode;
- бухгалтерские документы и sync к GreenInvoice/iCount;
- owner-аналитику и audit.

**Отличие от best-of-breed стека:** общая база `companies/{companyId}/`, связь точка → маршрут → документ → (опционально) движение склада, единый audit log.

**Отличие от CRM-систем:** модуль клиентов — **справочник (Customer Master Data)**, не воронка продаж (см. [`project-structure.md` §6](project-structure.md)).

---

## 4. Что может заменить (типичный legacy-набор)

| Отдельный инструмент | Функция в LogiRoute |
|----------------------|---------------------|
| Excel / Sheets для заказов | delivery points |
| Отдельный TMS | dispatcher + routes + map |
| Мессенджер + звонки водителю | driver app + FCM |
| Простой WMS / таблица склада | warehouse module |
| Выставление счетов (частично) | accounting + sync наружу |
| Разрозненные отчёты | owner reports + admin analytics |

LogiRoute **не заявляет** полную замену GreenInvoice/iCount — sync **исходящий** (push документов), провайдер остаётся системой записи для части компаний.

---

## 5. Тарифы (кратко для продаж)

Детали и лимиты — [`project-structure.md` §4](project-structure.md).

| План | Для кого (логика) |
|------|-------------------|
| `warehouse_only` | только склад |
| `logistics` | доставка без склада и бухгалтерии |
| `ops` | склад + логистика |
| `full` | операции + бухгалтерия + compliance |

Промо-цены первые 3 месяца — см. `billing_pricing.json`.

---

## 6. Оценка экономии для клиента

> **Disclaimer:** цифры ниже — **иллюстративная модель** для разговора с клиентом, не audited financial claim. Фактические цены конкурентов зависят от вендора, объёма и года.

### 6.1. Illustrative TCO comparison (₪/мес, Israel SMB)

| Категория | Разрозненный стек (диапазон) |
|-----------|----------------------------|
| TMS / маршрутизация | 800 – 2,500 |
| WMS / склад | 500 – 1,500 |
| Billing (GreenInvoice / iCount) | 200 – 600 |
| GPS / fleet add-on | 300 – 1,000 |
| Интеграции (разработка / Zapier) | amortized 500+ |

**Суммарный диапазон:** ~₪2,500 – 6,000+/мес + риск рассинхрона данных.

**LogiRoute `full` (regular):** ₪3,990/мес + setup ₪5,000 (из конфига billing).

### 6.2. Качественные выгоды (не monetized в коде)

1. Один login и одна база клиентов  
2. Меньше двойного ввода (точка → маршрут → документ)  
3. Один vendor support contract  
4. Audit trail между модулями  
5. Модульный рост: `logistics` → `ops` → `full`

---

## 7. Ограничения для честного pitch

Использовать при продаже — совпадает с [`project-structure.md` §9](project-structure.md):

- нет CRM / sales pipeline;
- barcode — USB, не камера;
- viewer role без UI;
- plan limits — soft warnings;
- iOS не primary;
- computerized warehouse — журнал есть, formal tax audit — roadmap.

---

## 8. Конкурентная карта (упрощённо)

| | LogiRoute | TMS-only | WMS-only | Billing-only | CRM |
|---|-----------|----------|----------|--------------|-----|
| Маршруты | ✓ | ✓ | — | — | — |
| Driver app | ✓ | частично | — | — | — |
| Склад | ✓ | — | ✓ | — | — |
| Счета IL | ✓ (full) | — | — | ✓ | — |
| BKMV / allocation | ✓ (full) | — | — | частично | — |
| Sales pipeline | — | — | — | — | ✓ |
| Client master | ✓ | частично | частично | ✓ | ✓ |

---

## 9. Связанные документы

- [`project-structure.md`](project-structure.md) — технические факты  
- [`computerized-warehouse.md`](computerized-warehouse.md) — склад barcode  
- `ISRAELI_TAX_COMPLIANCE.md` — tax compliance details  
