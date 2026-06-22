const crypto = require("crypto");

function sha256hex(s) {
  return crypto.createHash("sha256").update(s, "utf8").digest("hex");
}

/**
 * Canonical chain hash v1 — для issueInvoice.
 * Обе системы пишут в общую цепочку целостности одного counterKey, поэтому
 * формула хэша обязана быть байт-в-байт одинаковой.
 *
 * v1|{companyId}|{counterKey}|{docType}|{docNumber}|{docId}|{issuedAtMillis}|{prevHashOrGENESIS}
 */
function buildChainHashV1({
  companyId,
  counterKey,
  docType,
  docNumber,
  docId,
  issuedAtMillis,
  prevHash,
}) {
  const prev = prevHash ?? "GENESIS";
  const canonical = `v1|${companyId}|${counterKey}|${docType}|${docNumber}|${docId}|${issuedAtMillis}|${prev}`;
  return sha256hex(canonical);
}

module.exports = { sha256hex, buildChainHashV1 };
