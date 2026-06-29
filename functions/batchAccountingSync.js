const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { enqueueExternalAccountingSync } = require("./accounting/sync_external_document");
const { correlationLog } = require("./lib/correlation");

const db = admin.firestore();

/**
 * Пакетная синхронизация с Greeninvoice/iCount.
 * Callable: { companyId, mode: 'failed'|'unsynced', limit? }
 */
exports.batchAccountingSync = functions.https.onCall(async (data, context) => {
  correlationLog("accounting_sync", data, context, { mode: data?.mode });
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }

  const { companyId, mode = "failed", limit = 25 } = data || {};
  if (!companyId) {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }
  if (mode !== "failed" && mode !== "unsynced") {
    throw new functions.https.HttpsError("invalid-argument", "mode must be failed|unsynced");
  }

  const uid = context.auth.uid;
  const userSnap = await db.doc(`users/${uid}`).get();
  const role = userSnap.data()?.role;
  const userCompany = userSnap.data()?.companyId;
  const allowed =
    role === "super_admin" ||
    (userCompany === companyId &&
      ["admin", "accountant", "dispatcher", "owner"].includes(role));
  if (!allowed) {
    throw new functions.https.HttpsError("permission-denied", "Not allowed");
  }

  const cap = Math.min(Math.max(Number(limit) || 25, 1), 40);
  const docIds = [];

  if (mode === "failed") {
    const snap = await db
      .collection(`companies/${companyId}/accounting/_root/sync_ledger`)
      .where("status", "==", "failed")
      .limit(cap)
      .get();
    docIds.push(...snap.docs.map((d) => d.id));
  } else {
    const snap = await db
      .collection(`companies/${companyId}/accounting/_root/invoices`)
      .where("status", "==", "issued")
      .limit(150)
      .get();

    for (const doc of snap.docs) {
      const inv = doc.data();
      const seq = Number(inv.sequentialNumber);
      if (!Number.isFinite(seq) || seq <= 0) continue;

      const ledger = await db
        .doc(`companies/${companyId}/accounting/_root/sync_ledger/${doc.id}`)
        .get();
      if (ledger.exists && ledger.data()?.status === "synced") continue;

      docIds.push(doc.id);
      if (docIds.length >= cap) break;
    }
  }

  const results = [];
  for (const docId of docIds) {
    const r = await enqueueExternalAccountingSync({
      companyId,
      docId,
      uid,
      force: true,
    });
    results.push({
      docId,
      ok: r.ok === true,
      skipped: r.skipped === true,
      reason: r.reason || r.error || null,
    });
  }

  const succeeded = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok && !r.skipped).length;
  const skipped = results.filter((r) => r.skipped).length;

  return {
    ok: true,
    mode,
    processed: results.length,
    succeeded,
    failed,
    skipped,
    results,
  };
});
