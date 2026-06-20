function normalizeVatRate(v) {
  const n = Number(v);
  if (!Number.isFinite(n) || n <= 0) return 18;
  if (n <= 1) return Math.round(n * 100);
  return n;
}

/**
 * Map LogiRoute invoice / accountingDoc → neutral payload for external adapters.
 */
function mapInvoiceToExternalDoc({ invoice, companySettings }) {
  const isOwnerDoc = invoice.totals != null && invoice.customerName != null;
  const rawLines = invoice.lines || [];
  const lines = rawLines.map((line) => ({
    description: line.description || line.name || "",
    quantity: Number(line.quantity) || 1,
    unitPrice: Number(
      line.unitPrice ?? line.price ?? line.totalBeforeVat ?? 0
    ),
    vatRate: normalizeVatRate(line.vatRate ?? line.vat ?? 0.18),
  }));

  const netFromTotals = isOwnerDoc
    ? Number(invoice.totals?.net ?? 0)
    : Number(invoice.net ?? 0);
  const vatFromTotals = isOwnerDoc
    ? Number(invoice.totals?.vat ?? 0)
    : Number(invoice.vat ?? 0);
  const grossFromTotals = isOwnerDoc
    ? Number(invoice.totals?.gross ?? 0)
    : Number(invoice.gross ?? 0);

  const net =
    netFromTotals ||
    lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);
  const vat =
    vatFromTotals ||
    lines.reduce(
      (sum, l) => sum + l.quantity * l.unitPrice * (l.vatRate / 100),
      0
    );

  const docType = isOwnerDoc
    ? invoice.type || "tax_invoice"
    : invoice.docType || invoice.counterKey || "invoice";

  return {
    docType,
    docNumber: invoice.docNumber,
    clientName: invoice.clientName || invoice.customerName || "",
    clientTaxId: invoice.clientTaxId || invoice.customerTaxId || "",
    clientAddress: invoice.clientAddress || invoice.address || "",
    currency: invoice.currency || "ILS",
    lines,
    net,
    vat,
    gross: grossFromTotals || net + vat,
    notes: invoice.notes || "",
    issuedAt: invoice.issuedAt,
    company: {
      name: companySettings?.nameHebrew || companySettings?.nameEnglish || "",
      taxId: companySettings?.taxId || "",
    },
  };
}

module.exports = { mapInvoiceToExternalDoc };
