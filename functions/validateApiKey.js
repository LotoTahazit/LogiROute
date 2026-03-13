const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

/**
 * HTTP function: валидация API-ключа компании.
 *
 * Внешние системы могут вызывать этот endpoint для проверки ключа
 * и получения данных компании.
 *
 * Headers:
 *   - x-api-key: string
 *
 * Response:
 *   - 200: { valid: true, companyId, companyName }
 *   - 401: { valid: false, error: "..." }
 */
exports.validateApiKey = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, x-api-key");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const apiKey = req.headers["x-api-key"];
  if (!apiKey) {
    res.status(401).json({ valid: false, error: "Missing x-api-key header" });
    return;
  }

  try {
    // Search all companies for matching API key
    const companiesSnap = await db.collection("companies").get();

    for (const companyDoc of companiesSnap.docs) {
      const companyId = companyDoc.id;

      const intDoc = await db
        .collection("companies")
        .doc(companyId)
        .collection("settings")
        .doc("integrations")
        .get();

      if (!intDoc.exists) continue;

      const intData = intDoc.data();
      const apiKeysCfg = intData.apiKeys || {};

      if (apiKeysCfg.enabled && apiKeysCfg.key === apiKey) {
        const companyData = companyDoc.data();
        console.log(`✅ API key validated for company ${companyId}`);

        // Log access
        await db
          .collection("companies")
          .doc(companyId)
          .collection("api_access_logs")
          .add({
            ip: req.ip,
            userAgent: req.headers["user-agent"] || "",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

        res.status(200).json({
          valid: true,
          companyId,
          companyName: companyData.nameHebrew || companyData.nameEnglish || "",
        });
        return;
      }
    }

    console.log("❌ Invalid API key attempt");
    res.status(401).json({ valid: false, error: "Invalid API key" });
  } catch (err) {
    console.error(`❌ validateApiKey error: ${err.message}`);
    res.status(500).json({ valid: false, error: "Internal error" });
  }
});

/**
 * Callable: получение данных через API-ключ (для внутреннего использования).
 *
 * Позволяет внешним системам получать данные о доставках, клиентах и т.д.
 * через API-ключ компании.
 *
 * Параметры:
 *   - apiKey: string
 *   - action: "deliveries" | "clients" | "status"
 *   - params?: object (фильтры)
 */
exports.apiKeyAction = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, x-api-key");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const apiKey = req.headers["x-api-key"];
  if (!apiKey) {
    res.status(401).json({ error: "Missing x-api-key header" });
    return;
  }

  try {
    // Find company by API key
    const companiesSnap = await db.collection("companies").get();
    let foundCompanyId = null;

    for (const companyDoc of companiesSnap.docs) {
      const intDoc = await db
        .collection("companies")
        .doc(companyDoc.id)
        .collection("settings")
        .doc("integrations")
        .get();

      if (!intDoc.exists) continue;
      const intData = intDoc.data();
      const apiKeysCfg = intData.apiKeys || {};

      if (apiKeysCfg.enabled && apiKeysCfg.key === apiKey) {
        foundCompanyId = companyDoc.id;
        break;
      }
    }

    if (!foundCompanyId) {
      res.status(401).json({ error: "Invalid API key" });
      return;
    }

    const action = req.query.action || req.body?.action;

    switch (action) {
      case "deliveries": {
        // Get today's delivery points
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const snap = await db
          .collection("delivery_points")
          .where("companyId", "==", foundCompanyId)
          .where("date", ">=", admin.firestore.Timestamp.fromDate(today))
          .limit(200)
          .get();

        const deliveries = snap.docs.map((d) => ({
          id: d.id,
          clientName: d.data().clientName || "",
          address: d.data().address || "",
          status: d.data().status || "",
          pallets: d.data().pallets || 0,
        }));
        res.status(200).json({ deliveries });
        break;
      }

      case "status": {
        res.status(200).json({
          status: "active",
          companyId: foundCompanyId,
          timestamp: new Date().toISOString(),
        });
        break;
      }

      default:
        res.status(400).json({
          error: "Unknown action. Supported: deliveries, status",
        });
    }
  } catch (err) {
    console.error(`❌ apiKeyAction error: ${err.message}`);
    res.status(500).json({ error: "Internal error" });
  }
});
