const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const RESET_BASE = "https://logiroute-app.web.app/reset-password";

const MESSAGES = {
  ru: {
    subject: "Сброс пароля LogiRoute",
    html: (link) =>
      `<p>Здравствуйте!</p><p>Чтобы задать новый пароль, перейдите по ссылке (действует 1 час):</p><p><a href="${link}">${link}</a></p><p>Если вы не запрашивали сброс — проигнорируйте это письмо.</p>`,
  },
  en: {
    subject: "LogiRoute password reset",
    html: (link) =>
      `<p>Hello!</p><p>Follow this link to set a new password (valid for 1 hour):</p><p><a href="${link}">${link}</a></p><p>If you did not request this, ignore this email.</p>`,
  },
  he: {
    subject: "איפוס סיסמה LogiRoute",
    html: (link) =>
      `<p>שלום,</p><p>לחץ/י על הקישור לקביעת סיסמה חדשה (תקף לשעה):</p><p><a href="${link}">${link}</a></p><p>אם לא ביקשת איפוס — התעלם/י ממייל זה.</p>`,
  },
};

function buildResetLink(firebaseLink) {
  const parsed = new URL(firebaseLink);
  const oobCode = parsed.searchParams.get("oobCode");
  const mode = parsed.searchParams.get("mode") || "resetPassword";
  if (!oobCode) return null;
  return `${RESET_BASE}?mode=${encodeURIComponent(mode)}&oobCode=${encodeURIComponent(oobCode)}`;
}

function getSmtpConfig() {
  const smtpHost = process.env.SMTP_HOST;
  const smtpPort = parseInt(process.env.SMTP_PORT || "587", 10);
  const smtpUser = process.env.SMTP_USER;
  const smtpPass = process.env.SMTP_PASS;
  const smtpFrom = process.env.SMTP_FROM || smtpUser;
  if (!smtpHost || !smtpUser || !smtpPass) return null;
  return {
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: { user: smtpUser, pass: smtpPass },
    from: smtpFrom,
  };
}

/**
 * Отправляет письмо сброса пароля со ссылкой на web.app (не firebaseapp.com).
 */
exports.sendPasswordResetEmail = functions.https.onCall(async (data) => {
  const email = String(data?.email || "")
    .trim()
    .toLowerCase();
  const lang = MESSAGES[data?.languageCode] ? data.languageCode : "ru";

  if (!email || !email.includes("@")) {
    throw new functions.https.HttpsError("invalid-argument", "invalid-email");
  }

  const smtp = getSmtpConfig();
  if (!smtp) {
    console.error("SMTP not configured for password reset");
    throw new functions.https.HttpsError("failed-precondition", "smtp-not-configured");
  }

  let firebaseLink;
  try {
    firebaseLink = await admin.auth().generatePasswordResetLink(email, {
      url: RESET_BASE,
      handleCodeInApp: false,
    });
  } catch (e) {
    // Не раскрываем, есть ли email в системе (enumeration protection).
    if (e.code === "auth/user-not-found") {
      console.log(`Password reset requested for unknown email: ${email}`);
      return { ok: true };
    }
    console.error("generatePasswordResetLink failed:", e);
    throw new functions.https.HttpsError("internal", "link-generation-failed");
  }

  const resetLink = buildResetLink(firebaseLink);
  if (!resetLink) {
    console.error("Could not parse oobCode from:", firebaseLink);
    throw new functions.https.HttpsError("internal", "link-parse-failed");
  }

  const msg = MESSAGES[lang];
  const transporter = nodemailer.createTransport({
    host: smtp.host,
    port: smtp.port,
    secure: smtp.secure,
    auth: smtp.auth,
    tls: { rejectUnauthorized: false },
  });

  try {
    await transporter.sendMail({
      from: `"LogiRoute" <${smtp.from}>`,
      to: email,
      subject: msg.subject,
      html: msg.html(resetLink),
    });
    console.log(`✅ Password reset email sent to ${email}`);
    return { ok: true };
  } catch (e) {
    console.error("SMTP send failed:", e);
    throw new functions.https.HttpsError("internal", "email-send-failed");
  }
});
