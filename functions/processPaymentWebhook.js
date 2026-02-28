const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// =========================================================
// Constants
// =========================================================

/** Anti-replay: reject webhooks older than this (seconds) */
const MAX_WEBHOOK_AGE_SEC = 300; // 5 minutes

// =========================================================
// Webhook Hardening Helpers
// =========================================================

/**
 * Verify Stripe webhook signature using raw body.
 * Stripe signs the raw body (Buffer), NOT the parsed JSON.
 * Format: t=<timestamp>,v1=<signature>
 */
function _verifyStripeSignature(rawBody, sigHeader, secret) {
  if (!sigHeader || !secret) return { valid: false, reason: "missing_sig_or_secret" };

  const parts = {};
  sigHeader.split(",").forEach((item) => {
    const [key, value] = item.split("=");
    parts[key] = value;
  });

  const timestamp = parts["t"];
  const expectedSig = parts["v1"];
  if (!timestamp || !expectedSig) {
    return { valid: false, reason: "malformed_signature_header" };
  }

  // Anti-replay: check timestamp freshness
  const ageSeconds = Math.floor(Date.now() / 1000) - parseInt(timestamp, 10);
  if (ageSeconds > MAX_WEBHOOK_AGE_SEC) {
    return { valid: false, reason: `replay_rejected_age_${ageSeconds}s` };
  }

  // Compute expected signature: HMAC-SHA256(t + "." + rawBody)
  const signedPayload = `${timestamp}.${rawBody}`;
  const computedSig = crypto
    .createHmac("sha256", secret)
    .update(signedPayload, "utf8")
    .digest("hex");

  const isValid = crypto.timingSafeEqual(
    Buffer.from(computedSig, "hex"),
    Buffer.from(expectedSig, "hex")
  );

  return { valid: isValid, reason: isValid ? "ok" : "signature_mismatch" };
}

/**
 * Idempotency check: has this eventId already been processed?
 * Uses companies/{companyId}/payment_events/{eventId} as dedupe ledger.
 *
 * Returns { isDuplicate: bool, existingDoc?: data }
 */
async function _checkIdempotency(companyId, eventId) {
  if (!eventId) return { isDuplicate: false };

  const ref = db.doc(`companies/${companyId}/payment_events/${eventId}`);
  const snap = await ref.get();
  if (snap.exists) {
    return { isDuplicate: true, existingDoc: snap.data() };
  }
  return { isDuplicate: false };
}

/**
 * Record payment event for idempotency (append-only ledger).
 */
async function _recordPaymentEvent(companyId, eventId, data) {
  if (!eventId) return;
  const ref = db.doc(`companies/${companyId}/payment_events/${eventId}`);
  await ref.set({
    ...data,
    processedAt: FieldValue.serverTimestamp(),
  });
}

// =========================================================
// Main Webhook Handler
// =========================================================

/**
 * Payment Webhook Handler — HTTP endpoint для приёма webhook от платёжных провайдеров.
 *
 * Hardening:
 * - Stripe: raw body signature verification + anti-replay (5 min window)
 * - Idempotency: dedupe by eventId in payment_events subcollection
 * - Company lookup: by paymentCustomerId/subscriptionId, NOT from query params
 * - Transactional activation: payment_event + company update in one transaction
 *
 * URL: https://<region>-<project>.cloudfunctions.net/processPaymentWebhook?provider=stripe
 */
exports.processPaymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const provider = req.query.provider;
  if (!provider || !["stripe", "tranzila", "payplus"].includes(provider)) {
    res.status(400).json({ error: "Valid provider query param required (stripe|tranzila|payplus)" });
    return;
  }

  try {
    let result;
    switch (provider) {
      case "stripe":
        result = await _handleStripe(req);
        break;
      case "tranzila":
        result = await _handleTranzila(req);
        break;
      case "payplus":
        result = await _handlePayPlus(req);
        break;
    }

    if (result.companyId && result.paidUntil) {
      // Idempotency check
      const eventId = result.eventId || result.transactionId;
      if (eventId) {
        const { isDuplicate } = await _checkIdempotency(result.companyId, eventId);
        if (isDuplicate) {
          console.log(`🔁 Duplicate webhook ignored: ${eventId} for ${result.companyId}`);
          res.status(200).json({ ok: true, idempotent: true, eventId });
          return;
        }
      }

      await _activateSubscription(
        result.companyId,
        result.paidUntil,
        provider,
        result.subscriptionId,
        result.transactionId,
        eventId
      );
      res.status(200).json({ ok: true, companyId: result.companyId });
    } else {
      // Event not relevant (e.g. non-payment event) — acknowledge
      res.status(200).json({ ok: true, skipped: true, reason: result.reason || "not a payment event" });
    }
  } catch (err) {
    console.error(`❌ Webhook error (${provider}):`, err.message);
    // Return 500 so provider retries (except for validation errors)
    const status = err.statusCode || 500;
    res.status(status).json({ error: err.message });
  }
});

// =========================================================
// Manual Payment Callable
// =========================================================

/**
 * Manual payment registration — callable for super_admin.
 * Позволяет вручную зарегистрировать оплату (банковский перевод, наличные и т.д.)
 *
 * Hardening:
 * - note is required (audit trail)
 * - cannot decrease paidUntil (only extend)
 * - idempotent by transactionId
 */
exports.registerManualPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }

  const uid = context.auth.uid;
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists || userSnap.data().role !== "super_admin") {
    throw new functions.https.HttpsError("permission-denied", "super_admin only");
  }

  const { companyId, paidUntilISO, note } = data;
  if (!companyId || !paidUntilISO) {
    throw new functions.https.HttpsError("invalid-argument", "companyId and paidUntilISO required");
  }
  if (!note || typeof note !== "string" || note.trim().length < 3) {
    throw new functions.https.HttpsError("invalid-argument", "note is required (min 3 chars) — explain why manual payment");
  }

  const paidUntil = new Date(paidUntilISO);
  if (isNaN(paidUntil.getTime())) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid date format");
  }

  // Guard: cannot decrease paidUntil
  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new functions.https.HttpsError("not-found", "Company not found");
  }
  const companyData = companySnap.data();
  const prevStatus = companyData.billingStatus || "unknown";

  if (companyData.paidUntil) {
    const currentPaidUntil = companyData.paidUntil.toDate();
    if (paidUntil < currentPaidUntil) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Cannot decrease paidUntil: current=${currentPaidUntil.toISOString()}, requested=${paidUntil.toISOString()}. Only extending is allowed.`
      );
    }
  }

  const eventId = `manual_${uid}_${Date.now()}`;

  // Idempotency (unlikely for manual, but safe)
  const { isDuplicate } = await _checkIdempotency(companyId, eventId);
  if (isDuplicate) {
    return { ok: true, idempotent: true, eventId };
  }

  await _activateSubscription(companyId, paidUntil, "manual", null, eventId, eventId);

  // Audit with actor info
  await db.collection(`companies/${companyId}/audit`).add({
    moduleKey: "billing",
    type: "billing_status_changed",
    entity: { collection: "companies", docId: companyId },
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    fromStatus: prevStatus,
    toStatus: "active",
    reason: `Manual payment: ${note.trim()}`,
    paymentProvider: "manual",
    paidUntil: Timestamp.fromDate(paidUntil),
  });

  return { ok: true, companyId, paidUntil: paidUntil.toISOString(), eventId };
});

// =========================================================
// Provider-specific handlers
// =========================================================

async function _handleStripe(req) {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = functions.config().stripe?.webhook_secret;

  // A) Verify signature using raw body
  if (webhookSecret) {
    if (!sig) {
      const err = new Error("Missing stripe-signature header");
      err.statusCode = 401;
      throw err;
    }
    const rawBody = req.rawBody; // Buffer — Firebase provides this automatically
    if (!rawBody) {
      const err = new Error("Missing raw body for signature verification");
      err.statusCode = 400;
      throw err;
    }
    const verification = _verifyStripeSignature(rawBody, sig, webhookSecret);
    if (!verification.valid) {
      console.error(`🔐 Stripe signature verification failed: ${verification.reason}`);
      const err = new Error(`Signature verification failed: ${verification.reason}`);
      err.statusCode = 401;
      throw err;
    }
    console.log("🔐 Stripe signature verified OK");
  } else {
    console.warn("⚠️ STRIPE_WEBHOOK_SECRET not configured — signature verification SKIPPED");
  }

  const event = req.body;
  if (!event || !event.type || !event.id) {
    throw new Error("Invalid Stripe event (missing type or id)");
  }

  const stripeEventId = event.id; // e.g. evt_1234... — used for idempotency

  // Handle relevant events
  if (event.type === "invoice.paid" || event.type === "checkout.session.completed") {
    const obj = event.data?.object;
    if (!obj) throw new Error("Missing event data.object");

    // D) Lookup company by paymentCustomerId — NOT from query params
    const customerId = obj.customer;
    const subscriptionId = obj.subscription;
    const periodEnd = obj.lines?.data?.[0]?.period?.end
      || obj.current_period_end
      || null;

    if (!customerId) throw new Error("Missing customer ID in Stripe event");

    const companySnap = await db
      .collection("companies")
      .where("paymentCustomerId", "==", customerId)
      .limit(1)
      .get();

    if (companySnap.empty) {
      console.warn(`⚠️ No company found for Stripe customer: ${customerId}`);
      return { reason: `No company for customer ${customerId}` };
    }

    const companyId = companySnap.docs[0].id;
    const paidUntil = periodEnd ? new Date(periodEnd * 1000) : _addMonth(new Date());

    return { companyId, paidUntil, subscriptionId, transactionId: obj.id, eventId: stripeEventId };
  }

  // Subscription cancelled
  if (event.type === "customer.subscription.deleted") {
    const obj = event.data?.object;
    const customerId = obj?.customer;
    if (customerId) {
      const snap = await db.collection("companies").where("paymentCustomerId", "==", customerId).limit(1).get();
      if (!snap.empty) {
        const companyId = snap.docs[0].id;
        const prevStatus = snap.docs[0].data().billingStatus || "active";

        // Idempotency for cancellation
        const { isDuplicate } = await _checkIdempotency(companyId, stripeEventId);
        if (isDuplicate) {
          return { reason: "subscription_deleted_already_processed" };
        }

        await snap.docs[0].ref.update({
          billingStatus: "cancelled",
          billingStatusChangedAt: FieldValue.serverTimestamp(),
          billingStatusChangedBy: "system:stripe_webhook",
        });

        await _recordPaymentEvent(companyId, stripeEventId, {
          type: "subscription_cancelled",
          provider: "stripe",
          stripeEventId,
          prevStatus,
          newStatus: "cancelled",
        });

        await db.collection(`companies/${companyId}/audit`).add({
          moduleKey: "billing",
          type: "billing_status_changed",
          entity: { collection: "companies", docId: companyId },
          createdBy: "system:stripe_webhook",
          createdAt: FieldValue.serverTimestamp(),
          fromStatus: prevStatus,
          toStatus: "cancelled",
          reason: "Stripe subscription deleted",
        });
      }
    }
    return { reason: "subscription_deleted_handled" };
  }

  return { reason: `Unhandled Stripe event: ${event.type}` };
}

async function _handleTranzila(req) {
  const body = req.body;
  const response = body.Response;
  const tranId = body.ConfirmationCode || body.index;

  if (response !== "000" && response !== "0") {
    console.log(`⚠️ Tranzila non-success response: ${response}`);
    return { reason: `Tranzila response: ${response}` };
  }

  if (!tranId) {
    throw new Error("Missing ConfirmationCode/index in Tranzila webhook");
  }

  // D) Lookup company by TranzilaTK (token) stored as paymentCustomerId
  // Fallback: company_id in custom field (less secure, but needed for initial setup)
  let companyId = null;
  const token = body.TranzilaTK;
  if (token) {
    const snap = await db.collection("companies").where("paymentCustomerId", "==", token).limit(1).get();
    if (!snap.empty) companyId = snap.docs[0].id;
  }
  if (!companyId) {
    companyId = body.company_id || body.custom1;
  }
  if (!companyId) {
    throw new Error("Cannot determine company from Tranzila webhook (no token match, no company_id)");
  }

  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new Error(`Company not found: ${companyId}`);
  }

  const paidUntil = _addMonth(new Date());
  const eventId = `tranzila_${tranId}`;
  return { companyId, paidUntil, subscriptionId: null, transactionId: tranId, eventId };
}

async function _handlePayPlus(req) {
  const body = req.body;
  const statusCode = body.status_code;
  const transactionUid = body.transaction_uid;

  if (statusCode !== "000") {
    return { reason: `PayPlus status: ${statusCode}` };
  }

  if (!transactionUid) {
    throw new Error("Missing transaction_uid in PayPlus webhook");
  }

  // D) Lookup by paymentCustomerId first, fallback to more_info
  let companyId = null;
  const payPlusCustomer = body.customer_uid;
  if (payPlusCustomer) {
    const snap = await db.collection("companies").where("paymentCustomerId", "==", payPlusCustomer).limit(1).get();
    if (!snap.empty) companyId = snap.docs[0].id;
  }
  if (!companyId) {
    companyId = body.more_info;
  }
  if (!companyId) {
    throw new Error("Cannot determine company from PayPlus webhook");
  }

  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new Error(`Company not found: ${companyId}`);
  }

  const paidUntil = _addMonth(new Date());
  const eventId = `payplus_${transactionUid}`;
  return { companyId, paidUntil, subscriptionId: null, transactionId: transactionUid, eventId };
}

// =========================================================
// Shared activation logic (transactional)
// =========================================================

/**
 * Activate subscription — transactional:
 * 1. Check idempotency (payment_events/{eventId})
 * 2. Update company billingStatus + paidUntil
 * 3. Record payment event (dedupe ledger)
 * 4. Audit log
 *
 * All in a Firestore transaction to prevent race conditions.
 */
async function _activateSubscription(companyId, paidUntil, provider, subscriptionId, transactionId, eventId) {
  const companyRef = db.doc(`companies/${companyId}`);

  await db.runTransaction(async (tx) => {
    const companySnap = await tx.get(companyRef);
    if (!companySnap.exists) {
      throw new Error(`Company not found: ${companyId}`);
    }

    // Double-check idempotency inside transaction
    if (eventId) {
      const eventRef = db.doc(`companies/${companyId}/payment_events/${eventId}`);
      const eventSnap = await tx.get(eventRef);
      if (eventSnap.exists) {
        console.log(`🔁 Idempotent (in-tx): ${eventId}`);
        return; // no-op
      }

      // Record payment event inside transaction
      tx.set(eventRef, {
        type: "payment_received",
        provider,
        transactionId: transactionId || null,
        subscriptionId: subscriptionId || null,
        paidUntil: Timestamp.fromDate(paidUntil),
        processedAt: FieldValue.serverTimestamp(),
        prevStatus: companySnap.data().billingStatus || "unknown",
        newStatus: "active",
      });
    }

    const prevStatus = companySnap.data().billingStatus || "unknown";

    const update = {
      billingStatus: "active",
      paidUntil: Timestamp.fromDate(paidUntil),
      paymentProvider: provider,
      billingStatusChangedAt: FieldValue.serverTimestamp(),
      billingStatusChangedBy: `system:${provider}_webhook`,
    };
    if (subscriptionId) update.subscriptionId = subscriptionId;

    tx.update(companyRef, update);

    console.log(`✅ ${companyId}: ${prevStatus} → active (paid until ${paidUntil.toISOString()}) [event: ${eventId}]`);
  });

  // Audit outside transaction (non-blocking, append-only)
  try {
    const companySnap = await companyRef.get();
    const prevStatus = companySnap.data()?.billingStatusChangedBy?.includes("webhook")
      ? "grace_or_other" // approximate — real prev was in transaction
      : "unknown";

    await db.collection(`companies/${companyId}/audit`).add({
      moduleKey: "billing",
      type: "billing_status_changed",
      entity: { collection: "companies", docId: companyId },
      createdBy: `system:${provider}_webhook`,
      createdAt: FieldValue.serverTimestamp(),
      toStatus: "active",
      reason: `Payment received via ${provider}`,
      transactionId,
      eventId,
      paidUntil: Timestamp.fromDate(paidUntil),
    });

    // Notification: payment received
    await db.collection(`companies/${companyId}/notifications`).add({
      type: "payment_received",
      title: "התשלום התקבל בהצלחה",
      body: `התשלום דרך ${provider} התקבל. החשבון פעיל עד ${paidUntil.toISOString().split("T")[0]}.`,
      severity: "info",
      createdAt: FieldValue.serverTimestamp(),
      read: false,
    });
  } catch (auditErr) {
    console.warn(`⚠️ Audit write failed (non-blocking): ${auditErr.message}`);
  }
}

function _addMonth(date) {
  const d = new Date(date);
  d.setMonth(d.getMonth() + 1);
  return d;
}
