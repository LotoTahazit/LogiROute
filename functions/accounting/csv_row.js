const CSV_COLUMNS = [
  "doc_type",
  "doc_number",
  "date",
  "client_name",
  "client_number",
  "net_amount",
  "vat_amount",
  "total_amount",
  "discount",
  "payment_due",
  "payment_method",
  "status",
  "doc_id",
  "linked_doc_id",
];

function formatDate(dt) {
  const d = dt instanceof Date ? dt : new Date(dt);
  if (Number.isNaN(d.getTime())) return "";
  return [
    String(d.getDate()).padStart(2, "0"),
    String(d.getMonth() + 1).padStart(2, "0"),
    d.getFullYear(),
  ].join("/");
}

function resolveDate(issuedAt) {
  if (!issuedAt) return "";
  if (issuedAt.toDate) return formatDate(issuedAt.toDate());
  if (issuedAt instanceof Date) return formatDate(issuedAt);
  return formatDate(issuedAt);
}

/** Одна строка universal CSV (mirrors accounting_export_service.dart). */
function buildUniversalCsvRow({ payload, docId }) {
  return {
    doc_type: payload.docType || "",
    doc_number: payload.docNumber ?? "",
    date: resolveDate(payload.issuedAt),
    client_name: payload.clientName || "",
    client_number: payload.clientTaxId || "",
    net_amount: Number(payload.net || 0).toFixed(2),
    vat_amount: Number(payload.vat || 0).toFixed(2),
    total_amount: Number(payload.gross || 0).toFixed(2),
    discount: "0.00",
    payment_due: "",
    payment_method: "",
    status: "issued",
    doc_id: docId || "",
    linked_doc_id: payload.references?.originalDocId || "",
  };
}

function csvEscape(value, separator) {
  const s = String(value ?? "");
  if (s.includes(separator) || s.includes('"') || s.includes("\n")) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function csvRowToLine(row, separator = ",") {
  return CSV_COLUMNS.map((k) => csvEscape(row[k], separator)).join(separator);
}

module.exports = {
  CSV_COLUMNS,
  buildUniversalCsvRow,
  csvRowToLine,
  formatDate,
};
