/**
 * Load accounting document from unified invoices collection.
 */
async function loadAccountingDocument(db, companyId, docId) {
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
