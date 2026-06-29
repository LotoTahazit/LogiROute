/**
 * Safety guards for Demo Mode purge/reset.
 * Unit-tested — do not bypass without updating tests.
 */

const DEMO_COMPANY_ID = "demo-foods-israel";

/** Collections where every deleted doc MUST have isDemo === true */
const STRICT_IS_DEMO_PATHS = [
  "warehouse/_root/box_types",
  "warehouse/_root/inventory",
  "warehouse/_root/product_types",
  "warehouse/_root/inventory_counts",
  "warehouse/_root/inventory_history",
  "logistics/_root/clients",
  "logistics/_root/delivery_points",
  "logistics/_root/routes",
  "logistics/_root/drivers",
  "logistics/_root/trucks",
  "logistics/_root/route_history",
  "logistics/_root/delivery_events",
  "logistics/_root/archive_routes",
  "accounting/_root/invoices",
  "accounting/_root/counters",
  "metrics/daily/days",
  "driver_locations",
  "members",
  "settings",
];

/** Company-scoped aux — purge all docs only after company demoCompany verified */
const AUX_PURGE_PATHS = [
  "notifications",
  "audit",
  "systemEvents",
  "printEvents",
];

function assertDemoCompanyId(companyId) {
  if (companyId !== DEMO_COMPANY_ID) {
    throw new Error(`Refusing demo purge: companyId must be ${DEMO_COMPANY_ID}`);
  }
}

function assertDemoCompanyDoc(companySnap) {
  assertDemoCompanyId(companySnap.id);
  if (!companySnap.exists) {
    return { exists: false };
  }
  const data = companySnap.data() || {};
  if (data.demoCompany !== true) {
    throw new Error(
      `Refusing demo purge: companies/${companySnap.id} demoCompany !== true`,
    );
  }
  return { exists: true, data };
}

function classifyDocForStrictDelete(data) {
  if (!data || typeof data !== "object") {
    return { deletable: false, reason: "missing-data" };
  }
  if ("isDemo" in data) {
    if (data.isDemo === true) return { deletable: true, reason: "isDemo" };
    return { deletable: false, reason: "isDemo-false" };
  }
  return { deletable: false, reason: "isDemo-missing" };
}

function buildPurgePaths(companyId) {
  assertDemoCompanyId(companyId);
  const strict = STRICT_IS_DEMO_PATHS.map(
    (p) => `companies/${companyId}/${p}`,
  );
  const aux = AUX_PURGE_PATHS.map((p) => `companies/${companyId}/${p}`);
  return { strict, aux };
}

module.exports = {
  DEMO_COMPANY_ID,
  STRICT_IS_DEMO_PATHS,
  AUX_PURGE_PATHS,
  assertDemoCompanyId,
  assertDemoCompanyDoc,
  classifyDocForStrictDelete,
  buildPurgePaths,
};
