# כללי אבטחה — Firestore Security Rules

## עקרונות מנחים

1. **כל בקשה דורשת אימות** — `request.auth != null`
2. **הפרדת דיירים** — גישה רק לנתוני החברה של המשתמש
3. **אי-מחיקה** — מסמכים חשבונאיים לא ניתנים למחיקה
4. **אי-שינוי** — שדות מוגנים לא ניתנים לשינוי לאחר סיום
5. **append-only** — יומנים ושרשראות לא ניתנים לעדכון
6. **אטומיות** — מוני מספור עולים ב-1 בדיוק
7. **זיהוי שחקן** — actorUid/printedBy == auth.uid

## סיכום כללים לפי אוסף

### מסמכים חשבונאיים (`invoices`)
- **קריאה**: משתמשי החברה + super_admin
- **יצירה**: admin, dispatcher + super_admin
- **עדכון לפני סיום**: חופשי (admin, dispatcher)
- **עדכון אחרי סיום**: רק שדות whitelist — כל השדות המוגנים חייבים להישאר זהים
- **מחיקה**: `if false` — אסורה לחלוטין

### יומן ביקורת (`auditLog`)
- **קריאה**: משתמשי החברה
- **יצירה**: `actorUid == request.auth.uid`
- **עדכון**: `if false`
- **מחיקה**: `if false`

### אירועי הדפסה (`printEvents`)
- **קריאה**: משתמשי החברה
- **יצירה**: `printedBy == request.auth.uid`
- **עדכון**: `if false`
- **מחיקה**: `if false`

### מוני מספור (`counters`)
- **יצירה**: `lastNumber == 1`
- **עדכון**: `lastNumber == resource.data.lastNumber + 1`
- **מחיקה**: `if false`

### שרשרת שלמות (`integrity_chain`)
- **יצירה**: admin, dispatcher
- **עדכון**: `if false`
- **מחיקה**: `if false`

### קישורים בין מסמכים (`document_links`)
- **יצירה**: admin, dispatcher
- **עדכון**: `if false`
- **מחיקה**: `if false`

### בקשות הקצאה (`assignment_requests`)
- **יצירה**: admin, dispatcher
- **עדכון**: רק שדות סטטוס (invoiceId לא משתנה)
- **מחיקה**: `if false`

### גיבויים (`backups`)
- **יצירה**: admin
- **עדכון**: `if false`
- **מחיקה**: `if false`

### בדיקות שחזור (`restore_tests`)
- **יצירה**: admin
- **עדכון**: `if false`
- **מחיקה**: `if false`

### יומן גישה (`access_log`)
- **יצירה**: `actorUid == request.auth.uid`
- **עדכון**: `if false`
- **מחיקה**: `if false`

### ריצות ייצוא (`uniform_export_runs`)
- **יצירה**: admin, dispatcher
- **עדכון**: `if false`
- **מחיקה**: `if false`

### תבניות הדפסה (`print_templates`)
- **יצירה/עדכון**: admin
- **מחיקה**: `if false`

### בדיקות מדיניות שמירה (`retention_checks`)
- **יצירה**: admin
- **עדכון**: `if false`
- **מחיקה**: `if false`
