'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {
  runIntegrityChecks,
  summarizeBySeverity,
  fingerprint,
} = require('./lib/integrityChecks');

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Жёсткие лимиты чтения (cost guard).
const LIMITS = {
  users: 1000,
  members: 1000,
  points: 3000,
  routes: 2000,
  invoices: 3000,
  inventory: 3000,
  productTypes: 1000,
  sessions: 1000,
  locations: 1000,
  syncLedger: 2000,
};
const MAX_OPEN_SCAN = 3000;

function companyBase(companyId) {
  return db.collection('companies').doc(companyId);
}

function docsToList(snap) {
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function safeList(query) {
  try {
    const snap = await query.get();
    return docsToList(snap);
  } catch (e) {
    console.warn(`integrity: query failed: ${e.message}`);
    return [];
  }
}

async function assertCanRun(uid, companyId) {
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError('permission-denied', 'User not found');
  }
  const data = userSnap.data();
  const role = data.role;
  const isSuper = role === 'super_admin';
  if (!['super_admin', 'admin', 'owner'].includes(role)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'admin, owner or super_admin required',
    );
  }
  if (!isSuper && data.companyId !== companyId) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Not a member of this company',
    );
  }
}

/** Собирает снимок данных компании (bounded reads). */
async function loadSnapshot(companyId) {
  const base = companyBase(companyId);
  const logistics = base.collection('logistics').doc('_root');
  const accounting = base.collection('accounting').doc('_root');
  const warehouse = base.collection('warehouse').doc('_root');

  const [
    users,
    members,
    deliveryPoints,
    routes,
    invoices,
    inventory,
    productTypes,
    driverSessions,
    driverLocations,
    syncLedger,
    rcSnap,
  ] = await Promise.all([
    safeList(db.collection('users').where('companyId', '==', companyId).limit(LIMITS.users)),
    safeList(base.collection('members').limit(LIMITS.members)),
    safeList(logistics.collection('delivery_points').limit(LIMITS.points)),
    safeList(logistics.collection('routes').limit(LIMITS.routes)),
    safeList(accounting.collection('invoices').limit(LIMITS.invoices)),
    safeList(warehouse.collection('inventory').limit(LIMITS.inventory)),
    safeList(warehouse.collection('product_types').limit(LIMITS.productTypes)),
    safeList(base.collection('driver_sessions').limit(LIMITS.sessions)),
    safeList(base.collection('driver_locations').limit(LIMITS.locations)),
    safeList(accounting.collection('sync_ledger').limit(LIMITS.syncLedger)),
    base.collection('settings').doc('remote_config').get().catch(() => null),
  ]);

  const remoteConfig = rcSnap && rcSnap.exists ? rcSnap.data() : null;
  const sessionStaleMinutes =
    remoteConfig && typeof remoteConfig.driverSessionStaleMinutes === 'number'
      ? remoteConfig.driverSessionStaleMinutes
      : 5;

  return {
    companyId,
    nowMillis: Date.now(),
    sessionStaleMinutes,
    users,
    members,
    deliveryPoints,
    routes,
    invoices,
    inventory,
    productTypes,
    driverSessions,
    driverLocations,
    syncLedger,
    remoteConfig,
  };
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function commitInBatches(ops) {
  for (const part of chunk(ops, 450)) {
    const batch = db.batch();
    for (const op of part) {
      if (op.type === 'set') batch.set(op.ref, op.data, { merge: true });
      else if (op.type === 'update') batch.update(op.ref, op.data);
    }
    await batch.commit();
  }
}

/**
 * Дедуп + reopen + auto-resolve.
 * @returns {{open:number, reopened:number, ignored:number, created:number, resolved:number}}
 */
async function writeIssues(companyId, checkId, issues, correlationId, isDemo) {
  const issueCol = companyBase(companyId).collection('integrity_issues');
  const now = FieldValue.serverTimestamp();

  const foundIds = new Set();
  const prepared = issues.map((issue) => {
    const id = fingerprint(companyId, issue.entityType, issue.entityId, issue.issueCode);
    foundIds.add(id);
    return { id, issue };
  });

  // Читаем существующие issues пачками.
  const existingById = new Map();
  for (const part of chunk(prepared.map((p) => issueCol.doc(p.id)), 300)) {
    if (part.length === 0) continue;
    const snaps = await db.getAll(...part);
    for (const snap of snaps) existingById.set(snap.id, snap);
  }

  const ops = [];
  const stats = { open: 0, reopened: 0, ignored: 0, created: 0, resolved: 0 };

  for (const { id, issue } of prepared) {
    const ref = issueCol.doc(id);
    const snap = existingById.get(id);
    const common = {
      companyId,
      entityType: issue.entityType,
      entityId: issue.entityId,
      issueCode: issue.issueCode,
      severity: issue.severity,
      title: issue.title,
      description: issue.description,
      metadata: issue.metadata || {},
      lastSeenAt: now,
      checkId,
      correlationId: correlationId || null,
      isDemo: !!isDemo,
    };

    if (!snap || !snap.exists) {
      ops.push({ type: 'set', ref, data: { ...common, status: 'open', detectedAt: now } });
      stats.created += 1;
      stats.open += 1;
      continue;
    }

    const status = snap.data().status;
    if (status === 'ignored') {
      ops.push({ type: 'set', ref, data: { ...common } });
      stats.ignored += 1;
    } else if (status === 'resolved') {
      ops.push({
        type: 'set',
        ref,
        data: { ...common, status: 'open', resolvedAt: FieldValue.delete(), reopenedAt: now },
      });
      stats.reopened += 1;
      stats.open += 1;
    } else {
      ops.push({ type: 'set', ref, data: { ...common, status: 'open' } });
      stats.open += 1;
    }
  }

  // Auto-resolve: ранее open, но в этом прогоне не найдены.
  const openSnap = await issueCol
    .where('status', '==', 'open')
    .limit(MAX_OPEN_SCAN)
    .get()
    .catch(() => ({ docs: [] }));
  for (const doc of openSnap.docs) {
    if (foundIds.has(doc.id)) continue;
    ops.push({
      type: 'update',
      ref: doc.ref,
      data: { status: 'resolved', resolvedAt: now, resolvedReason: 'auto', checkId },
    });
    stats.resolved += 1;
  }

  await commitInBatches(ops);
  return stats;
}

async function writeAudit(companyId, type, uid, extra) {
  try {
    await companyBase(companyId).collection('audit').add({
      moduleKey: 'logistics',
      type,
      entity: { collection: 'integrity_checks', docId: extra.checkId || 'check' },
      createdBy: uid || 'system',
      createdAt: FieldValue.serverTimestamp(),
      ...extra,
    });
  } catch (e) {
    console.warn(`integrity audit ${type} failed: ${e.message}`);
  }
}

/** Ядро: один прогон проверки для компании. */
async function runForCompany(companyId, { uid, trigger, correlationId } = {}) {
  const companySnap = await companyBase(companyId).get();
  const isDemo =
    (companySnap.exists && companySnap.data().isDemo === true) ||
    companyId === 'demo-foods-israel';

  const checkRef = companyBase(companyId).collection('integrity_checks').doc();
  const checkId = checkRef.id;
  const startedAt = FieldValue.serverTimestamp();

  await checkRef.set({
    checkId,
    status: 'running',
    trigger: trigger || 'manual',
    startedBy: uid || 'system',
    startedAt,
    correlationId: correlationId || null,
    isDemo,
  });
  await writeAudit(companyId, 'integrity_check_started', uid, { checkId, trigger });

  const startMs = Date.now();
  let stats;
  let bySeverity;
  let issuesCount = 0;
  try {
    const snapshot = await loadSnapshot(companyId);
    const issues = runIntegrityChecks(snapshot);
    issuesCount = issues.length;
    bySeverity = summarizeBySeverity(issues);
    stats = await writeIssues(companyId, checkId, issues, correlationId, isDemo);
  } catch (e) {
    await checkRef.set(
      { status: 'failed', error: e.message, completedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
    throw e;
  }

  const result = {
    checkId,
    status: 'completed',
    completedAt: FieldValue.serverTimestamp(),
    durationMs: Date.now() - startMs,
    foundIssues: issuesCount,
    bySeverity,
    openIssues: stats.open,
    createdIssues: stats.created,
    reopenedIssues: stats.reopened,
    ignoredIssues: stats.ignored,
    autoResolvedIssues: stats.resolved,
  };
  await checkRef.set(result, { merge: true });
  await writeAudit(companyId, 'integrity_check_completed', uid, {
    checkId,
    foundIssues: issuesCount,
    bySeverity,
  });

  return result;
}

// ===== Callable =====
exports.generateIntegrityCheck = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const companyId = data && data.companyId;
  if (!companyId || typeof companyId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'companyId required');
  }
  await assertCanRun(context.auth.uid, companyId);
  const result = await runForCompany(companyId, {
    uid: context.auth.uid,
    trigger: 'manual',
    correlationId: data && (data.correlationId || data.requestId),
  });
  // completedAt — Firestore-сентинел, не сериализуется в ответ callable.
  const { completedAt, ...clean } = result;
  return { ok: true, ...clean };
});

// ===== Scheduled (nightly) =====
exports.scheduledDataIntegrityCheck = functions.pubsub
  .schedule('15 2 * * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async () => {
    const companiesSnap = await db
      .collection('companies')
      .where('billingStatus', 'in', ['active', 'trial', 'grace'])
      .limit(500)
      .get();

    let processed = 0;
    let failed = 0;
    for (const companyDoc of companiesSnap.docs) {
      try {
        await runForCompany(companyDoc.id, { trigger: 'scheduled' });
        processed += 1;
      } catch (e) {
        failed += 1;
        console.error(`scheduledDataIntegrityCheck ${companyDoc.id}: ${e.message}`);
      }
    }
    console.log(`scheduledDataIntegrityCheck done: ${processed} ok, ${failed} failed`);
    return { processed, failed };
  });

exports.runForCompany = runForCompany;
