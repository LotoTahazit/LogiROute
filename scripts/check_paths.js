const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({
  credential: cert(require("./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json")),
});

const db = getFirestore();
const companyId = "Y.C. Plast";

async function main() {
  // Проверяем старые пути (без _root)
  const oldPaths = [
    `companies/${companyId}/delivery_points`,
    `companies/${companyId}/clients`,
    `companies/${companyId}/invoices`,
    `companies/${companyId}/inventory`,
    `companies/${companyId}/box_types`,
    `companies/${companyId}/product_types`,
    `companies/${companyId}/prices`,
    `companies/${companyId}/counters`,
  ];

  // Проверяем новые пути (с _root)
  const newPaths = [
    `companies/${companyId}/logistics/_root/delivery_points`,
    `companies/${companyId}/logistics/_root/clients`,
    `companies/${companyId}/accounting/_root/invoices`,
    `companies/${companyId}/warehouse/_root/inventory`,
    `companies/${companyId}/warehouse/_root/box_types`,
    `companies/${companyId}/warehouse/_root/product_types`,
    `companies/${companyId}/logistics/_root/prices`,
    `companies/${companyId}/accounting/_root/counters`,
  ];

  console.log("=== OLD PATHS (without _root) ===");
  for (const path of oldPaths) {
    const snap = await db.collection(path).limit(3).get();
    console.log(`${path}: ${snap.docs.length} docs`);
  }

  console.log("\n=== NEW PATHS (with _root) ===");
  for (const path of newPaths) {
    const snap = await db.collection(path).limit(3).get();
    console.log(`${path}: ${snap.docs.length} docs`);
  }
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
