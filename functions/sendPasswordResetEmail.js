const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const RESET_BASE = "https://logiroute-app.web.app/reset-password";
const FROM_NAME = process.env.SMTP_FROM_NAME || "LogiRoute";

function resetEmailHtml(link, cta) {
  return `<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;line-height:1.5;color:#222">
<p>${cta.greeting}</p>
<p>${cta.body}</p>
<p style="margin:24px 0"><a href="${link}" style="display:inline-block;padding:12px 24px;background:#1565C0;color:#fff;text-decoration:none;border-radius:6px;font-weight:600">${cta.button}</a></p>
<p style="font-size:12px;color:#666">${cta.footer}</p>
<p style="font-size:12px;color:#999">${cta.ignore}</p>
</body></html>`;
}

const MESSAGES = {
  ru: {
    subject: "Сброс пароля LogiRoute",
    greeting: "Здравствуйте!",
    body: "Чтобы задать новый пароль, нажмите кнопку ниже (ссылка действует 1 час):",
    button: "Сбросить пароль",
    footer: "LogiRoute — система управления доставками",
    ignore: "Если вы не запрашивали сброс — проигнорируйте это письмо.",
  },
  en: {
    subject: "LogiRoute password reset",
    greeting: "Hello!",
    body: "Click the button below to set a new password (link valid for 1 hour):",
    button: "Reset password",
    footer: "LogiRoute — delivery management",
    ignore: "If you did not request this, ignore this email.",
  },
  he: {
    subject: "איפוס סיסמה LogiRoute",
    greeting: "שלום,",
    body: "לחץ/י על הכפתור לקביעת סיסמה חדשה (תקף לשעה):",
    button: "איפוס סיסמה",
    footer: "LogiRoute — ניהול משלוחים",
    ignore: "אם לא ביקשת איפוס — התעלם/י ממייל זה.",
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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Генерирует Firebase reset link. Свою ссылку собираем из oobCode в buildResetLink,
 * поэтому ActionCodeSettings не обязательны (и часто ломаются из‑за authorized domains).
 * При auth/internal-error повторяем попытку (транзиентные сбои Google).
 */
async function generateFirebaseResetLink(email) {
  const attempts = [
    () => admin.auth().generatePasswordResetLink(email),
    () =>
      admin.auth().generatePasswordResetLink(email, {
        url: RESET_BASE,
        handleCodeInApp: false,
      }),
  ];

  let lastErr;
  for (let round = 0; round < 2; round++) {
    for (const attempt of attempts) {
      try {
        return await attempt();
      } catch (e) {
        if (e.code === "auth/user-not-found") throw e;
        lastErr = e;
        console.warn(
          "generatePasswordResetLink attempt failed:",
          e?.code,
          e?.message || e,
        );
      }
    }
    if (round === 0) await sleep(1500);
  }
  throw lastErr;
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
    firebaseLink = await generateFirebaseResetLink(email);
  } catch (e) {
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
      from: { name: FROM_NAME, address: smtp.from },
      to: email,
      subject: msg.subject,
      html: resetEmailHtml(resetLink, msg),
    });
    console.log(`✅ Password reset email sent to ${email}`);
    return { ok: true };
  } catch (e) {
    console.error("SMTP send failed:", e);
    throw new functions.https.HttpsError("internal", "email-send-failed");
  }
});
