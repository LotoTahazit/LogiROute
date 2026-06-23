const admin = require("firebase-admin");
const { getAccountingAdapter } = require("./provider_registry");
const { mapInvoiceToExternalDoc } = require("./document_mapper");
const { loadAccountingDocument } = require("./load_document");

function _db() {
  return admin.firestore();
}

const FieldValue = admin.firestore.FieldValue;

async function _writeExternalFields(ref, provider, result, invoiceData) {
  if (!ref || !result?.ok) return;
  const patch = {
    externalProvider: provider,
    externalId: result.externalId || null,
    externalDocNumber: result.externalNumber || null,
    externalDistributionNumber: result.distributionNumber || null,
    externalPdfUrl: result.pdfUrl || null,
    externalSyncedAt: FieldValue.serverTimestamp(),
  };
  // distributionNumber провайдера = официальный מספר הקצaה ТОЛЬКО для
  // провайдеров, интегрированных с חשבוניות ישראל (Greeninvoice/iCount сами
  // получают allocation). Для прочих это лишь внутренний номер провайдера —
  // он остаётся в externalDistributionNumber и НЕ считается ITA allocation.
  const dist = result.distributionNumber;
  const inv = invoiceData || {};
  const dt = String(inv.documentType || "");
  const taxDoc = dt === "invoice" || dt === "taxInvoiceReceipt";
  const allocatingProvider =
    provider === "greeninvoice" || provider === "icount";
  if (dist && taxDoc && allocatingProvider && !inv.assignmentNumber) {
    patch.assignmentNumber = String(dist);
    patch.assignmentStatus = "approved";
  }
  await ref.set(patch, { merge: true });
}

/**
 * Idempotent external accounting sync.
 * Ledger: companies/{companyId}/accounting/_root/sync_ledger/{docId}
 */
async function enqueueExternalAccountingSync({
  companyId,
  docId,
  invoiceId,
  invoiceData,
  uid,
  force = false,
}) {
  const documentId = docId || invoiceId;
  if (!documentId) {
    return { skipped: true, reason: "missing_doc_id" };
  }

  const db = _db();
  const settingsSnap = await db
    .doc(`companies/${companyId}/settings/settings`)
    .get();
  const companySettings = settingsSnap.data() || {};
  const provider = companySettings.accountingProvider || "none";

  if (!provider || provider === "none") {
    return { skipped: true, reason: "provider_none" };
  }

  const adapter = getAccountingAdapter(provider);
  if (!adapter) {
    return { skipped: true, reason: "unknown_provider" };
  }

  const ledgerRef = db.doc(
    `companies/${companyId}/accounting/_root/sync_ledger/${documentId}`
  );
  const ledgerSnap = await ledgerRef.get();
  if (
    !force &&
    ledgerSnap.exists &&
    ledgerSnap.data()?.status === "synced"
  ) {
    return { skipped: true, reason: "already_synced", idempotent: true };
  }

  let loaded = await loadAccountingDocument(db, companyId, documentId);
  if (!loaded && invoiceData) {
    loaded = { data: invoiceData, source: "inline", ref: null };
  }
  if (!loaded) {
    return { skipped: true, reason: "document_not_found" };
  }

  if (!loaded.ref) {
    const resolved = await loadAccountingDocument(db, companyId, documentId);
    if (resolved?.ref) {
      loaded.ref = resolved.ref;
      loaded.source = resolved.source;
    }
  }

  const credSnap = await db
    .doc(`companies/${companyId}/settings/accounting_credentials`)
    .get();
  const credentials = credSnap.data() || {};

  const payload = mapInvoiceToExternalDoc({
    invoice: loaded.data,
    companySettings,
  });

  const prevAttempts = ledgerSnap.exists ? (ledgerSnap.data()?.attempts || 0) : 0;

  await ledgerRef.set(
    {
      docId: documentId,
      provider,
      status: "processing",
      attempts: prevAttempts + 1,
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: uid || null,
      lastError: FieldValue.delete(),
    },
    { merge: true }
  );

  try {
    const result = await adapter.createDocument({
      payload,
      credentials,
      companyId,
      docId: documentId,
    });
    const ok = result.ok === true;
    await ledgerRef.set(
      {
        status: ok ? "synced" : "failed",
        provider,
        externalId: result.externalId || null,
        externalNumber: result.externalNumber || null,
        distributionNumber: result.distributionNumber || null,
        pdfUrl: result.pdfUrl || null,
        externalResult: result,
        lastError: ok ? null : result.message || result.reason || "sync_failed",
        syncedAt: ok ? FieldValue.serverTimestamp() : null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    if (ok && loaded.ref) {
      await _writeExternalFields(loaded.ref, provider, result, loaded.data);
    }

    return { ok, provider, result };
  } catch (e) {
    await ledgerRef.set(
      {
        status: "failed",
        lastError: e.message,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    console.warn(`⚠️ external accounting sync failed: ${e.message}`);
    return { ok: false, error: e.message };
  }
}

module.exports = { enqueueExternalAccountingSync };
