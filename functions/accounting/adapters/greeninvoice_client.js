const PRODUCTION_BASE = "https://api.greeninvoice.co.il/api/v1";
const SANDBOX_BASE = "https://sandbox.d.greeninvoice.co.il/api/v1";

function baseUrl(credentials) {
  if (credentials?.baseUrl) return credentials.baseUrl.replace(/\/$/, "");
  return credentials?.sandbox ? SANDBOX_BASE : PRODUCTION_BASE;
}

async function _parseJson(res) {
  const text = await res.text();
  try {
    return text ? JSON.parse(text) : {};
  } catch {
    return { raw: text };
  }
}

async function getToken({ apiKey, secretKey, sandbox }) {
  const res = await fetch(`${baseUrl({ sandbox })}/account/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      id: apiKey,
      secret: secretKey,
      grant_type: "client_credentials",
    }),
  });
  const data = await _parseJson(res);
  if (!res.ok) {
    const msg = data.errorMessage || data.message || res.statusText;
    throw new Error(`Greeninvoice auth failed (${res.status}): ${msg}`);
  }
  if (!data.token) {
    throw new Error("Greeninvoice auth: missing token in response");
  }
  return data.token;
}

async function apiRequest({ method, path, token, body, credentials, _isRetry }) {
  const res = await fetch(`${baseUrl(credentials)}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await _parseJson(res);
  if (res.status === 401 && !_isRetry) {
    const fresh = await getToken({
      apiKey: credentials.apiKey,
      secretKey: credentials.secretKey,
      sandbox: credentials.sandbox,
    });
    return apiRequest({
      method,
      path,
      token: fresh,
      body,
      credentials,
      _isRetry: true,
    });
  }
  if (!res.ok) {
    const msg = data.errorMessage || data.message || res.statusText;
    throw new Error(`Greeninvoice ${method} ${path} (${res.status}): ${msg}`);
  }
  return data;
}

function mapDocType(docType) {
  const t = String(docType || "invoice").toLowerCase();
  if (t.includes("credit")) return 330;
  if (t.includes("receipt") && t.includes("invoice")) return 320;
  if (t.includes("receipt")) return 400;
  return 305;
}

function buildDocumentBody(payload) {
  const type = mapDocType(payload.docType);
  const income = (payload.lines || []).map((line) => ({
    description: line.description || "פריט",
    quantity: Number(line.quantity) || 1,
    price: Number(line.unitPrice) || 0,
    vatType: Number(line.vatRate) > 0 ? 0 : 2,
  }));
  if (income.length === 0) {
    income.push({
      description: payload.notes || "שירות",
      quantity: 1,
      price: Number(payload.net) || Number(payload.gross) || 0,
      vatType: 0,
    });
  }

  const body = {
    type,
    lang: "he",
    currency: payload.currency || "ILS",
    client: {
      name: payload.clientName || "לקוח",
      taxId: payload.clientTaxId || undefined,
      add: true,
    },
    income,
    remarks: payload.notes || "",
  };

  if (type === 320 || type === 400) {
    const amount = Number(payload.gross) || income.reduce(
      (s, l) => s + l.quantity * l.price * 1.17,
      0
    );
    body.payment = [
      {
        type: 1,
        price: Math.round(amount * 100) / 100,
        date: new Date().toISOString().slice(0, 10),
      },
    ];
  }

  if (type === 330) {
    const linkNum =
      payload.references?.originalExternalDocNumber ??
      payload.references?.originalDocNumber;
    body.remarks =
      payload.notes ||
      (linkNum != null ? `זיכוי למסמך ${linkNum}` : "");
    if (linkNum != null) {
      body.linkedDocuments = [{ type: 305, number: String(linkNum) }];
    } else if (payload.references?.originalDocId) {
      body.linkedDocuments = [
        { type: 305, number: payload.references.originalDocId },
      ];
    }
  }

  return body;
}

async function createDocument({ payload, credentials }) {
  const useSandbox = credentials.sandbox === true;
  console.log(
    `🌿 Greeninvoice createDocument (${useSandbox ? "sandbox" : "production"}) client=${payload.clientName}`
  );
  const token = await getToken({
    apiKey: credentials.apiKey,
    secretKey: credentials.secretKey,
    sandbox: credentials.sandbox,
  });

  const docBody = buildDocumentBody(payload);
  const created = await apiRequest({
    method: "POST",
    path: "/documents",
    token,
    body: docBody,
    credentials,
  });

  const externalId = created.id || created.documentId;
  let pdfUrl = created.url || created.downloadUrl || null;
  let distributionNumber =
    created.numbering?.allocationNumber ||
    created.allocationNumber ||
    created.number ||
    null;

  if (externalId && !pdfUrl) {
    try {
      const links = await apiRequest({
        method: "GET",
        path: `/documents/${externalId}/download/links`,
        token,
        credentials,
      });
      pdfUrl =
        links.origin ||
        links.he ||
        links.en ||
        (Array.isArray(links) ? links[0]?.url : null) ||
        null;
    } catch (e) {
      console.warn("⚠️ Greeninvoice download links:", e.message);
    }
  }

  return {
    ok: true,
    status: "synced",
    externalId: externalId ? String(externalId) : null,
    externalNumber: created.number != null ? String(created.number) : null,
    distributionNumber: distributionNumber != null ? String(distributionNumber) : null,
    pdfUrl,
    raw: {
      type: created.type,
      totalAmount: created.totalAmount ?? created.total,
    },
  };
}

module.exports = {
  getToken,
  createDocument,
  mapDocType,
  buildDocumentBody,
};
