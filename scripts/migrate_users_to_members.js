/**
 * Одноразовый скрипт: для каждого пользователя из `users` с companyId
 * создаёт документ в `companies/{companyId}/members/{uid}`.
 *
 * Запуск: node scripts/migrate_users_to_members.js
 *
 * Требует: GOOGLE_APPLICATION_CREDENTIALS или firebase login
 */

const admin = require('firebase-admin');

const serviceAccount = require('./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'logiroute-app',
});

const db = admin.firestore();

async function migrate() {
  const usersSnap = await db.collection('users').get();
  console.log(`Found ${usersSnap.size} users`);

  let created = 0;
  let skipped = 0;

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    const data = userDoc.data();
    const companyId = data.companyId;
    const role = data.role || 'viewer';

    if (!companyId || companyId.trim() === '') {
      console.log(`  SKIP ${uid} (${data.email}) — no companyId`);
      skipped++;
      continue;
    }

    const memberRef = db
      .collection('companies')
      .doc(companyId)
      .collection('members')
      .doc(uid);

    const existing = await memberRef.get();
    if (existing.exists) {
      console.log(`  SKIP ${uid} (${data.email}) — already in members`);
      skipped++;
      continue;
    }

    await memberRef.set({
      role: role,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`  ✅ ${uid} (${data.email}) → companies/${companyId}/members/${uid} [${role}]`);
    created++;
  }

  console.log(`\nDone: ${created} created, ${skipped} skipped`);
}

migrate().catch(console.error);
