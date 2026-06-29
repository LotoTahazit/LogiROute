const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

const DAY_LIMIT = 1000;
const MONTH_INVOICE_LIMIT = 2000;
const ACTIVE_LIMIT = 200;
const LIVE_INVOICE = new Set(["issued", "active"]);
const COMPLETED_STATUS = new Set([
  "completed",
  "הושלם",
  "завершён",
  "завершен",
]);

function formatDateKey(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function parseDateKey(dateKey) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey);
  if (!m) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "date must be YYYY-MM-DD"
    );
  }
  const y = +m[1];
  const mo = +m[2];
  const d = +m[3];
  const start = new Date(y, mo - 1, d, 0, 0, 0, 0);
  const end = new Date(y, mo - 1, d, 23, 59, 59, 999);
  return { start, end, y, mo };
}

function monthBounds(y, mo) {
  const start = new Date(y, mo - 1, 1, 0, 0, 0, 0);
  const end = new Date(y, mo, 0, 23, 59, 59, 999);
  return { start, end };
}

async function assertCanRecalculate(uid, companyId) {
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError("permission-denied", "User not found");
  }
  const role = userSnap.data().role;
  const isSuperAdmin = role === "super_admin";
  if (!["super_admin", "admin", "owner"].includes(role)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "admin, owner or super_admin required"
    );
  }
  if (!isSuperAdmin && userSnap.data().companyId !== companyId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not a member of this company"
    );
  }
}

/**
 * Bounded daily KPI for Owner Dashboard overview.
 * Path: companies/{companyId}/metrics/daily/days/{YYYY-MM-DD}
 * Idempotent: merge + server timestamp.
 */
async function computeDailyMetrics(companyId, dateKey) {
  const { start, end, y, mo } = parseDateKey(dateKey);
  const startTs = Timestamp.fromDate(start);
  const endTs = Timestamp.fromDate(end);

  const dpCol = db.collection(
    `companies/${companyId}/logistics/_root/delivery_points`
  );

  const completedSnap = await dpCol
    .where("completedAt", ">=", startTs)
    .where("completedAt", "<=", endTs)
    .limit(DAY_LIMIT)
    .get();

  const deliveriesToday = completedSnap.docs.filter((doc) =>
    COMPLETED_STATUS.has(doc.data().status)
  ).length;

  const createdDpSnap = await dpCol
    .where("createdAt", ">=", startTs)
    .where("createdAt", "<=", endTs)
    .limit(DAY_LIMIT)
    .get();

  const activeSnap = await dpCol
    .where("status", "in", ["assigned", "in_progress"])
    .limit(ACTIVE_LIMIT)
    .get();

  const activeDriverIds = new Set();
  for (const doc of activeSnap.docs) {
    const data = doc.data();
    if (data.archived === true) continue;
    if (data.driverId) activeDriverIds.add(data.driverId);
  }

  const { start: monthStart, end: monthEnd } = monthBounds(y, mo);
  const invCol = db.collection(
    `companies/${companyId}/accounting/_root/invoices`
  );

  const invSnap = await invCol
    .where("deliveryDate", ">=", Timestamp.fromDate(monthStart))
    .where("deliveryDate", "<=", Timestamp.fromDate(monthEnd))
    .limit(MONTH_INVOICE_LIMIT)
    .get();

  const invoicesThisMonth = invSnap.docs.filter((doc) =>
    LIVE_INVOICE.has(doc.data().status)
  ).length;

  const invCreatedSnap = await invCol
    .where("createdAt", ">=", startTs)
    .where("createdAt", "<=", endTs)
    .limit(DAY_LIMIT)
    .get();

  const whSnap = await db
    .collection(
      `companies/${companyId}/warehouse/_root/inventory_history`
    )
    .where("timestamp", ">=", startTs)
    .where("timestamp", "<=", endTs)
    .limit(DAY_LIMIT)
    .get();

  const peSnap = await db
    .collection(`companies/${companyId}/printEvents`)
    .where("printedAt", ">=", startTs)
    .where("printedAt", "<=", endTs)
    .limit(DAY_LIMIT)
    .get();

  let printErrorsToday = 0;
  peSnap.forEach((doc) => {
    if (doc.data().status === "error") printErrorsToday += 1;
  });

  const metrics = {
    date: dateKey,
    deliveriesToday,
    invoicesThisMonth,
    warehouseMovements: whSnap.size,
    activeDrivers: activeDriverIds.size,
    printEventsToday: peSnap.size,
    printErrorsToday,
    recordsCreatedToday: createdDpSnap.size + invCreatedSnap.size,
    updatedAt: FieldValue.serverTimestamp(),
  };

  await db
    .doc(`companies/${companyId}/metrics/daily/days/${dateKey}`)
    .set(metrics, { merge: true });

  return metrics;
}

exports.computeDailyMetrics = computeDailyMetrics;

exports.recalculateDailyMetrics = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }

    const companyId = data && data.companyId;
    if (!companyId || typeof companyId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "companyId required"
      );
    }

    await assertCanRecalculate(context.auth.uid, companyId);

    const dateKey =
      data && typeof data.date === "string" && data.date
        ? data.date
        : formatDateKey(new Date());

    const metrics = await computeDailyMetrics(companyId, dateKey);
    return { ok: true, date: dateKey, metrics };
  }
);

/** Nightly: today + yesterday for each company (bounded reads per day). */
exports.scheduledDailyMetrics = functions.pubsub
  .schedule("0 1 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const now = new Date();
    const todayKey = formatDateKey(now);
    const y = new Date(now);
    y.setDate(y.getDate() - 1);
    const yesterdayKey = formatDateKey(y);

    const companiesSnap = await db.collection("companies").select().limit(500).get();
    let processed = 0;

    for (const companyDoc of companiesSnap.docs) {
      const companyId = companyDoc.id;
      try {
        await computeDailyMetrics(companyId, todayKey);
        await computeDailyMetrics(companyId, yesterdayKey);
        processed += 1;
      } catch (err) {
        console.error(
          `scheduledDailyMetrics failed for ${companyId}: ${err.message}`
        );
      }
    }

    console.log(
      `scheduledDailyMetrics done: ${processed} companies (${todayKey}, ${yesterdayKey})`
    );
    return { processed, todayKey, yesterdayKey };
  });
