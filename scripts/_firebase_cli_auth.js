/**
 * Credentials from `firebase login` (configstore), same as firebase-tools ADC.
 */
const fs = require("fs");
const os = require("os");
const path = require("path");

const CLIENT_ID =
  process.env.FIREBASE_CLIENT_ID ||
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const CLIENT_SECRET =
  process.env.FIREBASE_CLIENT_SECRET || "j9iVZfS8kkCEFUPaAeJV0sAi";

function configstorePath() {
  const home = os.homedir();
  const candidates = [
    path.join(home, ".config", "configstore", "firebase-tools.json"),
    path.join(process.env.APPDATA || "", "configstore", "firebase-tools.json"),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  throw new Error("firebase-tools.json не найден — выполните: firebase login");
}

function loadFirebaseCliConfig() {
  const raw = fs.readFileSync(configstorePath(), "utf8");
  return JSON.parse(raw);
}

function loadFirebaseCliCredential() {
  const cfg = loadFirebaseCliConfig();
  const refresh = cfg.tokens?.refresh_token;
  if (!refresh) throw new Error("firebase login: нет refresh_token — выполните firebase login");
  return {
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: refresh,
    type: "authorized_user",
  };
}

function writeAdcFile() {
  const cfg = loadFirebaseCliConfig();
  const email = cfg.user?.email || "unknown_user";
  const slug = email.replace("@", "_").replace(/\./g, "_");
  const dir = path.join(os.homedir(), ".config", "firebase");
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${slug}_application_default_credentials.json`);
  fs.writeFileSync(file, JSON.stringify(loadFirebaseCliCredential(), null, 2));
  process.env.GOOGLE_APPLICATION_CREDENTIALS = file;
  return file;
}

function adminFromFirebaseCli(projectId) {
  writeAdcFile();
  const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));
  admin.initializeApp({
    projectId,
    credential: admin.credential.applicationDefault(),
  });
  return admin;
}

module.exports = {
  adminFromFirebaseCli,
  loadFirebaseCliCredential,
  loadFirebaseCliConfig,
  CLIENT_ID,
  CLIENT_SECRET,
};
