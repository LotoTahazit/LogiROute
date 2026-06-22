/**
 * Enable daily Firestore scheduled backups (28d retention) via REST API.
 * Auth: firebase login. Requires Owner/Editor on logiroute-app.
 *
 * Usage: node scripts/enable_gcp_firestore_backup.js
 */
const https = require("https");
const {
  loadFirebaseCliCredential,
  CLIENT_ID,
  CLIENT_SECRET,
} = require("./_firebase_cli_auth");

const projectId =
  process.argv.find((a) => a.startsWith("--project="))?.split("=")[1] || "logiroute-app";

function postForm(url, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      url,
      { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" } },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          else resolve(JSON.parse(data));
        });
      }
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

function api(method, url, token, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method,
        headers: {
          Authorization: `Bearer ${token}`,
          ...(body ? { "Content-Type": "application/json" } : {}),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          else resolve(data ? JSON.parse(data) : {});
        });
      }
    );
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function accessToken() {
  const cred = loadFirebaseCliCredential();
  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: cred.refresh_token,
    grant_type: "refresh_token",
  }).toString();
  const tok = await postForm("https://oauth2.googleapis.com/token", body);
  return tok.access_token;
}

async function main() {
  const token = await accessToken();
  const dbUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)`;
  const db = await api("GET", dbUrl, token);
  const location = db.locationId || db.uid?.split("/")[3];
  if (!location) throw new Error("Не удалось определить регион Firestore");
  console.log(`📍 Firestore: ${location} (project ${projectId})`);

  const parent = `projects/${projectId}/databases/(default)/backupSchedules`;
  const listUrl = `https://firestore.googleapis.com/v1/${parent}`;
  const existing = await api("GET", listUrl, token);
  const schedules = existing.backupSchedules || [];

  if (schedules.length > 0) {
    console.log(`✅ Расписаний бэкапа: ${schedules.length}`);
    for (const s of schedules) {
      const kind = s.dailyRecurrence
        ? "daily"
        : s.weeklyRecurrence
          ? "weekly"
          : "custom";
      const days = s.retention
        ? Math.round(parseInt(s.retention.replace("s", ""), 10) / 86400)
        : "?";
      console.log(`   • ${s.name}`);
      console.log(`     ${kind}, retention ~${days}d`);
    }
    console.log(`\n   PowerShell: scripts\\list_firestore_backups.cmd`);
    console.log(`   ili: scripts\\gcloud.cmd firestore backups schedules list "--database=(default)"`);
    return;
  }

  const created = await api(
    "POST",
    `https://firestore.googleapis.com/v1/${parent}?backupScheduleId=daily-28d`,
    token,
    {
      dailyRecurrence: {},
      retention: `${28 * 24 * 60 * 60}s`,
    }
  );
  console.log(`✅ Firestore Backup включён (${location}, daily, 28d):`);
  console.log("  ", created.name);
}

main().catch((e) => {
  console.error("❌", e.message);
  process.exit(1);
});
