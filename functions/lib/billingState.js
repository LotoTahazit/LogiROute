const DEFAULT_GRACE_DAYS = 7;

const CANONICAL_STATUSES = [
  "active",
  "trial",
  "grace",
  "suspended",
  "cancelled",
];

/** Legacy alias — treat as suspended. Not written to new docs. */
const LEGACY_BLOCKED_STATUS = "blocked";

function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v.toDate === "function") return v.toDate();
  return null;
}

function gracePeriodDays(data) {
  const d = data && data.gracePeriodDays;
  return typeof d === "number" && d > 0 ? d : DEFAULT_GRACE_DAYS;
}

function addDays(date, days) {
  const out = new Date(date.getTime());
  out.setDate(out.getDate() + days);
  return out;
}

function graceUntil(data, anchor) {
  if (!anchor) return null;
  return addDays(anchor, gracePeriodDays(data));
}

/**
 * Unified billing evaluation (C3).
 * Expired trial → grace window until trialUntil + gracePeriodDays.
 * Expired grace → deny until billingEnforcer sets suspended.
 */
function evaluateBilling(data, now = new Date()) {
  if (!data || typeof data !== "object") {
    return {
      allowsAccess: false,
      displayPhase: "blocked",
      storedStatus: "",
      blockReason: "missing_data",
    };
  }

  const status = data.billingStatus;
  if (!status || typeof status !== "string") {
    return {
      allowsAccess: false,
      displayPhase: "blocked",
      storedStatus: "",
      blockReason: "missing_status",
    };
  }

  if (
    status === LEGACY_BLOCKED_STATUS ||
    status === "suspended" ||
    status === "cancelled"
  ) {
    return {
      allowsAccess: false,
      displayPhase: "blocked",
      storedStatus: status,
      blockReason: status,
    };
  }

  if (status === "active") {
    return {
      allowsAccess: true,
      displayPhase: "active",
      storedStatus: status,
    };
  }

  if (status === "grace") {
    const anchor = toDate(data.paidUntil) || toDate(data.trialUntil);
    if (!anchor) {
      return {
        allowsAccess: false,
        displayPhase: "blocked",
        storedStatus: status,
        blockReason: "missing_paidUntil",
      };
    }
    const until = graceUntil(data, anchor);
    if (now < until) {
      return {
        allowsAccess: true,
        displayPhase: "grace",
        storedStatus: status,
        graceUntil: until,
      };
    }
    return {
      allowsAccess: false,
      displayPhase: "blocked",
      storedStatus: status,
      blockReason: "grace_expired",
      graceUntil: until,
    };
  }

  if (status === "trial") {
    const trialUntil = toDate(data.trialUntil) || toDate(data.trialEndsAt);
    if (!trialUntil) {
      return {
        allowsAccess: false,
        displayPhase: "blocked",
        storedStatus: status,
        blockReason: "missing_trialUntil",
      };
    }
    if (now < trialUntil) {
      return {
        allowsAccess: true,
        displayPhase: "trial",
        storedStatus: status,
        trialUntil,
      };
    }
    const until = graceUntil(data, trialUntil);
    if (now < until) {
      return {
        allowsAccess: true,
        displayPhase: "grace",
        storedStatus: status,
        trialUntil,
        graceUntil: until,
      };
    }
    return {
      allowsAccess: false,
      displayPhase: "blocked",
      storedStatus: status,
      blockReason: "grace_expired",
      trialUntil,
      graceUntil: until,
    };
  }

  return {
    allowsAccess: false,
    displayPhase: "blocked",
    storedStatus: status,
    blockReason: "unknown_status",
  };
}

function billingAllowsAccess(data, now = new Date()) {
  return evaluateBilling(data, now).allowsAccess;
}

module.exports = {
  DEFAULT_GRACE_DAYS,
  CANONICAL_STATUSES,
  LEGACY_BLOCKED_STATUS,
  evaluateBilling,
  billingAllowsAccess,
  graceUntil,
  gracePeriodDays,
};
