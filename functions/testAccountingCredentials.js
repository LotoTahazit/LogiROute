const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { getAccountingAdapter } = require("./accounting/provider_registry");

/**
 * Проверка API-ключей Greeninvoice / iCount без создания документа.
 * Callable: { companyId, provider? }
 */
exports.testAccountingCredentials = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }

    const { companyId, provider: providerArg } = data || {};
    if (!companyId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "companyId required"
      );
    }

    const db = admin.firestore();
    const uid = context.auth.uid;
    const userSnap = await db.doc(`users/${uid}`).get();
    const role = userSnap.data()?.role;
    const userCompany = userSnap.data()?.companyId;
    const allowed =
      role === "super_admin" ||
      (userCompany === companyId &&
        ["admin", "accountant", "owner"].includes(role));
    if (!allowed) {
      throw new functions.https.HttpsError("permission-denied", "Not allowed");
    }

    const settingsSnap = await db
      .doc(`companies/${companyId}/settings/settings`)
      .get();
    const provider =
      providerArg || settingsSnap.data()?.accountingProvider || "none";
    if (!provider || provider === "none" || provider === "export") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "External provider not configured"
      );
    }

    const adapter = getAccountingAdapter(provider);
    if (!adapter?.testCredentials) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Provider ${provider} does not support credential test`
      );
    }

    const credSnap = await db
      .doc(`companies/${companyId}/settings/accounting_credentials`)
      .get();
    const credentials = credSnap.data() || {};

    try {
      const result = await adapter.testCredentials({ credentials, companyId });
      return { ok: result.ok === true, provider, ...result };
    } catch (e) {
      return { ok: false, provider, message: e.message };
    }
  }
);
