const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function для создания пользователя
 * Вызывается из приложения админом/суперадмином
 */
exports.createUser = functions.https.onCall(async (data, context) => {
  // Проверяем что пользователь авторизован
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  // Проверяем что пользователь - админ или суперадмин
  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Caller profile not found'
    );
  }

  const callerRole = callerDoc.data().role;
  if (callerRole !== 'admin' && callerRole !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can create users'
    );
  }

  // Извлекаем данные
  const {
    email,
    password,
    name,
    role,
    companyId,
    palletCapacity,
    truckWeight,
    vehicleNumber
  } = data;

  // Валидация
  if (!email || !password || !name || !role || !companyId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  // Проверяем права: обычный админ может создавать только в своей компании
  if (callerRole === 'admin') {
    const callerCompanyId = callerDoc.data().companyId;
    if (companyId !== callerCompanyId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin can only create users in their own company'
      );
    }

    // Обычный админ не может создавать других админов
    if (role === 'admin' || role === 'super_admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin cannot create other admins'
      );
    }
  }

  try {
    // Создаём пользователя в Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Создаём профиль в Firestore
    const userData = {
      email: email,
      name: name,
      role: role,
      companyId: companyId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: callerUid,
    };

    if (palletCapacity !== undefined) userData.palletCapacity = palletCapacity;
    if (truckWeight !== undefined) userData.truckWeight = truckWeight;
    if (vehicleNumber !== undefined) userData.vehicleNumber = vehicleNumber;

    await admin.firestore().collection('users').doc(userRecord.uid).set(userData);

    return {
      success: true,
      uid: userRecord.uid,
      message: 'User created successfully'
    };

  } catch (error) {
    console.error('Error creating user:', error);
    
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError(
        'already-exists',
        'Email already in use'
      );
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create user: ' + error.message
    );
  }
});

/**
 * Cloud Function для обновления пользователя
 */
exports.updateUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Caller profile not found');
  }

  const callerRole = callerDoc.data().role;
  if (callerRole !== 'admin' && callerRole !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can update users');
  }

  const { uid, email, password, name, role, palletCapacity, truckWeight, vehicleNumber } = data;

  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'User UID is required');
  }

  try {
    // Обновляем в Firebase Auth
    const authUpdates = {};
    if (email) authUpdates.email = email;
    if (password) authUpdates.password = password;
    if (name) authUpdates.displayName = name;

    if (Object.keys(authUpdates).length > 0) {
      await admin.auth().updateUser(uid, authUpdates);
    }

    // Обновляем в Firestore
    const firestoreUpdates = {};
    if (email) firestoreUpdates.email = email;
    if (name) firestoreUpdates.name = name;
    if (role) firestoreUpdates.role = role;
    if (palletCapacity !== undefined) firestoreUpdates.palletCapacity = palletCapacity;
    if (truckWeight !== undefined) firestoreUpdates.truckWeight = truckWeight;
    if (vehicleNumber !== undefined) firestoreUpdates.vehicleNumber = vehicleNumber;
    firestoreUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    if (Object.keys(firestoreUpdates).length > 0) {
      await admin.firestore().collection('users').doc(uid).update(firestoreUpdates);
    }

    return { success: true, message: 'User updated successfully' };

  } catch (error) {
    console.error('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update user: ' + error.message);
  }
});

/**
 * Cloud Function для удаления пользователя
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Caller profile not found');
  }

  const callerRole = callerDoc.data().role;
  if (callerRole !== 'admin' && callerRole !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can delete users');
  }

  const { uid } = data;

  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'User UID is required');
  }

  try {
    // Удаляем из Firebase Auth
    await admin.auth().deleteUser(uid);

    // Удаляем из Firestore
    await admin.firestore().collection('users').doc(uid).delete();

    return { success: true, message: 'User deleted successfully' };

  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user: ' + error.message);
  }
});
