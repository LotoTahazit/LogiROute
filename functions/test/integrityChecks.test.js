'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  fingerprint,
  invoiceSubtotal,
  validateRemoteConfig,
  runIntegrityChecks,
  summarizeBySeverity,
} = require('../lib/integrityChecks');

const codes = (issues) => issues.map((i) => i.issueCode);
const has = (issues, code) => codes(issues).includes(code);
const bySeverity = (issues, code) =>
  (issues.find((i) => i.issueCode === code) || {}).severity;

function healthySnapshot() {
  return {
    companyId: 'c1',
    nowMillis: 1_700_000_000_000,
    users: [
      { id: 'u1', role: 'driver' },
      { id: 'u2', role: 'dispatcher' },
    ],
    members: [
      { id: 'u1', role: 'driver' },
      { id: 'u2', role: 'dispatcher' },
    ],
    deliveryPoints: [
      {
        id: 'p1',
        companyId: 'c1',
        clientName: 'Acme',
        status: 'assigned',
        driverId: 'u1',
        routeId: 'r1',
        latitude: 32.0,
        longitude: 35.0,
      },
    ],
    routes: [{ id: 'r1', status: 'active', driverId: 'u1', pointIds: ['p1'] }],
    invoices: [{ id: 'i1', companyId: 'c1', clientName: 'Acme', status: 'draft' }],
    inventory: [{ id: 'inv1', quantity: 5, productTypeId: 'pt1' }],
    productTypes: [{ id: 'pt1', productCode: 'X1', name: 'Item' }],
    driverSessions: [],
    driverLocations: [],
    syncLedger: [],
    remoteConfig: {
      autoCloseRadiusMeters: 50,
      autoCloseResetRadiusMeters: 60,
      autoCloseWaitSeconds: 120,
      closeUndoSeconds: 10,
      gpsStaleMinutes: 30,
      driverSessionHeartbeatSeconds: 30,
      driverSessionStaleMinutes: 10,
      importPreviewRows: 20,
      backgroundAutoCloseEnabled: false,
      driverDeviceSessionLockEnabled: true,
    },
  };
}

describe('runIntegrityChecks — healthy data', () => {
  it('clean snapshot produces no issues', () => {
    assert.deepEqual(runIntegrityChecks(healthySnapshot()), []);
  });
});

describe('runIntegrityChecks — users / members', () => {
  it('member without user → critical', () => {
    const s = healthySnapshot();
    s.members.push({ id: 'ghost', role: 'driver' });
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'member_without_user'));
    assert.equal(bySeverity(out, 'member_without_user'), 'critical');
  });

  it('invalid role and role mismatch are flagged', () => {
    const s = healthySnapshot();
    s.members[0].role = 'wizard'; // unknown role
    s.users[0].role = 'driver'; // mismatch with member
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'invalid_role'));
    assert.ok(has(out, 'member_user_role_mismatch'));
  });

  it('user without member → high', () => {
    const s = healthySnapshot();
    s.users.push({ id: 'orphan', role: 'driver' });
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'user_without_member'));
  });
});

describe('runIntegrityChecks — delivery points', () => {
  it('cross-tenant point → critical', () => {
    const s = healthySnapshot();
    s.deliveryPoints[0].companyId = 'OTHER';
    assert.ok(has(runIntegrityChecks(s), 'cross_tenant'));
  });

  it('assigned point with missing driver', () => {
    const s = healthySnapshot();
    s.deliveryPoints[0].driverId = 'nobody';
    assert.ok(has(runIntegrityChecks(s), 'point_assigned_missing_driver'));
  });

  it('archived point is skipped', () => {
    const s = healthySnapshot();
    s.deliveryPoints[0].archived = true;
    s.deliveryPoints[0].companyId = 'OTHER';
    assert.ok(!has(runIntegrityChecks(s), 'cross_tenant'));
  });
});

describe('runIntegrityChecks — routes', () => {
  it('active route without points → critical', () => {
    const s = healthySnapshot();
    s.routes[0].pointIds = [];
    assert.ok(has(runIntegrityChecks(s), 'route_active_no_points'));
  });

  it('active route with all points done → critical', () => {
    const s = healthySnapshot();
    s.deliveryPoints[0].status = 'completed';
    s.deliveryPoints[0].completedAt = 1_699_000_000_000;
    assert.ok(has(runIntegrityChecks(s), 'route_active_all_done'));
  });

  it('route without driver → high', () => {
    const s = healthySnapshot();
    s.routes[0].driverId = '';
    assert.ok(has(runIntegrityChecks(s), 'route_without_driver'));
  });
});

describe('runIntegrityChecks — invoices', () => {
  it('issued invoice without finalizedAt → high', () => {
    const s = healthySnapshot();
    s.invoices[0] = { id: 'i2', companyId: 'c1', clientName: 'Acme', status: 'issued' };
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'invoice_issued_no_timestamp'));
  });

  it('negative total non-credit → critical', () => {
    const s = healthySnapshot();
    s.invoices[0] = {
      id: 'i3', companyId: 'c1', clientName: 'Acme', status: 'draft',
      items: [{ quantity: 1, pricePerUnit: -100 }],
    };
    assert.ok(has(runIntegrityChecks(s), 'invoice_negative_total'));
  });

  it('credit note without link → high', () => {
    const s = healthySnapshot();
    s.invoices[0] = {
      id: 'cn1', companyId: 'c1', clientName: 'Acme', status: 'issued',
      finalizedAt: 1, documentType: 'creditNote',
    };
    assert.ok(has(runIntegrityChecks(s), 'credit_note_no_link'));
  });

  it('failed sync ledger entry → sync_failed high', () => {
    const s = healthySnapshot();
    s.syncLedger = [{ id: 'i1', status: 'failed', provider: 'icount', lastError: 'boom' }];
    assert.ok(has(runIntegrityChecks(s), 'sync_failed'));
  });
});

describe('runIntegrityChecks — inventory', () => {
  it('negative quantity + missing product type', () => {
    const s = healthySnapshot();
    s.inventory = [{ id: 'x', quantity: -3, productTypeId: 'missing' }];
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'inventory_negative_quantity'));
    assert.ok(has(out, 'inventory_missing_product_type'));
  });
});

describe('runIntegrityChecks — driver sessions / gps', () => {
  it('stale active session flagged', () => {
    const s = healthySnapshot();
    s.sessionStaleMinutes = 5;
    s.driverSessions = [
      { id: 'u1', driverId: 'u1', active: true, lastSeenAt: s.nowMillis - 10 * 60 * 1000 },
    ];
    assert.ok(has(runIntegrityChecks(s), 'session_stale'));
  });

  it('gps zero coords flagged', () => {
    const s = healthySnapshot();
    s.driverLocations = [{ id: 'g1', latitude: 0, longitude: 0, timestamp: s.nowMillis }];
    assert.ok(has(runIntegrityChecks(s), 'location_zero_coords'));
  });
});

describe('runIntegrityChecks — remote config', () => {
  it('out-of-range and reset<enter flagged', () => {
    const s = healthySnapshot();
    s.remoteConfig.autoCloseRadiusMeters = 10; // below min 20
    s.remoteConfig.autoCloseResetRadiusMeters = 5; // below radius and min
    const out = runIntegrityChecks(s);
    assert.ok(has(out, 'remote_config_invalid'));
    assert.ok(has(out, 'remote_config_reset_below_enter'));
  });
});

describe('helpers', () => {
  it('fingerprint is deterministic and 40 chars', () => {
    const a = fingerprint('c1', 'invoice', 'i1', 'code');
    const b = fingerprint('c1', 'invoice', 'i1', 'code');
    const c = fingerprint('c1', 'invoice', 'i2', 'code');
    assert.equal(a, b);
    assert.notEqual(a, c);
    assert.equal(a.length, 40);
  });

  it('invoiceSubtotal applies discount', () => {
    const v = invoiceSubtotal({ items: [{ quantity: 2, pricePerUnit: 100 }], discount: 10 });
    assert.equal(v, 180);
  });

  it('validateRemoteConfig detects bgNoLock', () => {
    const r = validateRemoteConfig({
      backgroundAutoCloseEnabled: true,
      driverDeviceSessionLockEnabled: false,
    });
    assert.equal(r.bgNoLock, true);
  });

  it('summarizeBySeverity counts', () => {
    const counts = summarizeBySeverity([
      { severity: 'critical' }, { severity: 'critical' }, { severity: 'low' },
    ]);
    assert.deepEqual(counts, { critical: 2, high: 0, medium: 0, low: 1 });
  });
});
