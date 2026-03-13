const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const db = admin.firestore();

/**
 * Trigger: новый документ в /users/{uid} с role == 'pending'
 * Отправляет email super_admin'у о новой регистрации.
 *
 * Requires env vars:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
 *   SUPER_ADMIN_EMAIL  — куда слать уведомление
 */
exports.onUserRegistered = functions.firestore
  .document("users/{uid}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    // Только pending-пользователи (новые регистрации через onboarding)
    if (!data || data.role !== "pending") return null;

    const { uid } = context.params;
    const userName = data.name || "—";
    const userEmail = data.email || "—";
    const userPhone = data.phone || "—";
    const createdAt = data.createdAt
      ? data.createdAt.toDate().toLocaleString("he-IL", { timeZone: "Asia/Jerusalem" })
      : new Date().toLocaleString("he-IL", { timeZone: "Asia/Jerusalem" });

    console.log(`👤 New pending user: uid=${uid}, email=${userEmail}`);

    // SMTP config
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = parseInt(process.env.SMTP_PORT || "587", 10);
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const smtpFrom = process.env.SMTP_FROM || smtpUser;
    const superAdminEmail = process.env.SUPER_ADMIN_EMAIL;

    if (!smtpHost || !smtpUser || !smtpPass || !superAdminEmail) {
      console.log("⚠️ SMTP or SUPER_ADMIN_EMAIL not configured, skipping");
      return null;
    }

    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: { user: smtpUser, pass: smtpPass },
    });

    // Firebase Console deep-link to the user doc (optional, handy)
    const consoleUrl = `https://console.firebase.google.com/project/${process.env.GCLOUD_PROJECT}/firestore/data/users/${uid}`;

    const subject = `[LogiRoute] משתמש חדש נרשם — ${userName}`;
    const html = `
      <div style="font-family: Arial, sans-serif; direction: rtl; text-align: right; max-width: 600px; margin: 0 auto;">
        <div style="background: #1565C0; color: white; padding: 16px 24px; border-radius: 8px 8px 0 0;">
          <h2 style="margin: 0;">👤 משתמש חדש ממתין לאישור</h2>
        </div>
        <div style="background: #f5f5f5; padding: 24px; border-radius: 0 0 8px 8px;">
          <table style="width: 100%; border-collapse: collapse; font-size: 15px;">
            <tr>
              <td style="padding: 8px 0; color: #666; width: 120px;">שם:</td>
              <td style="padding: 8px 0; font-weight: bold;">${userName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">אימייל:</td>
              <td style="padding: 8px 0;">${userEmail}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">טלפון:</td>
              <td style="padding: 8px 0;">${userPhone}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">UID:</td>
              <td style="padding: 8px 0; font-size: 12px; color: #999;">${uid}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">נרשם:</td>
              <td style="padding: 8px 0;">${createdAt}</td>
            </tr>
          </table>
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          <p style="font-size: 14px; color: #333;">
            יש לשייך את המשתמש לחברה ולהקצות לו תפקיד במערכת הניהול.
          </p>
          <a href="${consoleUrl}"
             style="display: inline-block; background: #1565C0; color: white; padding: 10px 20px;
                    border-radius: 6px; text-decoration: none; font-size: 14px; margin-top: 8px;">
            פתח ב-Firestore Console
          </a>
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          <p style="font-size: 12px; color: #999;">הודעה אוטומטית מ-LogiRoute. אין להשיב להודעה זו.</p>
        </div>
      </div>
    `;

    try {
      await transporter.sendMail({
        from: `"LogiRoute" <${smtpFrom}>`,
        to: superAdminEmail,
        subject,
        html,
      });
      console.log(`✅ Registration notification sent to ${superAdminEmail}`);
    } catch (err) {
      console.error(`❌ Failed to send registration email: ${err.message}`);
    }

    return null;
  });
