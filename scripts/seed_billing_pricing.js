/**
 * Upload config/billing_pricing.json → Firestore config/billing_pricing
 *
 * Usage (from repo root):
 *   node scripts/seed_billing_pricing.js
 *   node scripts/seed_billing_pricing.js --project logiroute-app
 */
const fs = require("fs");
const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const projectArg = process.argv.find((a) => a.startsWith("--project="));
const projectId = projectArg
  ? projectArg.split("=")[1]
  : process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "logiroute-app";

const jsonPath = path.join(__dirname, "..", "config", "billing_pricing.json");
const payload = JSON.parse(fs.readFileSync(jsonPath, "utf8"));

admin.initializeApp({ projectId });
const db = admin.firestore();

async function main() {
  await db.doc("config/billing_pricing").set(payload, { merge: true });
  console.log(`✅ config/billing_pricing uploaded to ${projectId}`);
}

main().catch((e) => {
  console.error("❌", e.message);
  process.exit(1);
});
