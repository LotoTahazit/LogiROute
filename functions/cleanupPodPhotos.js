const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

function podBucket() {
  return admin.storage().bucket();
}

const RETENTION_DAYS = 90;

/**
 * Удаляет PoD-фото старше 90 дней из Storage.
 * Путь: companies/{companyId}/pod/{pointId}/{timestamp}.jpg
 * Метаданные доставки (podLat, podLng, podAt) в Firestore сохраняются.
 */
exports.cleanupPodPhotos = functions.pubsub
  .schedule('30 3 * * *') // ежедневно 03:30
  .timeZone('Asia/Jerusalem')
  .onRun(async () => {
    const cutoffMs = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
    let deleted = 0;

    try {
      const [files] = await podBucket().getFiles({ prefix: 'companies/' });

      for (const file of files) {
        if (!file.name.includes('/pod/')) continue;

        const [meta] = await file.getMetadata();
        const created = new Date(meta.timeCreated).getTime();
        if (created >= cutoffMs) continue;

        await file.delete();
        deleted++;

        const match = file.name.match(
          /^companies\/([^/]+)\/pod\/([^/]+)\//
        );
        if (!match) continue;

        const [, companyId, pointId] = match;
        const pointRef = db.doc(
          `companies/${companyId}/logistics/_root/delivery_points/${pointId}`
        );
        await pointRef
          .update({ podPhotoUrl: admin.firestore.FieldValue.delete() })
          .catch(() => {});
      }

      console.log(
        `🧹 [cleanupPodPhotos] Deleted ${deleted} photos older than ${RETENTION_DAYS} days`
      );
    } catch (e) {
      console.error('❌ [cleanupPodPhotos] Error:', e);
    }

    return null;
  });
