/**
 * Load accounting document from Owner Dashboard (accountingDocs) or legacy invoices.
 */
async function loadAccountingDocument(db, companyId, docId) {
  const ownerRef = db.doc(`companies/${companyId}/accountingDocs/${docId}`);
  const ownerSnap = await ownerRef.get();
  if (ownerSnap.exists) {
    return {
      data: ownerSnap.data() || {},
      source: "accountingDocs",
      ref: ownerRef,
    };
  }

  const invoiceRef = db.doc(
    `companies/${companyId}/accounting/_root/invoices/${docId}`
  );
  const invoiceSnap = await invoiceRef.get();
  if (invoiceSnap.exists) {
    return {
      data: invoiceSnap.data() || {},
      source: "invoices",
      ref: invoiceRef,
    };
  }

  return null;
}

module.exports = { loadAccountingDocument };
