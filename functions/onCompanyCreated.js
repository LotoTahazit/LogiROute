const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

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
