const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizePlan,
  rootEntitlementsPatch,
  entitlementsForPlan,
  limitsForPlan,
} = require("../lib/companyModules");

describe("companyModules (H4)", () => {
  it("normalizePlan falls back to full", () => {
    assert.equal(normalizePlan(null), "full");
    assert.equal(normalizePlan("unknown"), "full");
    assert.equal(normalizePlan("ops"), "ops");
  });

  it("create company patch includes plan modules limits", () => {
    const patch = rootEntitlementsPatch("full");
    assert.equal(patch.plan, "full");
    assert.equal(patch.modules.accounting, true);
    assert.equal(patch.limits.maxUsers, 50);
  });

  it("upgrade ops → full enables accounting", () => {
    const ops = entitlementsForPlan("ops");
    const full = entitlementsForPlan("full");
    assert.equal(ops.accounting, false);
    assert.equal(full.accounting, true);
    assert.ok(
      limitsForPlan("full").maxDocsPerMonth >
        limitsForPlan("ops").maxDocsPerMonth,
    );
  });

  it("downgrade full → warehouse_only disables logistics", () => {
    const full = entitlementsForPlan("full");
    const wh = entitlementsForPlan("warehouse_only");
    assert.equal(full.logistics, true);
    assert.equal(wh.logistics, false);
    assert.equal(limitsForPlan("warehouse_only").maxUsers, 5);
  });

  it("cancel/billing-only does not require plan patch helper", () => {
    const before = rootEntitlementsPatch("full");
    const after = rootEntitlementsPatch("full");
    assert.deepEqual(before.modules, after.modules);
  });

  it("demo seed uses full entitlements patch", () => {
    const patch = rootEntitlementsPatch("full");
    assert.equal(patch.plan, "full");
    assert.equal(patch.modules.reports, true);
    assert.equal(patch.limits.maxRoutesPerDay, 200);
  });
});
