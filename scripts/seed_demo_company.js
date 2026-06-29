/**
 * Seed Demo Foods Israel (demo-foods-israel) via Admin SDK.
 * Requires: firebase login, DEMO_SEED_PASSWORD (min 12 chars)
 *
 * Usage:
 *   set DEMO_SEED_PASSWORD=...
 *   node scripts/seed_demo_company.js
 *   node scripts/seed_demo_company.js --dry-run
 *   node scripts/seed_demo_company.js --reset
 */
const { adminFromFirebaseCli } = require("./_firebase_cli_auth");

const dryRun = process.argv.includes("--dry-run");
const reset = process.argv.includes("--reset");
const projectArg = process.argv.find((a) => a.startsWith("--project="));
const projectId = projectArg
  ? projectArg.split("=")[1]
  : process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "logiroute-app";

async function main() {
  if (!process.env.DEMO_SEED_PASSWORD && !dryRun) {
    console.error("❌ Set DEMO_SEED_PASSWORD (min 12 chars)");
    process.exit(1);
  }
  adminFromFirebaseCli(projectId);
  const {
    seedDemoCompany,
    purgeDemoCompany,
    previewDemoPurge,
    DEMO_COMPANY_ID,
  } = require("../functions/demoSeed");

  const preview = await previewDemoPurge(DEMO_COMPANY_ID);
  console.log(JSON.stringify(preview, null, 2));

  if (dryRun) {
    console.log("✅ Dry-run only — nothing deleted");
    return;
  }

  if (reset) {
    if (!preview.safeToPurge && preview.exists) {
      console.error("❌ Reset blocked — fix blocked documents first");
      process.exit(1);
    }
    console.log(`🔄 Reset demo company ${DEMO_COMPANY_ID}…`);
    await purgeDemoCompany(DEMO_COMPANY_ID);
  } else {
    const admin = require("firebase-admin");
    const snap = await admin.firestore().doc(`companies/${DEMO_COMPANY_ID}`).get();
    if (snap.exists) {
      console.error(`❌ ${DEMO_COMPANY_ID} already exists — use --reset`);
      process.exit(1);
    }
  }

  const result = await seedDemoCompany("cli-script");
  console.log("✅ Demo company seeded:", JSON.stringify(result, null, 2));
}

main().catch((e) => {
  console.error("❌", e.message);
  if (e.preview) console.error(JSON.stringify(e.preview, null, 2));
  process.exit(1);
});
