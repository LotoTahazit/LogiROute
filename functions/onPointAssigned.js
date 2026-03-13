const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * onPointAssigned — Firestore trigger на delivery_points.
 * Срабатывает при изменении driverId или status.
 *
 * Типы уведомлений:
 *   NEW_STOP       — точка назначена водителю (driverId: null → value)
 *   ROUTE_CHANGED  — точка переназначена другому водителю
 *   STOP_CANCELLED — точка отменена
 *   URGENT_STOP    — срочная точка назначена
 *
 * Путь: companies/{companyId}/logistics/_root/delivery_points/{pointId}
 */
exports.onPointAssigned = functions.firestore
  .document('companies/{companyId}/logistics/_root/delivery_points/{pointId}')
  .onUpdate(async (change, context) => {
    const { companyId, pointId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    const oldDriverId = before.driverId || null;
    const newDriverId = after.driverId || null;
    const oldStatus = before.status || '';
    const newStatus = after.status || '';
    const clientName = after.clientName || 'Unknown';
    const address = after.address || '';
    const urgency = after.urgency || 'normal';

    // === 1. STOP_CANCELLED ===
    if (newStatus === 'cancelled' && oldStatus !== 'cancelled') {
      if (oldDriverId) {
        await _sendDriverNotification(companyId, oldDriverId, {
          type: 'STOP_CANCELLED',
          title: '❌ נקודה בוטלה',
          body: `${clientName} — ${address}`,
          pointId,
        });
      }
      return null;
    }

    // === 2. NEW_STOP (driverId: null → value) ===
    if (!oldDriverId && newDriverId) {
      const notifType = urgency === 'urgent' ? 'URGENT_STOP' : 'NEW_STOP';
      const title = urgency === 'urgent' ? '🚨 נקודה דחופה חדשה' : '📦 נקודה חדשה';

      await _sendDriverNotification(companyId, newDriverId, {
        type: notifType,
        title,
        body: `${clientName} — ${address}`,
        pointId,
      });
      return null;
    }

    // === 3. ROUTE_CHANGED (driverId changed) ===
    if (oldDriverId && newDriverId && oldDriverId !== newDriverId) {
      // Уведомляем старого водителя
      await _sendDriverNotification(companyId, oldDriverId, {
        type: 'STOP_CANCELLED',
        title: '🔄 נקודה הועברה',
        body: `${clientName} הועברה לנהג אחר`,
        pointId,
      });

      // Уведомляем нового водителя
      const notifType = urgency === 'urgent' ? 'URGENT_STOP' : 'ROUTE_CHANGED';
      const title = urgency === 'urgent' ? '🚨 נקודה דחופה חדשה' : '📦 נקודה חדשה במסלול';

      await _sendDriverNotification(companyId, newDriverId, {
        type: notifType,
        title,
        body: `${clientName} — ${address}`,
        pointId,
      });
      return null;
    }

    return null;
  });

/**
 * Отправляет уведомление водителю через notifications коллекцию.
 * sendPushNotification Cloud Function подхватит его и отправит FCM.
 */
async function _sendDriverNotification(companyId, driverId, data) {
  try {
    await db
      .collection('companies')
      .doc(companyId)
      .collection('notifications')
      .add({
        ...data,
        driverId,
        severity: data.type === 'URGENT_STOP' ? 'critical' : 'info',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

    console.log(
      `📱 [onPointAssigned] ${data.type} → driver ${driverId}: ${data.body}`
    );
  } catch (e) {
    console.error(`❌ [onPointAssigned] Error sending notification:`, e);
  }
}
