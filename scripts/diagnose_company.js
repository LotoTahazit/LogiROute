const admin = require('firebase-admin');
const serviceAccount = require('./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'logiroute-app',
});

const db = admin.firestore();

async function diagnose() {
  // 1. Full company document dump
  const companyDoc = await db.collection('companies').doc('Y.C. Plast').get();
  console.log('\n=== FULL COMPANY DOC (Y.C. Plast) ===');
  if (companyDoc.exists) {
    const data = companyDoc.data();
    console.log(JSON.stringify(data, null, 2));
  } else {
    console.log('❌ DOES NOT EXIST');
  }

  // 2. Check owner user doc
  const ownerDoc = await db.collection('users').doc('EHvu4n84AoSdn558LPvxnkhw3yJ2').get();
  console.log('\n=== OWNER USER DOC (yoav@logi.com) ===');
  if (ownerDoc.exists) {
    console.log(JSON.stringify(ownerDoc.data(), null, 2));
  } else {
    console.log('❌ DOES NOT EXIST');
  }

  // 3. Check members with full data
  const membersSnap = await db.collection('companies').doc('Y.C. Plast').collection('members').get();
  console.log('\n=== MEMBERS FULL DATA ===');
  for (const doc of membersSnap.docs) {
    console.log(`\n  --- ${doc.id} ---`);
    console.log(`  ${JSON.stringify(doc.data())}`);
  }

  // 4. Check settings subcollection
  const settingsSnap = await db.collection('companies').doc('Y.C. Plast').collection('settings').get();
  console.log('\n=== SETTINGS SUBCOLLECTION ===');
  console.log(`  Count: ${settingsSnap.size}`);
  settingsSnap.forEach(doc => {
    console.log(`  ${doc.id}: ${JSON.stringify(doc.data())}`);
  });

  // 5. Check daily_summaries
  const summariesSnap = await db.collection('companies').doc('Y.C. Plast').collection('daily_summaries').get();
  console.log('\n=== DAILY SUMMARIES ===');
  console.log(`  Count: ${summariesSnap.size}`);

  // 6. Check systemEvents
  const eventsSnap = await db.collection('companies').doc('Y.C. Plast').collection('systemEvents').get();
  console.log('\n=== SYSTEM EVENTS ===');
  console.log(`  Count: ${eventsSnap.size}`);
}

diagnose().catch(console.error);
