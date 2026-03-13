const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();

// =========================================================
// Canonical hash (must match issueInvoice.js exactly)
// =========================================================

function sha256hex(s) {
  return crypto.createHash("sha256").update(s, "utf8").digest("hex");
}

function buildChainHashV1({ companyId, counterKey, docType, docNumber, docId, issuedAtMillis, prevHash }) {
  const prev = prevHash ?? "GENESIS";
  return sha256hex(`v1|${companyId}|${counterKey}|${docType}|${docNumber}|${docId}|${issuedAtMillis}|${prev}`);
}

// =========================================================
// verifyIntegrityChain — Callable Function
// Пересчитывает chain hashes для диапазона [from..to]
// =========================================================

const MAX_RANGE = 2000;

exports.verifyIntegrityChain = functions.https.onCall(async (data, context) => {
  // --- 1. Auth ---
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const uid = context.auth.uid;

  // --- 2. Input validation ---
  const { companyId, counterKey } = data;
  let { from, to } = data;

  if (!companyId || typeof companyId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }
  if (!counterKey || typeof counterKey !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "counterKey required");
  }
  from = Number(from);
  to = Number(to);
  if (!Number.isInteger(from) || from < 1) {
    throw new functions.https.HttpsError("invalid-argument", "from must be >= 1");
  }
  if (!Number.isInteger(to) || to < from) {
    throw new functions.https.HttpsError("invalid-argument", "to must be >= from");
  }
  if (to - from + 1 > MAX_RANGE) {
    throw new functions.https.HttpsError("invalid-argument", `Range too large (max ${MAX_RANGE})`);
  }

  // --- 3. RBAC: admin or super_admin, membership, billing ---
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError("permission-denied", "User not found");
  }
  const userData = userSnap.data();
  const role = userData.role;
  const isSuperAdmin = role === "super_admin";

  if (!isSuperAdmin && role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admin role required");
  }
  if (!isSuperAdmin && userData.companyId !== companyId) {
    throw new functions.https.HttpsError("permission-denied", "Not a member of this company");
  }

  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new functions.https.HttpsError("not-found", "Company not found");
  }
  const company = companySnap.data();

  if (!isSuperAdmin) {
    const status = company.billingStatus || "active";
    const allowed = ["active", "grace"];
    if (status === "trial") {
      if (!company.trialUntil || company.trialUntil.toDate() < new Date()) {
        throw new functions.https.HttpsError("failed-precondition", "Trial expired");
      }
    } else if (!allowed.includes(status)) {
      throw new functions.https.HttpsError("failed-precondition", `Billing status: ${status}`);
    }
  }

  // --- 4. Batch-read chain docs via getAll ---
  const chainBase = `companies/${companyId}/accounting/_root/integrity_chain`;

  // If from > 1, read from-1 to get starting prevHash
  const refs = [];
  if (from > 1) {
    refs.push(db.doc(`${chainBase}/${counterKey}_${from - 1}`));
  }
  for (let n = from; n <= to; n++) {
    refs.push(db.doc(`${chainBase}/${counterKey}_${n}`));
  }

  const snaps = await db.getAll(...refs);

  // --- 5. Determine starting prevHash ---
  let snapIdx = 0;
  let prevHashExpected = null; // null → first element should have GENESIS

  if (from > 1) {
    const prevSnap = snaps[snapIdx++];
    if (!prevSnap.exists) {
      return {
        ok: false,
        companyId,
        counterKey,
        range: { from, to },
        checkedUntil: from - 1,
        firstBrokenAt: from - 1,
        reason: "MISSING_PREV_FOR_RANGE",
        expected: null,
        actual: null,
        doc: null,
      };
    }
    prevHashExpected = prevSnap.data().hash || null;
  }

  // --- 6. Walk the chain ---
  let checked = 0;

  for (let n = from; n <= to; n++) {
    const snap = snaps[snapIdx++];

    // 6.1 Missing entry
    if (!snap.exists) {
      return {
        ok: false,
        companyId,
        counterKey,
        range: { from, to },
        checkedUntil: n - 1,
        firstBrokenAt: n,
        reason: "MISSING_ENTRY",
        expected: null,
        actual: null,
        doc: null,
      };
    }

    const d = snap.data();

    // 6.2 Schema validation
    if (
      typeof d.hash !== "string" ||
      typeof d.docId !== "string" ||
      typeof d.docType !== "string" ||
      d.docNumber !== n ||
      d.counterKey !== counterKey
    ) {
      return {
        ok: false,
        companyId,
        counterKey,
        range: { from, to },
        checkedUntil: n - 1,
        firstBrokenAt: n,
        reason: "SCHEMA_INVALID",
        expected: { docNumber: n, counterKey },
        actual: { docNumber: d.docNumber, counterKey: d.counterKey },
        doc: { docId: d.docId || null },
      };
    }

    // 6.3 prevHash check
    const expectedPrev = prevHashExpected ?? "GENESIS";
    const actualPrev = d.prevHash ?? "GENESIS";

    if (actualPrev !== expectedPrev) {
      return {
        ok: false,
        companyId,
        counterKey,
        range: { from, to },
        checkedUntil: n - 1,
        firstBrokenAt: n,
        reason: "PREV_HASH_MISMATCH",
        expected: { prevHash: expectedPrev },
        actual: { prevHash: actualPrev },
        doc: { docId: d.docId, issuedAtMillis: d.issuedAt ? d.issuedAt.toMillis() : null },
      };
    }

    // 6.4 Recompute hash
    const issuedAtMillis = d.issuedAt ? d.issuedAt.toMillis() : 0;
    const hashExpected = buildChainHashV1({
      companyId,
      counterKey,
      docType: d.docType,
      docNumber: n,
      docId: d.docId,
      issuedAtMillis,
      prevHash: actualPrev === "GENESIS" ? null : actualPrev,
    });

    if (hashExpected !== d.hash) {
      return {
        ok: false,
        companyId,
        counterKey,
        range: { from, to },
        checkedUntil: n - 1,
        firstBrokenAt: n,
        reason: "HASH_MISMATCH",
        expected: { hash: hashExpected },
        actual: { hash: d.hash },
        doc: { docId: d.docId, issuedAtMillis },
      };
    }

    prevHashExpected = d.hash;
    checked++;
  }

  // --- 7. Success ---
  return {
    ok: true,
    companyId,
    counterKey,
    range: { from, to },
    checked,
    firstBrokenAt: null,
    last: {
      docNumber: to,
      hash: prevHashExpected,
    },
  };
});
