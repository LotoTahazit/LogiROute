const admin = require('firebase-admin');
const serviceAccount = require('./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'logiroute-app',
});

const db = admin.firestore();

async function check() {
  // 1. Check company document
  const companyDoc = await db.collection('companies').doc('Y.C. Plast').get();
  console.log('\n=== COMPANY DOC: Y.C. Plast ===');
  if (companyDoc.exists) {
    const data = companyDoc.data();
    console.log('  nameHebrew:', data.nameHebrew);
    console.log('  nameEnglish:', data.nameEnglish);
    console.log('  taxId:', data.taxId);
    console.log('  billingStatus:', data.billingStatus);
    console.log('  plan:', data.plan);
    console.log('  modules:', JSON.stringify(data.modules));
    console.log('  limits:', JSON.stringify(data.limits));
  } else {
    console.log('  ❌ DOES NOT EXIST');
  }

  // 2. Check members subcollection
  const membersSnap = await db.collection('companies').doc('Y.C. Plast').collection('members').get();
  console.log('\n=== MEMBERS (companies/Y.C. Plast/members) ===');
  console.log(`  Count: ${membersSnap.size}`);
  membersSnap.forEach(doc => {
    console.log(`  ${doc.id}: ${JSON.stringify(doc.data())}`);
  });

  // 3. Check accountingDocs subcollection
  const docsSnap = await db.collection('companies').doc('Y.C. Plast').collection('accountingDocs').get();
  console.log('\n=== ACCOUNTING DOCS (companies/Y.C. Plast/accountingDocs) ===');
  console.log(`  Count: ${docsSnap.size}`);

  // 4. Check invites subcollection
  const invitesSnap = await db.collection('companies').doc('Y.C. Plast').collection('invites').get();
  console.log('\n=== INVITES (companies/Y.C. Plast/invites) ===');
  console.log(`  Count: ${invitesSnap.size}`);

  // 5. Check audit subcollection
  const auditSnap = await db.collection('companies').doc('Y.C. Plast').collection('audit').get();
  console.log('\n=== AUDIT (companies/Y.C. Plast/audit) ===');
  console.log(`  Count: ${auditSnap.size}`);

  // 6. Check Firestore rules - list all companies
  const companiesSnap = await db.collection('companies').get();
  console.log('\n=== ALL COMPANIES ===');
  companiesSnap.forEach(doc => {
    console.log(`  ${doc.id}`);
  });

  // 7. Check global users for owner
  const usersSnap = await db.collection('users').get();
  console.log('\n=== ALL USERS ===');
  usersSnap.forEach(doc => {
    const d = doc.data();
    console.log(`  ${doc.id}: email=${d.email}, role=${d.role}, companyId=${d.companyId}`);
  });
}

check().catch(console.error);
