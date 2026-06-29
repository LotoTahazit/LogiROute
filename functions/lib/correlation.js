const crypto = require('crypto');

/**
 * correlationId из клиента (или requestId). Если нет — генерируем.
 */
function resolveCorrelationId(data) {
  const raw = data?.correlationId || data?.requestId;
  if (typeof raw === 'string' && raw.trim()) return raw.trim();
  return crypto.randomUUID();
}

function correlationLog(operation, data, context, extra = {}) {
  const correlationId = resolveCorrelationId(data);
  const payload = {
    correlationId,
    operation,
    companyId: data?.companyId ?? null,
    userId: context?.auth?.uid ?? null,
    timestamp: new Date().toISOString(),
    ...extra,
  };
  console.log(JSON.stringify(payload));
  return correlationId;
}

function correlationErrorDetails(data, context, extra = {}) {
  return {
    correlationId: resolveCorrelationId(data),
    companyId: data?.companyId ?? null,
    userId: context?.auth?.uid ?? null,
    operation: extra.operation ?? null,
    timestamp: new Date().toISOString(),
    ...extra,
  };
}

module.exports = {
  resolveCorrelationId,
  correlationLog,
  correlationErrorDetails,
};
