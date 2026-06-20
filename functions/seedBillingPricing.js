const functions = require("firebase-functions");
const admin = require("firebase-admin");
const pricing = require("./config/billing_pricing.json");

/** One-shot / repeat: write config/billing_pricing (super_admin only). */
exports.seedBillingPricing = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const user = await admin.firestore().doc(`users/${context.auth.uid}`).get();
  if (user.data()?.role !== "super_admin") {
    throw new functions.https.HttpsError("permission-denied", "super_admin only");
  }
  await admin.firestore().doc("config/billing_pricing").set(pricing, { merge: true });
  return { ok: true, plans: Object.keys(pricing.plans) };
});
