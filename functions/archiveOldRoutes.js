const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Ежедневный архив старых маршрутов
 * Запускается каждый день в 01:00
 * Перемещает delivery_points с routeDate < сегодня в archive_routes
 */
exports.archiveOldRoutes = functions.pubsub
  .schedule('0 1 * * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    console.log('🗄️ Starting daily route archiving...');

    try {
      const now = new Date();
      const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const todayTs = admin.firestore.Timestamp.fromDate(todayMidnight);

      const companiesSnap = await db.collection('companies').get();
      let totalArchived = 0;

      for (const companyDoc of companiesSnap.docs) {
        const companyId = companyDoc.id;
        const pointsRef = db
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('delivery_points');

        const archiveRef = db
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('archive_routes');

        // Находим старые completed точки с routeDate < сегодня
        const oldPoints = await pointsRef
          .where('status', '==', 'completed')
          .where('routeDate', '<', todayTs)
          .limit(500)
          .get();

        if (oldPoints.empty) continue;

        const batch = db.batch();
        let count = 0;

        for (const doc of oldPoints.docs) {
          const data = doc.data();
          // Копируем в архив
          batch.set(archiveRef.doc(doc.id), {
            ...data,
            archivedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          // Удаляем из основной коллекции
          batch.delete(doc.ref);
          count++;
        }

        await batch.commit();
        totalArchived += count;
        console.log(`📦 ${companyId}: archived ${count} old route points`);
      }

      // Также архивируем старые документы из routes коллекции
      for (const companyDoc of companiesSnap.docs) {
        const companyId = companyDoc.id;
        const routesRef = db
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('routes');

        const oldRoutes = await routesRef
          .where('routeDate', '<', todayTs)
          .limit(200)
          .get();

        if (!oldRoutes.empty) {
          const batch = db.batch();
          for (const doc of oldRoutes.docs) {
            batch.delete(doc.ref);
          }
          await batch.commit();
          console.log(`🗑️ ${companyId}: cleaned ${oldRoutes.size} old route docs`);
        }
      }

      console.log(`✅ Daily route archiving done: ${totalArchived} points archived`);
      return { archived: totalArchived };
    } catch (err) {
      console.error(`❌ Route archiving error: ${err.message}`);
      throw err;
    }
  });
