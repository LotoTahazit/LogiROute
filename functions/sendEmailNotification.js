const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const db = admin.firestore();

/**
 * Trigger: when a billing-related notification is created.
 * Sends email to company admin(s) for critical billing events.
 *
 * Requires env config:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
 *
 * Supported notification types for email:
 *   - billing_grace: "Your account enters grace period"
 *   - billing_suspended: "Your account has been suspended"
 *   - payment_received: "Payment confirmed"
 */
exports.sendEmailNotification = functions.firestore
  .document("companies/{companyId}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const { companyId, notifId } = context.params;
    const data = snap.data();

    // Only send emails for billing-critical notifications
    const emailTypes = [
      "billing_grace",
      "billing_suspended",
      "payment_received",
      "billing_trial_ending",
    ];

    if (!data || !emailTypes.includes(data.type)) {
      return null;
    }

    console.log(`📧 Email trigger for ${companyId}/${notifId}: ${data.type}`);

    try {
      // Get SMTP config from environment
      const smtpHost = process.env.SMTP_HOST;
      const smtpPort = parseInt(process.env.SMTP_PORT || "587", 10);
      const smtpUser = process.env.SMTP_USER;
      const smtpPass = process.env.SMTP_PASS;
      const smtpFrom = process.env.SMTP_FROM || smtpUser;

      if (!smtpHost || !smtpUser || !smtpPass) {
        console.log("⚠️ SMTP not configured, skipping email");
        return null;
      }

      // Find admin users of this company
      const usersSnap = await db
        .collection("users")
        .where("companyId", "==", companyId)
        .where("role", "in", ["admin", "super_admin"])
        .get();

      const emails = usersSnap.docs
        .map((doc) => doc.data().email)
        .filter((e) => e && e.includes("@"));

      if (emails.length === 0) {
        console.log(`⚠️ No admin emails found for company ${companyId}`);
        return null;
      }

      // Create transporter
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpPort === 465,
        auth: { user: smtpUser, pass: smtpPass },
      });

      // Build email content based on type
      const { subject, html } = _buildEmailContent(data);

      // Send to all admins
      const results = [];
      for (const email of emails) {
        try {
          const info = await transporter.sendMail({
            from: `"LogiRoute" <${smtpFrom}>`,
            to: email,
            subject,
            html,
          });
          results.push({ email, status: "sent", smtpResponse: info.response || "" });
          console.log(`✅ Email sent to ${email}`);
        } catch (err) {
          results.push({ email, status: "failed", error: err.message, code: err.code || "" });
          console.error(`❌ Email failed for ${email}: ${err.message}`);
        }
      }

      // Log failures to email_delivery_logs (only errors, to minimize cost)
      const failures = results.filter((r) => r.status === "failed");
      if (failures.length > 0) {
        try {
          const logsRef = db
            .collection("companies")
            .doc(companyId)
            .collection("email_delivery_logs");
          const batch = db.batch();
          for (const f of failures) {
            batch.set(logsRef.doc(), {
              email: f.email,
              errorCode: f.code || "smtp_error",
              errorMessage: f.error,
              notifType: data.type,
              notifId,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        } catch (logErr) {
          console.error(`⚠️ Failed to write email delivery logs: ${logErr.message}`);
        }
      }

      // Record email send in notification doc
      await snap.ref.update({
        emailSent: true,
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        emailResults: results,
      });

      return { sent: results.filter((r) => r.status === "sent").length };
    } catch (err) {
      console.error(`❌ Email notification error: ${err.message}`);
      return null;
    }
  });

/**
 * Build email subject and HTML body based on notification type
 */
function _buildEmailContent(data) {
  const title = data.title || "LogiRoute Notification";
  const body = data.body || "";
  const severity = data.severity || "info";

  const colorMap = {
    critical: "#D32F2F",
    warning: "#F57C00",
    info: "#1976D2",
  };
  const color = colorMap[severity] || colorMap.info;

  const subject = `[LogiRoute] ${title}`;
  const html = `
    <div style="font-family: Arial, sans-serif; direction: rtl; text-align: right; max-width: 600px; margin: 0 auto;">
      <div style="background: ${color}; color: white; padding: 16px 24px; border-radius: 8px 8px 0 0;">
        <h2 style="margin: 0;">${title}</h2>
      </div>
      <div style="background: #f5f5f5; padding: 24px; border-radius: 0 0 8px 8px;">
        <p style="font-size: 16px; color: #333; line-height: 1.6;">${body}</p>
        <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
        <p style="font-size: 12px; color: #999;">
          הודעה אוטומטית מ-LogiRoute. אין להשיב להודעה זו.
        </p>
      </div>
    </div>
  `;

  return { subject, html };
}
