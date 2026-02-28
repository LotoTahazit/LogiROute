const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { serverTimestamp } = require("firebase/firestore");

// ====== CONFIG: реальные пути проекта ======
// users и companies — top-level коллекции (без _root)
// _root используется ВНУТРИ company subtree: companies/{id}/logistics/_root/...
const USERS_COL = "users";
const COMPANIES_COL = "companies";
// =======================================================

let testEnv;

function rulesPath() {
  return path.join(process.cwd(), "firestore.rules");
}

async function seedBaseData() {
  const adminDb = testEnv.unauthenticatedContext().firestore(); // bypass rules via env.withSecurityRulesDisabled
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // companies
    await db.doc(`${COMPANIES_COL}/c1`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Company 1",
    });
    await db.doc(`${COMPANIES_COL}/c2`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Company 2",
    });
    await db.doc(`${COMPANIES_COL}/cBlocked`).set({
      billingStatus: "suspended",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Blocked Co",
    });

    // users
    await db.doc(`${USERS_COL}/u_super`).set({ role: "super_admin", companyId: "c1" });
    await db.doc(`${USERS_COL}/u_disp_c1`).set({ role: "dispatcher", companyId: "c1" });
    await db.doc(`${USERS_COL}/u_driver_c1`).set({ role: "driver", companyId: "c1" });
    await db.doc(`${USERS_COL}/u_disp_c2`).set({ role: "dispatcher", companyId: "c2" });
    await db.doc(`${USERS_COL}/u_warehouse_c1`).set({ role: "warehouse_keeper", companyId: "c1" });

    // sample docs in company subtree (с _root namespace)
    await db.doc(`${COMPANIES_COL}/c1/logistics/_root/delivery_points/p1`).set({
      status: "new",
      statusUpdatedAt: 0,
      title: "Point 1",
      address: "Test",
      driverId: "u_driver_c1",
      driverName: "Driver 1",
    });

    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/counters/routes`).set({ lastNumber: 10 });

    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/invoices/inv1`).set({
      companyId: "c1",
      total: 100,
      createdAt: 123,
      createdBy: "u_disp_c1",
    });

    // issued invoice — для тестов immutable server fields
    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/invoices/inv_issued`).set({
      companyId: "c1",
      total: 200,
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "issued",
      sequentialNumber: 42,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "abc123hash",
    });

    // draft invoice — для тестов client cannot flip to issued
    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/invoices/inv_draft`).set({
      companyId: "c1",
      total: 50,
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "draft",
      sequentialNumber: 0,
    });

    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/integrity_chain/a1`).set({
      action: "seed",
      createdAt: 1,
    });

    // clients, prices, warehouse docs for companyIdMatchesPath tests
    await db.doc(`${COMPANIES_COL}/c1/logistics/_root/clients/cl1`).set({
      companyId: "c1", name: "Client 1",
    });
    await db.doc(`${COMPANIES_COL}/c1/logistics/_root/prices/pr1`).set({
      companyId: "c1", type: "box", number: "350", price: 10,
    });
    await db.doc(`${COMPANIES_COL}/c1/warehouse/_root/box_types/bt1`).set({
      companyId: "c1", type: "בביע", number: "350",
    });
    await db.doc(`${COMPANIES_COL}/c1/warehouse/_root/product_types/pt1`).set({
      companyId: "c1", name: "Type 1",
    });

    // blocked company subtree sample
    await db.doc(`${COMPANIES_COL}/cBlocked/logistics/_root/delivery_points/pb1`).set({
      status: "new",
      statusUpdatedAt: 0,
    });

    // === hasModule test companies ===
    // logistics disabled
    await db.doc(`${COMPANIES_COL}/cNoLog`).set({
      billingStatus: "active",
      modules: { logistics: false, warehouse: true, dispatcher: true, accounting: true },
      name: "No Logistics Co",
    });
    // accounting disabled
    await db.doc(`${COMPANIES_COL}/cNoAcc`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: false },
      name: "No Accounting Co",
    });
    // users for module-disabled companies
    await db.doc(`${USERS_COL}/u_disp_noLog`).set({ role: "dispatcher", companyId: "cNoLog" });
    await db.doc(`${USERS_COL}/u_disp_noAcc`).set({ role: "dispatcher", companyId: "cNoAcc" });
    // docs in disabled-module branches
    await db.doc(`${COMPANIES_COL}/cNoLog/logistics/_root/delivery_points/p1`).set({ status: "new" });
    await db.doc(`${COMPANIES_COL}/cNoAcc/accounting/_root/invoices/inv1`).set({ total: 10 });

    // === canUseModule RBAC tests ===
    // admin user for c1
    await db.doc(`${USERS_COL}/u_admin_c1`).set({ role: "admin", companyId: "c1" });
    // company with accounting disabled (for admin module-disabled test)
    await db.doc(`${COMPANIES_COL}/cNoAccAdmin`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: false },
      name: "No Accounting Admin Co",
    });
    await db.doc(`${USERS_COL}/u_admin_noAcc`).set({ role: "admin", companyId: "cNoAccAdmin" });
    await db.doc(`${COMPANIES_COL}/cNoAccAdmin/accounting/_root/invoices/inv1`).set({ total: 50 });
    // seed for Layer 6 write tests
    await db.doc(`${COMPANIES_COL}/cNoAcc/accounting/_root/integrity_chain/ch1`).set({ action: "seed" });
    await db.doc(`${COMPANIES_COL}/cNoAccAdmin/accounting/_root/receipts/r1`).set({ total: 10 });

    // === Dispatcher module tests ===
    await db.doc(`${COMPANIES_COL}/c1/dispatcher/_root/driver_locations/dl1`).set({
      driverId: "u_driver_c1", lat: 32.0, lng: 34.8,
    });
    // company with dispatcher disabled
    await db.doc(`${COMPANIES_COL}/cNoDisp`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: false, accounting: true },
      name: "No Dispatcher Co",
    });
    await db.doc(`${USERS_COL}/u_disp_noDisp`).set({ role: "dispatcher", companyId: "cNoDisp" });
    await db.doc(`${COMPANIES_COL}/cNoDisp/dispatcher/_root/driver_locations/dl1`).set({
      driverId: "test", lat: 0, lng: 0,
    });

    // === Warehouse fine-grained tests ===
    await db.doc(`${COMPANIES_COL}/c1/warehouse/_root/inventory/inv_item1`).set({
      productCode: "P001", type: "בקבוק", number: "500",
      quantity: 100, quantityPerPallet: 50, lastUpdated: Date.now(), updatedBy: "seed",
    });
    await db.doc(`${COMPANIES_COL}/c1/warehouse/_root/inventory_counts/ic1`).set({
      status: "in_progress", startedAt: Date.now(), userName: "Tester",
      items: [], summary: { totalItems: 0, checkedItems: 0 },
    });
    await db.doc(`${COMPANIES_COL}/c1/warehouse/_root/inventory_history/ih1`).set({
      productCode: "P001", type: "בקבוק", number: "500",
      quantityChange: 10, quantityBefore: 90, quantityAfter: 100,
      timestamp: Date.now(), userName: "seed", action: "add",
    });
    // company with warehouse disabled
    await db.doc(`${COMPANIES_COL}/cNoWh`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: false, dispatcher: true, accounting: true },
      name: "No Warehouse Co",
    });
    await db.doc(`${USERS_COL}/u_wh_noWh`).set({ role: "warehouse_keeper", companyId: "cNoWh" });
    await db.doc(`${COMPANIES_COL}/cNoWh/warehouse/_root/inventory/i1`).set({ quantity: 1 });

    // === Accounting receipts/credit_notes tests ===
    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/receipts/r1`).set({
      companyId: "c1", total: 500, createdAt: 111, createdBy: "u_admin_c1",
    });
    await db.doc(`${COMPANIES_COL}/c1/accounting/_root/credit_notes/cn1`).set({
      companyId: "c1", total: 200, createdAt: 222, createdBy: "u_admin_c1",
    });

    // === Cross-module audit log tests ===
    await db.doc(`${COMPANIES_COL}/c1/audit/aud_seed`).set({
      moduleKey: "accounting", type: "invoice_issued",
      entity: { collection: "invoices", docId: "inv1" },
      createdBy: "u_admin_c1", createdAt: Date.now(),
    });

    // === Billing state machine tests ===
    // trial company (trialUntil in the future)
    await db.doc(`${COMPANIES_COL}/cTrial`).set({
      billingStatus: "trial",
      trialUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // +30 days
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Trial Co",
    });
    await db.doc(`${USERS_COL}/u_disp_trial`).set({ role: "dispatcher", companyId: "cTrial" });
    await db.doc(`${COMPANIES_COL}/cTrial/logistics/_root/clients/cl1`).set({
      companyId: "cTrial", name: "Trial Client",
    });

    // trial expired company (trialUntil in the past)
    await db.doc(`${COMPANIES_COL}/cTrialExp`).set({
      billingStatus: "trial",
      trialUntil: new Date(Date.now() - 24 * 60 * 60 * 1000), // -1 day
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Trial Expired Co",
    });
    await db.doc(`${USERS_COL}/u_disp_trialExp`).set({ role: "dispatcher", companyId: "cTrialExp" });
    await db.doc(`${COMPANIES_COL}/cTrialExp/logistics/_root/clients/cl1`).set({
      companyId: "cTrialExp", name: "Expired Client",
    });

    // grace company
    await db.doc(`${COMPANIES_COL}/cGrace`).set({
      billingStatus: "grace",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Grace Co",
    });
    await db.doc(`${USERS_COL}/u_disp_grace`).set({ role: "dispatcher", companyId: "cGrace" });
    await db.doc(`${COMPANIES_COL}/cGrace/logistics/_root/clients/cl1`).set({
      companyId: "cGrace", name: "Grace Client",
    });

    // suspended company (already have cBlocked with suspended)
    // user for suspended company
    await db.doc(`${USERS_COL}/u_disp_blocked`).set({ role: "dispatcher", companyId: "cBlocked" });

    // cancelled company
    await db.doc(`${COMPANIES_COL}/cCancelled`).set({
      billingStatus: "cancelled",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Cancelled Co",
    });
    await db.doc(`${USERS_COL}/u_disp_cancelled`).set({ role: "dispatcher", companyId: "cCancelled" });
    await db.doc(`${COMPANIES_COL}/cCancelled/logistics/_root/clients/cl1`).set({
      companyId: "cCancelled", name: "Cancelled Client",
    });

    // === Security audit: seed data для новых коллекций ===
    // notification для тестов update
    await db.doc(`${COMPANIES_COL}/c1/notifications/notif1`).set({
      type: "billing_grace",
      title: "תקופת חסד",
      body: "החשבון שלך נכנס לתקופת חסד",
      severity: "warning",
      read: false,
      createdAt: new Date(),
    });

    // payment_event для тестов read
    await db.doc(`${COMPANIES_COL}/c1/payment_events/pe1`).set({
      provider: "stripe",
      amount: 499,
      currency: "ILS",
      processedAt: new Date(),
    });

    // checkout_session для тестов
    await db.doc(`${COMPANIES_COL}/c1/checkout_sessions/cs1`).set({
      provider: "stripe",
      plan: "full",
      status: "pending",
      createdBy: "u_admin_c1",
      createdAt: new Date(),
    });

    // export_preset для тестов
    await db.doc(`${COMPANIES_COL}/c1/export_presets/ep1`).set({
      name: "Hashavshevet",
      format: "hashavshevet",
      encoding: "windows1255",
    });

    // === Accounting period lock tests ===
    // Company with accountingLockedUntil = 2026-01-31
    const lockedDate = new Date("2026-01-31T23:59:59Z");
    await db.doc(`${COMPANIES_COL}/cLocked`).set({
      billingStatus: "active",
      modules: { logistics: true, warehouse: true, dispatcher: true, accounting: true },
      name: "Locked Period Co",
      accountingLockedUntil: lockedDate,
    });
    await db.doc(`${USERS_COL}/u_admin_locked`).set({ role: "admin", companyId: "cLocked" });
    await db.doc(`${USERS_COL}/u_disp_locked`).set({ role: "dispatcher", companyId: "cLocked" });
    // invoice in locked period (Jan 15)
    await db.doc(`${COMPANIES_COL}/cLocked/accounting/_root/invoices/inv_locked`).set({
      companyId: "cLocked", total: 100, documentType: "invoice",
      deliveryDate: new Date("2026-01-15T00:00:00Z"),
      createdAt: 111, createdBy: "u_admin_locked",
    });
    // invoice in open period (Feb 5)
    await db.doc(`${COMPANIES_COL}/cLocked/accounting/_root/invoices/inv_open`).set({
      companyId: "cLocked", total: 200, documentType: "invoice",
      deliveryDate: new Date("2026-02-05T00:00:00Z"),
      createdAt: 222, createdBy: "u_admin_locked",
    });
    // credit note in locked period (Jan 10)
    await db.doc(`${COMPANIES_COL}/cLocked/accounting/_root/credit_notes/cn_locked`).set({
      companyId: "cLocked", total: 50,
      deliveryDate: new Date("2026-01-10T00:00:00Z"),
      createdAt: 333, createdBy: "u_admin_locked",
    });
    // receipt in locked period
    await db.doc(`${COMPANIES_COL}/cLocked/accounting/_root/receipts/r_locked`).set({
      companyId: "cLocked", total: 75,
      deliveryDate: new Date("2026-01-20T00:00:00Z"),
      createdAt: 444, createdBy: "u_admin_locked",
    });
  });

  // just to silence unused
  void adminDb;
}

function authed(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-rules-tests",
    firestore: { rules: fs.readFileSync(rulesPath(), "utf8") },
  });

  await seedBaseData();
});

test.after(async () => {
  await testEnv.cleanup();
});

test("Company isolation: member can read own company subtree", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(db.doc(`${COMPANIES_COL}/c1/logistics/_root/delivery_points/p1`).get());
});

test("Company isolation: member cannot read чужую компанию", async () => {
  const db = authed("u_disp_c1");
  await assertFails(db.doc(`${COMPANIES_COL}/c2/logistics/_root/delivery_points/any`).get());
});

test("Billing blocked: member cannot access blocked company", async () => {
  // ВАЖНО: это тест на включённый billingActive (billingStatus == active)
  const db = authed("u_disp_c1");
  await assertFails(db.doc(`${COMPANIES_COL}/cBlocked/logistics/_root/delivery_points/pb1`).get());
});

test("Super admin bypass: super_admin can read anything", async () => {
  const db = authed("u_super");
  await assertSucceeds(db.doc(`${COMPANIES_COL}/c2/logistics/_root/delivery_points/any`).get());
  await assertSucceeds(db.doc(`${COMPANIES_COL}/cBlocked/logistics/_root/delivery_points/pb1`).get());
});

test("Driver status-only: driver can update ONLY status(+allowed fields)", async () => {
  const db = authed("u_driver_c1");
  const ref = db.doc(`${COMPANIES_COL}/c1/logistics/_root/delivery_points/p1`);

  // ✅ allowed: status update
  await assertSucceeds(ref.update({ status: "arrived", updatedByUid: "u_driver_c1", updatedAt: Date.now() }));

  // ❌ forbidden: touching other field
  await assertFails(ref.update({ title: "Hacked" }));
});

test("Counters +1 only: can increment by exactly 1", async () => {
  const db = authed("u_disp_c1");
  const ref = db.doc(`${COMPANIES_COL}/c1/accounting/_root/counters/routes`);

  // read current
  const snap = await ref.get();
  assert.equal(snap.exists, true);
  const v = snap.data().lastNumber;

  // ✅ +1
  await assertSucceeds(ref.update({ lastNumber: v + 1 }));

  // ❌ +2
  await assertFails(ref.update({ lastNumber: v + 4 }));
});

test("Audit (integrity_chain) append-only: create ok, update/delete forbidden", async () => {
  const db = authed("u_disp_c1");
  const ref = db.doc(`${COMPANIES_COL}/c1/accounting/_root/integrity_chain/a_new`);

  // ✅ create
  await assertSucceeds(ref.set({ action: "created", createdAt: Date.now() }));

  // ❌ update
  await assertFails(ref.update({ action: "changed" }));

  // ❌ delete
  await assertFails(ref.delete());
});

test("Invoices: delete forbidden", async () => {
  const db = authed("u_disp_c1");
  const ref = db.doc(`${COMPANIES_COL}/c1/accounting/_root/invoices/inv1`);
  await assertFails(ref.delete());
});

// =========================================================
// Layer 2: hasModule tests
// =========================================================

test("Modules: logistics disabled denies access to logistics/_root", async () => {
  const db = authed("u_disp_noLog");
  await assertFails(
    db.doc(`${COMPANIES_COL}/cNoLog/logistics/_root/delivery_points/p1`).get()
  );
});

test("Modules: accounting disabled denies access to accounting/_root", async () => {
  const db = authed("u_disp_noAcc");
  await assertFails(
    db.doc(`${COMPANIES_COL}/cNoAcc/accounting/_root/invoices/inv1`).get()
  );
});

test("Modules: super_admin bypass still allows access even if module disabled", async () => {
  const db = authed("u_super");
  await assertSucceeds(
    db.doc(`${COMPANIES_COL}/cNoLog/logistics/_root/delivery_points/p1`).get()
  );
  await assertSucceeds(
    db.doc(`${COMPANIES_COL}/cNoAcc/accounting/_root/invoices/inv1`).get()
  );
});

// =========================================================
// Layer 3: data integrity — companyId must match path
// =========================================================

test("delivery_points: dispatcher create denied if companyId in doc != path companyId", async () => {
  const db = authed("u_disp_c1");

  await assertFails(
    db.doc(`companies/c1/logistics/_root/delivery_points/bad1`).set({
      companyId: "c2",
      status: "new",
      driverId: "d1",
      driverName: "Driver",
      address: "X",
      createdAt: Date.now(),
    })
  );
});

test("delivery_points: dispatcher update denied if tries to change companyId", async () => {
  const db = authed("u_disp_c1");
  const ref = db.doc(`companies/c1/logistics/_root/delivery_points/p1`);

  await assertFails(
    ref.update({
      companyId: "c2",
    })
  );
});

// =========================================================
// Layer 3 continued: companyIdMatchesPath on invoices, clients, prices, warehouse
// =========================================================

// --- Invoices ---
test("invoices: create denied if companyId != path companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/badInv`).set({
      companyId: "c2", total: 1, documentType: "delivery", deliveryDate: new Date("2026-03-01"),
    })
  );
});

test("invoices: update denied if tries to change companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).update({
      companyId: "c2",
    })
  );
});

// --- Clients ---
test("clients: create denied if companyId != path companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/clients/badCl`).set({
      companyId: "c2", name: "X",
    })
  );
});

test("clients: update denied if tries to change companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/clients/cl1`).update({
      companyId: "c2",
    })
  );
});

// --- Prices ---
test("prices: create denied if companyId != path companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/prices/badPr`).set({
      companyId: "c2", type: "box", number: "350", price: 1,
    })
  );
});

test("prices: update denied if tries to change companyId", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/prices/pr1`).update({
      companyId: "c2",
    })
  );
});

// --- Warehouse wildcard (box_types + product_types) ---
test("warehouse box_types: create denied if companyId != path companyId", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/box_types/badBt`).set({
      companyId: "c2", type: "בביע", number: "999",
    })
  );
});

test("warehouse product_types: update denied if tries to change companyId", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/product_types/pt1`).update({
      companyId: "c2",
    })
  );
});

// =========================================================
// Layer 4: immutable fields — createdAt/createdBy on invoices
// =========================================================

test("invoices: update denied if tries to change createdAt", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).update({
      createdAt: Date.now(),
    })
  );
});

test("invoices: update denied if tries to change createdBy", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).update({
      createdBy: "someone_else",
    })
  );
});

// =========================================================
// Layer 5: canUseModule RBAC × Module matrix
// =========================================================

test("RBAC: driver cannot read accounting invoices", async () => {
  const db = authed("u_driver_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).get()
  );
});

test("RBAC: warehouse_keeper cannot read logistics clients", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/clients/cl1`).get()
  );
});

test("RBAC: dispatcher can read logistics but not warehouse", async () => {
  const db = authed("u_disp_c1");
  // ✅ logistics — dispatcher allowed
  await assertSucceeds(
    db.doc(`companies/c1/logistics/_root/clients/cl1`).get()
  );
  // ❌ warehouse — dispatcher not in warehouse matrix
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/box_types/bt1`).get()
  );
});

test("RBAC: admin can access all enabled modules", async () => {
  const db = authed("u_admin_c1");
  // ✅ logistics
  await assertSucceeds(
    db.doc(`companies/c1/logistics/_root/clients/cl1`).get()
  );
  // ✅ accounting
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).get()
  );
  // ✅ warehouse
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/box_types/bt1`).get()
  );
});

test("RBAC: modules.accounting=false blocks even admin", async () => {
  const db = authed("u_admin_noAcc");
  await assertFails(
    db.doc(`companies/cNoAccAdmin/accounting/_root/invoices/inv1`).get()
  );
});

test("RBAC: super_admin bypasses all module+role checks", async () => {
  const db = authed("u_super");
  // super_admin can access everything regardless of role matrix
  await assertSucceeds(
    db.doc(`companies/c1/logistics/_root/clients/cl1`).get()
  );
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).get()
  );
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/box_types/bt1`).get()
  );
  // even disabled modules
  await assertSucceeds(
    db.doc(`companies/cNoAccAdmin/accounting/_root/invoices/inv1`).get()
  );
});

// =========================================================
// Layer 6: canWriteModule — unified write gate
// =========================================================

// --- cross-module write denial ---
test("L6 write: dispatcher cannot write to warehouse box_types", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/box_types/newBt`).set({
      companyId: "c1", type: "test", number: "1",
    })
  );
});

test("L6 write: warehouse_keeper cannot write to logistics clients", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/clients/newCl`).set({
      companyId: "c1", name: "Test",
    })
  );
});

test("L6 write: driver cannot create accounting integrity_chain", async () => {
  const db = authed("u_driver_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_chain/drv1`).set({
      action: "hack", createdAt: Date.now(),
    })
  );
});

// --- positive: admin can write to accounting ---
test("L6 write: admin can create integrity_chain in accounting", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/integrity_chain/adm1`).set({
      action: "admin_created", createdAt: Date.now(),
    })
  );
});

// --- module disabled blocks write even for admin ---
test("L6 write: accounting disabled blocks admin create receipt", async () => {
  const db = authed("u_admin_noAcc");
  await assertFails(
    db.doc(`companies/cNoAccAdmin/accounting/_root/receipts/newR`).set({
      total: 100,
    })
  );
});

test("L6 write: accounting disabled blocks dispatcher create integrity_chain", async () => {
  const db = authed("u_disp_noAcc");
  await assertFails(
    db.doc(`companies/cNoAcc/accounting/_root/integrity_chain/newCh`).set({
      action: "test", createdAt: Date.now(),
    })
  );
});

// --- printEvents ---
test("L6 write: printEvents create ok if printedBy == uid", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv1/printEvents/pe1`).set({
      documentId: "inv1",
      printedBy: "u_disp_c1",
      mode: "original",
      copiesCount: 1,
    })
  );
});

test("L6 write: printEvents create denied if printedBy != uid", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1/printEvents/pe2`).set({
      documentId: "inv1",
      printedBy: "someone_else",
      mode: "original",
      copiesCount: 1,
    })
  );
});

test("L6 write: super_admin can write anywhere", async () => {
  const db = authed("u_super");
  // warehouse
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/box_types/su_bt`).set({
      companyId: "c1", type: "super", number: "999",
    })
  );
  // logistics
  await assertSucceeds(
    db.doc(`companies/c1/logistics/_root/clients/su_cl`).set({
      companyId: "c1", name: "Super Client",
    })
  );
  // accounting (even disabled)
  await assertSucceeds(
    db.doc(`companies/cNoAccAdmin/accounting/_root/integrity_chain/su_ch`).set({
      action: "super_bypass", createdAt: Date.now(),
    })
  );
});

// =========================================================
// Dispatcher module — canUseModule/canWriteModule contract
// =========================================================

test("Dispatcher: dispatcher can read dispatcher/_root", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/dispatcher/_root/driver_locations/dl1`).get()
  );
});

test("Dispatcher: driver can read dispatcher/_root", async () => {
  const db = authed("u_driver_c1");
  await assertSucceeds(
    db.doc(`companies/c1/dispatcher/_root/driver_locations/dl1`).get()
  );
});

test("Dispatcher: driver can write to dispatcher/_root", async () => {
  const db = authed("u_driver_c1");
  await assertSucceeds(
    db.doc(`companies/c1/dispatcher/_root/driver_locations/drv_new`).set({
      driverId: "u_driver_c1", lat: 32.1, lng: 34.9,
    })
  );
});

test("Dispatcher: warehouse_keeper cannot read dispatcher/_root", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/dispatcher/_root/driver_locations/dl1`).get()
  );
});

test("Dispatcher: modules.dispatcher=false blocks dispatcher read", async () => {
  const db = authed("u_disp_noDisp");
  await assertFails(
    db.doc(`companies/cNoDisp/dispatcher/_root/driver_locations/dl1`).get()
  );
});

test("Dispatcher: modules.dispatcher=false blocks dispatcher write", async () => {
  const db = authed("u_disp_noDisp");
  await assertFails(
    db.doc(`companies/cNoDisp/dispatcher/_root/driver_locations/new1`).set({
      driverId: "test", lat: 1, lng: 1,
    })
  );
});

test("Dispatcher: super_admin bypasses disabled dispatcher module", async () => {
  const db = authed("u_super");
  await assertSucceeds(
    db.doc(`companies/cNoDisp/dispatcher/_root/driver_locations/dl1`).get()
  );
});

// =========================================================
// Logistics module — prices delete contract
// =========================================================

test("Logistics: dispatcher cannot delete price", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/logistics/_root/prices/pr1`).delete()
  );
});

test("Logistics: admin can delete price", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/logistics/_root/prices/pr1`).delete()
  );
});

// =========================================================
// Warehouse module — fine-grained rules (no wildcard)
// =========================================================

// --- inventory_history: append-only ---
test("Warehouse: warehouse_keeper can create inventory_history", async () => {
  const db = authed("u_warehouse_c1");
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/inventory_history/ih_new`).set({
      productCode: "P002", type: "test", number: "1",
      quantityChange: 5, quantityBefore: 0, quantityAfter: 5,
      timestamp: Date.now(), userName: "keeper", action: "add",
    })
  );
});

test("Warehouse: inventory_history update forbidden", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/inventory_history/ih1`).update({
      quantityChange: 999,
    })
  );
});

test("Warehouse: inventory_history delete forbidden", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/inventory_history/ih1`).delete()
  );
});

// --- inventory_counts: create+update, no delete ---
test("Warehouse: warehouse_keeper can create inventory_count", async () => {
  const db = authed("u_warehouse_c1");
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/inventory_counts/ic_new`).set({
      status: "in_progress", startedAt: Date.now(), userName: "keeper",
      items: [], summary: { totalItems: 0, checkedItems: 0 },
    })
  );
});

test("Warehouse: warehouse_keeper can update inventory_count status", async () => {
  const db = authed("u_warehouse_c1");
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/inventory_counts/ic1`).update({
      status: "completed",
    })
  );
});

test("Warehouse: inventory_counts delete forbidden", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/inventory_counts/ic1`).delete()
  );
});

// --- inventory: writable snapshot ---
test("Warehouse: warehouse_keeper can update inventory quantity", async () => {
  const db = authed("u_warehouse_c1");
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/inventory/inv_item1`).update({
      quantity: 95, lastUpdated: Date.now(), updatedBy: "keeper",
    })
  );
});

test("Warehouse: warehouse_keeper cannot delete inventory (admin only)", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/inventory/inv_item1`).delete()
  );
});

test("Warehouse: admin can delete inventory item", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/warehouse/_root/inventory/inv_item1`).delete()
  );
});

// --- cross-module denial ---
test("Warehouse: dispatcher cannot write to inventory", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/inventory/disp_item`).set({
      productCode: "X", quantity: 1,
    })
  );
});

// --- module disabled ---
test("Warehouse: module disabled blocks warehouse_keeper read", async () => {
  const db = authed("u_wh_noWh");
  await assertFails(
    db.doc(`companies/cNoWh/warehouse/_root/inventory/i1`).get()
  );
});

test("Warehouse: module disabled blocks warehouse_keeper write", async () => {
  const db = authed("u_wh_noWh");
  await assertFails(
    db.doc(`companies/cNoWh/warehouse/_root/inventory/new1`).set({
      productCode: "X", quantity: 1,
    })
  );
});

// --- wildcard closed: unknown warehouse subcollection denied ---
test("Warehouse: write to unknown subcollection denied", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/warehouse/_root/unknown_collection/doc1`).set({
      data: "hack",
    })
  );
});

// =========================================================
// Accounting module — receipts + credit_notes final closure
// =========================================================

test("Accounting: admin can create receipt", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/receipts/r_new`).set({
      companyId: "c1", total: 300, deliveryDate: new Date("2026-03-01"), createdAt: Date.now(), createdBy: "u_admin_c1",
    })
  );
});

test("Accounting: receipt create denied if companyId != path", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/receipts/r_bad`).set({
      companyId: "c2", total: 100, deliveryDate: new Date("2026-03-01"), createdAt: Date.now(), createdBy: "u_admin_c1",
    })
  );
});

test("Accounting: receipt update denied if createdBy changed", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/receipts/r1`).update({
      createdBy: "someone_else",
    })
  );
});

test("Accounting: credit_note update denied if createdAt changed", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/credit_notes/cn1`).update({
      createdAt: 999999,
    })
  );
});

test("Accounting: module disabled blocks admin create receipt", async () => {
  const db = authed("u_admin_noAcc");
  await assertFails(
    db.doc(`companies/cNoAccAdmin/accounting/_root/receipts/r_blocked`).set({
      companyId: "cNoAccAdmin", total: 50, deliveryDate: new Date("2026-03-01"), createdAt: Date.now(), createdBy: "u_admin_noAcc",
    })
  );
});

// --- accounting catch-all: unknown subcollection denied ---
test("Accounting: write to unknown subcollection denied", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/unknown_stuff/doc1`).set({
      data: "hack",
    })
  );
});

// =========================================================
// Accounting module — remaining coverage (anchors, auditLog, invoices fine-grained)
// =========================================================

// --- integrity_anchors: append-only, admin-only ---
test("Accounting: admin can create integrity_anchor", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/integrity_anchors/anc1`).set({
      hash: "abc123", createdAt: Date.now(),
    })
  );
});

test("Accounting: dispatcher cannot create integrity_anchor", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_anchors/anc2`).set({
      hash: "xyz", createdAt: Date.now(),
    })
  );
});

// --- invoices: dispatcher can only create delivery notes ---
test("Accounting: dispatcher can create delivery note", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv_del`).set({
      companyId: "c1", total: 50, documentType: "delivery",
      deliveryDate: new Date("2026-03-01"),
      createdAt: Date.now(), createdBy: "u_disp_c1",
    })
  );
});

test("Accounting: dispatcher cannot create non-delivery invoice", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_tax`).set({
      companyId: "c1", total: 100, documentType: "tax_invoice",
      deliveryDate: new Date("2026-03-01"),
      createdAt: Date.now(), createdBy: "u_disp_c1",
    })
  );
});

// --- dispatcher cannot update invoices (admin-only) ---
test("Accounting: dispatcher cannot update invoice", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv1`).update({
      total: 999,
    })
  );
});

// =========================================================
// Cross-module AUDIT LOG — /companies/{c}/audit/{eventId}
// =========================================================

function auditDoc(overrides = {}) {
  return {
    moduleKey: "dispatcher",
    type: "delivery_point_status_changed",
    entity: { collection: "delivery_points", docId: "p1" },
    createdBy: "u_disp_c1",
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

// ✅ dispatcher creates audit event for own module (dispatcher)
test("Audit: dispatcher can create audit event for moduleKey=dispatcher", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/audit/aud_disp1`).set(auditDoc())
  );
});

// ❌ cross-module: dispatcher cannot create audit for warehouse
test("Audit: dispatcher cannot create audit event for moduleKey=warehouse", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_cross1`).set(auditDoc({
      moduleKey: "warehouse",
      type: "inventory_adjusted",
      entity: { collection: "inventory", docId: "i1" },
    }))
  );
});

// ❌ cross-module: warehouse_keeper cannot create audit for logistics
test("Audit: warehouse_keeper cannot create audit event for moduleKey=logistics", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_cross2`).set(auditDoc({
      moduleKey: "logistics",
      type: "route_published",
      entity: { collection: "routes", docId: "r1" },
      createdBy: "u_warehouse_c1",
    }))
  );
});

// ❌ module disabled blocks create even for admin
test("Audit: module disabled blocks admin create audit event", async () => {
  const db = authed("u_admin_noAcc");
  await assertFails(
    db.doc(`companies/cNoAccAdmin/audit/aud_disabled`).set({
      moduleKey: "accounting",
      type: "invoice_issued",
      entity: { collection: "invoices", docId: "inv1" },
      createdBy: "u_admin_noAcc",
      createdAt: serverTimestamp(),
    })
  );
});

// ❌ createdBy != uid denied
test("Audit: create denied if createdBy != uid", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_baduid`).set(auditDoc({
      createdBy: "someone_else",
    }))
  );
});

// ❌ update/delete forbidden (append-only)
test("Audit: update and delete forbidden", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_seed`).update({ type: "hacked" })
  );
  await assertFails(
    db.doc(`companies/c1/audit/aud_seed`).delete()
  );
});

// ✅ read allowed for company member, ❌ denied for blocked billing
test("Audit: company member can read, blocked billing denied", async () => {
  const db = authed("u_disp_c1");
  // ✅ active company
  await assertSucceeds(
    db.doc(`companies/c1/audit/aud_seed`).get()
  );
  // ❌ blocked company (u_disp_c1 is member of c1, not cBlocked)
  await assertFails(
    db.doc(`companies/cBlocked/audit/any_doc`).get()
  );
});

// =========================================================
// Billing state machine — trial | active | grace | suspended | cancelled
// =========================================================

// ✅ trial (not expired): read + write allowed
test("Billing: trial (active) allows read and write", async () => {
  const db = authed("u_disp_trial");
  // read
  await assertSucceeds(
    db.doc(`companies/cTrial/logistics/_root/clients/cl1`).get()
  );
  // write
  await assertSucceeds(
    db.doc(`companies/cTrial/logistics/_root/clients/cl_new`).set({
      companyId: "cTrial", name: "New Client",
    })
  );
});

// ❌ trial expired: read and write blocked
test("Billing: trial expired blocks read and write", async () => {
  const db = authed("u_disp_trialExp");
  await assertFails(
    db.doc(`companies/cTrialExp/logistics/_root/clients/cl1`).get()
  );
  await assertFails(
    db.doc(`companies/cTrialExp/logistics/_root/clients/cl_new`).set({
      companyId: "cTrialExp", name: "X",
    })
  );
});

// ✅ grace: read + write allowed
test("Billing: grace allows read and write", async () => {
  const db = authed("u_disp_grace");
  await assertSucceeds(
    db.doc(`companies/cGrace/logistics/_root/clients/cl1`).get()
  );
  await assertSucceeds(
    db.doc(`companies/cGrace/logistics/_root/clients/cl_new`).set({
      companyId: "cGrace", name: "Grace New",
    })
  );
});

// ❌ suspended: read and write blocked
test("Billing: suspended blocks read and write", async () => {
  const db = authed("u_disp_blocked");
  await assertFails(
    db.doc(`companies/cBlocked/logistics/_root/delivery_points/pb1`).get()
  );
  await assertFails(
    db.doc(`companies/cBlocked/logistics/_root/clients/cl_new`).set({
      companyId: "cBlocked", name: "X",
    })
  );
});

// ❌ cancelled: read and write blocked
test("Billing: cancelled blocks read and write", async () => {
  const db = authed("u_disp_cancelled");
  await assertFails(
    db.doc(`companies/cCancelled/logistics/_root/clients/cl1`).get()
  );
  await assertFails(
    db.doc(`companies/cCancelled/logistics/_root/clients/cl_new`).set({
      companyId: "cCancelled", name: "X",
    })
  );
});

// ✅ super_admin bypasses all billing states
test("Billing: super_admin bypasses suspended and cancelled", async () => {
  const db = authed("u_super");
  // suspended
  await assertSucceeds(
    db.doc(`companies/cBlocked/logistics/_root/delivery_points/pb1`).get()
  );
  // cancelled
  await assertSucceeds(
    db.doc(`companies/cCancelled/logistics/_root/clients/cl1`).get()
  );
  // trial expired
  await assertSucceeds(
    db.doc(`companies/cTrialExp/logistics/_root/clients/cl1`).get()
  );
});

// =========================================================
// Accounting Period Lock — accountingLockedUntil
// =========================================================

// ❌ create invoice in locked period (deliveryDate=Jan 15, lockedUntil=Jan 31)
test("Period lock: create invoice in locked period denied", async () => {
  const db = authed("u_admin_locked");
  await assertFails(
    db.doc(`companies/cLocked/accounting/_root/invoices/inv_new_locked`).set({
      companyId: "cLocked", total: 100, documentType: "invoice",
      deliveryDate: new Date("2026-01-15T00:00:00Z"),
      createdAt: Date.now(), createdBy: "u_admin_locked",
    })
  );
});

// ✅ create invoice in open period (deliveryDate=Feb 5, lockedUntil=Jan 31)
test("Period lock: create invoice in open period allowed", async () => {
  const db = authed("u_admin_locked");
  await assertSucceeds(
    db.doc(`companies/cLocked/accounting/_root/invoices/inv_new_open`).set({
      companyId: "cLocked", total: 200, documentType: "invoice",
      deliveryDate: new Date("2026-02-05T00:00:00Z"),
      createdAt: Date.now(), createdBy: "u_admin_locked",
    })
  );
});

// ❌ update invoice in locked period (existing deliveryDate=Jan 15)
test("Period lock: update invoice in locked period denied", async () => {
  const db = authed("u_admin_locked");
  await assertFails(
    db.doc(`companies/cLocked/accounting/_root/invoices/inv_locked`).update({
      total: 999,
    })
  );
});

// ✅ create credit note with current date (Feb 5) referencing old invoice — allowed
test("Period lock: create credit note in open period for old invoice allowed", async () => {
  const db = authed("u_admin_locked");
  await assertSucceeds(
    db.doc(`companies/cLocked/accounting/_root/credit_notes/cn_new_open`).set({
      companyId: "cLocked", total: 50,
      deliveryDate: new Date("2026-02-05T00:00:00Z"),
      linkedInvoiceId: "inv_locked",
      createdAt: Date.now(), createdBy: "u_admin_locked",
    })
  );
});

// ❌ update credit note in locked period (existing deliveryDate=Jan 10)
test("Period lock: update credit note in locked period denied", async () => {
  const db = authed("u_admin_locked");
  await assertFails(
    db.doc(`companies/cLocked/accounting/_root/credit_notes/cn_locked`).update({
      total: 999,
    })
  );
});

// ✅ super_admin bypass: can create/update in locked period
test("Period lock: super_admin bypasses period lock", async () => {
  const db = authed("u_super");
  // create in locked period
  await assertSucceeds(
    db.doc(`companies/cLocked/accounting/_root/invoices/inv_super_locked`).set({
      companyId: "cLocked", total: 50, documentType: "invoice",
      deliveryDate: new Date("2026-01-10T00:00:00Z"),
      createdAt: Date.now(), createdBy: "u_super",
    })
  );
  // update in locked period
  await assertSucceeds(
    db.doc(`companies/cLocked/accounting/_root/invoices/inv_locked`).update({
      total: 777,
    })
  );
});

// =========================================================
// Audit: billing/lock admin changes (3 new types)
// =========================================================

// ✅ admin can create audit with type=billing_status_changed
test("Audit: admin can create billing_status_changed audit event", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/audit/aud_billing1`).set({
      moduleKey: "accounting",
      type: "billing_status_changed",
      entity: { collection: "billing", docId: "c1" },
      createdBy: "u_admin_c1",
      createdAt: serverTimestamp(),
    })
  );
});

// ❌ warehouse_keeper cannot create billing_status_changed (no canWriteModule for accounting)
test("Audit: warehouse_keeper cannot create billing_status_changed", async () => {
  const db = authed("u_warehouse_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_billing2`).set({
      moduleKey: "accounting",
      type: "billing_status_changed",
      entity: { collection: "billing", docId: "c1" },
      createdBy: "u_warehouse_c1",
      createdAt: serverTimestamp(),
    })
  );
});

// ❌ type not in allowlist → denied
test("Audit: unknown type denied even for admin", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/audit/aud_billing3`).set({
      moduleKey: "accounting",
      type: "some_unknown_type",
      entity: { collection: "billing", docId: "c1" },
      createdBy: "u_admin_c1",
      createdAt: serverTimestamp(),
    })
  );
});

// =========================================================
// Task 35: Server-issued fields immutability tests
// =========================================================

// ❌ Client cannot flip status from draft to issued
test("Immutable: client cannot set status to 'issued' on draft invoice", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_draft`).update({
      companyId: "c1",
      status: "issued",
    })
  );
});

// ❌ Client cannot change sequentialNumber on issued invoice
test("Immutable: client cannot change sequentialNumber on issued invoice", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_issued`).update({
      companyId: "c1",
      sequentialNumber: 999,
    })
  );
});

// ❌ Client cannot change finalizedAt on issued invoice
test("Immutable: client cannot change finalizedAt on issued invoice", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_issued`).update({
      companyId: "c1",
      finalizedAt: new Date("2026-12-31"),
    })
  );
});

// ❌ Client cannot change finalizedBy on issued invoice
test("Immutable: client cannot change finalizedBy on issued invoice", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_issued`).update({
      companyId: "c1",
      finalizedBy: "hacker",
    })
  );
});

// ❌ Client cannot change immutableSnapshotHash on issued invoice
test("Immutable: client cannot change immutableSnapshotHash on issued invoice", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_issued`).update({
      companyId: "c1",
      immutableSnapshotHash: "tampered_hash",
    })
  );
});

// ✅ Admin can update non-immutable field on issued invoice (e.g. notes)
// status stays 'issued' (unchanged), server fields unchanged
test("Immutable: admin can update non-server fields on issued invoice", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv_issued`).update({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "issued",
      sequentialNumber: 42,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "abc123hash",
      notes: "admin note",
    })
  );
});

// =========================================================
// Chain integrity rules tests
// =========================================================

// ❌ Cannot update chain entry (append-only)
test("Chain: cannot update existing chain entry", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_chain/a1`).update({
      hash: "tampered",
    })
  );
});

// ❌ Cannot delete chain entry
test("Chain: cannot delete chain entry", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_chain/a1`).delete()
  );
});

// ❌ Cannot update anchor entry (append-only)
test("Anchor: cannot update existing anchor", async () => {
  const db = authed("u_super");
  // Seed an anchor first
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/accounting/_root/integrity_anchors/anc_test`).set({
      counterKey: "invoice",
      docNumber: 1,
      invoiceId: "inv1",
      documentHash: "abc",
      createdAt: new Date(),
      createdBy: "u_super",
    });
  });
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_anchors/anc_test`).update({
      documentHash: "tampered",
    })
  );
});

// ❌ Cannot delete anchor entry
test("Anchor: cannot delete anchor", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/integrity_anchors/anc_test`).delete()
  );
});

// =========================================================
// Soft-void lifecycle tests
// =========================================================

// ✅ Admin can void an issued invoice (status: issued → voided)
test("Void: admin can void issued invoice", async () => {
  // Seed a separate issued invoice for void test
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/accounting/_root/invoices/inv_for_void`).set({
      companyId: "c1",
      total: 200,
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "issued",
      sequentialNumber: 43,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "abc123hash",
    });
  });

  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv_for_void`).update({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "voided",
      sequentialNumber: 43,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "abc123hash",
      voidedBy: "u_admin_c1",
      voidReason: "test void",
    })
  );
});

// ❌ Voided invoice cannot be updated (frozen)
test("Void: voided invoice is frozen — no further updates", async () => {
  // First, seed a voided invoice
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/accounting/_root/invoices/inv_voided`).set({
      companyId: "c1",
      total: 300,
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "voided",
      sequentialNumber: 99,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "xyz",
      cancelledBy: "u_admin_c1",
      cancellationReason: "voided",
    });
  });

  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_voided`).update({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "voided",
      sequentialNumber: 99,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "xyz",
      notes: "trying to modify voided doc",
    })
  );
});

// ❌ Cannot un-void (voided → issued)
test("Void: cannot un-void invoice (voided → issued)", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_voided`).update({
      companyId: "c1",
      status: "issued",
    })
  );
});

// ✅ Admin can create audit event with type invoice_voided
test("Audit: admin can create invoice_voided audit event", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/audit/aud_void1`).set({
      moduleKey: "accounting",
      type: "invoice_voided",
      entity: { collection: "invoices", docId: "inv_issued" },
      createdBy: "u_admin_c1",
      createdAt: serverTimestamp(),
    })
  );
});

// =========================================================
// Void fields hardening tests
// =========================================================

// ❌ Void without voidedBy == uid → denied
test("Void: cannot void with wrong voidedBy", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/accounting/_root/invoices/inv_void_uid`).set({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "issued",
      sequentialNumber: 55,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "hash55",
    });
  });

  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/accounting/_root/invoices/inv_void_uid`).update({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "voided",
      sequentialNumber: 55,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "hash55",
      voidedBy: "someone_else",
      voidReason: "test",
    })
  );
});

// ✅ Void with correct voidedBy == uid → allowed
test("Void: can void with correct voidedBy == uid", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/accounting/_root/invoices/inv_void_ok`).set({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "issued",
      sequentialNumber: 56,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "hash56",
    });
  });

  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/accounting/_root/invoices/inv_void_ok`).update({
      companyId: "c1",
      createdAt: 123,
      createdBy: "u_admin_c1",
      deliveryDate: new Date("2026-06-01"),
      status: "voided",
      sequentialNumber: 56,
      finalizedAt: new Date("2026-01-15"),
      finalizedBy: "server",
      immutableSnapshotHash: "hash56",
      voidedBy: "u_admin_c1",
      voidReason: "legitimate void",
    })
  );
});

// =========================================================
// Security audit: новые коллекции (notifications, payment_events,
// checkout_sessions, export_presets)
// =========================================================

// =========================================================
// 1. Notifications: company member can read
// =========================================================
test("Notifications: company member can read", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/notifications/notif1`).get()
  );
});

// =========================================================
// 2. Notifications: client CANNOT create (server-only)
// =========================================================
test("Notifications: client cannot create (server-only)", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/notifications/notif_fake`).set({
      type: "billing_suspended",
      title: "Fake suspension",
      body: "Hacked",
      severity: "critical",
      read: false,
      createdAt: new Date(),
    })
  );
});

// =========================================================
// 3. Notifications: client can ONLY set read/readAt (не title/body/type)
// =========================================================
test("Notifications: client can mark as read (only read + readAt)", async () => {
  const db = authed("u_disp_c1");
  await assertSucceeds(
    db.doc(`companies/c1/notifications/notif1`).update({
      read: true,
      readAt: serverTimestamp(),
    })
  );
});

test("Notifications: client cannot change title/body/type", async () => {
  // Сначала сбросим read обратно для чистоты
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/notifications/notif1`).update({
      read: false,
    });
  });

  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/notifications/notif1`).update({
      title: "Hacked title",
    })
  );
});

test("Notifications: client cannot set read=false (un-read)", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/notifications/notif1`).update({
      read: true,
    });
  });

  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/notifications/notif1`).update({
      read: false,
    })
  );
});

// =========================================================
// 4. Notifications: delete — admin only
// =========================================================
test("Notifications: admin can delete", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/notifications/notif_del`).set({
      type: "info", title: "temp", body: "", severity: "info", read: false, createdAt: new Date(),
    });
  });

  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/notifications/notif_del`).delete()
  );
});

test("Notifications: non-admin cannot delete", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/notifications/notif1`).delete()
  );
});

// =========================================================
// 5. payment_events: admin can read
// =========================================================
test("payment_events: admin can read", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/payment_events/pe1`).get()
  );
});

// =========================================================
// 6. payment_events: non-admin cannot read
// =========================================================
test("payment_events: non-admin (dispatcher) cannot read", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/payment_events/pe1`).get()
  );
});

// =========================================================
// 7. payment_events: client cannot create/update/delete
// =========================================================
test("payment_events: client cannot create", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/payment_events/pe_fake`).set({
      provider: "manual", amount: 9999, processedAt: new Date(),
    })
  );
});

test("payment_events: client cannot update", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/payment_events/pe1`).update({ amount: 0 })
  );
});

test("payment_events: client cannot delete", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/payment_events/pe1`).delete()
  );
});

// =========================================================
// 8. checkout_sessions: admin can read
// =========================================================
test("checkout_sessions: admin can read", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/checkout_sessions/cs1`).get()
  );
});

// =========================================================
// 9. checkout_sessions: client cannot create/update/delete
// =========================================================
test("checkout_sessions: client cannot create", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/checkout_sessions/cs_fake`).set({
      provider: "stripe", plan: "full", status: "paid",
    })
  );
});

test("checkout_sessions: client cannot update status", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/checkout_sessions/cs1`).update({ status: "paid" })
  );
});

// =========================================================
// 10. export_presets: admin can CRUD
// =========================================================
test("export_presets: admin can read", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/export_presets/ep1`).get()
  );
});

test("export_presets: admin can create", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/export_presets/ep_new`).set({
      name: "Priority", format: "priority_csv", encoding: "utf8",
    })
  );
});

test("export_presets: admin can update", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/export_presets/ep1`).update({ name: "Updated" })
  );
});

test("export_presets: admin can delete", async () => {
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/export_presets/ep_new`).delete()
  );
});

// =========================================================
// 11. export_presets: non-admin denied write
// =========================================================
test("export_presets: dispatcher cannot create", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/export_presets/ep_hack`).set({
      name: "Hack", format: "csv", encoding: "utf8",
    })
  );
});

test("export_presets: driver cannot read", async () => {
  const db = authed("u_driver_c1");
  await assertFails(
    db.doc(`companies/c1/export_presets/ep1`).get()
  );
});

// =========================================================
// 12. Catch-all: неизвестная subcollection блокируется
// =========================================================
test("Catch-all: unknown subcollection under company is blocked", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/unknown_collection/doc1`).set({ data: "test" })
  );
});

test("Catch-all: unknown subcollection read also blocked", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/unknown_collection/doc1`).get()
  );
});

// =========================================================
// 13. Delivery telemetry logs — push_delivery_logs, email_delivery_logs
// =========================================================
test("push_delivery_logs: admin can read", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/push_delivery_logs/pdl1`).set({
      errorCode: "messaging/invalid-registration-token",
      timestamp: new Date(),
    });
  });
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/push_delivery_logs/pdl1`).get()
  );
});

test("push_delivery_logs: non-admin cannot read", async () => {
  const db = authed("u_disp_c1");
  await assertFails(
    db.doc(`companies/c1/push_delivery_logs/pdl1`).get()
  );
});

test("push_delivery_logs: client cannot create", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/push_delivery_logs/pdl_fake`).set({
      errorCode: "test", timestamp: new Date(),
    })
  );
});

test("email_delivery_logs: admin can read", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`companies/c1/email_delivery_logs/edl1`).set({
      errorCode: "smtp_error",
      timestamp: new Date(),
    });
  });
  const db = authed("u_admin_c1");
  await assertSucceeds(
    db.doc(`companies/c1/email_delivery_logs/edl1`).get()
  );
});

test("email_delivery_logs: client cannot create", async () => {
  const db = authed("u_admin_c1");
  await assertFails(
    db.doc(`companies/c1/email_delivery_logs/edl_fake`).set({
      errorCode: "test", timestamp: new Date(),
    })
  );
});
