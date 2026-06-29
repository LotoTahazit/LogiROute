const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  DEMO_COMPANY_ID,
  assertDemoCompanyId,
  assertDemoCompanyDoc,
  classifyDocForStrictDelete,
  buildPurgePaths,
} = require("../demoSeedSafety");

describe("demoSeedSafety", () => {
  it("rejects non-demo companyId", () => {
    assert.throws(() => assertDemoCompanyId("acme-corp"), /demo-foods-israel/);
  });

  it("allows only demo-foods-israel", () => {
    assert.doesNotThrow(() => assertDemoCompanyId(DEMO_COMPANY_ID));
  });

  it("rejects company without demoCompany flag", () => {
    assert.throws(
      () =>
        assertDemoCompanyDoc({
          id: DEMO_COMPANY_ID,
          exists: true,
          data: () => ({ demoCompany: false }),
        }),
      /demoCompany/,
    );
  });

  it("classifyDocForStrictDelete requires isDemo true", () => {
    assert.equal(classifyDocForStrictDelete({ isDemo: true }).deletable, true);
    assert.equal(classifyDocForStrictDelete({ isDemo: false }).deletable, false);
    assert.equal(classifyDocForStrictDelete({}).deletable, false);
  });

  it("buildPurgePaths only for demo company id", () => {
    assert.throws(() => buildPurgePaths("other"));
    const paths = buildPurgePaths(DEMO_COMPANY_ID);
    assert.ok(paths.strict.length > 0);
    assert.ok(paths.aux.length > 0);
    assert.ok(
      paths.strict.every((p) => p.startsWith(`companies/${DEMO_COMPANY_ID}/`)),
    );
  });
});
