const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

// =========================================================
// Canonical hash helpers
// =========================================================

function sha256hex(s) {
  return crypto.createHash("sha256").update(s, "utf8").digest("hex");
}

/**
 * Canonical chain hash v1.
 * v1|{companyId}|{counterKey}|{docType}|{docNumber}|{docId}|{issuedAtMillis}|{prevHashOrGENESIS}
 */
function buildChainHashV1({ companyId, counterKey, docType, docNumber, docId, issuedAtMillis, prevHash }) {
  const prev = prevHash ?? "GENESIS";
  const canonical = `v1|${companyId}|${counterKey}|${docType}|${docNumber}|${docId}|${issuedAtMillis}|${prev}`;
  return sha256hex(canonical);
}

// =========================================================
// issueInvoice — Callable Function
// Атомарно: counter++ → invoice.status=issued → anchor → chain → audit
// =========================================================

/**
 * Предусловия (до транзакции):
 * 1. auth != null
 * 2. user role: admin | dispatcher | super_admin
 * 3. company membership + billing allows write
 * 4. accounting module enabled
 * 5. invoice exists, status == draft, no docNumber
 * 6. deliveryDate > accountingLockedUntil (period lock)
 *
 * Идемпотентность: если invoice уже issued — возвращаем существующий номер.
 */
exports.issueInvoice = functions.https.onCall(async (data, context) => {
  // --- 1. Auth ---
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const uid = context.auth.uid;

  // --- 2. Input validation ---
  const { companyId, invoiceId, counterKey } = data;
  if (!companyId || typeof companyId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }
  if (!invoiceId || typeof invoiceId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "invoiceId required");
  }
  if (!counterKey || typeof counterKey !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "counterKey required");
  }

  // --- 3. User doc + RBAC ---
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError("permission-denied", "User not found");
  }
  const userData = userSnap.data();
  const role = userData.role;
  const isSuperAdmin = role === "super_admin";

  if (!isSuperAdmin && !["admin", "dispatcher"].includes(role)) {
    throw new functions.https.HttpsError("permission-denied", "Role not allowed");
  }

  // --- 4. Company membership ---
  if (!isSuperAdmin && userData.companyId !== companyId) {
    throw new functions.https.HttpsError("permission-denied", "Not a member of this company");
  }

  // --- 5. Company doc: billing + modules + period lock ---
  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new functions.https.HttpsError("not-found", "Company not found");
  }
  const company = companySnap.data();

  // Billing guard
  if (!isSuperAdmin) {
    const status = company.billingStatus || "active";
    const allowed = ["active", "grace"];
    if (status === "trial") {
      if (!company.trialUntil || company.trialUntil.toDate() < new Date()) {
        throw new functions.https.HttpsError("permission-denied", "Trial expired");
      }
    } else if (!allowed.includes(status)) {
      throw new functions.https.HttpsError("permission-denied", `Billing status: ${status}`);
    }

    // Module guard
    if (!company.modules || company.modules.accounting !== true) {
      throw new functions.https.HttpsError("permission-denied", "Accounting module disabled");
    }
  }

  // --- 6. Read invoice (pre-transaction check) ---
  const invoiceRef = db.doc(
    `companies/${companyId}/accounting/_root/invoices/${invoiceId}`
  );
  const invoiceSnap = await invoiceRef.get();
  if (!invoiceSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Invoice not found");
  }
  const invoice = invoiceSnap.data();

  // Idempotency: already issued → return existing
  if (invoice.status === "issued" && invoice.sequentialNumber > 0) {
    return {
      ok: true,
      invoiceId,
      issued: true,
      docNumber: invoice.sequentialNumber,
      docNumberFormatted: String(invoice.sequentialNumber),
      issuedAt: invoice.finalizedAt ? invoice.finalizedAt.toDate().toISOString() : null,
      anchorId: null,
      chainId: null,
      counterAfter: invoice.sequentialNumber,
      idempotent: true,
    };
  }

  // Must be draft
  if (invoice.status && invoice.status !== "draft") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Invoice status is '${invoice.status}', expected 'draft'`
    );
  }

  // Must not have docNumber already
  if (invoice.sequentialNumber && invoice.sequentialNumber > 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Invoice already has a sequential number"
    );
  }

  // deliveryDate required
  if (!invoice.deliveryDate) {
    throw new functions.https.HttpsError("failed-precondition", "deliveryDate missing");
  }

  // Period lock
  if (!isSuperAdmin && company.accountingLockedUntil) {
    const lockedUntil = company.accountingLockedUntil.toDate();
    const deliveryDate = invoice.deliveryDate.toDate();
    if (deliveryDate <= lockedUntil) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Document date is in locked accounting period"
      );
    }
  }

  // --- 7. Transaction: counter → invoice → anchor → chain ---
  const counterRef = db.doc(
    `companies/${companyId}/accounting/_root/counters/${counterKey}`
  );

  const result = await db.runTransaction(async (tx) => {
    // 7.1 Read counter
    const counterSnap = await tx.get(counterRef);
    let currentValue = 0;
    if (counterSnap.exists) {
      currentValue = counterSnap.data().lastNumber || 0;
    }
    const nextNumber = currentValue + 1;

    // 7.2 Re-read invoice inside transaction
    const invSnap = await tx.get(invoiceRef);
    const invData = invSnap.data();

    // Double-check idempotency inside transaction
    if (invData.status === "issued" && invData.sequentialNumber > 0) {
      return { idempotent: true, docNumber: invData.sequentialNumber };
    }

    // 7.3 Deterministic issuedAt (Timestamp.now() — server time, but available for hash)
    const issuedAt = Timestamp.now();
    const issuedAtMillis = issuedAt.toMillis();

    // 7.4 Compute immutableSnapshotHash (бизнес-данные документа)
    const snapshotInput = [
      companyId,
      invoiceId,
      counterKey,
      nextNumber,
      invData.clientName || "",
      invData.clientNumber || "",
      invData.deliveryDate ? invData.deliveryDate.toDate().toISOString() : "",
      JSON.stringify(invData.items || []),
      String(invData.discount || 0),
    ].join("|");
    const snapshotHash = sha256hex(snapshotInput);

    // 7.5 Read prevHash from chain (deterministic ID)
    let prevHash = null;
    if (nextNumber > 1) {
      const prevChainId = `${counterKey}_${nextNumber - 1}`;
      const prevChainSnap = await tx.get(
        db.doc(`companies/${companyId}/accounting/_root/integrity_chain/${prevChainId}`)
      );
      if (prevChainSnap.exists) {
        prevHash = prevChainSnap.data().hash || null;
      }
    }

    // 7.6 Canonical chain hash v1
    const chainHash = buildChainHashV1({
      companyId,
      counterKey,
      docType: counterKey,
      docNumber: nextNumber,
      docId: invoiceId,
      issuedAtMillis,
      prevHash,
    });

    // 7.7 Update invoice → issued
    tx.update(invoiceRef, {
      status: "issued",
      sequentialNumber: nextNumber,
      finalizedAt: issuedAt,
      finalizedBy: uid,
      immutableSnapshotHash: snapshotHash,
    });

    // 7.8 Update counter
    if (counterSnap.exists) {
      tx.update(counterRef, {
        lastNumber: nextNumber,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: uid,
      });
    } else {
      tx.set(counterRef, {
        lastNumber: nextNumber,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: uid,
      });
    }

    // 7.9 Integrity anchor (deterministic ID)
    const anchorId = `${counterKey}_${nextNumber}`;
    const anchorRef = db.doc(
      `companies/${companyId}/accounting/_root/integrity_anchors/${anchorId}`
    );
    tx.set(anchorRef, {
      counterKey,
      docNumber: nextNumber,
      invoiceId,
      documentHash: snapshotHash,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });

    // 7.10 Integrity chain (deterministic ID, canonical v1 hash)
    const chainId = `${counterKey}_${nextNumber}`;
    const chainRef = db.doc(
      `companies/${companyId}/accounting/_root/integrity_chain/${chainId}`
    );
    tx.set(chainRef, {
      counterKey,
      docNumber: nextNumber,
      docId: invoiceId,
      docType: counterKey,
      issuedAt,
      prevHash: prevHash ?? "GENESIS",
      hash: chainHash,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });

    return {
      idempotent: false,
      docNumber: nextNumber,
      snapshotHash,
      anchorId,
      chainId,
      issuedAt: issuedAt.toDate().toISOString(),
    };
  });

  // Idempotent return from inside transaction
  if (result.idempotent) {
    return {
      ok: true,
      invoiceId,
      issued: true,
      docNumber: result.docNumber,
      docNumberFormatted: String(result.docNumber),
      issuedAt: null,
      anchorId: null,
      chainId: null,
      counterAfter: result.docNumber,
      idempotent: true,
    };
  }

  // --- 8. Audit (outside transaction — non-blocking) ---
  try {
    await db.collection(`companies/${companyId}/audit`).add({
      moduleKey: "accounting",
      type: "invoice_issued",
      entity: { collection: "invoices", docId: invoiceId },
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.warn("⚠️ Audit write failed (non-blocking):", e.message);
  }

  return {
    ok: true,
    invoiceId,
    issued: true,
    docNumber: result.docNumber,
    docNumberFormatted: String(result.docNumber),
    issuedAt: result.issuedAt,
    anchorId: result.anchorId,
    chainId: result.chainId,
    counterAfter: result.docNumber,
    idempotent: false,
  };
});
