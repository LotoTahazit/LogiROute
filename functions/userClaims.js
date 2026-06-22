const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

/**
 * Синхронизирует custom claims (role, companyId) с документом users/{uid}.
 * Нужно правилам Storage/Firestore, которые сверяют request.auth.token.*.
 * Claims попадают в токен клиента при следующем обновлении ID-токена
 * (re-login или getIdToken(true) — приложение зовёт ensureMyClaims при логине).
 */
exports.syncUserClaims = functions.firestore
  .document("users/{uid}")
  .onWrite(async (change, context) => {
    const { uid } = context.params;
    const after = change.after.exists ? change.after.data() : null;
    const role = after && after.role ? String(after.role) : null;
    const companyId = after && after.companyId ? String(after.companyId) : null;

    let existing = {};
    try {
      const u = await admin.auth().getUser(uid);
      existing = u.customClaims || {};
    } catch (e) {
      // Пользователь мог быть удалён из Auth — выходим тихо.
      console.warn(`syncUserClaims: getUser(${uid}) failed: ${e.message}`);
      return null;
    }

    if (existing.role === role && existing.companyId === companyId) {
      return null; // без изменений
    }

    try {
      await admin.auth().setCustomUserClaims(uid, { role, companyId });
      console.log(`✅ claims set uid=${uid} role=${role} companyId=${companyId}`);
    } catch (e) {
      console.error(`❌ setCustomUserClaims(${uid}) failed: ${e.message}`);
    }
    return null;
  });

/**
 * Callable: выставляет claims вызывающему пользователю по его users/{uid}.
 * Приложение зовёт ПОСЛЕ логина, затем делает getIdToken(true), чтобы свежие
 * claims попали в токен. Это же бэкофиллит существующих пользователей
 * (у которых claims ещё не выставлены) — без действий администратора.
 */
exports.ensureMyClaims = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const uid = context.auth.uid;
  const snap = await db.doc(`users/${uid}`).get();
  if (!snap.exists) {
    return { ok: false, reason: "no-user-doc" };
  }
  const d = snap.data();
  const role = d.role ? String(d.role) : null;
  const companyId = d.companyId ? String(d.companyId) : null;

  const tok = context.auth.token || {};
  if (tok.role === role && tok.companyId === companyId) {
    return { ok: true, changed: false };
  }
  await admin.auth().setCustomUserClaims(uid, { role, companyId });
  return { ok: true, changed: true };
});
