/**
 * Миграция данных из старых путей (companies/{id}/collection)
 * в новые _root пути (companies/{id}/module/_root/collection)
 *
 * Запуск:
 *   $env:NODE_PATH = "functions/node_modules" ; node scripts/migrate_to_root.js
 */
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({
  credential: cert(require("./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json")),
});

const db = getFirestore();

// Маппинг: старый путь → новый путь (относительно companies/{companyId}/)
const MIGRATION_MAP = [
  // LOGISTICS
  { old: "delivery_points", new: "logistics/_root/delivery_points" },
  { old: "clients",         new: "logistics/_root/clients" },
  { old: "cached_routes",   new: "logistics/_root/cached_routes" },
  { old: "prices",          new: "logistics/_root/prices" },
  // WAREHOUSE
  { old: "box_types",       new: "warehouse/_root/box_types" },
  { old: "inventory",       new: "warehouse/_root/inventory" },
  { old: "product_types",   new: "warehouse/_root/product_types" },
  { old: "inventory_counts", new: "warehouse/_root/inventory_counts" },
  { old: "inventory_history", new: "warehouse/_root/inventory_history" },
  // ACCOUNTING
  { old: "invoices",        new: "accounting/_root/invoices" },
  { old: "counters",        new: "accounting/_root/counters" },
  { old: "integrity_chain", new: "accounting/_root/integrity_chain" },
  { old: "integrity_anchors", new: "accounting/_root/integrity_anchors" },
  { old: "assignment_requests", new: "accounting/_root/assignment_requests" },
  // DISPATCHER
  { old: "driver_locations", new: "dispatcher/_root/driver_locations" },
];

async function migrateCollection(companyId, mapping) {
  const oldPath = `companies/${companyId}/${mapping.old}`;
  const newPath = `companies/${companyId}/${mapping.new}`;

  const snap = await db.collection(oldPath).get();
  if (snap.empty) {
    console.log(`  ⏭️  ${mapping.old}: 0 docs (skip)`);
    return 0;
  }

  let count = 0;
  // Batch write (max 500 per batch)
  const batches = [];
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const newRef = db.collection(newPath).doc(doc.id);
    batch.set(newRef, data, { merge: true });
    batchCount++;
    count++;

    if (batchCount >= 450) {
      batches.push(batch);
      batch = db.batch();
      batchCount = 0;
    }
  }
  if (batchCount > 0) {
    batches.push(batch);
  }

  for (const b of batches) {
    await b.commit();
  }

  console.log(`  ✅ ${mapping.old} → ${mapping.new}: ${count} docs migrated`);

  // Migrate subcollections for invoices (auditLog, printEvents)
  if (mapping.old === "invoices") {
    let subCount = 0;
    for (const doc of snap.docs) {
      // auditLog
      const auditSnap = await db.collection(`${oldPath}/${doc.id}/auditLog`).get();
      if (!auditSnap.empty) {
        const subBatch = db.batch();
        for (const subDoc of auditSnap.docs) {
          subBatch.set(
            db.collection(`${newPath}/${doc.id}/auditLog`).doc(subDoc.id),
            subDoc.data(),
            { merge: true }
          );
          subCount++;
        }
        await subBatch.commit();
      }
      // printEvents
      const printSnap = await db.collection(`${oldPath}/${doc.id}/printEvents`).get();
      if (!printSnap.empty) {
        const subBatch = db.batch();
        for (const subDoc of printSnap.docs) {
          subBatch.set(
            db.collection(`${newPath}/${doc.id}/printEvents`).doc(subDoc.id),
            subDoc.data(),
            { merge: true }
          );
          subCount++;
        }
        await subBatch.commit();
      }
    }
    if (subCount > 0) {
      console.log(`     ↳ invoice subcollections (auditLog + printEvents): ${subCount} docs`);
    }
  }

  return count;
}

async function main() {
  // Get all companies
  const companiesSnap = await db.collection("companies").get();
  console.log(`Found ${companiesSnap.docs.length} companies\n`);

  let totalDocs = 0;

  for (const companyDoc of companiesSnap.docs) {
    const companyId = companyDoc.id;
    console.log(`\n📦 Company: "${companyId}"`);

    for (const mapping of MIGRATION_MAP) {
      const count = await migrateCollection(companyId, mapping);
      totalDocs += count;
    }
  }

  console.log(`\n✅ Migration complete. Total docs migrated: ${totalDocs}`);
  process.exit(0);
}

main().catch((e) => {
  console.error("❌ Error:", e.message);
  console.error(e.stack);
  process.exit(1);
});
