const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// --- Canonical hash (same as issueInvoice.js / verifyIntegrityChain.js) ---
function sha256hex(s) {
  return crypto.createHash("sha256").update(s, "utf8").digest("hex");
}
function buildChainHashV1({ companyId, counterKey, docType, docNumber, docId, issuedAtMillis, prevHash }) {
  const prev = prevHash ?? "GENESIS";
  return sha256hex(`v1|${companyId}|${counterKey}|${docType}|${docNumber}|${docId}|${issuedAtMillis}|${prev}`);
}

const COUNTER_KEYS = [
  "tax_invoice",
  "receipt",
  "credit_note",
  "delivery_note",
  "tax_invoice_receipt",
];
const MAX_CHECK = 2000;

/**
 * Ночная проверка целостности цепочки для всех активных компаний.
 * Запускается каждую ночь в 03:30.
 * При обнаружении поломки — пишет audit event + notification.
 */
exports.scheduledIntegrityCheck = functions.pubsub
  .schedule("30 3 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    console.log("🔗 Starting scheduled integrity check...");

    // Получаем все активные компании
    const companiesSnap = await db.collection("companies")
      .where("billingStatus", "in", ["active", "grace", "trial"])
      .get();

    if (companiesSnap.empty) {
      console.log("No active companies found");
      return null;
    }

    let totalChecked = 0;
    let totalBroken = 0;

    for (const companyDoc of companiesSnap.docs) {
      const companyId = companyDoc.id;
      const chainBase = `companies/${companyId}/accounting/_root/integrity_chain`;
      const counterBase = `companies/${companyId}/accounting/_root/counters`;

      for (const counterKey of COUNTER_KEYS) {
        try {
          // Читаем текущий counter
          const counterSnap = await db.doc(`${counterBase}/${counterKey}`).get();
          if (!counterSnap.exists) continue;
          const lastNumber = counterSnap.data().lastNumber || 0;
          if (lastNumber === 0) continue;

          const from = Math.max(1, lastNumber - MAX_CHECK + 1);
          const to = lastNumber;

          // Find the first existing chain entry to avoid false positives
          // for documents created before the integrity chain was deployed.
          let actualFrom = from;
          {
            const probeSnap = await db.doc(`${chainBase}/${counterKey}_${from}`).get();
            if (!probeSnap.exists) {
              let lo = from;
              let hi = to;
              let found = -1;
              while (lo <= hi) {
                const mid = Math.floor((lo + hi) / 2);
                const midSnap = await db.doc(`${chainBase}/${counterKey}_${mid}`).get();
                if (midSnap.exists) {
                  found = mid;
                  hi = mid - 1;
                } else {
                  lo = mid + 1;
                }
              }
              if (found === -1) {
                console.log(`ℹ️ [${companyId}] ${counterKey}: no chain entries found, skipping`);
                continue;
              }
              actualFrom = found;
            }
          }

          // Batch read chain docs
          const refs = [];
          if (actualFrom > 1) {
            refs.push(db.doc(`${chainBase}/${counterKey}_${actualFrom - 1}`));
          }
          for (let n = actualFrom; n <= to; n++) {
            refs.push(db.doc(`${chainBase}/${counterKey}_${n}`));
          }
          const snaps = await db.getAll(...refs);

          let snapIdx = 0;
          let prevHashExpected = null;

          if (actualFrom > 1) {
            const prevSnap = snaps[snapIdx++];
            if (prevSnap.exists) {
              prevHashExpected = prevSnap.data().hash || null;
            }
            // If prev doesn't exist, we start without linkage check
          }

          let broken = false;
          let brokenAt = null;
          let brokenReason = null;

          for (let n = actualFrom; n <= to; n++) {
            const snap = snaps[snapIdx++];
            if (!snap.exists) {
              broken = true;
              brokenAt = n;
              brokenReason = "MISSING_ENTRY";
              break;
            }

            const d = snap.data();
            const expectedPrev = prevHashExpected ?? "GENESIS";
            const actualPrev = d.prevHash ?? "GENESIS";

            if (actualPrev !== expectedPrev) {
              broken = true;
              brokenAt = n;
              brokenReason = "PREV_HASH_MISMATCH";
              break;
            }

            const issuedAtMillis = d.issuedAt ? d.issuedAt.toMillis() : 0;
            const hashExpected = buildChainHashV1({
              companyId,
              counterKey,
              docType: d.docType,
              docNumber: n,
              docId: d.docId,
              issuedAtMillis,
              prevHash: actualPrev === "GENESIS" ? null : actualPrev,
            });

            if (hashExpected !== d.hash) {
              broken = true;
              brokenAt = n;
              brokenReason = "HASH_MISMATCH";
              break;
            }

            prevHashExpected = d.hash;
            totalChecked++;
          }

          if (broken) {
            totalBroken++;
            console.error(`❌ [${companyId}] ${counterKey}: broken at #${brokenAt} — ${brokenReason}`);

            // Write audit event
            try {
              await db.collection(`companies/${companyId}/audit`).add({
                moduleKey: "accounting",
                type: "invoice_issued", // reuse allowed type for audit rules
                entity: { collection: "invoices", docId: `chain_${counterKey}_${brokenAt}` },
                createdBy: "system",
                createdAt: FieldValue.serverTimestamp(),
              });
            } catch (auditErr) {
              // Audit write may fail if rules block system user — use Admin SDK bypass
              console.warn(`⚠️ Audit write failed for ${companyId}: ${auditErr.message}`);
            }

            // Write notification for admin
            try {
              const reasonLabels = {
                "MISSING_ENTRY": "מסמך חסר",
                "HASH_MISMATCH": "חתימה לא תואמת",
                "PREV_HASH_MISMATCH": "קישור שגוי בין מסמכים",
                "MISSING_PREV_FOR_RANGE": "מסמך קודם חסר",
              };
              const reasonLabel = reasonLabels[brokenReason] || brokenReason;
              const docTypeLabels = {
                "invoice": "חשבונית",
                "receipt": "קבלה",
                "delivery": "תעודת משלוח",
                "taxInvoiceReceipt": "חשבונית מס קבלה",
                "creditNote": "זיכוי",
              };
              const docTypeLabel = docTypeLabels[counterKey] || counterKey;
              await db.collection(`companies/${companyId}/notifications`).add({
                type: "integrity_chain_broken",
                title: `בעיית שלמות: ${docTypeLabel} מס׳ ${brokenAt}`,
                body: `נמצאה בעיה ב${docTypeLabel} מס׳ ${brokenAt}: ${reasonLabel}. יש לבדוק את הרצף.`,
                severity: "critical",
                counterKey,
                brokenAt,
                reason: brokenReason,
                createdAt: FieldValue.serverTimestamp(),
                read: false,
              });
            } catch (notifErr) {
              console.warn(`⚠️ Notification write failed: ${notifErr.message}`);
            }
          }
        } catch (err) {
          console.error(`❌ Error checking ${companyId}/${counterKey}: ${err.message}`);
        }
      }
    }

    console.log(`✅ Scheduled integrity check complete: ${totalChecked} entries checked, ${totalBroken} broken chains found`);
    return { totalChecked, totalBroken };
  });
