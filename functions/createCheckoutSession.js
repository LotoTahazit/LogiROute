const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

/**
 * createCheckoutSession — Callable Function
 *
 * Генерирует payment link для hosted checkout у настроенного провайдера.
 * Клиент получает URL → редирект → оплата → webhook → active.
 *
 * Поддерживаемые провайдеры:
 * - stripe: Stripe Checkout Session
 * - tranzila: Tranzila hosted payment page URL
 * - payplus: PayPlus payment page link
 *
 * Input: { companyId } (опционально: planId, months)
 * Output: { url, sessionId, provider }
 *
 * Источник правды — ВСЕГДА webhook. Этот endpoint только генерирует ссылку.
 */
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  // --- Auth ---
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const uid = context.auth.uid;

  // --- Input ---
  const { companyId, months } = data;
  if (!companyId || typeof companyId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }
  const billingMonths = months && Number.isInteger(months) && months > 0 ? months : 1;

  // --- User check: must be admin of this company or super_admin ---
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError("permission-denied", "User not found");
  }
  const userData = userSnap.data();
  const isSuperAdmin = userData.role === "super_admin";
  if (!isSuperAdmin) {
    if (userData.companyId !== companyId) {
      throw new functions.https.HttpsError("permission-denied", "Not a member of this company");
    }
    if (!["admin"].includes(userData.role)) {
      throw new functions.https.HttpsError("permission-denied", "Only admin can initiate payment");
    }
  }

  // --- Company doc ---
  const companySnap = await db.doc(`companies/${companyId}`).get();
  if (!companySnap.exists) {
    throw new functions.https.HttpsError("not-found", "Company not found");
  }
  const company = companySnap.data();
  const provider = company.paymentProvider || _getDefaultProvider();
  const plan = company.plan || "full";

  // --- Price lookup ---
  const priceConfig = _getPriceConfig(plan, billingMonths);

  let result;
  switch (provider) {
    case "stripe":
      result = await _createStripeSession(companyId, company, priceConfig, uid);
      break;
    case "tranzila":
      result = _createTranzilaUrl(companyId, company, priceConfig);
      break;
    case "payplus":
      result = await _createPayPlusLink(companyId, company, priceConfig);
      break;
    default:
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Payment provider '${provider}' does not support hosted checkout. Use manual payment.`
      );
  }

  // --- Save pending session ---
  await db.collection(`companies/${companyId}/checkout_sessions`).add({
    provider,
    sessionId: result.sessionId || null,
    url: result.url,
    plan,
    months: billingMonths,
    amount: priceConfig.amount,
    currency: priceConfig.currency,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    status: "pending", // pending → completed (via webhook) or expired
  });

  // Audit
  try {
    await db.collection(`companies/${companyId}/audit`).add({
      moduleKey: "billing",
      type: "billing_status_changed",
      entity: { collection: "companies", docId: companyId },
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      reason: `Checkout session created (${provider}, ${plan}, ${billingMonths}mo)`,
    });
  } catch (_) { /* non-blocking */ }

  return {
    url: result.url,
    sessionId: result.sessionId || null,
    provider,
    amount: priceConfig.amount,
    currency: priceConfig.currency,
  };
});

// =========================================================
// Price configuration
// =========================================================

function _getPriceConfig(plan, months) {
  // Monthly prices in ILS (agorot for Stripe)
  const prices = {
    warehouse_only: 149,
    ops: 299,
    full: 499,
    custom: 499,
  };
  const monthlyPrice = prices[plan] || prices.full;
  const amount = monthlyPrice * months;

  return {
    amount, // ILS
    amountAgorot: amount * 100, // for Stripe (cents/agorot)
    currency: "ILS",
    description: `LogiRoute ${plan} — ${months} חודש${months > 1 ? "ים" : ""}`,
    months,
  };
}

function _getDefaultProvider() {
  // Check which provider is configured
  const config = functions.config();
  if (config.stripe?.secret_key) return "stripe";
  if (config.tranzila?.terminal) return "tranzila";
  if (config.payplus?.api_key) return "payplus";
  return "manual"; // fallback
}

// =========================================================
// Stripe Checkout Session
// =========================================================

async function _createStripeSession(companyId, company, priceConfig, uid) {
  const secretKey = functions.config().stripe?.secret_key;
  if (!secretKey) {
    throw new functions.https.HttpsError("failed-precondition", "Stripe not configured (stripe.secret_key)");
  }

  // Use fetch (Node 18+) to call Stripe API directly — no SDK dependency needed
  const params = new URLSearchParams();
  params.append("mode", "subscription");
  params.append("payment_method_types[0]", "card");
  params.append("line_items[0][price_data][currency]", priceConfig.currency.toLowerCase());
  params.append("line_items[0][price_data][unit_amount]", String(priceConfig.amountAgorot / priceConfig.months));
  params.append("line_items[0][price_data][recurring][interval]", "month");
  params.append("line_items[0][price_data][product_data][name]", priceConfig.description);
  params.append("line_items[0][quantity]", "1");
  params.append("client_reference_id", companyId);
  params.append("metadata[companyId]", companyId);
  params.append("metadata[uid]", uid);

  // Success/cancel URLs
  const baseUrl = functions.config().app?.base_url || "https://app.logiroute.com";
  params.append("success_url", `${baseUrl}/billing/success?session_id={CHECKOUT_SESSION_ID}`);
  params.append("cancel_url", `${baseUrl}/billing/cancelled`);

  // Reuse existing Stripe customer if available
  if (company.paymentCustomerId) {
    params.append("customer", company.paymentCustomerId);
  } else {
    params.append("customer_email", company.email || "");
  }

  const response = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${secretKey}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params.toString(),
  });

  const session = await response.json();
  if (!response.ok) {
    console.error("Stripe error:", JSON.stringify(session));
    throw new functions.https.HttpsError("internal", `Stripe error: ${session.error?.message || "unknown"}`);
  }

  // Save customer ID if new
  if (session.customer && !company.paymentCustomerId) {
    await db.doc(`companies/${companyId}`).update({
      paymentCustomerId: session.customer,
    });
  }

  return { url: session.url, sessionId: session.id };
}

// =========================================================
// Tranzila hosted page URL
// =========================================================

function _createTranzilaUrl(companyId, company, priceConfig) {
  const terminal = functions.config().tranzila?.terminal;
  if (!terminal) {
    throw new functions.https.HttpsError("failed-precondition", "Tranzila not configured (tranzila.terminal)");
  }

  const baseUrl = functions.config().app?.base_url || "https://app.logiroute.com";

  // Tranzila hosted payment page parameters
  const params = new URLSearchParams({
    supplier: terminal,
    sum: String(priceConfig.amount),
    currency: "1", // 1 = ILS
    company_id: companyId, // custom field for webhook
    cred_type: "1", // regular charge
    tranmode: "A", // authorization + capture
    notify_url_address: `${functions.config().app?.functions_url || ""}/processPaymentWebhook?provider=tranzila`,
    success_url_address: `${baseUrl}/billing/success`,
    fail_url_address: `${baseUrl}/billing/cancelled`,
    pdesc: priceConfig.description,
  });

  const url = `https://direct.tranzila.com/${terminal}/iframenew.php?${params.toString()}`;
  return { url, sessionId: `tranzila_${Date.now()}` };
}

// =========================================================
// PayPlus payment page link
// =========================================================

async function _createPayPlusLink(companyId, company, priceConfig) {
  const apiKey = functions.config().payplus?.api_key;
  const secretKey = functions.config().payplus?.secret_key;
  if (!apiKey || !secretKey) {
    throw new functions.https.HttpsError("failed-precondition", "PayPlus not configured (payplus.api_key, payplus.secret_key)");
  }

  const baseUrl = functions.config().app?.base_url || "https://app.logiroute.com";

  const payload = {
    payment_page_uid: functions.config().payplus?.page_uid || "",
    charge_method: 1, // charge
    amount: priceConfig.amount,
    currency_code: "ILS",
    description: priceConfig.description,
    more_info: companyId, // custom field for webhook
    customer: {
      customer_name: company.nameHebrew || company.nameEnglish || companyId,
      email: company.email || "",
      phone: company.phone || "",
    },
    sendEmailApproval: true,
    sendEmailFailure: false,
    charge_default: 0,
    success_page_url: `${baseUrl}/billing/success`,
    failure_page_url: `${baseUrl}/billing/cancelled`,
    callback_url: `${functions.config().app?.functions_url || ""}/processPaymentWebhook?provider=payplus`,
  };

  const response = await fetch("https://restapi.payplus.co.il/api/v1.0/PaymentPages/generateLink", {
    method: "POST",
    headers: {
      "Authorization": JSON.stringify({ api_key: apiKey, secret_key: secretKey }),
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const result = await response.json();
  if (!response.ok || result.results?.status !== "success") {
    console.error("PayPlus error:", JSON.stringify(result));
    throw new functions.https.HttpsError("internal", `PayPlus error: ${result.results?.description || "unknown"}`);
  }

  return { url: result.data?.payment_page_link, sessionId: result.data?.page_request_uid };
}
