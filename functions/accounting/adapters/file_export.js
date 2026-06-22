const admin = require("firebase-admin");
const { buildUniversalCsvRow, csvRowToLine } = require("../csv_row");

/** File export provider — queues row for uniform CSV export. */
module.exports = {
  name: "export",

  async createDocument({ payload, credentials, companyId, docId }) {
    if (!companyId || !docId) {
      return { ok: false, status: "failed", message: "companyId and docId required" };
    }

    const csvRow = buildUniversalCsvRow({ payload, docId });
    const csvPreview = csvRowToLine(csvRow);

    await admin
      .firestore()
      .doc(`companies/${companyId}/accounting/_root/export_queue/${docId}`)
      .set({
        csvRow,
        payload: {
          docType: payload.docType,
          docNumber: payload.docNumber,
          clientName: payload.clientName,
          gross: payload.gross,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      ok: true,
      status: "synced",
      externalId: docId,
      externalNumber:
        payload.docNumber != null ? String(payload.docNumber) : null,
      message: `CSV export queued: ${csvPreview}`,
    };
  },
};
