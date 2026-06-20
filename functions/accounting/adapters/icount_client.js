const ICOUNT_BASE = "https://api.icount.co.il/api/v3.php";

async function _parseJson(res) {
  const text = await res.text();
  try {
    return text ? JSON.parse(text) : {};
  } catch {
    return { raw: text, status: false };
  }
}

function mapDocType(docType) {
  const t = String(docType || "invoice").toLowerCase();
  if (t.includes("credit")) return "refund";
  if (t.includes("receipt") && t.includes("invoice")) return "invrec";
  if (t.includes("receipt")) return "receipt";
  return "invoice";
}

function formatDocDate(issuedAt) {
  const d = issuedAt ? new Date(issuedAt) : new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}${m}${day}`;
}

function buildFormBody(payload) {
  const params = new URLSearchParams();
  params.set("doctype", mapDocType(payload.docType));
  params.set("client_name", payload.clientName || "לקוח");
  if (payload.clientTaxId) params.set("vat_id", payload.clientTaxId);
  params.set("doc_date", formatDocDate(payload.issuedAt));
  params.set("currency", payload.currency === "ILS" ? "NIS" : payload.currency || "NIS");
  params.set("vattype", "1");

  const lines = payload.lines?.length
    ? payload.lines
    : [{ description: payload.notes || "שירות", quantity: 1, unitPrice: payload.net || payload.gross || 0, vatRate: 18 }];

  lines.forEach((line, i) => {
    params.set(`desc[${i}]`, line.description || "פריט");
    params.set(`unitprice[${i}]`, String(line.unitPrice || 0));
    params.set(`quantity[${i}]`, String(line.quantity || 1));
  });

  if (payload.notes) params.set("comment", payload.notes);
  return params;
}

async function createDocument({ payload, credentials }) {
  const token = credentials.token;
  if (!token) {
    throw new Error("iCount token missing");
  }

  const res = await fetch(`${ICOUNT_BASE}/doc/create`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: buildFormBody(payload).toString(),
  });

  const data = await _parseJson(res);
  const failed =
    !res.ok ||
    data.status === false ||
    data.status === "false" ||
    data.error === true ||
    data.error === 1;

  if (failed) {
    const msg =
      data.error_description ||
      data.reason ||
      data.message ||
      data.err_msg ||
      JSON.stringify(data).slice(0, 300);
    throw new Error(`iCount doc/create: ${msg}`);
  }

  const externalId =
    data.doc_id ?? data.docid ?? data.docId ?? data.id ?? null;
  const externalNumber =
    data.docnum ?? data.doc_number ?? data.docNumber ?? data.number ?? null;
  const pdfUrl =
    data.pdf_link ?? data.pdf_url ?? data.doc_url ?? data.url ?? null;

  return {
    ok: true,
    status: "synced",
    externalId: externalId != null ? String(externalId) : null,
    externalNumber: externalNumber != null ? String(externalNumber) : null,
    distributionNumber:
      data.allocation_number != null
        ? String(data.allocation_number)
        : null,
    pdfUrl,
    raw: data,
  };
}

module.exports = { createDocument, mapDocType, buildFormBody };
