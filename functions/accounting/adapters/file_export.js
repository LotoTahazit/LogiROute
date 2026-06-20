/** File export fallback — no live API; marks doc for uniform CSV export. */
module.exports = {
  name: "export",

  async createDocument({ payload }) {
    return {
      ok: true,
      status: "export_only",
      externalId: null,
      message: "Use uniform CSV export from LogiRoute admin",
      payloadPreview: {
        client: payload.clientName,
        gross: payload.gross,
      },
    };
  },
};
