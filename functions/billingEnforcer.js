const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

/**
 * Billing Enforcer — callable function для проверки подписок.
 * Вызывается вручную из админки или автоматически (webhook/trigger).
 * Убрана зависимость от Cloud Scheduler для экономии.
 *
 * State machine (строго однонаправленная):
 *   trial expired → grace
 *   active + paidUntil expired → grace
 *   grace + grace period expired → suspended
 *
 * Инварианты:
 * - НИКОГДА не трогаем cancelled (терминальный статус)
 * - Если paidUntil в будущем, но статус "ошибочный" (grace/suspended) → self-heal → active
 * - Audit всегда содержит fromStatus, toStatus, reason, paidUntil, graceUntil
 */
exports.billingEnforcer = functions.pubsub
  .schedule("0 4 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    console.log("💰 Starting billing enforcement...");

    const now = new Date();
    let transitioned = 0;
    let selfHealed = 0;

    // === 0. Self-heal: grace/suspended but paidUntil is in the future → active ===
    try {
      const healSnap = await db
        .collection("companies")
        .where("billingStatus", "in", ["grace", "suspended"])
        .get();

      for (const doc of healSnap.docs) {
        const data = doc.data();
        if (!data.paidUntil) continue;

        const paidUntil = data.paidUntil.toDate();
        if (paidUntil > now) {
          const fromStatus = data.billingStatus;
          await doc.ref.update({
            billingStatus: "active",
            billingStatusChangedAt: FieldValue.serverTimestamp(),
            billingStatusChangedBy: "system:billingEnforcer:self_heal",
          });
          await _auditTransition(doc.id, fromStatus, "active",
            `Self-heal: paidUntil (${paidUntil.toISOString()}) is in the future`,
            paidUntil, null);
          selfHealed++;
          console.log(`🩹 ${doc.id}: ${fromStatus} → active (self-heal, paidUntil=${paidUntil.toISOString()})`);
        }
      }
    } catch (err) {
      console.error("❌ Error in self-heal pass:", err.message);
    }

    // === 1. Trial expired → grace ===
    try {
      const trialSnap = await db
        .collection("companies")
        .where("billingStatus", "==", "trial")
        .where("trialUntil", "<", Timestamp.fromDate(now))
        .get();

      for (const doc of trialSnap.docs) {
        const data = doc.data();
        const graceDays = data.gracePeriodDays || 7;
        const trialEnd = data.trialUntil.toDate();
        const graceEnd = new Date(trialEnd);
        graceEnd.setDate(graceEnd.getDate() + graceDays);

        // Trial always goes to grace first (not directly to suspended)
        const paidUntilValue = data.paidUntil || data.trialUntil;

        await doc.ref.update({
          billingStatus: "grace",
          paidUntil: paidUntilValue,
          billingStatusChangedAt: FieldValue.serverTimestamp(),
          billingStatusChangedBy: "system:billingEnforcer",
        });

        await _auditTransition(doc.id, "trial", "grace",
          "Trial expired",
          paidUntilValue.toDate ? paidUntilValue.toDate() : trialEnd,
          graceEnd);
        transitioned++;

        // Notification for company
        try {
          await db.collection(`companies/${doc.id}/notifications`).add({
            type: "billing_grace",
            title: "תקופת הניסיון הסתיימה — נדרש תשלום",
            body: `תקופת הניסיון הסתיימה. יש לך ${graceDays} ימים לבצע תשלום לפני השעיית החשבון.`,
            severity: "warning",
            createdAt: FieldValue.serverTimestamp(),
            read: false,
          });
        } catch (notifErr) {
          console.warn(`⚠️ Notification failed for ${doc.id}: ${notifErr.message}`);
        }

        console.log(`📋 ${doc.id}: trial → grace (grace until ${graceEnd.toISOString()})`);
      }
    } catch (err) {
      console.error("❌ Error processing trial companies:", err.message);
    }

    // === 2. Active with expired paidUntil → grace ===
    try {
      const activeSnap = await db
        .collection("companies")
        .where("billingStatus", "==", "active")
        .where("paidUntil", "<", Timestamp.fromDate(now))
        .get();

      for (const doc of activeSnap.docs) {
        const data = doc.data();
        const graceDays = data.gracePeriodDays || 7;
        const paidUntil = data.paidUntil.toDate();
        const graceEnd = new Date(paidUntil);
        graceEnd.setDate(graceEnd.getDate() + graceDays);

        await doc.ref.update({
          billingStatus: "grace",
          billingStatusChangedAt: FieldValue.serverTimestamp(),
          billingStatusChangedBy: "system:billingEnforcer",
        });

        await _auditTransition(doc.id, "active", "grace",
          "Payment expired (paidUntil < now)",
          paidUntil, graceEnd);
        transitioned++;

        // Notification for company
        try {
          await db.collection(`companies/${doc.id}/notifications`).add({
            type: "billing_grace",
            title: "התשלום פג תוקף — נדרש חידוש",
            body: `התשלום פג תוקף. יש לך ${graceDays} ימים לחדש את התשלום לפני השעיית החשבון.`,
            severity: "warning",
            createdAt: FieldValue.serverTimestamp(),
            read: false,
          });
        } catch (notifErr) {
          console.warn(`⚠️ Notification failed for ${doc.id}: ${notifErr.message}`);
        }

        console.log(`📋 ${doc.id}: active → grace (grace until ${graceEnd.toISOString()})`);
      }
    } catch (err) {
      console.error("❌ Error processing active companies:", err.message);
    }

    // === 3. Grace with expired grace period → suspended ===
    // NOTE: cancelled is NEVER touched (terminal state)
    try {
      const graceSnap = await db
        .collection("companies")
        .where("billingStatus", "==", "grace")
        .get();

      for (const doc of graceSnap.docs) {
        const data = doc.data();
        if (!data.paidUntil) continue;

        const graceDays = data.gracePeriodDays || 7;
        const paidUntil = data.paidUntil.toDate();
        const graceEnd = new Date(paidUntil);
        graceEnd.setDate(graceEnd.getDate() + graceDays);

        if (now > graceEnd) {
          await doc.ref.update({
            billingStatus: "suspended",
            billingStatusChangedAt: FieldValue.serverTimestamp(),
            billingStatusChangedBy: "system:billingEnforcer",
          });

          await _auditTransition(doc.id, "grace", "suspended",
            `Grace period (${graceDays}d) expired`,
            paidUntil, graceEnd);
          transitioned++;
          console.log(`📋 ${doc.id}: grace → suspended`);

          // Notification for admin
          try {
            await db.collection(`companies/${doc.id}/notifications`).add({
              type: "billing_suspended",
              title: "החשבון הושעה — נדרש תשלום",
              body: `תקופת החסד (${graceDays} ימים) הסתיימה. החשבון הושעה עד לביצוע תשלום.`,
              severity: "critical",
              createdAt: FieldValue.serverTimestamp(),
              read: false,
            });
          } catch (notifErr) {
            console.warn(`⚠️ Notification failed for ${doc.id}: ${notifErr.message}`);
          }
        }
      }
    } catch (err) {
      console.error("❌ Error processing grace companies:", err.message);
    }

    console.log(`✅ Billing enforcement complete: ${transitioned} transitions, ${selfHealed} self-healed`);
    return { transitioned, selfHealed };
  });

/**
 * Rich audit log for billing transitions (append-only).
 * Always includes: fromStatus, toStatus, reason, paidUntil, graceUntil
 */
async function _auditTransition(companyId, fromStatus, toStatus, reason, paidUntil, graceUntil) {
  try {
    const auditData = {
      moduleKey: "billing",
      type: "billing_status_changed",
      entity: { collection: "companies", docId: companyId },
      createdBy: "system:billingEnforcer",
      createdAt: FieldValue.serverTimestamp(),
      fromStatus,
      toStatus,
      reason,
    };
    if (paidUntil) auditData.paidUntil = Timestamp.fromDate(paidUntil);
    if (graceUntil) auditData.graceUntil = Timestamp.fromDate(graceUntil);

    await db.collection(`companies/${companyId}/audit`).add(auditData);
  } catch (err) {
    console.warn(`⚠️ Audit write failed for ${companyId}: ${err.message}`);
  }
}
