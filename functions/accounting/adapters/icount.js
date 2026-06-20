const client = require("./icount_client");

/** iCount API v3 — form-encoded doc/create. */
module.exports = {
  name: "icount",

  async createDocument({ payload, credentials }) {
    if (!credentials?.token) {
      return { ok: false, reason: "missing_credentials" };
    }
    try {
      return await client.createDocument({ payload, credentials });
    } catch (e) {
      console.error("❌ iCount createDocument:", e.message);
      return { ok: false, reason: "api_error", message: e.message };
    }
  },
};
