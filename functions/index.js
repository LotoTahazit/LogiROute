const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

// === Callable Functions ===
const { issueInvoice } = require('./issueInvoice');
exports.issueInvoice = issueInvoice;

const { verifyIntegrityChain } = require('./verifyIntegrityChain');
exports.verifyIntegrityChain = verifyIntegrityChain;

const { scheduledIntegrityCheck } = require('./scheduledIntegrityCheck');
exports.scheduledIntegrityCheck = scheduledIntegrityCheck;

// === Billing & Payment ===
const { billingEnforcer } = require('./billingEnforcer');
exports.billingEnforcer = billingEnforcer;

const { processPaymentWebhook, registerManualPayment } = require('./processPaymentWebhook');
exports.processPaymentWebhook = processPaymentWebhook;
exports.registerManualPayment = registerManualPayment;

const { createCheckoutSession } = require('./createCheckoutSession');
exports.createCheckoutSession = createCheckoutSession;

// === Push Notifications ===
const { sendPushNotification } = require('./sendPushNotification');
exports.sendPushNotification = sendPushNotification;

// === Email Notifications ===
const { sendEmailNotification } = require('./sendEmailNotification');
exports.sendEmailNotification = sendEmailNotification;

// === Company Lifecycle ===
const { onCompanyCreated } = require('./onCompanyCreated');
exports.onCompanyCreated = onCompanyCreated;

/**
 * Очистка старых delivery logs (push + email) — раз в неделю
 * Удаляет логи старше 30 дней, чтобы не раздувать Firestore cost
 */
exports.cleanupDeliveryLogs = functions.pubsub
  .schedule('0 3 * * 0') // каждое воскресенье в 03:00
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    console.log('🧹 Cleaning up old delivery logs...');
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

    let totalDeleted = 0;

    try {
      const companiesSnap = await db.collection('companies').get();

      for (const companyDoc of companiesSnap.docs) {
        const companyId = companyDoc.id;

        for (const logCollection of ['push_delivery_logs', 'email_delivery_logs']) {
          const logsSnap = await db
            .collection('companies')
            .doc(companyId)
            .collection(logCollection)
            .where('timestamp', '<', cutoffTs)
            .limit(500)
            .get();

          if (!logsSnap.empty) {
            const batch = db.batch();
            logsSnap.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            totalDeleted += logsSnap.size;
            console.log(`🗑️ ${companyId}/${logCollection}: deleted ${logsSnap.size}`);
          }
        }
      }

      console.log(`✅ Delivery logs cleanup done: ${totalDeleted} deleted`);
      return { deleted: totalDeleted };
    } catch (err) {
      console.error(`❌ Delivery logs cleanup error: ${err.message}`);
      throw err;
    }
  });

/**
 * Автоматическая архивация истории инвентаря
 * Запускается каждый месяц 1-го числа в 02:00
 */
exports.archiveInventoryHistory = functions.pubsub
  .schedule('0 2 1 * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    console.log('🗄️ Starting automatic inventory history archiving...');
    
    try {
      // Дата отсечки - 3 месяца назад
      const cutoffDate = new Date();
      cutoffDate.setMonth(cutoffDate.getMonth() - 3);
      
      console.log(`📅 Cutoff date: ${cutoffDate.toISOString()}`);
      
      // Получаем старые записи (порциями по 1000)
      const snapshot = await db.collection('inventory_history')
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .where('archived', '==', false) // Только неархивированные
        .orderBy('timestamp')
        .limit(1000)
        .get();
      
      if (snapshot.empty) {
        console.log('✅ No records to archive');
        return null;
      }
      
      console.log(`📦 Found ${snapshot.size} records to archive`);
      
      // Конвертируем в JSON
      const records = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        data._id = doc.id;
        // Конвертируем Timestamp в ISO string для JSON
        if (data.timestamp) {
          data.timestamp = data.timestamp.toDate().toISOString();
        }
        records.push(data);
      });
      
      // Создаем имя файла
      const year = cutoffDate.getFullYear();
      const month = String(cutoffDate.getMonth() + 1).padStart(2, '0');
      const fileName = `inventory_history_${year}_${month}.json`;
      const filePath = `archives/inventory_history/${fileName}`;
      
      // Загружаем в Storage
      const bucket = storage.bucket();
      const file = bucket.file(filePath);
      
      await file.save(JSON.stringify(records, null, 2), {
        contentType: 'application/json',
        metadata: {
          metadata: {
            recordCount: records.length.toString(),
            cutoffDate: cutoffDate.toISOString(),
            archivedAt: new Date().toISOString(),
          }
        }
      });
      
      console.log(`✅ Uploaded ${records.length} records to ${filePath}`);
      
      // Помечаем записи как архивированные
      const batch = db.batch();
      snapshot.forEach(doc => {
        batch.update(doc.ref, {
          archived: true,
          archivedAt: admin.firestore.FieldValue.serverTimestamp(),
          archiveFile: filePath,
        });
      });
      
      await batch.commit();
      
      console.log(`✅ Marked ${records.length} records as archived`);
      console.log('🎉 Inventory history archiving completed successfully');
      
      return {
        success: true,
        archived: records.length,
        filePath: filePath,
      };
      
    } catch (error) {
      console.error('❌ Error archiving inventory history:', error);
      throw error;
    }
  });

/**
 * Автоматическая архивация завершенных заказов
 * Запускается каждый месяц 1-го числа в 03:00
 */
exports.archiveCompletedOrders = functions.pubsub
  .schedule('0 3 1 * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    console.log('🗄️ Starting automatic completed orders archiving...');
    
    try {
      // Дата отсечки - 1 месяц назад
      const cutoffDate = new Date();
      cutoffDate.setMonth(cutoffDate.getMonth() - 1);
      
      console.log(`📅 Cutoff date: ${cutoffDate.toISOString()}`);
      
      // Получаем старые завершенные заказы
      const snapshot = await db.collection('delivery_points')
        .where('status', '==', 'completed')
        .where('completedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .where('archived', '==', false) // Только неархивированные
        .orderBy('completedAt')
        .limit(500)
        .get();
      
      if (snapshot.empty) {
        console.log('✅ No orders to archive');
        return null;
      }
      
      console.log(`📦 Found ${snapshot.size} orders to archive`);
      
      // Конвертируем в JSON
      const records = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        data._id = doc.id;
        // Конвертируем все Timestamp в ISO string
        ['completedAt', 'arrivedAt', 'openingTime'].forEach(field => {
          if (data[field]) {
            data[field] = data[field].toDate().toISOString();
          }
        });
        records.push(data);
      });
      
      // Создаем имя файла
      const year = cutoffDate.getFullYear();
      const month = String(cutoffDate.getMonth() + 1).padStart(2, '0');
      const fileName = `completed_orders_${year}_${month}.json`;
      const filePath = `archives/orders/${fileName}`;
      
      // Загружаем в Storage
      const bucket = storage.bucket();
      const file = bucket.file(filePath);
      
      await file.save(JSON.stringify(records, null, 2), {
        contentType: 'application/json',
        metadata: {
          metadata: {
            recordCount: records.length.toString(),
            cutoffDate: cutoffDate.toISOString(),
            archivedAt: new Date().toISOString(),
          }
        }
      });
      
      console.log(`✅ Uploaded ${records.length} orders to ${filePath}`);
      
      // Помечаем заказы как архивированные
      const batch = db.batch();
      snapshot.forEach(doc => {
        batch.update(doc.ref, {
          archived: true,
          archivedAt: admin.firestore.FieldValue.serverTimestamp(),
          archiveFile: filePath,
        });
      });
      
      await batch.commit();
      
      console.log(`✅ Marked ${records.length} orders as archived`);
      console.log('🎉 Completed orders archiving completed successfully');
      
      return {
        success: true,
        archived: records.length,
        filePath: filePath,
      };
      
    } catch (error) {
      console.error('❌ Error archiving completed orders:', error);
      throw error;
    }
  });

/**
 * Очистка старых архивированных записей из Firestore
 * Запускается каждый месяц 15-го числа в 02:00
 * Удаляет записи, которые были архивированы более 6 месяцев назад
 */
exports.cleanupArchivedRecords = functions.pubsub
  .schedule('0 2 15 * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    console.log('🧹 Starting cleanup of old archived records...');
    
    try {
      // Дата отсечки - 6 месяцев назад
      const cutoffDate = new Date();
      cutoffDate.setMonth(cutoffDate.getMonth() - 6);
      
      console.log(`📅 Cutoff date: ${cutoffDate.toISOString()}`);
      
      let totalDeleted = 0;
      
      // Очистка истории инвентаря
      const historySnapshot = await db.collection('inventory_history')
        .where('archived', '==', true)
        .where('archivedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .limit(500)
        .get();
      
      if (!historySnapshot.empty) {
        const batch1 = db.batch();
        historySnapshot.forEach(doc => {
          batch1.delete(doc.ref);
        });
        await batch1.commit();
        totalDeleted += historySnapshot.size;
        console.log(`🗑️ Deleted ${historySnapshot.size} archived inventory history records`);
      }
      
      // Очистка заказов
      const ordersSnapshot = await db.collection('delivery_points')
        .where('archived', '==', true)
        .where('archivedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .limit(500)
        .get();
      
      if (!ordersSnapshot.empty) {
        const batch2 = db.batch();
        ordersSnapshot.forEach(doc => {
          batch2.delete(doc.ref);
        });
        await batch2.commit();
        totalDeleted += ordersSnapshot.size;
        console.log(`🗑️ Deleted ${ordersSnapshot.size} archived order records`);
      }
      
      console.log(`✅ Total deleted: ${totalDeleted} records`);
      console.log('🎉 Cleanup completed successfully');
      
      return {
        success: true,
        deleted: totalDeleted,
      };
      
    } catch (error) {
      console.error('❌ Error cleaning up archived records:', error);
      throw error;
    }
  });
