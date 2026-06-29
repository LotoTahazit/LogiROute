# ТЗ: пакет для проверяющего (מבקר / רשות המסים)

> **Аудитория:** product, owner/admin, внешний מבקר, LogiRoute support  
> **База:** существующие BKMV, `audit_section`, `integrity_check`, period lock, PDF, sync ledger

---

## Статус

**POST-PILOT**

## Приоритет

**Высокий**

## Причина переноса

Функциональность не требуется для микро-пилота и первого коммерческого внедрения.  
Разработка начинается после успешного завершения пилота и получения обратной связи от первого клиента и бухгалтера.

## Критерий старта

- Пилот успешно завершён.
- Подтверждена потребность клиента.
- Закрыты критические эксплуатационные задачи (Remote Config, Integrity Checker, Incident Center при необходимости).

## Этапы

| Этап | Содержание |
|------|------------|
| **P0** | VAT Audit Package (מע״מ) |
| **P1** | Income Tax + Internal Audit + роль Auditor |
| **P2** | Расширенный Compliance Center, PDF batch, сводные отчёты, интеграция с Support Console |

---

## 1. Цель

Один понятный поток **«Пакет для ביקורת»**, без претензии заменить Hashavshevet/Rivhit, но закрывающий типовые запросы:

| Тип проверки | Кто спрашивает | Что нужно на выходе |
|--------------|----------------|---------------------|
| **מע״מ (НДС)** | רשות המסים / מבקר מע״מ | מבנה אחיד + реестр счетов + מספר הקצאה |
| **מס הכנסה** | מבקר פנימי / רואה חשבון | обороты, целостность нумерации, журнал, период |
| **ביקורת פנימית** | owner / CFO | audit trail, кто менял, сверка с доставками |

Не ломать: `Invoice` / `issueInvoice`, BKMV codec, `CrossModuleAuditService`, GreenInvoice/iCount sync.

---

## 2. Роли и доступ

### 2.1. Новая роль `auditor` (מבקר)

| | |
|---|---|
| **Уровень** | как `viewer` — только чтение |
| **Видит** | только экран **«Пакет для ביקורת»** + скачивание ZIP/CSV/PDF (без логистики, без настроек) |
| **Не видит** | маршруты, GPS, пользователей, billing secrets, API keys |
| **Срок** | опционально `auditorExpiresAt` на member doc |
| **Назначает** | owner / admin (не dispatcher) |

Альтернатива фазы 1: без новой роли — **временная ссылка** (signed URL + CF `generateAuditPackage`, TTL 24h). Роль предпочтительна для повторных ביקורת.

### 2.2. Кто готовит пакет

| Роль | Действие |
|------|----------|
| owner / admin / accountant | выбор периода → «Сформировать пакет» |
| super_admin | то же + Support Console shortcut |

---

## 3. UI: экран «Пакет для ביקורת»

**Путь:** Owner Dashboard → **Комплаенс** → `audit` (расширить) или отдельная вкладка `audit_package`.

### 3.1. Мастер (3 шага)

1. **Тип проверки** (radio):
   - מע״מ / מבנה אחיד
   - מס הכנסה / ספרים
   - ביקורת פנימית
2. **Период** — `from` / `to` (календарь; default = квартал / месяц)
3. **Состав пакета** — чеклисты по типу (см. §4)

Кнопки: **Предпросмотр** | **Скачать ZIP** | **Отправить מבקר** (email с ссылкой, фаза 2)

### 3.2. Блок «Статус готовности»

Перед выгрузкой показать:

- ✅/⚠️ ח.פ. заполнен
- ✅/⚠️ `bkmvSoftwareRegistrationNumber` (для מע״מ)
- ✅/⚠️ период не пересекает открытые draft (или предупреждение)
- ✅/⚠️ integrity chain за период (краткий итог)
- ✅/⚠️ счета без מספר הקצאה выше порога (если `enableAssignmentNumbers`)

---

## 4. Состав пакета по типу проверки

### 4.1. מע״מ / מבנה אחיד (приоритет P0)

| Файл в ZIP | Источник (существующий код) | Примечание |
|------------|----------------------------|------------|
| `OPENFRMT/BKMVDATA.TXT` + `INI.TXT` | `UniformExportService.exportOpenFormat` | уже есть; включить `BkmvSimulator` — при fail не отдавать ZIP |
| `manifest.json` | новый | companyId, taxId, period, exportAt, docCount, softwareRegNo |
| `invoices_register.csv` | новый query по `invoices` | id, docNumber, type, date, client, net, vat, gross, assignmentNumber, status |
| `assignment_gaps.csv` | новый | счета ≥ порога без הקצאה |
| `pdfs/` (опционально) | `invoice_print_service` batch | лимит N=50, остальное — только register |

**Не входит в P0:** автоматический דוח מע״מ цифрами (см. фаза 2).

### 4.2. מס הכנסה / ספרים (P1)

LogiRoute **не** ведёт полную כפולה; пакет = **первичка + контрольные отчёты**:

| Файл | Содержание |
|------|------------|
| `revenue_summary.csv` | выручка по месяцам (issued, не voided) — из `Invoice.isLive` |
| `invoices_register.csv` | как выше |
| `credit_notes_register.csv` | זיכוי со связью `linkedInvoiceId` |
| `integrity_report.json` | результат `verifyIntegrityChain` за диапазон номеров |
| `period_locks.json` | `accountingLockedUntil`, история смен (из audit `accounting_locked_until_changed`) |
| `external_sync_status.csv` | `sync_ledger` — что ушло в GI/iCount |

Явная **дисклеймер-строка** в manifest: «Не заменяет דוח שנתי לרשות המסים; для полной бухгалтерии — Hashavshevet / GI / iCount».

### 4.3. ביקורת פנימית (P1)

| Файл | Содержание |
|------|------------|
| `audit_events.csv` | `audit_section` export — уже есть логика |
| `access_log.csv` | `AccessLogService` за период |
| `delivery_vs_invoice.csv` | delivery_point_id, invoice_id, status доставки, сумма счёта |
| `inventory_movements.csv` | если `warehouse` — `inventory_history` за период |
| `user_actions_summary.csv` | агрегат по uid: create/void/export |

---

## 5. Backend

### 5.1. Callable `generateAuditPackage`

```
Input:  companyId, packageType (vat|income_tax|internal), from, to, includePdfs?
Output: { packageId, downloadUrl?, expiresAt, manifest, warnings[] }
```

- Генерация **на сервере** (Admin SDK) — не собирать ZIP на клиенте (лимит памяти web).
- Хранение: `companies/{id}/audit_packages/{packageId}` + Storage `audit_packages/{companyId}/{packageId}.zip`
- TTL Storage: 7 дней; metadata в Firestore для истории «кто выгрузил».

### 5.2. Переиспользование

| Модуль | Использование |
|--------|----------------|
| `UniformExportService` / `BkmvExporter` | מע״מ ZIP |
| `verifyIntegrityChain` CF | integrity_report |
| `AuditRepository` | audit CSV |
| `CrossModuleAuditService.allTypes` | фильтр для internal |
| `CorrelationContext` | `operation: export_audit_package` |

### 5.3. Firestore rules

- `audit_packages`: read owner/admin/accountant/auditor; create через CF only
- Storage: read signed URL; write CF only

---

## 6. Отличия от конкурентов (ожидания рынка)

| Функция | Hashavshevet / Rivhit | GreenInvoice | **LogiRoute (после ТЗ)** |
|---------|---------------------|--------------|--------------------------|
| מבנה אחיד | ✅ нативно | ✅ | ✅ через BKMV |
| דוח מע״מ готовый | ✅ | ✅ | ⚠️ P2 — сводка, не подача |
| מסך מבקר | ✅ read-only user | ограниченно | ✅ роль `auditor` |
| Связь доставка↔счёт | ❌ | ❌ | ✅ **уникально** |
| Integrity chain | редко | нет | ✅ |

---

## 7. Фазы реализации

### Фаза 1 (MVP, 1–2 спринта)

- [ ] Экран мастера + тип «מע״מ»
- [ ] CF `generateAuditPackage` → ZIP (BKMV + invoices_register + manifest)
- [ ] Кнопка в `audit_section` и `accounting_section`
- [ ] Предпросмотр warnings
- [ ] Тесты: пустой период, simulator fail, register fields

### Фаза 2

- [ ] Типы «מס הכנסה» + «פנימית»
- [ ] Роль `auditor` + rules
- [ ] `revenue_summary`, delivery_vs_invoice
- [ ] Email ссылка מבקר

### Фаза 3

- [ ] דוח מע״מ summary (не подача в שע״מ)
- [ ] Batch PDF в ZIP
- [ ] Audit package в Support Console (super_admin)

---

## 8. Тесты

| Тест | Ожидание |
|------|----------|
| VAT package empty period | warnings, no BKMV files |
| VAT package with invoices | simulator pass, register row count = issued count |
| Integrity fail | warning in manifest, ZIP optional block |
| auditor role | read package, deny write invoice |
| dispatcher | no access to audit package screen |
| GI sync row | external_sync_status reflects ledger |

---

## 9. Ручной чеклист (пилот)

1. Owner → Пакет → מע״מ → квартал → Download ZIP  
2. Прогнать ZIP через [בודק מבנה אחיד](https://www.gov.il) (sandbox)  
3. Сверить `invoices_register.csv` с UI бухгалтерии  
4. Создать user `auditor` → только экран пакета  
5. Support Console — нет регрессии  

---

## 10. Связанные файлы (текущие)

- `lib/widgets/bkmv_export_dialog.dart`
- `lib/services/uniform_export_service.dart`
- `lib/features/owner_dashboard/widgets/sections/audit_section.dart`
- `lib/screens/admin/integrity_check_screen.dart`
- `functions/verifyIntegrityChain.js`
- `ISRAELI_TAX_COMPLIANCE.md`

---

## Статус реализации

- [ ] P0 — VAT Audit Package
- [ ] P1 — Income Tax Package
- [ ] P1 — Internal Audit Package
- [ ] P1 — Auditor Role
- [ ] P2 — Compliance Dashboard
- [ ] P2 — Batch PDF
- [ ] P2 — Support Console Integration
