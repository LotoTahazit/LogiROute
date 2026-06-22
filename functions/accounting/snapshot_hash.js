const crypto = require("crypto");

/** Каноническое представление ключевых полей (mirrors Dart SnapshotHash). */
function buildPayload(doc) {
  let issuedAt = null;
  if (doc.issuedAt?.toDate) {
    issuedAt = doc.issuedAt.toDate().toISOString();
  } else if (doc.issuedAt instanceof Date) {
    issuedAt = doc.issuedAt.toISOString();
  } else if (typeof doc.issuedAt === "string") {
    issuedAt = doc.issuedAt;
  }

  return {
    docNumber: doc.docNumber,
    issuedAt,
    customerId: doc.customerId,
    lines: (doc.lines || []).map((line) => ({ ...line })),
    totals: doc.totals || {},
  };
}

/** SHA-256 hex от docNumber, issuedAt ISO, customerId, lines, totals. */
function compute(doc) {
  const jsonString = JSON.stringify(buildPayload(doc));
  return crypto.createHash("sha256").update(jsonString, "utf8").digest("hex");
}

module.exports = { compute, buildPayload };
