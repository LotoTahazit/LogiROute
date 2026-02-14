# Israeli Tax Law Compliance Guide
# מדריך תאימות לחוק המס הישראלי

## ⚖️ Legal Requirements / דרישות חוקיות

### 1. Sequential Numbering / מספור רץ
✅ **IMPLEMENTED** - חשבוניות מקבלות מספר רץ אוטומטי
- Each invoice receives an automatic sequential number
- Numbers cannot be skipped or reused
- Stored in Firestore counter document for atomicity

### 2. Immutability / אי-שינוי
✅ **IMPLEMENTED** - חשבוניות לא ניתנות לשינוי לאחר יצירה
- Invoices cannot be modified after creation
- `isImmutable` property prevents changes
- Only status changes (cancellation) are allowed

### 3. No Deletion / איסור מחיקה
✅ **IMPLEMENTED** - מחיקה אסורה, רק ביטול
- `deleteInvoice()` method throws error
- Use `cancelInvoice()` instead
- Cancelled invoices remain in database with status

### 4. Audit Trail / יומן שינויים
✅ **IMPLEMENTED** - כל פעולה נרשמת ביומן
- Every action logged in `auditLog` array
- Includes: timestamp, action, performer, details
- Cannot be deleted or modified

### 5. Invoice Status / סטטוס חשבונית
✅ **IMPLEMENTED** - מעקב אחר מצב החשבונית
- `active` - חשבונית תקפה
- `cancelled` - חשבונית מבוטלת
- `draft` - טיוטה (אם נדרש)

### 6. Copy Types / סוגי העתקים
✅ **IMPLEMENTED** - מקור, עותק, נעימן למקור
- `original` (מקור) - only one allowed
- `copy` (עותק) - multiple allowed
- `replacesOriginal` (נעימן למקור) - if original lost

## 🚨 Critical TODO Items

### HIGH PRIORITY

#### 1. Software Registration / רישום תוכנה
❌ **NOT IMPLEMENTED** - נדרש רישום ברשות המסים
- Register software with רשות המסים
- Get approval for accounting software
- URL: https://taxes.gov.il/

#### 2. Israel Invoice Integration / אינטגרציה עם חשבוניות ישראל
❌ **NOT IMPLEMENTED** - נדרש למספר הקצאה
- Required for B2B invoices above threshold:
  - 2025: ₪20,000
  - 2026 (Jan): ₪10,000
  - 2026 (Jun): ₪5,000
- Must integrate with tax authority API
- Get מספר הקצאה (allocation number)

#### 3. VAT Registration Verification / אימות רישום למע"מ
❌ **NOT IMPLEMENTED** - בדיקת עוסק מורשה
- Verify business is registered for VAT (עוסק מורשה)
- Only עוסק מורשה can issue חשבונית מס
- עוסק פטור cannot issue tax invoices

#### 4. Data Export / ייצוא נתונים
❌ **NOT IMPLEMENTED** - פורמט אחיד
- Implement Uniform File Module export
- Required format for tax authority
- Must include all invoice data

#### 5. Backup & Retention / גיבוי ושמירה
⚠️ **PARTIAL** - נדרש גיבוי מאובטח
- Firestore provides backup
- Need 7-year retention policy
- Implement secure backup procedure

### MEDIUM PRIORITY

#### 6. Company Details / פרטי החברה
⚠️ **PARTIAL** - חסרים פרטים חובה
Need to add to invoice:
- Company name (שם החברה)
- Tax ID / ח.פ (מספר עוסק)
- Address (כתובת)
- Phone (טלפון)

#### 7. Invoice Types / סוגי חשבוניות
⚠️ **PARTIAL** - תמיכה בסוגים נוספים
Currently only חשבונית מס. Consider adding:
- חשבונית מס-קבלה (tax invoice-receipt)
- חשבונית עסקה (transaction invoice for פטור)
- קבלה (receipt)

#### 8. Credit Notes / חשבוניות זיכוי
❌ **NOT IMPLEMENTED** - נדרש לתיקונים
- Implement credit notes for corrections
- Link to original invoice
- Maintain sequential numbering

## 📋 Implementation Checklist

### Phase 1: Core Compliance (DONE ✅)
- [x] Sequential numbering
- [x] Immutability
- [x] No deletion (only cancellation)
- [x] Audit trail
- [x] Invoice status
- [x] Copy types (מקור/עותק/נעימן למקור)

### Phase 2: Legal Requirements (TODO ❌)
- [ ] Register software with רשות המסים
- [ ] Integrate Israel Invoice API
- [ ] VAT registration verification
- [ ] Add company details to invoices
- [ ] Implement data export (Uniform File Module)
- [ ] 7-year retention policy

### Phase 3: Advanced Features (TODO ❌)
- [ ] Credit notes (חשבוניות זיכוי)
- [ ] Multiple invoice types
- [ ] Digital signature
- [ ] Email delivery with tracking
- [ ] Customer portal

## 🔒 Security Recommendations

1. **Access Control**
   - Only authorized users can create invoices
   - Separate permissions for cancellation
   - Audit log for all actions

2. **Data Integrity**
   - Use Firestore transactions for sequential numbers
   - Validate all data before saving
   - Regular integrity checks

3. **Backup**
   - Daily automated backups
   - Test restore procedures
   - 7-year retention

## 📞 Next Steps

### Immediate Actions:
1. **Consult with CPA** - Get professional advice on compliance
2. **Register Software** - Start registration process with רשות המסים
3. **Israel Invoice** - Research API integration requirements
4. **VAT Verification** - Implement business registration check

### Before Going Live:
1. Complete software registration
2. Implement Israel Invoice integration (if needed)
3. Add all required company details
4. Test with CPA/accountant
5. Implement data export
6. Set up backup procedures

## ⚠️ Legal Disclaimer

This implementation provides technical compliance features but:
- **NOT a substitute for legal advice**
- **Consult with Israeli CPA before use**
- **Software registration may be required**
- **Tax law changes frequently - stay updated**

## 📚 Resources

- רשות המסים: https://taxes.gov.il/
- חשבוניות ישראל: https://israelinvoice.taxes.gov.il/
- ניהול ספרים: https://taxes.gov.il/incomeTax/Pages/NihulPinkasum.aspx

---

**Last Updated:** February 2026
**Status:** Core compliance implemented, legal registration pending
