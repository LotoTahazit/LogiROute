const admin = require('firebase-admin');
const serviceAccount = require('./logiroute-app-firebase-adminsdk-fbsvc-ca3ba3d7c5.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'logiroute-app',
});

const db = admin.firestore();

async function fix() {
  const companyId = 'Y.C. Plast';
  
  // 1. Read settings/settings subcollection doc
  const settingsDoc = await db
    .collection('companies')
    .doc(companyId)
    .collection('settings')
    .doc('settings')
    .get();

  if (!settingsDoc.exists) {
    console.log('❌ settings/settings doc does not exist');
    return;
  }

  const settings = settingsDoc.data();
  console.log('📋 Settings data found:', Object.keys(settings).join(', '));

  // 2. Merge settings fields into root company doc
  // Only copy fields that are missing from root doc
  const companyDoc = await db.collection('companies').doc(companyId).get();
  const companyData = companyDoc.data();

  const fieldsToMerge = {};
  const fieldsFromSettings = [
    'nameHebrew', 'nameEnglish', 'taxId',
    'addressHebrew', 'addressEnglish', 'poBox', 'city', 'zipCode',
    'phone', 'fax', 'email', 'website',
    'invoiceFooterText', 'paymentTerms', 'bankDetails',
    'logoUrl', 'driverName', 'driverPhone', 'departureTime',
  ];

  for (const field of fieldsFromSettings) {
    if (settings[field] !== undefined && (companyData[field] === undefined || companyData[field] === null || companyData[field] === '')) {
      fieldsToMerge[field] = settings[field];
    }
  }

  // Also ensure plan and limits exist
  if (!companyData.plan) {
    fieldsToMerge.plan = 'full';
  }
  if (!companyData.limits) {
    fieldsToMerge.limits = {
      maxUsers: 999,
      maxDocsPerMonth: 99999,
      maxRoutesPerDay: 999,
    };
  }

  if (Object.keys(fieldsToMerge).length === 0) {
    console.log('✅ No fields to merge — company doc already has all data');
    return;
  }

  console.log('\n📝 Merging fields into company doc:', Object.keys(fieldsToMerge).join(', '));

  await db.collection('companies').doc(companyId).update(fieldsToMerge);

  console.log('✅ Company doc updated successfully');

  // 3. Verify
  const updatedDoc = await db.collection('companies').doc(companyId).get();
  const updated = updatedDoc.data();
  console.log('\n=== VERIFIED COMPANY DOC ===');
  console.log('  nameHebrew:', updated.nameHebrew);
  console.log('  nameEnglish:', updated.nameEnglish);
  console.log('  taxId:', updated.taxId);
  console.log('  phone:', updated.phone);
  console.log('  plan:', updated.plan);
  console.log('  billingStatus:', updated.billingStatus);
  console.log('  limits:', JSON.stringify(updated.limits));
}

fix().catch(console.error);
