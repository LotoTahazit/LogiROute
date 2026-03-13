# 📘 ENGINEERING_METHODS.md

## LogiRoute Accounting & Compliance Core Contract

---

## 1️⃣ SYSTEM INVARIANTS (НЕЛЬЗЯ НАРУШАТЬ)

### 1.1 Invoice Immutability (חוק ניהול ספרים)

После установки `finalizedAt != null` **запрещено** изменять:

- `sequentialNumber`
- `companyId`
- `clientName`
- `clientNumber`
- `address`
- `items`
- `discount`
- `immutableSnapshotHash`
- `finalizedAt`
- `finalizedBy`

**Разрешено** менять только:

- `status`
- `cancelledAt`
- `cancelledBy`
- `cancellationReason`
- `assignmentStatus`
- `assignmentNumber`
- `assignmentRequestedAt`
- `assignmentResponseRaw`
- `driverName`
- `truckNumber`
- `paymentDueDate`
- `deliveryDate`
- `originalPrinted`
- `copiesPrinted`
- `printedCount`
- `lastViewedAt`

### 1.2 Sequential Numbering

Коллекция:
```
companies/{companyId}/counters/{docType}
```

Правила:
- `create` → `lastNumber == 1`
- `update` → `lastNumber == previous + 1`
- `delete` → **запрещено**

❗ Никогда не использовать произвольный increment.
❗ Номер всегда берётся через транзакцию.

### 1.3 Audit Log — Append Only

Коллекция:
```
companies/{companyId}/invoices/{invoiceId}/auditLog/{eventId}
```

Правила:
- `create only`
- `update` запрещён
- `delete` запрещён
- `actorUid` ОБЯЗАН быть равен `request.auth.uid`

Обязательные поля:
```json
{
  "actorUid": "<auth.uid>",
  "action": "<string>",
  "ts": "serverTimestamp()",
  "invoiceId": "<id>",
  "companyId": "<id>"
}
```

### 1.4 Integrity Chain — Append Only

Коллекция:
```
companies/{companyId}/integrity_chain/{chainId}
```

- `create only`
- immutable
- `update`/`delete` запрещены

---

## 2️⃣ FINALIZE INVOICE — GOLDEN FLOW (ЗАПРЕЩЕНО МЕНЯТЬ ПОРЯДОК)

`finalizeInvoice(invoiceId)`

Внутри одной transaction:

1. Получить invoice
2. Проверить, что `finalizedAt == null`
3. Получить counter
4. `newNumber = counter.lastNumber + 1`
5. Обновить counter
6. Обновить invoice:
   - `sequentialNumber`
   - `finalizedAt`
   - `finalizedBy`
   - `immutableSnapshotHash`
7. Добавить auditLog event
8. Добавить integrity_chain запись

❗ Порядок менять запрещено
❗ Запись auditLog всегда после update invoice

---

## 3️⃣ IMMUTABLE SNAPSHOT HASH

Hash обязан включать:

- `companyId`
- `clientName`
- `clientNumber`
- `address`
- `items`
- `subtotalBeforeVAT`
- `vatAmount`
- `totalWithVAT`
- `discount`
- `linkedInvoiceId` (если есть)

Любое изменение структуры → **Change Proposal обязателен**.

---

## 4️⃣ ASSIGNMENT REQUEST FLOW (מספר הקצאה)

Коллекция:
```
companies/{companyId}/assignment_requests/{requestId}
```

Разрешено:
- `create`
- `update` только статусных полей

Запрещено:
- менять `invoiceId`
- `delete`

---

## 5️⃣ PRINT EVENTS

Коллекция:
```
printEvents
```

- Append-only.
- Обязательное поле: `printedBy == auth.uid`

---

## 6️⃣ CHANGE CONTROL POLICY

Любое изменение следующих модулей требует `CHANGE_PROPOSAL_YYYYMMDD.md`:

- `finalizeInvoice`
- `counters`
- `auditLog`
- `integrity_chain`
- `immutableSnapshotHash`
- Firestore Rules

Change Proposal должен содержать:

- Причина
- Риски
- Миграция
- Обратимость
- Влияние на compliance

**Без этого изменения запрещены.**

---

## 7️⃣ NON-NEGOTIABLES FOR AI / KИРО

При работе с кодом:

- ❌ Никаких рефакторингов без запроса
- ❌ Никаких переименований
- ❌ Никакого изменения порядка операций finalize
- ❌ Никакого удаления auditLog
- ❌ Никаких изменений правил immutability

Разрешено только:

- минимальный patch
- исправление багов
- добавление новых модулей без изменения core

---

## 8️⃣ FIRESTORE RULES ALIGNMENT

Любое изменение backend-логики должно:

- соответствовать текущим Firestore Rules
- не ослаблять immutability
- не разрешать delete invoices
- не разрешать update auditLog
- сохранять +1 numbering

---

## 9️⃣ COMPLIANCE LEVEL

Система разрабатывается как:

- SaaS Accounting System
- Israeli Tax Law Compliant
- Sequential Numbered
- Immutable Documents
- Append-only Audit Trail
- Integrity Chain Anchored

**Любое отклонение от этого — критическая ошибка.**

---

## 🔟 DOCUMENT TYPES (סוגי מסמכים)

### Enum: `InvoiceDocumentType`

| Значение | Название | Описание |
|----------|---------|----------|
| `invoice` | חשבונית מס | Налоговый инвойс. Основной документ. |
| `taxInvoiceReceipt` | חשבונית מס / קבלה | Инвойс + квитанция. Создаётся при галочке "תשלום התקבל". |
| `receipt` | קבלה | Квитанция об оплате. Привязана к חשבונית через `linkedInvoiceId`. |
| `delivery` | תעודת משלוח | Накладная. Без цен. |
| `creditNote` | חשבונית זיכוי | Credit note. Привязана к оригиналу через `linkedInvoiceId`. |

### Поля, специфичные для типов

- `paymentMethod` (String?) — способ оплаты. Используется для `taxInvoiceReceipt` и `receipt`.
- `linkedInvoiceId` (String?) — ссылка на оригинальный документ. Для `receipt` и `creditNote`.
- `deliveryPointId` (String?) — ID точки доставки. Для предотвращения дублей.

### Правила создания

- `invoice` → из точки доставки (CreateInvoiceDialog)
- `taxInvoiceReceipt` → из точки доставки, когда `_paymentReceived == true`
- `delivery` → из точки доставки (отдельная кнопка)
- `receipt` → из экрана ניהול חשבוניות, привязка к существующей חשבונית
- `creditNote` → из экрана ניהול חשבוניות, привязка к существующей חשבונית

### Нумерация

Каждый тип имеет свой счётчик: `companies/{companyId}/counters/{docType.name}`

### Требования к מספר הקצאה

Только `invoice` и `taxInvoiceReceipt` требуют מספר הקצאה (при превышении порога).

---

## 🔒 ЗАЩИТНЫЙ ПРОМПТ ДЛЯ KИРО

Использовать в начале каждого задания:

> Следуй строго ENGINEERING_METHODS.md. Никаких рефакторингов. Только минимальный patch. Нельзя менять finalize flow. Нельзя менять numbering contract. AuditLog всегда actorUid == auth.uid. Если требуется изменить core-методы — сначала создай Change Proposal.
