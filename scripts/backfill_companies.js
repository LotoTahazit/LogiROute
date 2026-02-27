/**
 * Бекфилл: добавляет billingStatus и modules в каждый company doc.
 * 
 * Запуск из корня проекта:
 *   set NODE_PATH=functions/node_modules && node scripts/backfill_companies.js
 */
const { initializeApp, applicationDefault, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

// Используем Firebase CLI credentials через gcloud
// Если не работает — раскомментируй строку с cert() и укажи путь к serviceAccountKey.json
initializeApp({
  credential: cert(require("./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json")),
});

const db = getFirestore();

async function main() {
  const snap = await db.collection("companies").get();

  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const patch = {};

    // billingStatus: 'active' по умолчанию (для billingActive() в rules)
    if (!data.billingStatus) {
      patch.billingStatus = "active";
    }

    // modules: все включены по умолчанию
    if (!data.modules || typeof data.modules !== "object") {
      patch.modules = {
        logistics: true,
        warehouse: true,
        dispatcher: true,
        accounting: true,
      };
    }

    if (Object.keys(patch).length > 0) {
      patch.updatedAt = FieldValue.serverTimestamp();
      await doc.ref.set(patch, { merge: true });
      updated++;
      console.log(`✅ Patched company "${doc.id}":`, JSON.stringify(patch, null, 0).replace(/"_methodName":"FieldValue.serverTimestamp"/, '"serverTimestamp()"'));
    } else {
      skipped++;
      console.log(`⏭️  Skipped company "${doc.id}" (already has billingStatus + modules)`);
    }
  }

  console.log(`\nDone. Updated: ${updated}, Skipped: ${skipped}, Total: ${snap.docs.length}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("❌ Error:", e.message);
  process.exit(1);
});
