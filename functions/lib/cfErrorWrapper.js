'use strict';

const { logPlatformErrorFromCf } = require('./platformErrors');

/**
 * Оборачивает Cloud Function handler (onCall / scheduled onRun).
 */
function wrapHandler(handler, name) {
  if (typeof handler !== 'function') return handler;
  return async function wrappedHandler(...args) {
    try {
      return await handler(...args);
    } catch (err) {
      const context = args.length > 1 ? args[1] : null;
      const data = args[0];
      await logPlatformErrorFromCf(err, context, {
        name,
        operation: name,
        correlationId: data?.correlationId || data?.requestId,
        companyId: data?.companyId,
      });
      throw err;
    }
  };
}

/**
 * Инструментирует exports index.js — callable + pubsub onRun.
 */
function instrumentCloudExports(exportObj) {
  for (const key of Object.keys(exportObj)) {
    const fn = exportObj[key];
    if (!fn || typeof fn !== 'object') continue;

    if (typeof fn.run === 'function' && fn.__trigger) {
      const originalRun = fn.run.bind(fn);
      fn.run = async (...args) => {
        try {
          return await originalRun(...args);
        } catch (err) {
          const data = args[0];
          const context = args.length > 1 ? args[1] : null;
          await logPlatformErrorFromCf(err, context, {
            name: key,
            operation: key,
            correlationId: data?.correlationId,
            companyId: data?.companyId,
          });
          throw err;
        }
      };
      continue;
    }

    if (fn.__endpoint && typeof fn.__endpoint.handler === 'function') {
      const original = fn.__endpoint.handler;
      fn.__endpoint.handler = wrapHandler(original, key);
    }
  }
}

module.exports = { wrapHandler, instrumentCloudExports };
