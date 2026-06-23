function normalizeVatRate(v) {
  const n = Number(v);
  if (!Number.isFinite(n) || n <= 0) return 18;
  if (n <= 1) return Math.round(n * 100);
  return n;
}

function tsToIso(ts) {
  if (!ts) return null;
  if (typeof ts.toDate === "function") return ts.toDate().toISOString();
  if (ts instanceof Date) return ts.toISOString();
  return null;
}

/** Invoice.documentType (Dart enum name) → canonical doc type key. */
function mapDocumentType(invoice) {
  const dt = String(invoice.documentType || invoice.docType || "").toLowerCase();
  if (dt === "invoice") return "tax_invoice";
  if (dt === "creditnote") return "credit_note";
  if (dt === "delivery") return "delivery_note";
  if (dt === "taxinvoicereceipt") return "tax_invoice_receipt";
  if (dt === "receipt") return "receipt";
  if (invoice.type) return invoice.type;
  if (invoice.counterKey) return invoice.counterKey;
  return "tax_invoice";
}

function mapItems(invoice) {
  const raw = invoice.items || invoice.lines || [];
  return raw.map((line) => {
    const desc =
      line.description ||
      [line.type, line.number].filter(Boolean).join(" ").trim() ||
      line.name ||
      line.productCode ||
      "";
    const qty = Number(line.quantity) || 1;
    const unit = Number(
      line.pricePerUnit ?? line.unitPrice ?? line.price ?? line.totalBeforeVat ?? 0
    );
    const vr = line.vatRate ?? line.vat ?? 0.18;
    return {
      description: desc || "פריט",
      quantity: qty,
      unitPrice: unit,
      vatRate: normalizeVatRate(vr),
    };
  });
}

function computeTotals(lines, invoice) {
  const netFromTotals = Number(invoice.totals?.net ?? invoice.net ?? 0);
  const vatFromTotals = Number(invoice.totals?.vat ?? invoice.vat ?? 0);
  const grossFromTotals = Number(invoice.totals?.gross ?? invoice.gross ?? 0);

  const net =
    netFromTotals ||
    lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);
  const vat =
    vatFromTotals ||
    lines.reduce(
      (sum, l) => sum + l.quantity * l.unitPrice * (l.vatRate / 100),
      0
    );
  return {
    net,
    vat,
    gross: grossFromTotals || net + vat,
  };
}

/**
 * Map LogiRoute invoice (Firestore `invoices`) → neutral payload for adapters.
 */
function mapInvoiceToExternalDoc({ invoice, companySettings }) {
  const lines = mapItems(invoice);
  const { net, vat, gross } = computeTotals(lines, invoice);
  const docType = mapDocumentType(invoice);

  const refs = invoice.references || {};
  const isCreditNote = docType === "credit_note";
  let notes = invoice.notes || "";
  if (isCreditNote) {
    const origNum =
      refs.originalDocNumber ??
      invoice.originalDocNumber ??
      "";
    const reason = invoice.reason || invoice.voidReason || "";
    notes = notes || `זיכוי למסמך ${origNum}: ${reason}`;
  }

  const issuedAt =
    tsToIso(invoice.finalizedAt) ||
    tsToIso(invoice.issuedAt) ||
    tsToIso(invoice.createdAt);

  return {
    docType,
    docNumber: invoice.sequentialNumber ?? invoice.docNumber ?? null,
    clientName: invoice.clientName || invoice.customerName || "",
    clientTaxId:
      invoice.clientNumber ||
      invoice.clientTaxId ||
      invoice.customerTaxId ||
      "",
    clientAddress: invoice.address || invoice.clientAddress || "",
    currency: invoice.currency || "ILS",
    lines,
    net,
    vat,
    gross,
    notes,
    reason: invoice.reason || invoice.voidReason || "",
    correctionType: invoice.correctionType || "",
    references: {
      originalDocId: refs.originalDocId || invoice.linkedInvoiceId || null,
      originalDocNumber: refs.originalDocNumber ?? invoice.originalDocNumber ?? null,
      originalExternalDocNumber: refs.originalExternalDocNumber ?? null,
    },
    issuedAt,
    paymentLines: (invoice.paymentLines || []).map((p) => ({
      method: p.method || "cash",
      amount: Number(p.amount) || 0,
      dueDate: p.dueDate || null,
      bankNumber: p.bankNumber || null,
      branchNumber: p.branchNumber || null,
      accountNumber: p.accountNumber || null,
      chequeNumber: p.chequeNumber || null,
    })),
    company: {
      name: companySettings?.nameHebrew || companySettings?.nameEnglish || "",
      taxId: companySettings?.taxId || "",
    },
  };
}

module.exports = { mapInvoiceToExternalDoc, mapDocumentType, mapItems };
