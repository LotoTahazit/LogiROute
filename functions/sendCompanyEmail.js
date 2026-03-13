const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const db = admin.firestore();

/**
 * Callable function: отправка email от имени компании.
 *
 * Читает SMTP-настройки из companies/{companyId}/settings/integrations → email
 * Если интеграция не настроена — fallback на env-переменные (глобальный SMTP).
 *
 * Параметры:
 *   - companyId: string
 *   - to: string | string[]
 *   - subject: string
 *   - html: string
 *   - text?: string (plain text fallback)
 */
exports.sendCompanyEmail = functions.https.onCall(async (data, context) => {
  // Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const { companyId, to, subject, html, text } = data;
  if (!companyId || !to || !subject || (!html && !text)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "companyId, to, subject, and html/text are required"
    );
  }

  const recipients = Array.isArray(to) ? to : [to];

  try {
    // 1. Try company-specific SMTP from integrations
    const intDoc = await db
      .collection("companies")
      .doc(companyId)
      .collection("settings")
      .doc("integrations")
      .get();

    let smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpSsl;

    const intData = intDoc.exists ? intDoc.data() : {};
    const emailCfg = intData.email || {};

    if (emailCfg.enabled && emailCfg.smtpHost && emailCfg.smtpUser) {
      // Company-specific SMTP
      smtpHost = emailCfg.smtpHost;
      smtpPort = emailCfg.smtpPort || 587;
      smtpUser = emailCfg.smtpUser;
      smtpPass = emailCfg.smtpPassword;
      smtpFrom = emailCfg.smtpFrom || smtpUser;
      smtpSsl = emailCfg.smtpSsl !== false;
      console.log(`📧 Using company SMTP: ${smtpHost}:${smtpPort}`);
    } else {
      // Fallback to global env
      smtpHost = process.env.SMTP_HOST;
      smtpPort = parseInt(process.env.SMTP_PORT || "587", 10);
      smtpUser = process.env.SMTP_USER;
      smtpPass = process.env.SMTP_PASS;
      smtpFrom = process.env.SMTP_FROM || smtpUser;
      smtpSsl = smtpPort === 465;
      console.log(`📧 Using global SMTP: ${smtpHost}:${smtpPort}`);
    }

    if (!smtpHost || !smtpUser || !smtpPass) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "SMTP not configured. Set up email integration or env variables."
      );
    }

    // 2. Create transporter
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpSsl && smtpPort === 465,
      auth: { user: smtpUser, pass: smtpPass },
      tls: { rejectUnauthorized: false },
    });

    // 3. Send to all recipients
    const results = [];
    for (const addr of recipients) {
      try {
        const info = await transporter.sendMail({
          from: `"LogiRoute" <${smtpFrom}>`,
          to: addr,
          subject,
          html: html || undefined,
          text: text || undefined,
        });
        results.push({ email: addr, status: "sent", messageId: info.messageId });
        console.log(`✅ Email sent to ${addr}`);
      } catch (err) {
        results.push({ email: addr, status: "failed", error: err.message });
        console.error(`❌ Email failed for ${addr}: ${err.message}`);
      }
    }

    // 4. Log to Firestore
    await db
      .collection("companies")
      .doc(companyId)
      .collection("email_delivery_logs")
      .add({
        to: recipients,
        subject,
        results,
        sentBy: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    const sent = results.filter((r) => r.status === "sent").length;
    return { success: sent > 0, sent, total: recipients.length, results };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) throw err;
    console.error(`❌ sendCompanyEmail error: ${err.message}`);
    throw new functions.https.HttpsError("internal", err.message);
  }
});
