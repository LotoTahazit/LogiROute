const client = require("./greeninvoice_client");

/** Greeninvoice / Morning — live API via REST. */
module.exports = {
  name: "greeninvoice",

  async createDocument({ payload, credentials }) {
    if (!credentials?.apiKey || !credentials?.secretKey) {
      return { ok: false, reason: "missing_credentials" };
    }
    try {
      return await client.createDocument({ payload, credentials });
    } catch (e) {
      console.error("❌ Greeninvoice createDocument:", e.message);
      return { ok: false, reason: "api_error", message: e.message };
    }
  },
};
