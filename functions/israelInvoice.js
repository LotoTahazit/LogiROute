const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();

/**
 * חשבוניות ישראל — מספר הקצאה (Israel Tax Authority allocation number).
 * НАТИВНАЯ интеграция, ВСЁ на сервере (токен/секрет НИКОГДА в клиенте).
 *
 * Поток (OAuth2 Authorization Code):
 *   1) israelInvoiceAuthUrl — выдаёт ссылку, по которой компания один раз
 *      авторизуется в רשות המסים;
 *   2) israelInvoiceOAuthCallback — меняет code на refresh-токен и кладёт его в
 *      companies/{cid}/private/israelInvoice (клиенту правила запрещают читать);
 *   3) requestAllocationNumber — обновляет access-токен и POST /Invoices/v2/Approval,
 *      пишет assignmentNumber/статус в счёт.
 *
 * === НАСТРОЙКА (functions/.env) — заполнить ПОСЛЕ регистрации ПО как «בית תוכנה»
 *     в שע"מ (тогда выдаются client_id/secret + точные OAuth-URL + sandbox): ===
 *   ISRAEL_INVOICE_ENV           = sandbox | production   (по умолчанию sandbox)
 *   ISRAEL_INVOICE_CLIENT_ID     = client_id из שע"מ
 *   ISRAEL_INVOICE_CLIENT_SECRET = client_secret из שע"מ
 *   ISRAEL_INVOICE_AUTH_URL      = OAuth authorize endpoint (из Open API User Guide)
 *   ISRAEL_INVOICE_TOKEN_URL     = OAuth token endpoint
 *   ISRAEL_INVOICE_SCOPE         = scope (из гайда)
 *   ISRAEL_INVOICE_REDIRECT_URI  = https://<region>-<project>.cloudfunctions.net/israelInvoiceOAuthCallback
 */

// Резурс-endpoints известны из офиц. спеки (gov.il vat_software-houses-180724-en).
const API_BASE = process.env.ISRAEL_INVOICE_ENV === "production"
  ? "https://ita-api.taxes.gov.il/shaam/production"
  : "https://ita-api.taxes.gov.il/shaam/tsandbox";
const APPROVAL_URL = `${API_BASE}/Invoices/v2/Approval`;

function cfg(name) {
  const v = process.env[name];
  if (!v) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Israel Invoice API not configured: ${name} (functions/.env). ` +
        "Зарегистрируйте ПО в שע\"מ и заполните креды.",
    );
  }
  return v;
}

function isPlatformConfigured() {
  return !!(
    process.env.ISRAEL_INVOICE_CLIENT_ID &&
    process.env.ISRAEL_INVOICE_CLIENT_SECRET &&
    process.env.ISRAEL_INVOICE_AUTH_URL &&
    process.env.ISRAEL_INVOICE_TOKEN_URL &&
    process.env.ISRAEL_INVOICE_REDIRECT_URI
  );
}

function oauthStateSecret() {
  const secret = process.env.ISRAEL_INVOICE_CLIENT_SECRET;
  if (!secret) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "ISRAEL_INVOICE_CLIENT_SECRET required for signed OAuth state",
    );
  }
  return secret;
}

function signState(companyId) {
  const sig = crypto
    .createHmac("sha256", oauthStateSecret())
    .update(String(companyId))
    .digest("hex")
    .slice(0, 16);
  return `${companyId}.${sig}`;
}

function parseState(state) {
  const s = String(state || "");
  const dot = s.lastIndexOf(".");
  if (dot < 1) return null;
  const companyId = s.slice(0, dot);
  const sig = s.slice(dot + 1);
  let secret;
  try {
    secret = oauthStateSecret();
  } catch {
    return null;
  }
  const expected = crypto
    .createHmac("sha256", secret)
    .update(companyId)
    .digest("hex")
    .slice(0, 16);
  return sig === expected ? companyId : null;
}

async function getCompanyTaxId(companyId) {
  const settingsSnap = await db
    .doc(`companies/${companyId}/settings/settings`)
    .get();
  const fromSettings = settingsSnap.exists ? settingsSnap.data().taxId : "";
  if (fromSettings) return String(fromSettings);
  const legacy = await db.doc(`companies/${companyId}`).get();
  return legacy.exists && legacy.data().taxId ? String(legacy.data().taxId) : "";
}

/** Док с токеном тенанта — читает только admin-SDK (правила: клиенту запрещено). */
function tokenRef(companyId) {
  return db.doc(`companies/${companyId}/private/israelInvoice`);
}

function invoiceRef(companyId, invoiceId) {
  return db.doc(
    `companies/${companyId}/accounting/_root/invoices/${invoiceId}`,
  );
}

/** Проверка: вызывающий — админ/владелец этой компании (или super_admin). */
function assertCompanyAdmin(context, companyId) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const t = context.auth.token || {};
  const ok = t.role === "super_admin" ||
    (t.companyId === companyId &&
      (t.role === "owner" || t.role === "admin" || t.role === "accountant"));
  if (!ok) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only company owner/admin/accountant can manage Israel Invoice connection",
    );
  }
}

/** Порог מספר הקצаה по дате (до НДС), синхронно с lib/models/invoice.dart. */
function thresholdFor(date) {
  if (date >= new Date("2026-06-01")) return 5000;
  if (date >= new Date("2026-01-01")) return 10000;
  return 20000;
}

/** Суммы из позиций счёта (зеркало Invoice.vatAmount/subtotalBeforeVAT в Dart). */
function computeAmounts(inv) {
  const items = Array.isArray(inv.items) ? inv.items : [];
  const lineNet = (i) => (Number(i.quantity) || 0) * (Number(i.pricePerUnit) || 0);
  const totalBeforeDiscount = items.reduce((s, i) => s + lineNet(i), 0);
  const discount = Number(inv.discount) || 0;
  const subtotal = totalBeforeDiscount * (1 - discount / 100);
  const hasLineVat = items.some((i) => i.vatRate != null);
  let vat;
  if (!hasLineVat) {
    vat = subtotal * 0.18;
  } else {
    const f = 1 - discount / 100;
    vat = items.reduce(
      (s, i) => s + lineNet(i) * f * (i.vatRate != null ? Number(i.vatRate) : 0.18),
      0,
    );
  }
  return { subtotal, vat, total: subtotal + vat };
}

function ymd(ts) {
  const d = ts && typeof ts.toDate === "function" ? ts.toDate() : new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}`;
}

// ───────────────────────── OAuth: authorize URL ─────────────────────────

exports.israelInvoiceAuthUrl = functions.https.onCall(async (data, context) => {
  const companyId = data && data.companyId;
  if (!companyId) {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }
  assertCompanyAdmin(context, companyId);

  const url = new URL(cfg("ISRAEL_INVOICE_AUTH_URL"));
  url.searchParams.set("response_type", "code");
  url.searchParams.set("client_id", cfg("ISRAEL_INVOICE_CLIENT_ID"));
  url.searchParams.set("redirect_uri", cfg("ISRAEL_INVOICE_REDIRECT_URI"));
  url.searchParams.set("scope", process.env.ISRAEL_INVOICE_SCOPE || "scope");
  url.searchParams.set("state", signState(companyId));
  return { url: url.toString(), platformConfigured: isPlatformConfigured() };
});

// ──────────────────────── OAuth: callback (code→token) ───────────────────

exports.israelInvoiceOAuthCallback = functions.https.onRequest(async (req, res) => {
  const code = req.query.code;
  const companyId = parseState(req.query.state);
  if (!code || !companyId) {
    res.status(400).send("Missing or invalid code/state");
    return;
  }
  try {
    const body = new URLSearchParams({
      grant_type: "authorization_code",
      code: String(code),
      redirect_uri: cfg("ISRAEL_INVOICE_REDIRECT_URI"),
      client_id: cfg("ISRAEL_INVOICE_CLIENT_ID"),
      client_secret: cfg("ISRAEL_INVOICE_CLIENT_SECRET"),
    });
    const r = await fetch(cfg("ISRAEL_INVOICE_TOKEN_URL"), {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });
    const tok = await r.json();
    if (!r.ok || !tok.refresh_token) {
      console.error("israelInvoice token exchange failed", r.status, tok);
      res.status(502).send("Token exchange failed");
      return;
    }
    await tokenRef(String(companyId)).set({
      refreshToken: tok.refresh_token,
      accessToken: tok.access_token || null,
      accessTokenExpiry: Date.now() + (Number(tok.expires_in) || 0) * 1000,
      connectedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    res.status(200).send(
      "<html dir='rtl'><body style='font-family:sans-serif;text-align:center;padding:40px'>" +
      "<h2>✅ החיבור למערכת חשבוניות ישראל הושלם</h2>" +
      "<p>אפשר לסגור את החלון ולחזור לאפליקציה.</p></body></html>",
    );
  } catch (e) {
    console.error("israelInvoiceOAuthCallback error", e);
    res.status(500).send("OAuth callback error");
  }
});

// ──────────────── Получить валидный access-токен (refresh) ───────────────

async function getAccessToken(companyId) {
  const snap = await tokenRef(companyId).get();
  if (!snap.exists || !snap.data().refreshToken) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Company is not connected to Israel Invoice (no token). Run OAuth connect first.",
    );
  }
  const data = snap.data();
  if (data.accessToken && data.accessTokenExpiry &&
      Date.now() < data.accessTokenExpiry - 60000) {
    return data.accessToken; // ещё валиден (буфер 60с)
  }
  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: data.refreshToken,
    client_id: cfg("ISRAEL_INVOICE_CLIENT_ID"),
    client_secret: cfg("ISRAEL_INVOICE_CLIENT_SECRET"),
  });
  const r = await fetch(cfg("ISRAEL_INVOICE_TOKEN_URL"), {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });
  const tok = await r.json();
  if (!r.ok || !tok.access_token) {
    throw new functions.https.HttpsError("unavailable",
      `Token refresh failed: ${r.status}`);
  }
  await tokenRef(companyId).set({
    accessToken: tok.access_token,
    accessTokenExpiry: Date.now() + (Number(tok.expires_in) || 0) * 1000,
    // ITA может вернуть новый refresh_token (ротация) — сохраняем.
    ...(tok.refresh_token ? { refreshToken: tok.refresh_token } : {}),
  }, { merge: true });
  return tok.access_token;
}

/**
 * ⚠️ Тело запроса /Approval — структура по требованиям спеки; ТОЧНЫЕ имена полей
 * сверить с Open API User Guide (sandbox) при подключении. Суммы — в шекелях с
 * 2 знаками; тип документа 305 = חשבונית מס (уточнить коды).
 */
function buildApprovalPayload(inv, amounts, sellerVatId) {
  return {
    Invoice_ID: inv.sequentialNumber,
    Invoice_Type: 305,
    Invoice_Date: ymd(inv.deliveryDate || inv.createdAt),
    Seller_VAT_Number: sellerVatId,
    Customer_VAT_Number: inv.clientNumber || "",
    Amount_Before_VAT: Number(amounts.subtotal.toFixed(2)),
    VAT_Amount: Number(amounts.vat.toFixed(2)),
    Payment_Amount: Number(amounts.total.toFixed(2)),
  };
}

// ─────────────────── requestAllocationNumber (callable) ──────────────────

async function requestAllocationForInvoice(companyId, invoiceId) {
  const ref = invoiceRef(companyId, invoiceId);
  const snap = await ref.get();
  if (!snap.exists) {
    return { ok: false, reason: "not_found" };
  }
  const inv = snap.data();

  // מספר הקצаה запрашивается ТОЛЬКО для ВЫПИСАННОГО документа с присвоенным
  // номером (для черновика номер ещё не выдан — запрос некорректен).
  if (inv.status !== "issued" || !(Number(inv.sequentialNumber) > 0)) {
    return { ok: false, reason: "not_issued" };
  }

  if (inv.assignmentStatus === "approved" && inv.assignmentNumber) {
    return { ok: true, alreadyApproved: true, assignmentNumber: inv.assignmentNumber };
  }

  const amounts = computeAmounts(inv);
  const reqDate = inv.deliveryDate && inv.deliveryDate.toDate
    ? inv.deliveryDate.toDate() : new Date();
  if (amounts.subtotal < thresholdFor(reqDate)) {
    await ref.update({ assignmentStatus: "notRequired" });
    return { ok: true, notRequired: true };
  }

  const sellerVatId = await getCompanyTaxId(companyId);
  if (!sellerVatId) {
    await ref.update({ assignmentStatus: "error", assignmentResponseRaw: "missing company taxId in settings/settings" });
    return { ok: false, error: "missing_tax_id" };
  }

  await ref.update({
    assignmentStatus: "pending",
    assignmentRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    const accessToken = await getAccessToken(companyId);
    const r = await fetch(APPROVAL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify(buildApprovalPayload(inv, amounts, sellerVatId)),
    });
    const raw = await r.text();
    let parsed = {};
    try { parsed = JSON.parse(raw); } catch (_) { /* not json */ }

    if (r.ok && (parsed.Confirmation_Number || parsed.allocationNumber)) {
      const num = String(parsed.Confirmation_Number || parsed.allocationNumber);
      await ref.update({
        assignmentNumber: num,
        assignmentStatus: "approved",
        assignmentResponseRaw: raw.slice(0, 4000),
      });
      return { ok: true, assignmentNumber: num };
    }
    const rejection = r.status === 400 || r.status === 403;
    await ref.update({
      assignmentStatus: rejection ? "rejected" : "error",
      assignmentResponseRaw: raw.slice(0, 4000),
    });
    return { ok: false, status: r.status, rejection, message: raw.slice(0, 500) };
  } catch (e) {
    await ref.update({ assignmentStatus: "error", assignmentResponseRaw: String(e).slice(0, 1000) });
    return { ok: false, error: String(e) };
  }
}

exports.requestAllocationForInvoice = requestAllocationForInvoice;

exports.requestAllocationNumber = functions.https.onCall(async (data, context) => {
  const companyId = data && data.companyId;
  const invoiceId = data && data.invoiceId;
  if (!companyId || !invoiceId) {
    throw new functions.https.HttpsError("invalid-argument",
      "companyId and invoiceId required");
  }
  assertCompanyAdmin(context, companyId);

  return requestAllocationForInvoice(companyId, invoiceId);
});

exports.israelInvoiceStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const companyId = data && data.companyId;
  if (!companyId) {
    throw new functions.https.HttpsError("invalid-argument", "companyId required");
  }

  const uid = context.auth.uid;
  const userSnap = await db.doc(`users/${uid}`).get();
  const role = userSnap.data()?.role;
  const userCompany = userSnap.data()?.companyId;
  const allowed =
    role === "super_admin" ||
    (userCompany === companyId &&
      ["admin", "accountant", "owner"].includes(role));
  if (!allowed) {
    throw new functions.https.HttpsError("permission-denied", "Not allowed");
  }

  const platformConfigured = isPlatformConfigured();
  const tokenSnap = await tokenRef(companyId).get();
  const companyConnected =
    tokenSnap.exists && !!tokenSnap.data()?.refreshToken;

  return {
    platformConfigured,
    companyConnected,
    assignmentReady: platformConfigured && companyConnected,
  };
});
