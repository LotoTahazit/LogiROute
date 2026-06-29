const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const { applyPlanToCompany } = require("./lib/companyModules");

const ID_PATTERN = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
const RESERVED = new Set(["system_company", "demo-foods-israel"]);

const WIZARD_STEPS = [
  "companyInfo",
  "importClients",
  "importProducts",
  "addDrivers",
  "warehouseSetup",
  "accountingSetup",
  "gpsCheck",
  "firstRoute",
  "testDelivery",
  "ready",
];

function wizardStepsMap(overrides = {}) {
  const steps = {};
  for (const key of WIZARD_STEPS) steps[key] = "notStarted";
  Object.assign(steps, overrides);
  return steps;
}

/**
 * Self-service: новый owner создаёт компанию после Firebase Auth signup.
 * Atomic transaction + claims + onCompanyCreated trigger (modules/counters/welcome).
 */
exports.registerOwnerCompany = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }

  const uid = context.auth.uid;
  const companyId = String(data?.companyId || "").trim().toLowerCase();
  const nameHebrew = String(data?.nameHebrew || "").trim();
  const nameEnglish = String(data?.nameEnglish || nameHebrew).trim();
  const taxId = String(data?.taxId || "").trim();
  const phone = String(data?.phone || "").trim();
  const name = String(data?.name || "").trim();
  const email = String(data?.email || context.auth.token.email || "")
    .trim()
    .toLowerCase();

  if (!ID_PATTERN.test(companyId)) {
    throw new functions.https.HttpsError("invalid-argument", "invalid-company-id");
  }
  if (RESERVED.has(companyId)) {
    throw new functions.https.HttpsError("permission-denied", "reserved-company-id");
  }
  if (!nameHebrew || !taxId || !name || !email) {
    throw new functions.https.HttpsError("invalid-argument", "missing-fields");
  }

  const companyRef = db.doc(`companies/${companyId}`);
  const userRef = db.doc(`users/${uid}`);
  const memberRef = db.doc(`companies/${companyId}/members/${uid}`);
  const settingsRef = db.doc(`companies/${companyId}/settings/settings`);
  const wizardRef = db.doc(`companies/${companyId}/settings/setup_wizard`);

  await db.runTransaction(async (tx) => {
    const [companySnap, userSnap] = await Promise.all([
      tx.get(companyRef),
      tx.get(userRef),
    ]);

    if (companySnap.exists) {
      throw new functions.https.HttpsError("already-exists", "company-exists");
    }

    if (userSnap.exists) {
      const ud = userSnap.data() || {};
      if (ud.companyId && ud.role && ud.role !== "pending") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "user-already-provisioned",
        );
      }
    }

    const trialUntil = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    );

    tx.set(companyRef, {
      nameHebrew,
      nameEnglish,
      name: nameHebrew,
      billingStatus: "trial",
      trialUntil,
      plan: "full",
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });

    tx.set(settingsRef, {
      nameHebrew,
      nameEnglish,
      taxId,
      phone,
      email,
      billingStatus: "trial",
      trialEndsAt: trialUntil,
      departureTime: "7:00",
    }, { merge: true });

    tx.set(wizardRef, {
      wizardCompleted: false,
      currentStepIndex: 1,
      steps: wizardStepsMap({ companyInfo: "completed" }),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    }, { merge: true });

    tx.set(userRef, {
      email,
      name,
      role: "owner",
      companyId,
      phone: phone || null,
      createdAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    tx.set(memberRef, {
      role: "owner",
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    }, { merge: true });
  });

  await applyPlanToCompany(db, companyId, "full");
  await admin.auth().setCustomUserClaims(uid, {
    role: "owner",
    companyId,
    isDemo: false,
  });

  console.log(`✅ registerOwnerCompany uid=${uid} company=${companyId}`);
  return { ok: true, companyId };
});
