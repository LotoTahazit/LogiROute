# Israeli Tax Law Compliance Guide
# מדריך תאימות לחוק המס הישראלי

**Last Updated:** February 2026 | **Status:** Implemented — pending software registration

---

## ✅ Implemented Features

### 1. Sequential Numbering / מספור רץ
**IMPLEMENTED** — מספור רץ אטומי לכל סוג מסמך

- אוסף: `companies/{companyId}/accountingDocs/{docId}`
- מוני מספור: `companies/{companyId}/accounting/_root/counters/{docType}`
- הקצאה אטומית ב-`issueDoc()` transaction: `lastNumber + 1`
- Firestore Rules אוכפים: `lastNumber == resource.data.lastNumber + 1`
- סדרות נפרדות: `tax_invoice`, `receipt`, `tax_invoice_receipt`, `credit_note`

### 2. Immutability / אי-שינוי
**IMPLEMENTED** — מסמך שהונפק לא ניתן לשינוי

- מעבר `draft → issued` מתבצע ב-`issueDoc()` transaction
- לאחר הנפקה: `docNumber`, `issuedAt`, `immutableSnapshotHash` — immutable ב-Firestore Rules
- `deleteDoc()` תמיד זורק `UnsupportedError`
- Firestore Rules: `allow delete: if false`

### 3. Snapshot Hash / חתימת שלמות
**IMPLEMENTED** — SHA-256 על 5 שדות ליבה

- מחלקה: `SnapshotHash.compute(doc)` ב-`lib/features/owner_dashboard/utils/snapshot_hash.dart`
- שדות: `docNumber`, `issuedAt`, `customerId`, `lines`, `totals`
- שיטה: JSON canonical serialization → UTF-8 → SHA-256
- נשמר ב-`immutableSnapshotHash` בעת הנפקה

### 4. Document State Machine / מחזור חיי מסמך
**IMPLEMENTED** — state machine מלא

```
draft → issued → locked → credited
      ↘ voided_before_delivery
```

| סטטוס | ערך | תיאור |
|--------|------|--------|
| טיוטה | `draft` | ניתן לעריכה |
| הונפק | `issued` | קיבל מספר + hash, immutable |
| נעול | `locked` | נעול לתקופת חשבונאות |
| זוכה | `credited` | בוטל על ידי תעודת זיכוי |
| בוטל לפני מסירה | `voided_before_delivery` | בוטל לפני מסירה |

### 5. Credit Notes / תעודות זיכוי
**IMPLEMENTED** — `createCreditNote()` ב-`AccountingDocsRepository`

- רק ממסמך בסטטוס `issued` או `locked`
- יוצר מסמך `credit_note` חדש עם קישור למקור
- מעדכן מקור: `status → credited`
- נרשם ביומן ביקורת

### 6. Audit Trail / יומן ביקורת
**IMPLEMENTED** — append-only cross-module audit

- אוסף: `companies/{companyId}/audit/{eventId}`
- כל פעולה חשבונאית נרשמת
- Firestore Rules: `allow update, delete: if false`

### 7. Document Types / סוגי מסמכים
**IMPLEMENTED** — 4 סוגים

| סוג | קוד |
|------|------|
| חשבונית מס | `tax_invoice` |
| קבלה | `receipt` |
| חשבונית מס קבלה | `tax_invoice_receipt` |
| תעודת זיכוי | `credit_note` |

### 8. RBAC / הרשאות
**IMPLEMENTED** — 7 תפקידים

| תפקיד | גישה לחשבונאות |
|--------|----------------|
| `super_admin` | מלאה |
| `owner` | קריאה בלבד |
| `admin` | מלאה |
| `accountant` | יצירה/עדכון draft, קריאת דוחות |
| `dispatcher` | קריאה בלבד |
| `driver` | ❌ |
| `warehouse_keeper` | ❌ |

### 9. Backup & Retention / גיבוי ושמירה
**IMPLEMENTED** — 3 שכבות גיבוי

| שכבה | תדירות | שמירה | RPO |
|------|---------|--------|-----|
| PITR | רציף | 7 ימים | ≤ 1 שעה |
| יומי | יומי | 14 ימים | ≤ 24 שעות |
| רבעוני | רבעוני | 7 שנים | תאימות |

### 10. Uniform File Export / קובץ במבנה אחיד
**IMPLEMENTED** — CSV export לרשות המסים

### 11. Israel Invoice / חשבוניות ישראל
**IMPLEMENTED** — מספר הקצאה

- ספי חובה: 20K₪ (2025), 10K₪ (01.01.2026), 5K₪ (01.06.2026)
- בקשה אוטומטית לאחר הנפקה
- retry + exponential backoff (3 ניסיונות)
- חסימת הדפסת מקור ללא הקצאה

---

## ⏳ Pending

| פריט | סטטוס | הערה |
|------|--------|------|
| רישום תוכנה ברשות המסים | ⏳ בתהליך | תיק הגשה מוכן ב-`docs/registration/` |
| Israel Invoice API endpoint | ⏳ placeholder | יוחלף ב-endpoint אמיתי לאחר רישום |
| Cloud Functions לנפקה | מתוכנן | העברת `issueDoc()` ל-trusted backend |
| External audit | מתוכנן | לפני השקה |

---

## 📚 Resources

- רשות המסים: https://taxes.gov.il/
- חשבוניות ישראל: https://israelinvoice.taxes.gov.il/
- ניהול ספרים: https://taxes.gov.il/incomeTax/Pages/NihulPinkasum.aspx
- תיק הגשה: `docs/registration/00_תיק_הגשה_לרישום_תוכנה.md`
