const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const greeninvoice = require("../accounting/adapters/greeninvoice");
const icount = require("../accounting/adapters/icount");

describe("accounting adapters", () => {
  it("greeninvoice rejects missing credentials", async () => {
    const r = await greeninvoice.createDocument({ payload: {}, credentials: {} });
    assert.equal(r.ok, false);
    assert.equal(r.reason, "missing_credentials");
  });

  it("greeninvoice testCredentials rejects missing keys", async () => {
    const r = await greeninvoice.testCredentials({ credentials: {} });
    assert.equal(r.ok, false);
  });

  it("icount rejects missing token", async () => {
    const r = await icount.createDocument({ payload: {}, credentials: {} });
    assert.equal(r.ok, false);
    assert.equal(r.reason, "missing_credentials");
  });
});
