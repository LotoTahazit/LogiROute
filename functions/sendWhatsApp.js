const functions = require("firebase-functions");
const admin = require("firebase-admin");
const https = require("https");

const db = admin.firestore();

/**
 * Callable function: отправка WhatsApp сообщения через WhatsApp Business API.
 *
 * Читает настройки из companies/{companyId}/settings/integrations → whatsapp
 *
 * Параметры:
 *   - companyId: string
 *   - phone: string (номер получателя в формате 972XXXXXXXXX)
 *   - message: string (текст сообщения)
 *   - templateName?: string (имя шаблона WhatsApp, если используется)
 *   - templateParams?: string[] (параметры шаблона)
 */
exports.sendWhatsApp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { companyId, phone, message, templateName, templateParams } = data;
  if (!companyId || !phone) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "companyId and phone are required"
    );
  }

  try {
    // 1. Read WhatsApp config
    const intDoc = await db
      .collection("companies")
      .doc(companyId)
      .collection("settings")
      .doc("integrations")
      .get();

    const intData = intDoc.exists ? intDoc.data() : {};
    const waCfg = intData.whatsapp || {};

    if (!waCfg.enabled || !waCfg.apiUrl || !waCfg.apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "WhatsApp integration not configured"
      );
    }

    // Normalize phone: remove +, spaces, dashes
    const cleanPhone = phone.replace(/[\s\-\+]/g, "");

    // 2. Build request body
    let body;
    if (templateName) {
      // Template message (for first contact / marketing)
      body = JSON.stringify({
        messaging_product: "whatsapp",
        to: cleanPhone,
        type: "template",
        template: {
          name: templateName,
          language: { code: "he" },
          components: templateParams
            ? [
                {
                  type: "body",
                  parameters: templateParams.map((p) => ({
                    type: "text",
                    text: p,
                  })),
                },
              ]
            : [],
        },
      });
    } else {
      // Free-form text message (within 24h window)
      body = JSON.stringify({
        messaging_product: "whatsapp",
        to: cleanPhone,
        type: "text",
        text: { body: message || "LogiRoute notification" },
      });
    }

    // 3. Send via WhatsApp Business API
    const apiUrl = new URL(
      waCfg.phoneId
        ? `${waCfg.apiUrl}/${waCfg.phoneId}/messages`
        : waCfg.apiUrl
    );

    const result = await new Promise((resolve, reject) => {
      const req = https.request(
        {
          hostname: apiUrl.hostname,
          path: apiUrl.pathname,
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${waCfg.apiKey}`,
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => (data += chunk));
          res.on("end", () => {
            try {
              const parsed = JSON.parse(data);
              if (res.statusCode >= 200 && res.statusCode < 300) {
                resolve(parsed);
              } else {
                reject(
                  new Error(
                    `WhatsApp API ${res.statusCode}: ${parsed.error?.message || data}`
                  )
                );
              }
            } catch {
              reject(new Error(`WhatsApp API response parse error: ${data}`));
            }
          });
        }
      );
      req.on("error", reject);
      req.write(body);
      req.end();
    });

    console.log(`✅ WhatsApp sent to ${cleanPhone}:`, JSON.stringify(result));

    // 4. Log
    await db
      .collection("companies")
      .doc(companyId)
      .collection("whatsapp_delivery_logs")
      .add({
        phone: cleanPhone,
        message: message || templateName || "",
        status: "sent",
        waMessageId: result.messages?.[0]?.id || null,
        sentBy: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { success: true, messageId: result.messages?.[0]?.id };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) throw err;
    console.error(`❌ sendWhatsApp error: ${err.message}`);

    // Log failure
    try {
      await db
        .collection("companies")
        .doc(companyId)
        .collection("whatsapp_delivery_logs")
        .add({
          phone: phone,
          message: message || templateName || "",
          status: "failed",
          error: err.message,
          sentBy: context.auth?.uid || "unknown",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (_) {}

    throw new functions.https.HttpsError("internal", err.message);
  }
});
