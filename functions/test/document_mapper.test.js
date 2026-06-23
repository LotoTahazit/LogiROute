const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  mapInvoiceToExternalDoc,
  mapDocumentType,
  mapItems,
} = require("../accounting/document_mapper");

describe("document_mapper", () => {
  it("maps sequentialNumber to docNumber", () => {
    const payload = mapInvoiceToExternalDoc({
      invoice: {
        documentType: "invoice",
        sequentialNumber: 42,
        clientName: "Test",
        items: [{ description: "A", quantity: 1, pricePerUnit: 100 }],
      },
      companySettings: { taxId: "123", nameHebrew: "חברה" },
    });
    assert.equal(payload.docNumber, 42);
    assert.equal(payload.docType, "tax_invoice");
    assert.equal(payload.net, 100);
  });

  it("falls back to docNumber when sequentialNumber missing", () => {
    const payload = mapInvoiceToExternalDoc({
      invoice: { documentType: "receipt", docNumber: 7, items: [] },
      companySettings: {},
    });
    assert.equal(payload.docNumber, 7);
    assert.equal(payload.docType, "receipt");
  });

  it("mapDocumentType normalizes Dart enum names", () => {
    assert.equal(mapDocumentType({ documentType: "creditNote" }), "credit_note");
    assert.equal(
      mapDocumentType({ documentType: "taxInvoiceReceipt" }),
      "tax_invoice_receipt"
    );
  });

  it("mapItems uses description and vatRate", () => {
    const lines = mapItems({
      items: [{ description: "שירות", quantity: 2, pricePerUnit: 50, vatRate: 0.17 }],
    });
    assert.equal(lines.length, 1);
    assert.equal(lines[0].description, "שירות");
    assert.equal(lines[0].vatRate, 17);
    assert.equal(lines[0].unitPrice, 50);
  });

  it("includes invoice notes in payload", () => {
    const payload = mapInvoiceToExternalDoc({
      invoice: {
        documentType: "invoice",
        sequentialNumber: 1,
        notes: "הערת בדיקה",
        items: [],
      },
      companySettings: {},
    });
    assert.equal(payload.notes, "הערת בדיקה");
  });
});
