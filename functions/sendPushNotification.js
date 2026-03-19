const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const ADMIN_ROLES = ["super_admin", "owner", "admin", "accountant"];
const ADMIN_ONLY_TYPES = new Set([
  "integrity_chain_broken",
  "billing_grace",
  "billing_suspended",
  "payment_received",
  "welcome",
]);

/**
 * Trigger: when a new notification is created in companies/{companyId}/notifications/{notifId}
 * Sends FCM push to all users of that company who have fcmTokens stored.
 *
 * Token format in user doc:
 *   fcmTokens: { [token]: { platform: "android"|"ios"|"web", updatedAt: Timestamp } }
 *   (legacy) fcmToken: string — single token, migrated on next save
 *
 * Telemetry: errors logged to companies/{companyId}/push_delivery_logs/{id}
 * Only failures are logged to minimize Firestore cost.
 */
exports.sendPushNotification = functions.firestore
  .document("companies/{companyId}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const { companyId, notifId } = context.params;
    const data = snap.data();

    if (!data || !data.title) {
      console.log(`⚠️ Notification ${notifId} has no title, skipping push`);
      return null;
    }

    console.log(`📱 Sending push for ${companyId}/${notifId}: ${data.title}`);

    try {
      // Find target user(s): strict targeting by default.
      // Broadcast is allowed only when notification explicitly sets broadcast=true.
      let usersSnap;
      if (data.driverId) {
        const driverDoc = await db.collection("users").doc(data.driverId).get();
        usersSnap = driverDoc.exists ? { docs: [driverDoc] } : { docs: [] };
        console.log(`📱 Targeting driver ${data.driverId}`);
      } else if (data.userId || data.uid || data.recipientId) {
        const targetUid = data.userId || data.uid || data.recipientId;
        const userDoc = await db.collection("users").doc(targetUid).get();
        usersSnap = userDoc.exists ? { docs: [userDoc] } : { docs: [] };
        console.log(`📱 Targeting user ${targetUid}`);
      } else if (Array.isArray(data.targetUserIds) && data.targetUserIds.length > 0) {
        const ids = data.targetUserIds
          .filter((v) => typeof v === "string" && v.length > 0)
          .slice(0, 10);
        if (ids.length > 0) {
          usersSnap = await db
            .collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", ids)
            .get();
          console.log(`📱 Targeting explicit users (${ids.length})`);
        } else {
          usersSnap = { docs: [] };
        }
      } else if (Array.isArray(data.targetRoles) && data.targetRoles.length > 0) {
        const roles = data.targetRoles
          .filter((v) => typeof v === "string" && v.length > 0)
          .slice(0, 10);
        if (roles.length > 0) {
          usersSnap = await db
            .collection("users")
            .where("companyId", "==", companyId)
            .where("role", "in", roles)
            .get();
          console.log(`📱 Targeting roles: ${roles.join(",")}`);
        } else {
          usersSnap = { docs: [] };
        }
      } else if (ADMIN_ONLY_TYPES.has(data.type)) {
        // Safety: admin/system alerts should not go to all drivers.
        usersSnap = await db
          .collection("users")
          .where("companyId", "==", companyId)
          .where("role", "in", ADMIN_ROLES)
          .get();
        console.log(`📱 Targeting admin roles for type=${data.type}`);
      } else if (data.broadcast === true) {
        // Explicit broadcast only.
        usersSnap = await db
          .collection("users")
          .where("companyId", "==", companyId)
          .get();
        console.log(`📢 Broadcast enabled explicitly for ${companyId}`);
      } else {
        // No explicit target -> do not broadcast by accident.
        console.log(`⚠️ Notification ${notifId} has no target; skipping push`);
        return null;
      }

      // Collect tokens: support both new map format and legacy string/array
      const tokenUserMap = new Map(); // token → { userRef, uid }
      for (const userDoc of usersSnap.docs) {
        const userData = userDoc.data();
        const uid = userDoc.id;

        // New format: fcmTokens map { token: { platform, updatedAt } }
        if (userData.fcmTokens && typeof userData.fcmTokens === "object" && !Array.isArray(userData.fcmTokens)) {
          for (const token of Object.keys(userData.fcmTokens)) {
            if (typeof token === "string" && token.length > 0) {
              tokenUserMap.set(token, { userRef: userDoc.ref, uid });
            }
          }
        }
        // Legacy: single string
        if (userData.fcmToken && typeof userData.fcmToken === "string") {
          tokenUserMap.set(userData.fcmToken, { userRef: userDoc.ref, uid });
        }
      }

      if (tokenUserMap.size === 0) {
        console.log(`⚠️ No FCM tokens found for company ${companyId}`);
        return null;
      }

      const uniqueTokens = [...tokenUserMap.keys()];
      console.log(`📱 Sending to ${uniqueTokens.length} tokens`);

      // Build FCM message
      const message = {
        notification: {
          title: data.title,
          body: data.body || "",
        },
        data: {
          type: data.type || "general",
          severity: data.severity || "info",
          companyId,
          notifId,
        },
        android: {
          priority: data.severity === "critical" ? "high" : "normal",
          notification: {
            channelId: data.severity === "critical" ? "critical_alerts" : "general",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send to each token
      const response = await admin.messaging().sendEachForMulticast({
        tokens: uniqueTokens,
        ...message,
      });

      console.log(
        `✅ Push sent: ${response.successCount} success, ${response.failureCount} failures`
      );

      // Process failures: log errors + clean invalid tokens
      if (response.failureCount > 0) {
        const invalidTokens = [];
        const errorEntries = [];

        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const token = uniqueTokens[idx];
            const errorCode = resp.error?.code || "unknown";
            const { uid } = tokenUserMap.get(token) || {};

            // Log every failure for telemetry
            errorEntries.push({
              token: token.substring(0, 20) + "...", // truncate for privacy
              uid: uid || "unknown",
              errorCode,
              errorMessage: resp.error?.message || "",
              notifId,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Mark for cleanup if token is dead
            if (
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/registration-token-not-registered"
            ) {
              invalidTokens.push(token);
            }
          }
        });

        // Write error logs (batch, only failures)
        if (errorEntries.length > 0) {
          const logsRef = db
            .collection("companies")
            .doc(companyId)
            .collection("push_delivery_logs");
          const batch = db.batch();
          for (const entry of errorEntries) {
            batch.set(logsRef.doc(), entry);
          }
          try {
            await batch.commit();
          } catch (logErr) {
            console.error(`⚠️ Failed to write push delivery logs: ${logErr.message}`);
          }
        }

        // Remove invalid tokens from user docs (new map format + legacy)
        if (invalidTokens.length > 0) {
          console.log(`🧹 Cleaning ${invalidTokens.length} invalid tokens`);
          for (const token of invalidTokens) {
            const { userRef } = tokenUserMap.get(token) || {};
            if (!userRef) continue;
            try {
              const updates = {};
              // Remove from fcmTokens map
              updates[`fcmTokens.${token}`] = admin.firestore.FieldValue.delete();
              await userRef.update(updates);
            } catch (cleanErr) {
              // Token key may contain dots — fallback: read-modify-write
              try {
                const userSnap = await userRef.get();
                const ud = userSnap.data() || {};
                if (ud.fcmTokens && typeof ud.fcmTokens === "object") {
                  const cleaned = { ...ud.fcmTokens };
                  delete cleaned[token];
                  await userRef.update({ fcmTokens: cleaned });
                }
                // Legacy single token
                if (ud.fcmToken === token) {
                  await userRef.update({ fcmToken: admin.firestore.FieldValue.delete() });
                }
              } catch (fallbackErr) {
                console.error(`⚠️ Token cleanup fallback failed: ${fallbackErr.message}`);
              }
            }
          }
        }
      }

      return { sent: response.successCount, failed: response.failureCount };
    } catch (err) {
      console.error(`❌ Push notification error: ${err.message}`);
      // Log critical FCM failure
      try {
        await db
          .collection("companies")
          .doc(companyId)
          .collection("push_delivery_logs")
          .add({
            errorCode: "fcm_send_error",
            errorMessage: err.message,
            notifId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
      } catch (_) { /* best effort */ }
      return null;
    }
  });
