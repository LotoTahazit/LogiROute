const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  evaluateBilling,
  billingAllowsAccess,
} = require("../lib/billingState");

const now = new Date("2026-06-21T12:00:00Z");

function company(overrides) {
  return {
    gracePeriodDays: 7,
    ...overrides,
  };
}

describe("billingState", () => {
  it("trial active allows access", () => {
    const trialUntil = new Date("2026-06-26T12:00:00Z");
    assert.equal(
      billingAllowsAccess(
        company({ billingStatus: "trial", trialUntil }),
        now
      ),
      true
    );
  });

  it("trial expired but grace valid allows access", () => {
    const trialUntil = new Date("2026-06-20T12:00:00Z");
    const eval = evaluateBilling(
      company({ billingStatus: "trial", trialUntil }),
      now
    );
    assert.equal(eval.allowsAccess, true);
    assert.equal(eval.displayPhase, "grace");
  });

  it("grace expired denies access", () => {
    const trialUntil = new Date("2026-06-01T12:00:00Z");
    assert.equal(
      billingAllowsAccess(
        company({ billingStatus: "trial", trialUntil }),
        now
      ),
      false
    );
  });

  it("grace status with valid paidUntil allows access", () => {
    const paidUntil = new Date("2026-06-19T12:00:00Z");
    assert.equal(
      billingAllowsAccess(
        company({ billingStatus: "grace", paidUntil }),
        now
      ),
      true
    );
  });

  it("suspended and cancelled deny access", () => {
    assert.equal(
      billingAllowsAccess(company({ billingStatus: "suspended" }), now),
      false
    );
    assert.equal(
      billingAllowsAccess(company({ billingStatus: "cancelled" }), now),
      false
    );
  });

  it("missing billing fields fail closed", () => {
    assert.equal(billingAllowsAccess(null, now), false);
    assert.equal(billingAllowsAccess({ billingStatus: "" }, now), false);
    assert.equal(
      billingAllowsAccess({ billingStatus: "trial" }, now),
      false
    );
  });
});
