'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  computeFingerprint,
  inferSeverity,
  sanitizeText,
  stackTop,
} = require('../lib/platformErrors');

test('stackTop picks second line', () => {
  const top = stackTop('Error\n  at foo.js:10\n  at bar.js:20');
  assert.equal(top, 'at foo.js:10');
});

test('computeFingerprint groups same error', () => {
  const a = computeFingerprint({
    errorType: 'HttpsError',
    stackTrace: 'Error\n  at fn.js:1',
    operation: 'issueInvoice',
  });
  const b = computeFingerprint({
    errorType: 'HttpsError',
    stackTrace: 'Error\n  at fn.js:1\n  at other.js:9',
    operation: 'issueInvoice',
  });
  assert.equal(a, b);
});

test('inferSeverity permission denied is high', () => {
  assert.equal(
    inferSeverity({ errorType: 'permission-denied', errorMessage: 'denied' }),
    'high',
  );
});

test('inferSeverity billing failure is critical', () => {
  assert.equal(
    inferSeverity({ errorType: 'Error', errorMessage: 'billing failure' }),
    'critical',
  );
});

test('sanitizeText redacts email', () => {
  const out = sanitizeText('failed for user@example.com');
  assert.ok(!out.includes('user@example.com'));
  assert.ok(out.includes('[email]'));
});
