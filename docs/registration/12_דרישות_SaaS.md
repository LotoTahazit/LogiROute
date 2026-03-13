# דרישות SaaS — תאימות לאודיט

## הפרדת דיירים (Tenant Isolation)

- כל בקשה חייבת לכלול `companyId` מתוך הקשר האימות
- אין קריאות חוצות-חברות (Cross-Tenant)
- Firestore Security Rules מוודאים: `userCompanyId == companyId`
- `companyId` נלקח מ-`CompanyContext.effectiveCompanyId` — לא hardcoded

## אחסון בלתי-ניתן לשינוי (Immutable Storage)

- מסמכים שעברו סיום — שדות מוגנים לא ניתנים לשינוי
- Firestore Security Rules אוכפים whitelist
- שרשרת שלמות (Integrity Chain) — hash-chain על כל המסמכים
- יומני ביקורת — append-only, לא ניתנים לעדכון או מחיקה

## גיבויים ושחזור (Backup & DR)

- גיבוי רבעוני — בשבוע הראשון של כל רבעון
- אחסון במקום נפרד
- בדיקת שחזור תקופתית — רישום תוצאות
- דוח מצב גיבויים — `getBackupComplianceReport()`

## יומני גישה (Access Logs)

- כל כניסה/יציאה נרשמת
- כל צפייה/הדפסה/ייצוא נרשמת
- אוסף: `companies/{companyId}/access_log/{logId}`
- append-only — `actorUid == auth.uid`
- סוגי אירועים: login, logout, viewDocument, printDocument, exportData

## גרסאות תבניות הדפסה (Print Template Versioning)

- כל גרסת תבנית נרשמת ב-`print_templates`
- מאפשר שחזור מדויק של מסמך כפי שהודפס
- שדות: version, description, registeredAt, registeredBy

## מדיניות שמירת נתונים (Data Retention)

- שמירה מינימלית: 7 שנים
- בדיקה תקופתית: `runRetentionCheck()`
- רישום בדיקות: `retention_checks`
- התראה על פערים במספור (אינדיקציה למחיקה)

## ייצוא נתונים

- קובץ במבנה אחיד (CSV) — לכל תקופה
- UTF-8 עם BOM
- מטא-נתונים: מפיק, תקופה, תאריך הפקה, מספר רשומות
- רישום כל ריצת ייצוא
