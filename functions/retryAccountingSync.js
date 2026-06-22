const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { enqueueExternalAccountingSync } = require("./accounting/sync_external_document");

/**
 * Retry external accounting sync for an issued invoice.
 * Callable: { companyId, invoiceId }
 */
exports.retryAccountingSync = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }

  const { companyId, invoiceId } = data || {};
  if (!companyId || !invoiceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "companyId and invoiceId required"
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

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

  const invRef = db.doc(
    `companies/${companyId}/accounting/_root/invoices/${invoiceId}`
  );
  const invSnap = await invRef.get();
  const inv = invSnap.exists ? invSnap.data() || {} : null;
  if (inv == null) {
    throw new functions.https.HttpsError("not-found", "Document not found");
  }
  const isIssued = inv.status === "issued" || inv.docNumber != null;
  if (!isIssued) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Invoice must be issued before external sync"
    );
  }

  const result = await enqueueExternalAccountingSync({
    companyId,
    docId: invoiceId,
    invoiceData: inv,
    uid,
    force: true,
  });

  return { ok: true, ...result };
});
