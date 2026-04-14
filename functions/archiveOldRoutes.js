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
  .onRun(async () => {
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

        // Находим completed точки, завершённые ДО сегодня (по completedAt)
        const oldPoints = await pointsRef
          .where('status', '==', 'completed')
          .where('completedAt', '<', todayTs)
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
      // 🛡️ SAFETY: проверяем что у маршрута нет активных точек перед удалением
      for (const companyDoc of companiesSnap.docs) {
        const companyId = companyDoc.id;
        const routesRef = db
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('routes');

        const pointsRefCheck = db
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('delivery_points');

        const oldRoutes = await routesRef
          .where('routeDate', '<', todayTs)
          .limit(200)
          .get();

        if (!oldRoutes.empty) {
          const batch = db.batch();
          let deleteCount = 0;
          for (const doc of oldRoutes.docs) {
            // 🛡️ Проверяем нет ли активных точек у этого маршрута
            const activePoints = await pointsRefCheck
              .where('routeId', '==', doc.id)
              .where('status', 'in', ['assigned', 'in_progress', 'מוקצה', 'בתהליך'])
              .limit(1)
              .get();
            if (!activePoints.empty) {
              console.log(`🛡️ ${companyId}: SKIPPING route ${doc.id} — still has active points`);
              continue;
            }
            batch.delete(doc.ref);
            deleteCount++;
          }
          if (deleteCount > 0) {
            await batch.commit();
            console.log(`🗑️ ${companyId}: cleaned ${deleteCount} old route docs`);
          }
        }
      }

      console.log(`✅ Daily route archiving done: ${totalArchived} points archived`);
      return { archived: totalArchived };
    } catch (err) {
      console.error(`❌ Route archiving error: ${err.message}`);
      throw err;
    }
  });
