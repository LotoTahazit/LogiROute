'use strict';

const crypto = require('crypto');
const admin = require('firebase-admin');

function errorsCol() {
  return admin.firestore().collection('platform').doc('system').collection('errors');
}

function privateCol() {
  return admin.firestore().collection('platform').doc('system').collection('error_private');
}

function stackTop(stackTrace) {
  if (!stackTrace || typeof stackTrace !== 'string') return '';
  const lines = stackTrace
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);
  return lines.length > 1 ? lines[1] : lines[0] || '';
}

function computeFingerprint({ errorType, stackTrace, operation }) {
  const payload = [
    String(errorType || 'unknown').toLowerCase(),
    stackTop(stackTrace),
    String(operation || 'unknown').toLowerCase(),
  ].join('|');
  return crypto.createHash('sha256').update(payload).digest('hex').slice(0, 40);
}

function inferSeverity({ errorType, errorMessage }) {
  const t = `${errorType || ''} ${errorMessage || ''}`.toLowerCase();
  if (
    /unhandled|crash|corruption|billing.*fail|accounting.*fail|internal-error/.test(t)
  ) {
    return 'critical';
  }
  if (/permission.denied|permission-denied|sync.*fail|import.*fail/.test(t)) {
    return 'high';
  }
  if (/gps|navigation|waze|notification/.test(t)) {
    return 'medium';
  }
  return 'low';
}

function sanitizeText(text) {
  if (text == null) return '';
  let s = String(text);
  s = s.replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g, '[email]');
  s = s.replace(/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+\b/g, '[jwt]');
  s = s.replace(/\b\d{13,19}\b/g, '[card]');
  s = s.replace(/password[=:]\s*\S+/gi, 'password=[redacted]');
  s = s.replace(/Bearer\s+\S+/gi, 'Bearer [redacted]');
  s = s.replace(/\+?\d{10,15}/g, '[phone]');
  return s.slice(0, 8000);
}

function sanitizeMetadata(meta) {
  if (!meta || typeof meta !== 'object') return {};
  const out = {};
  for (const [k, v] of Object.entries(meta)) {
    const key = k.toLowerCase();
    if (key.includes('password') || key.includes('token') || key.includes('secret')) {
      out[k] = '[redacted]';
    } else if (typeof v === 'string') {
      out[k] = sanitizeText(v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

async function upsertPlatformError(payload) {
  const fp = computeFingerprint(payload);
  const ref = errorsCol().doc(fp);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const nowDate = new Date();
  const severity = inferSeverity(payload);
  const cid = payload.correlationId ? String(payload.correlationId).trim() : null;

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      const data = snap.data() || {};
      const hourAgo = new Date(nowDate.getTime() - 3600000);
      const windowStart = data.hourWindowStart?.toDate?.();
      let hourCount = (data.hourOccurrences || 0) + 1;
      let hourWindowStart = data.hourWindowStart;
      if (!windowStart || windowStart < hourAgo) {
        hourCount = 1;
        hourWindowStart = admin.firestore.Timestamp.fromDate(nowDate);
      }
      const updates = {
        occurrences: admin.firestore.FieldValue.increment(1),
        lastSeen: now,
        hourOccurrences: hourCount,
        hourWindowStart,
        incidentSuggested: hourCount > 20,
      };
      if (severity === 'critical' || data.severity === 'critical') {
        updates.severity = 'critical';
      } else if (severity === 'high' && data.severity !== 'critical') {
        updates.severity = 'high';
      }
      if (cid) {
        updates.recentCorrelationIds = admin.firestore.FieldValue.arrayUnion(cid);
      }
      tx.update(ref, updates);
    } else {
      tx.set(ref, {
        errorId: fp,
        fingerprint: fp,
        companyId: payload.companyId || null,
        companyName: payload.companyName || null,
        userId: payload.userId || null,
        role: payload.role || null,
        deviceId: payload.deviceId || null,
        platform: payload.platform || null,
        appVersion: payload.appVersion || null,
        buildNumber: payload.buildNumber || null,
        environment: payload.environment || 'production',
        timestamp: now,
        severity,
        status: 'open',
        correlationId: cid,
        recentCorrelationIds: cid ? [cid] : [],
        operation: payload.operation || null,
        errorType: payload.errorType || 'unknown',
        errorMessage: sanitizeText(payload.errorMessage || ''),
        route: payload.route || null,
        metadata: sanitizeMetadata(payload.metadata),
        occurrences: 1,
        firstSeen: now,
        lastSeen: now,
        resolved: false,
        resolvedBy: null,
        resolvedAt: null,
        resolutionNote: null,
        source: payload.source || 'unknown',
        hourOccurrences: 1,
        hourWindowStart: admin.firestore.Timestamp.fromDate(nowDate),
        incidentSuggested: false,
      });
    }
  });

  if (payload.stackTrace) {
    await privateCol().doc(fp).set(
      {
        stackTrace: sanitizeText(payload.stackTrace),
        metadataRaw: sanitizeMetadata(payload.metadata),
        updatedAt: now,
      },
      { merge: true },
    );
  }

  return fp;
}

async function logPlatformErrorFromCf(err, context, extra = {}) {
  try {
    await upsertPlatformError({
      source: 'cloud_functions',
      errorType: err?.code || err?.name || 'Error',
      errorMessage: err?.message || String(err),
      stackTrace: err?.stack || String(err),
      operation: extra.operation || extra.name || 'cf',
      correlationId: extra.correlationId,
      companyId: extra.companyId || null,
      userId: context?.auth?.uid || null,
      role: context?.auth?.token?.role || null,
      metadata: { functionName: extra.name, ...extra.metadata },
    });
  } catch (e) {
    console.error('logPlatformErrorFromCf failed', e.message);
  }
}

module.exports = {
  errorsCol,
  privateCol,
  stackTop,
  computeFingerprint,
  inferSeverity,
  sanitizeText,
  sanitizeMetadata,
  upsertPlatformError,
  logPlatformErrorFromCf,
};
