# Firestore Index Audit (H8)

> **Дата:** 2026-06-21  
> **Файл индексов:** [`firestore.indexes.json`](../firestore.indexes.json)

## Deploy

```bash
firebase deploy --only firestore:indexes
```

Дождаться статуса **Enabled** в Firebase Console → Firestore → Indexes (composite queries падают до build complete).

---

## Критичные runtime queries (пилот)

| # | Path | Query | Index | Статус |
|---|------|-------|-------|--------|
| 1 | `…/accounting/_root/invoices` | `deliveryDate` range + `orderBy deliveryDate desc` | `invoices`: deliveryDate DESC | **ADD H8** |
| 2 | `…/accounting/_root/invoices` | `createdAt` range + `orderBy createdAt desc` | `invoices`: createdAt DESC | **ADD H8** |
| 3 | `…/accounting/_root/invoices` | `status whereIn` + `createdAt` range + `orderBy createdAt desc` | `invoices`: status ASC, createdAt DESC | **ADD H8** |
| 4 | `…/accounting/_root/invoices` | `clientNumber ==` + `orderBy sequentialNumber desc` | `invoices`: clientNumber, sequentialNumber DESC | **ADD H8** |
| 5 | `…/accounting/_root/invoices` | `clientNumber` + `status whereIn` + `orderBy sequentialNumber desc` | `invoices`: clientNumber, status, sequentialNumber DESC | **ADD H8** |
| 6 | `…/accounting/_root/invoices` | `documentType ==` + `orderBy sequentialNumber asc` | `invoices`: documentType, sequentialNumber ASC | **ADD H8** |
| 7 | `…/accounting/_root/invoices` | `linkedInvoiceId` + `documentType` (credit note lookup) | `invoices`: linkedInvoiceId, documentType | **ADD H8** |
| 8 | `…/logistics/_root/delivery_points` | `createdAt` range + `orderBy createdAt desc` (analytics) | `delivery_points`: createdAt DESC | **ADD H8** |
| 9 | `…/logistics/_root/delivery_points` | `status whereIn` + `orderBy __name__` (route release scan) | `delivery_points`: status, __name__ | **ADD H8** |
| 10 | `users` | `companyId ==` + `fcmToken > ''` count (support diag) | `users`: companyId, fcmToken | **ADD H8** |

**Источники:** `reports_section.dart`, `analytics_screen.dart`, `invoice_service.dart`, `route_service.dart`, `support_diagnostic_service.dart`.

---

## Уже покрыты (без изменений H8)

| Path | Query | Index | Почему OK |
|------|-------|-------|-----------|
| `invoices` | `deliveryPointId` + `documentType` + `status` | existing 3-field | duplicate guard |
| `delivery_points` | `status` + `completedAt` + `orderBy completedAt` | existing | archive stale |
| `delivery_points` | `driverId` + `status` (+ `orderInRoute`) | existing | dispatcher/driver |
| `delivery_points` | `routeId` + `orderBy orderInRoute` | existing | route reorder |
| `usage_events` | `eventName` + `timestamp >=` count | existing | usage summary |
| `usage_events` | `timestamp >=` + `orderBy timestamp desc` | existing | usage sample |
| `inventory` | `type` + `number` | existing | lookup by type/number |
| `inventory` | `orderBy productCode` only | auto single-field | list stream |
| `inventory` | `barcode ==` only | auto single-field | scan lookup |
| `prices` | `orderBy type` only | auto single-field | price list |
| `companies` | `orderBy documentId` only | auto single-field | customer health pagination |
| `members` | `role ==` count | auto single-field | health drivers count |
| `routes` | `status ==` count | auto single-field | active routes count |
| `delivery_points` | `status whereIn` count | auto single-field | support pending/cancelled |
| `sync_ledger` | `status == failed` count | auto single-field | failed sync count |
| `notifications` | `read == false` count | auto single-field | unread count |
| `audit` / logs | `orderBy createdAt/processedAt/timestamp desc` limit | existing single-field | support console lists |

---

## Legacy indexes (удалить позже, не H8)

| Index | Причина |
|-------|---------|
| `delivery_points` **COLLECTION_GROUP** (companyId, driverId, …) | В `lib/` нет `collectionGroup()` — queries company-scoped |
| `driver_locations.companyId` + timestamp | GPS path `companies/{id}/driver_locations` без поля `companyId` в doc |
| `routes.companyId` + status | routes под `logistics/_root/routes`, не flat `companies/{id}/routes` |

Не удалять до подтверждения отсутствия внешних/скриптовых collectionGroup queries.

---

## Ручная проверка после deploy

1. Owner → Reports → период 30 дней (без FAILED_PRECONDITION)
2. Admin → Analytics → custom range
3. Accounting → список invoices с фильтром даты
4. Support Console → открыть компанию (FCM count, delivery counts)
5. Usage Summary → 7/30 дней
