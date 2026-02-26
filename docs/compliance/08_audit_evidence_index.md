# Audit Evidence Index
## LogiRoute Billing System — Where Every Claim Is Proven

**Version:** 1.0  
**Date:** 2026-02-26  
**Purpose:** Maps each compliance requirement to the exact file, rule, or service that implements it.  
Intended for: tax authority auditors, security reviewers, investors, enterprise clients.

---

## 1. Immutability of Financial Documents

| Claim | Evidence | Location |
|-------|----------|----------|
| Finalized documents cannot be modified | Firestore Rules whitelist on `finalizedAt != null` | `firestore.rules` → `match /invoices/{invoiceId}` → `allow update` |
| Protected fields enforced server-side | Field-level equality checks in Rules | `firestore.rules` lines: `sequentialNumber`, `companyId`, `clientName`, `items`, `discount`, `immutableSnapshotHash` |
| Deletion is forbidden by law | `allow delete: if false` | `firestore.rules` → `match /invoices/{invoiceId}` |
| Dart-level guard | `ImmutabilityGuard` class | `lib/services/immutability_guard.dart` |
| Documentation | אי-שינוי ושלמות מסמכים | `docs/registration/03_אי_שינוי_ושלמות_מסמכים.md` |

---

## 2. Sequential Numbering Integrity

| Claim | Evidence | Location |
|-------|----------|----------|
| Atomic sequential number per document type | Firestore transaction, counter increment == 1 only | `lib/services/invoice_service.dart` → `_getNextSequentialNumberForType()` |
| Counter can only increment by 1 | Rules enforce `lastNumber == resource.data.lastNumber + 1` | `firestore.rules` → `match /counters/{counterId}` |
| Separate series per type (invoice, credit, delivery, receipt) | `InvoiceDocumentType` enum, separate counter docs | `lib/models/invoice.dart`, `lib/services/invoice_service.dart` |
| Gap detection with audit alert | `verifySequentialIntegrity()` returns `SequentialIntegrityResult`, writes audit event `severity: HIGH` | `lib/services/invoice_service.dart` → `verifySequentialIntegrity()` |
| Documentation | סוגי מסמכים ומספור | `docs/registration/02_סוגי_מסמכים_ומספור.md` |

---

## 3. Immutable Snapshot Hash

| Claim | Evidence | Location |
|-------|----------|----------|
| Hash computed at finalization | `computeSnapshotHash()` called in `finalizeInvoice()` | `lib/models/invoice.dart` → `computeSnapshotHash()` |
| Hash includes all financial fields | `companyId`, `sequentialNumber`, `clientName`, `clientNumber`, `items`, `discount`, `subtotalBeforeVAT`, `vatAmount`, `totalWithVAT`, `createdBy`, `linkedInvoiceId`, `item.type`, `item.number` | `lib/models/invoice.dart` → `computeSnapshotHash()` |
| Hash stored immutably | `immutableSnapshotHash` in whitelist — cannot change after finalization | `firestore.rules` → invoice update rule |
| Hash chain linking documents | Each finalized doc appended to integrity chain | `lib/services/integrity_chain_service.dart` → `appendToChain()` |
| External anchor support | Quarterly hash anchoring to external ref | `lib/services/integrity_chain_service.dart` → `createAnchor()` |

---

## 4. Append-Only Audit Log

| Claim | Evidence | Location |
|-------|----------|----------|
| Every action logged before execution (log-before-action) | `logEvent()` called before Firestore write | `lib/services/invoice_service.dart` → `createInvoice()`, `cancelInvoice()`, `finalizeInvoice()` |
| Audit log is append-only | `allow update: if false`, `allow delete: if false` | `firestore.rules` → `match /auditLog/{eventId}` |
| actorUid must match Firebase Auth UID | `request.resource.data.actorUid == request.auth.uid` | `firestore.rules` → `match /auditLog/{eventId}` → `allow create` |
| Document view tracking | `AccessLogService.logAccess(viewDocument)` on invoice open | `lib/services/access_log_service.dart`, `lib/screens/dispatcher/invoice_management_screen.dart` |
| Print events logged separately | `PrintEventService.recordPrintEvent()` | `lib/services/print_event_service.dart` |
| Documentation | יומן ביקורת | `docs/registration/05_יומן_ביקורת.md` |

---

## 5. Print Controls (מקור / עותק)

| Claim | Evidence | Location |
|-------|----------|----------|
| Only one מקור per document (Israeli law) | `originalPrinted` flag, enforced in `printInvoice()` | `lib/services/invoice_print_service.dart` → `printInvoice()` |
| מקור blocked without מספר הקצאה (above threshold) | Check `requiresAssignment && assignmentStatus != approved` before printing | `lib/services/invoice_print_service.dart` → `printFirstTime()` |
| Above-threshold without assignment → prints עותק with warning | Falls through to 3x עותק path, orange snackbar shown | `lib/services/invoice_print_service.dart`, `lib/screens/dispatcher/dispatcher_dashboard.dart` |
| Reprint marked with timestamp | `הדפסה חוזרת DD/MM/YYYY HH:MM` watermark on PDF | `lib/services/invoice_print_service.dart` → `_buildInvoiceTitle()` |
| Documentation | הדפסה ועותקים | `docs/registration/04_הדפסה_ועותקים.md` |

---

## 6. חשבוניות ישראל — מספר הקצאה

| Claim | Evidence | Location |
|-------|----------|----------|
| Thresholds by date (20000/10000/5000 ₪ before VAT) | `_getThreshold(DateTime date)` | `lib/services/invoice_assignment_service.dart` → `_getThreshold()` |
| Assignment requested automatically on finalization | `_assignmentService.requestAssignmentNumber()` called in `finalizeInvoice()` | `lib/services/invoice_service.dart` → `finalizeInvoice()` |
| Idempotency key prevents duplicate assignment | `Idempotency-Key: requestId` header in API call | `lib/services/invoice_assignment_service.dart` → `_callAssignmentApi()` |
| Retry with exponential backoff | `_sendWithRetry()` up to 3 attempts | `lib/services/invoice_assignment_service.dart` → `_sendWithRetry()` |
| Assignment requests stored append-only | `allow delete: if false` | `firestore.rules` → `match /assignment_requests/{requestId}` |
| Documentation | חשבוניות ישראל מספר הקצאה | `docs/registration/08_חשבוניות_ישראל_מספר_הקצאה.md` |

---

## 7. Role-Based Access Control (RBAC)

| Claim | Evidence | Location |
|-------|----------|----------|
| Roles: super_admin, admin, dispatcher, driver, warehouse_keeper | `UserModel.role` field | `lib/models/user_model.dart` |
| Least privilege enforced server-side | Per-collection role checks in Rules | `firestore.rules` — every collection |
| Tenant isolation: users see only their company | `companyId == request.auth.uid companyId` check | `firestore.rules` → all nested `companies/{companyId}/*` rules |
| Invoice create: admin + dispatcher only | `role in ['admin', 'dispatcher']` | `firestore.rules` → `match /invoices/{invoiceId}` → `allow create` |
| Documentation | אבטחה והרשאות | `docs/registration/10_אבטחה_והרשאות.md`, `docs/registration/13_כללי_אבטחה_Firestore.md` |

---

## 8. Multi-Tenant Isolation

| Claim | Evidence | Location |
|-------|----------|----------|
| All data nested under `companies/{companyId}/` | Nested Firestore collections | `lib/services/invoice_service.dart`, `lib/services/audit_log_service.dart`, all services |
| companyId always dynamic, never hardcoded | `CompanyContext.effectiveCompanyId` | `lib/services/company_context.dart` |
| super_admin can switch companies | `CompanySelectionService.selectCompany()` | `lib/services/company_selection_service.dart` |
| Documentation | דרישות SaaS | `docs/registration/12_דרישות_SaaS.md` |

---

## 9. Server Timestamps

| Claim | Evidence | Location |
|-------|----------|----------|
| `finalizedAt` uses server timestamp | `FieldValue.serverTimestamp()` | `lib/services/invoice_service.dart` → `finalizeInvoice()` |
| `cancelledAt` uses server timestamp | `FieldValue.serverTimestamp()` | `lib/services/invoice_service.dart` → `cancelInvoice()` |
| Client clock manipulation impossible | All critical timestamps set server-side | All `*At` fields in Firestore writes |

---

## 10. Credit Notes

| Claim | Evidence | Location |
|-------|----------|----------|
| Credit note is a new document, original unchanged | `createCreditNote()` creates new doc, never modifies original | `lib/services/invoice_service.dart` → `createCreditNote()` |
| Separate sequential series for credit notes | `InvoiceDocumentType.creditNote` counter | `lib/services/invoice_service.dart` → `_getNextSequentialNumberForType()` |
| Formal link between credit and original | `DocumentLinkService.createLink()` | `lib/services/document_link_service.dart` |
| Documentation | קישורים בין מסמכים | `docs/registration/11_קישורים_בין_מסמכים.md` |

---

## 11. Data Retention

| Claim | Evidence | Location |
|-------|----------|----------|
| 7-year minimum retention (Israeli law) | Policy document | `docs/registration/15_מדיניות_שמירת_נתונים.md` |
| Retention checks logged | `DataRetentionService` | `lib/services/data_retention_service.dart` |
| Backup collection append-only | `allow update: if false`, `allow delete: if false` | `firestore.rules` → `match /backups/{backupId}` |
| Documentation | גיבוי ושמירת נתונים | `docs/registration/06_גיבוי_ושמירת_נתונים.md` |

---

## 12. Uniform Export File (קובץ במבנה אחיד)

| Claim | Evidence | Location |
|-------|----------|----------|
| Export in tax authority format | `ExportService` | `lib/services/export_service.dart` |
| Export runs logged append-only | `uniform_export_runs` collection | `firestore.rules` → `match /uniform_export_runs/{runId}` |
| Documentation | קובץ במבנה אחיד | `docs/registration/07_קובץ_במבנה_אחיד.md` |

---

## 13. Security & Encryption

| Claim | Evidence | Location |
|-------|----------|----------|
| All data encrypted at rest (AES-256) | Google Cloud Firestore default | `docs/compliance/01_security_policy.md` |
| All data in transit via TLS 1.2+ | Firebase Hosting + Firestore | `docs/compliance/01_security_policy.md` |
| Authentication mandatory | `request.auth != null` on every rule | `firestore.rules` — every collection |
| Firebase Authentication | `AuthService` | `lib/services/auth_service.dart` |
| Documentation | מדיניות אבטחת מידע | `docs/registration/19_מדיניות_אבטחת_מידע.md`, `docs/compliance/01_security_policy.md` |

---

## 14. Integrity Chain (Hash Chain)

| Claim | Evidence | Location |
|-------|----------|----------|
| Each finalized doc linked to previous hash | `prevHash + documentHash + sequentialNumber → chainHash` | `lib/services/integrity_chain_service.dart` → `appendToChain()` |
| Chain verification detects tampering | `verifyChain()` checks every link | `lib/services/integrity_chain_service.dart` → `verifyChain()` |
| Chain is append-only | `allow update: if false`, `allow delete: if false` | `firestore.rules` → `match /integrity_chain/{chainId}` |
| External anchor for top-tier assurance | `createAnchor()` / `verifyAnchor()` | `lib/services/integrity_chain_service.dart` |

---

## Quick Reference: Key Files

| File | Role |
|------|------|
| `firestore.rules` | Server-side enforcement of all access and immutability rules |
| `lib/services/invoice_service.dart` | Core invoice lifecycle: create, finalize, cancel, credit note |
| `lib/models/invoice.dart` | Data model + `computeSnapshotHash()` |
| `lib/services/audit_log_service.dart` | Append-only audit trail |
| `lib/services/integrity_chain_service.dart` | Hash chain + external anchors |
| `lib/services/invoice_assignment_service.dart` | מספר הקצאה API integration |
| `lib/services/invoice_print_service.dart` | Print controls: מקור/עותק enforcement |
| `lib/services/immutability_guard.dart` | Dart-level immutability guard |
| `lib/services/data_retention_service.dart` | 7-year retention policy |
| `lib/services/access_log_service.dart` | Document view tracking |
| `docs/registration/` | 21 Hebrew compliance documents for tax authority |
| `docs/compliance/` | 7 English governance documents for auditors/investors |
