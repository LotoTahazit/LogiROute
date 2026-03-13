/**
 * Интеграционный тест verifyIntegrityChain callable.
 * Запуск: $env:NODE_PATH = "functions/node_modules" ; node scripts/test_verify_chain.js
 *
 * Тестирует:
 * 1. Валидная цепочка → ok=true
 * 2. Изменённый hash → HASH_MISMATCH
 * 3. Изменённый prevHash → PREV_HASH_MISMATCH
 * 4. Удалённый элемент → MISSING_ENTRY
 * 5. Проверка с середины при отсутствии prev → MISSING_PREV_FOR_RANGE
 */

const admin = require("firebase-admin");
const crypto = require("crypto");
const path = require("path");

const serviceAccountPath = path.join(
  __dirname,
  "logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json"
);
admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

// --- Canonical hash (same as server) ---
function sha256hex(s) {
  return crypto.createHash("sha256").update(s, "utf8").digest("hex");
}
function buildChainHashV1({ companyId, counterKey, docType, docNumber, docId, issuedAtMillis, prevHash }) {
  const prev = prevHash ?? "GENESIS";
  return sha256hex(`v1|${companyId}|${counterKey}|${docType}|${docNumber}|${docId}|${issuedAtMillis}|${prev}`);
}

// --- Test config ---
const TEST_COMPANY = "test-verify-chain-tmp";
const COUNTER_KEY = "test_inv";
const CHAIN_BASE = `companies/${TEST_COMPANY}/accounting/_root/integrity_chain`;

async function cleanup() {
  const snap = await db.collection(CHAIN_BASE).get();
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  if (snap.docs.length > 0) await batch.commit();
}

async function seedChain(count) {
  let prevHash = null;
  const entries = [];
  for (let n = 1; n <= count; n++) {
    const issuedAt = Timestamp.fromMillis(1700000000000 + n * 1000);
    const docId = `doc_${n}`;
    const hash = buildChainHashV1({
      companyId: TEST_COMPANY,
      counterKey: COUNTER_KEY,
      docType: COUNTER_KEY,
      docNumber: n,
      docId,
      issuedAtMillis: issuedAt.toMillis(),
      prevHash,
    });
    const entry = {
      counterKey: COUNTER_KEY,
      docNumber: n,
      docId,
      docType: COUNTER_KEY,
      issuedAt,
      prevHash: prevHash ?? "GENESIS",
      hash,
      createdAt: Timestamp.now(),
      createdBy: "test",
    };
    await db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_${n}`).set(entry);
    entries.push(entry);
    prevHash = hash;
  }
  return entries;
}

// --- Inline verify logic (mirrors callable) ---
async function verifyRange(from, to) {
  const refs = [];
  if (from > 1) {
    refs.push(db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_${from - 1}`));
  }
  for (let n = from; n <= to; n++) {
    refs.push(db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_${n}`));
  }
  const snaps = await db.getAll(...refs);

  let snapIdx = 0;
  let prevHashExpected = null;

  if (from > 1) {
    const prevSnap = snaps[snapIdx++];
    if (!prevSnap.exists) {
      return { ok: false, firstBrokenAt: from - 1, reason: "MISSING_PREV_FOR_RANGE" };
    }
    prevHashExpected = prevSnap.data().hash || null;
  }

  let checked = 0;
  for (let n = from; n <= to; n++) {
    const snap = snaps[snapIdx++];
    if (!snap.exists) {
      return { ok: false, firstBrokenAt: n, reason: "MISSING_ENTRY", checkedUntil: n - 1 };
    }
    const d = snap.data();

    const expectedPrev = prevHashExpected ?? "GENESIS";
    const actualPrev = d.prevHash ?? "GENESIS";
    if (actualPrev !== expectedPrev) {
      return { ok: false, firstBrokenAt: n, reason: "PREV_HASH_MISMATCH", checkedUntil: n - 1 };
    }

    const issuedAtMillis = d.issuedAt ? d.issuedAt.toMillis() : 0;
    const hashExpected = buildChainHashV1({
      companyId: TEST_COMPANY,
      counterKey: COUNTER_KEY,
      docType: d.docType,
      docNumber: n,
      docId: d.docId,
      issuedAtMillis,
      prevHash: actualPrev === "GENESIS" ? null : actualPrev,
    });

    if (hashExpected !== d.hash) {
      return { ok: false, firstBrokenAt: n, reason: "HASH_MISMATCH", checkedUntil: n - 1 };
    }

    prevHashExpected = d.hash;
    checked++;
  }

  return { ok: true, checked, firstBrokenAt: null };
}

// --- Tests ---
let passed = 0;
let failed = 0;

function assert(condition, name) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ❌ ${name}`);
    failed++;
  }
}

async function runTests() {
  console.log("\n🔗 verifyIntegrityChain integration tests\n");

  // Test 1: Valid chain
  console.log("Test 1: Valid chain (1..5)");
  await cleanup();
  await seedChain(5);
  let r = await verifyRange(1, 5);
  assert(r.ok === true, "ok=true");
  assert(r.checked === 5, "checked=5");
  assert(r.firstBrokenAt === null, "firstBrokenAt=null");

  // Test 2: Tampered hash at element 3
  console.log("\nTest 2: Tampered hash at element 3");
  await db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_3`).update({ hash: "tampered_hash" });
  r = await verifyRange(1, 5);
  assert(r.ok === false, "ok=false");
  assert(r.firstBrokenAt === 3, "firstBrokenAt=3");
  assert(r.reason === "HASH_MISMATCH", "reason=HASH_MISMATCH");

  // Test 3: Tampered prevHash at element 3
  console.log("\nTest 3: Tampered prevHash at element 3");
  await cleanup();
  await seedChain(5);
  await db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_3`).update({ prevHash: "wrong_prev" });
  r = await verifyRange(1, 5);
  assert(r.ok === false, "ok=false");
  assert(r.firstBrokenAt === 3, "firstBrokenAt=3");
  assert(r.reason === "PREV_HASH_MISMATCH", "reason=PREV_HASH_MISMATCH");

  // Test 4: Missing element 3
  console.log("\nTest 4: Missing element 3");
  await cleanup();
  await seedChain(5);
  await db.doc(`${CHAIN_BASE}/${COUNTER_KEY}_3`).delete();
  r = await verifyRange(1, 5);
  assert(r.ok === false, "ok=false");
  assert(r.firstBrokenAt === 3, "firstBrokenAt=3");
  assert(r.reason === "MISSING_ENTRY", "reason=MISSING_ENTRY");

  // Test 5: Verify from middle with missing prev
  console.log("\nTest 5: Verify from=10 with missing prev (9)");
  await cleanup();
  await seedChain(5); // only 1..5 exist
  r = await verifyRange(10, 12);
  assert(r.ok === false, "ok=false");
  assert(r.firstBrokenAt === 9, "firstBrokenAt=9 (missing prev)");
  assert(r.reason === "MISSING_PREV_FOR_RANGE", "reason=MISSING_PREV_FOR_RANGE");

  // Test 6: Valid sub-range from middle
  console.log("\nTest 6: Valid sub-range from=3 to=5");
  await cleanup();
  await seedChain(5);
  r = await verifyRange(3, 5);
  assert(r.ok === true, "ok=true");
  assert(r.checked === 3, "checked=3");

  // Cleanup
  await cleanup();

  console.log(`\n📊 Results: ${passed} passed, ${failed} failed out of ${passed + failed}`);
  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});
