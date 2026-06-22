/**
 * Upload config/billing_pricing.json → Firestore config/billing_pricing
 * Auth: firebase login (refresh token from configstore) or GOOGLE_APPLICATION_CREDENTIALS
 */
const fs = require("fs");
const path = require("path");
const { adminFromFirebaseCli } = require("./_firebase_cli_auth");

const projectArg = process.argv.find((a) => a.startsWith("--project="));
const projectId = projectArg
  ? projectArg.split("=")[1]
  : process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "logiroute-app";

const jsonPath = path.join(__dirname, "..", "config", "billing_pricing.json");
const payload = JSON.parse(fs.readFileSync(jsonPath, "utf8"));

async function main() {
  const admin = adminFromFirebaseCli(projectId);
  await admin.firestore().doc("config/billing_pricing").set(payload, { merge: true });
  console.log(`✅ config/billing_pricing → ${projectId}`);
  console.log("   addons:", Object.keys(payload.addons || {}).join(", "));
}

main().catch((e) => {
  console.error("❌", e.message);
  process.exit(1);
});
