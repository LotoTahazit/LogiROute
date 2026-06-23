const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

const COUNTER_KEYS = [
  "tax_invoice",
  "receipt",
  "credit_note",
  "delivery_note",
  "tax_invoice_receipt",
];

async function initAccountingCounters(companyId) {
  const batch = db.batch();
  const base = db.collection("companies").doc(companyId)
    .collection("accounting").doc("_root").collection("counters");
  for (const key of COUNTER_KEYS) {
    batch.set(base.doc(key), { lastNumber: 0 }, { merge: true });
  }
  await batch.commit();
}

/**
 * Trigger: при создании нового документа компании.
 * Создаёт welcome-уведомление (server-side, обходит правила безопасности).
 *
 * Это нужно потому что клиентский код НЕ может создавать notifications
 * (create: false в firestore.rules — защита от спама/подделки billing-сообщений).
 */
exports.onCompanyCreated = functions.firestore
  .document("companies/{companyId}")
  .onCreate(async (snap, context) => {
    const { companyId } = context.params;
    const data = snap.data();

    console.log(`🏢 Новая компания создана: ${companyId}`);

    try {
      await initAccountingCounters(companyId);
      console.log(`✅ Accounting counters initialized for ${companyId}`);
    } catch (err) {
      console.error(`❌ Counters init failed for ${companyId}: ${err.message}`);
    }

    try {
      await db
        .collection("companies")
        .doc(companyId)
        .collection("notifications")
        .add({
          type: "welcome",
          title: "ברוכים הבאים ל-LogiRoute!",
          body: "תקופת הניסיון שלך פעילה ל-14 ימים. הגדר את החברה שלך והתחל לעבוד.",
          severity: "info",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

      console.log(`✅ Welcome notification создано для ${companyId}`);
    } catch (err) {
      console.error(`❌ Ошибка создания welcome notification: ${err.message}`);
    }

    return null;
  });
