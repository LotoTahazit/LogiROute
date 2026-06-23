# Israeli Tax Law Compliance Guide
# מדריך תאימות לחוק המס הישראלי

**Last Updated:** June 2026 | **Status:** Implemented — software registration pending

---

## ✅ Implemented Features

### 1. Sequential Numbering / מספור רץ
**IMPLEMENTED** — אטומי לכל סוג מסמך

- אוסף: `companies/{companyId}/accounting/_root/invoices/{invoiceId}`
- מונים: `companies/{companyId}/accounting/_root/counters/{docType}`
- הקצאה ב-`issueInvoice` Cloud Function (transaction)
- סדרות: `tax_invoice`, `receipt`, `tax_invoice_receipt`, `credit_note`

### 2. Immutability / אי-שינוי
**IMPLEMENTED**

- `draft → issued` ב-transaction
- לאחר הנפקה: `docNumber`, `issuedAt`, `immutableSnapshotHash` — immutable ב-Firestore Rules
- מחיקה אסורה

### 3. Snapshot Hash / חתימת שלמות
**IMPLEMENTED** — SHA-256 על שדות ליבה

### 4. Document State Machine
```
draft → issued → locked → credited
      ↘ voided_before_delivery
```

### 5. Credit Notes / תעודות זיכוי
**IMPLEMENTED** — `InvoiceService.createCreditNote()`

### 6. Audit Trail
**IMPLEMENTED** — `companies/{companyId}/audit`

### 7. Document Types
| סוג | קוד |
|------|------|
| חשבונית מס | `tax_invoice` |
| קבלה | `receipt` |
| חשבונית מס קבלה | `tax_invoice_receipt` |
| תעודת זיכוי | `credit_note` |

### 8. RBAC
Owner — קריאה; Admin/Accountant — מלאה; Dispatcher — מוגבל.

### 9. OPENFRMT / BKMV Export
**IMPLEMENTED** — horaot 1.31

- `lib/services/bkmv/` — codec, records, exporter, simulator
- `UniformExportService` — ZIP (INI.TXT + BKMVDATA.TXT, ISO-8859-8)
- D120 תשלומים (מזומן/צ'ק/העברה/אשראי/תשלומים)
- בדיקה מקומית לפני הורדה (`BkmvSimulator`)
- UI: Owner `bkmv_export_dialog`, Admin `accounting_export_screen`

### 10. External Accounting (Greeninvoice / iCount)
**IMPLEMENTED**

- ספק: `companySettings.accountingProvider` — `greeninvoice` | `icount` | `export` | `none`
- אישורים: `settings/accounting_credentials`
- סנכרון אוטומטי אחרי הנפקה (`enqueueExternalAccountingSync`)
- יומן: `accounting/_root/sync_ledger`
- Callable: `retryAccountingSync`, `testAccountingCredentials`
- תשלומים מרובים → Greeninvoice API

### 11. Israel Invoice / מספר הקצאה
**IMPLEMENTED** (דורש OAuth רשות המסים)

- ספי: 20K₪ (2025), 10K₪ (2026), 5K₪ (06/2026)
- `requestAllocationNumber` + אוטומטי אחרי `issueInvoice`
- `AppConfig.enableAssignmentNumbers = true`
- חסימת הדפסת מקור ללא הקצאה

### 12. PDF Printing
**IMPLEMENTED**

- מקור / עותק / נאמן למקור
- עוסק מורשה, מע״מ, מספר הקצאה
- Owner: הדפסה מרשימת מסמכים

---

## ⏳ Pending

| פריט | סטטוס | הערה |
|------|--------|------|
| רישום תוכנה ברשות המסים | ⏳ | שדה `bkmvSoftwareRegistrationNumber` בניהול חברה |
| Israel Invoice OAuth | ⏳ | `functions/.env` אחרי רישום בית תוכנה |
| External audit | מתוכנן | לפני השקה |

---

## 📚 Resources

- רשות המסים: https://taxes.gov.il/
- חשבוניות ישראל: https://israelinvoice.taxes.gov.il/
- תיק הגשה: `docs/registration/00_תיק_הגשה_לרישום_תוכנה.md`
