/**
 * Server mirror of Dart CompanyModulesService (H4).
 * Запрещено менять plan/modules/limits на root без applyPlanToCompany().
 */

const PLAN_MODULES = {
  logistics: {
    warehouse: false,
    logistics: true,
    dispatcher: true,
    accounting: false,
    reports: true,
  },
  warehouse_only: {
    warehouse: true,
    logistics: false,
    dispatcher: false,
    accounting: false,
    reports: false,
  },
  ops: {
    warehouse: true,
    logistics: true,
    dispatcher: true,
    accounting: false,
    reports: true,
  },
  full: {
    warehouse: true,
    logistics: true,
    dispatcher: true,
    accounting: true,
    reports: true,
  },
};

const PLAN_LIMITS = {
  warehouse_only: { maxUsers: 5, maxDocsPerMonth: 500, maxRoutesPerDay: 10 },
  logistics: { maxUsers: 10, maxDocsPerMonth: 1000, maxRoutesPerDay: 40 },
  ops: { maxUsers: 15, maxDocsPerMonth: 2000, maxRoutesPerDay: 50 },
  full: { maxUsers: 50, maxDocsPerMonth: 10000, maxRoutesPerDay: 200 },
};

function normalizePlan(plan) {
  return PLAN_MODULES[plan] ? plan : "full";
}

function entitlementsForPlan(plan) {
  return { ...PLAN_MODULES[normalizePlan(plan)] };
}

function limitsForPlan(plan) {
  const key = normalizePlan(plan);
  return { ...(PLAN_LIMITS[key] || PLAN_LIMITS.full) };
}

/** Patch for companies/{id} root — plan + modules + limits. */
function rootEntitlementsPatch(plan) {
  const normalized = normalizePlan(plan);
  return {
    plan: normalized,
    modules: entitlementsForPlan(normalized),
    limits: limitsForPlan(normalized),
  };
}

/**
 * Единственная точка записи plan/modules/limits (server).
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} companyId
 * @param {string} plan
 * @param {object} [options]
 * @param {import('firebase-admin/firestore').FieldValue} [options.fieldValue]
 */
async function applyPlanToCompany(db, companyId, plan, options = {}) {
  const FieldValue = options.fieldValue || require("firebase-admin").firestore.FieldValue;
  const patch = rootEntitlementsPatch(plan);
  const companyRef = db.doc(`companies/${companyId}`);
  await companyRef.set(patch, { merge: true });
  await companyRef.collection("settings").doc("settings").set(
    {
      plan: patch.plan,
      modules: patch.modules,
      modulesMirrorUpdatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return patch;
}

module.exports = {
  PLAN_MODULES,
  PLAN_LIMITS,
  normalizePlan,
  entitlementsForPlan,
  limitsForPlan,
  rootEntitlementsPatch,
  applyPlanToCompany,
};
