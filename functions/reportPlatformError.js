const functions = require('firebase-functions');
const { resolveCorrelationId } = require('./lib/correlation');
const { upsertPlatformError, sanitizeMetadata } = require('./lib/platformErrors');

/**
 * Клиентский отчёт необработанных ошибок → platform/system/errors.
 */
exports.reportPlatformError = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }

  const correlationId = resolveCorrelationId(data);
  const payload = {
    source: data?.source || 'flutter',
    errorType: data?.errorType || 'unknown',
    errorMessage: data?.errorMessage || '',
    stackTrace: data?.stackTrace || '',
    operation: data?.operation || null,
    correlationId,
    companyId: data?.companyId || context.auth.token?.companyId || null,
    companyName: data?.companyName || null,
    userId: context.auth.uid,
    role: context.auth.token?.role || data?.role || null,
    deviceId: data?.deviceId || null,
    platform: data?.platform || null,
    appVersion: data?.appVersion || null,
    buildNumber: data?.buildNumber || null,
    environment: data?.environment || 'production',
    route: data?.route || null,
    metadata: sanitizeMetadata(data?.metadata),
  };

  const errorId = await upsertPlatformError(payload);
  return { errorId, correlationId };
});
