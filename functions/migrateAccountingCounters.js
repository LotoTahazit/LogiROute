const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

/** Legacy provision keys → canonical counter keys (issueInvoice). */
const LEGACY_TO_CANONICAL = {
  invoice: "tax_invoice",
  creditNote: "credit_note",
  delivery: "delivery_note",
  taxInvoiceReceipt: "tax_invoice_receipt",
  receipt: "receipt",
};

/**
 * Merge legacy counter docs into canonical keys (super_admin only).
 * Callable: { companyId? } — без companyId мигрирует все компании.
 */
exports.migrateAccountingCounters = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }
    const uid = context.auth.uid;
    const userSnap = await db.doc(`users/${uid}`).get();
    if (userSnap.data()?.role !== "super_admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "super_admin only"
      );
    }

    const targetCompanyId = data && data.companyId;
    let companyIds = [];
    if (targetCompanyId) {
      companyIds = [targetCompanyId];
    } else {
      const snap = await db.collection("companies").select().get();
      companyIds = snap.docs.map((d) => d.id);
    }

    const results = [];

    for (const companyId of companyIds) {
      const base = `companies/${companyId}/accounting/_root/counters`;
      let merged = 0;

      for (const [legacy, canonical] of Object.entries(LEGACY_TO_CANONICAL)) {
        if (legacy === canonical) continue;

        const legacyRef = db.doc(`${base}/${legacy}`);
        const canonRef = db.doc(`${base}/${canonical}`);
        const legacySnap = await legacyRef.get();
        if (!legacySnap.exists) continue;

        const legacyNum = legacySnap.data().lastNumber || 0;
        if (legacyNum <= 0) continue;

        await db.runTransaction(async (tx) => {
          const canonSnap = await tx.get(canonRef);
          const canonNum = canonSnap.exists
            ? canonSnap.data().lastNumber || 0
            : 0;
          const next = Math.max(legacyNum, canonNum);
          if (next > canonNum) {
            tx.set(canonRef, { lastNumber: next }, { merge: true });
          }
        });
        merged += 1;
      }

      results.push({ companyId, merged });
    }

    return { ok: true, companies: results.length, results };
  }
);
