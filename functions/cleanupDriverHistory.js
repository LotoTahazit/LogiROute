const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * cleanupDriverHistory — каждые 6 часов удаляет GPS-историю старше 24 часов.
 * Путь: companies/{companyId}/driver_locations/{driverId}/history
 */
exports.cleanupDriverHistory = functions.pubsub
  .schedule('0 */6 * * *') // каждые 6 часов
  .timeZone('Asia/Jerusalem')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );

    let totalDeleted = 0;

    try {
      const companies = await db.collection('companies').get();

      for (const company of companies.docs) {
        const drivers = await company.ref
          .collection('driver_locations')
          .get();

        for (const driver of drivers.docs) {
          const old = await driver.ref
            .collection('history')
            .where('timestamp', '<', cutoff)
            .limit(500)
            .get();

          if (old.empty) continue;

          const batch = db.batch();
          old.docs.forEach(doc => batch.delete(doc.ref));
          await batch.commit();
          totalDeleted += old.size;
        }
      }

      console.log(`🧹 [cleanupDriverHistory] Deleted ${totalDeleted} old GPS records`);
    } catch (e) {
      console.error('❌ [cleanupDriverHistory] Error:', e);
    }

    return null;
  });
