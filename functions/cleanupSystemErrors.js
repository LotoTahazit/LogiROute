const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { errorsCol, privateCol } = require('./lib/platformErrors');

/**
 * Удаляет resolved system errors старше 90 дней.
 */
exports.cleanupSystemErrors = functions.pubsub
  .schedule('0 4 * * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 90);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

    let deleted = 0;
    const snap = await errorsCol()
      .where('resolved', '==', true)
      .where('resolvedAt', '<', cutoffTs)
      .limit(200)
      .get();

    const batch = admin.firestore().batch();
    snap.docs.forEach((doc) => {
      batch.delete(doc.ref);
      batch.delete(privateCol().doc(doc.id));
      deleted += 1;
    });
    if (deleted > 0) await batch.commit();
    console.log(`cleanupSystemErrors: deleted ${deleted}`);
    return { deleted };
  });
