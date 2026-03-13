const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * onRoutePointChanged — при назначении точки водителю,
 * пересчитывает totalStops и totalPallets в routes документе.
 *
 * Polyline НЕ пересчитывается автоматически (дорого).
 * Polyline обновляется только при:
 *   - создании маршрута (createOptimizedRoute)
 *   - ручной перестановке точек (recalculateETAs)
 *
 * Путь: companies/{companyId}/logistics/_root/delivery_points/{pointId}
 */
exports.onRoutePointChanged = functions.firestore
  .document('companies/{companyId}/logistics/_root/delivery_points/{pointId}')
  .onUpdate(async (change, context) => {
    const { companyId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    const oldRouteId = before.routeId || null;
    const newRouteId = after.routeId || null;

    // Обновляем route stats только если routeId изменился или status изменился
    const routeIdsToUpdate = new Set();
    if (oldRouteId) routeIdsToUpdate.add(oldRouteId);
    if (newRouteId) routeIdsToUpdate.add(newRouteId);

    if (routeIdsToUpdate.size === 0) return null;

    // Проверяем что реально изменилось что-то важное
    const driverChanged = before.driverId !== after.driverId;
    const statusChanged = before.status !== after.status;
    const routeChanged = oldRouteId !== newRouteId;
    if (!driverChanged && !statusChanged && !routeChanged) return null;

    const routesRef = db
      .collection('companies')
      .doc(companyId)
      .collection('logistics')
      .doc('_root')
      .collection('routes');

    const pointsRef = db
      .collection('companies')
      .doc(companyId)
      .collection('logistics')
      .doc('_root')
      .collection('delivery_points');

    for (const routeId of routeIdsToUpdate) {
      try {
        // Считаем актуальные stats для этого маршрута
        const pointsSnap = await pointsRef
          .where('routeId', '==', routeId)
          .where('status', 'in', ['assigned', 'in_progress'])
          .get();

        const totalStops = pointsSnap.size;
        const totalPallets = pointsSnap.docs.reduce(
          (sum, doc) => sum + ((doc.data().pallets || 0)),
          0
        );

        const routeDoc = await routesRef.doc(routeId).get();
        if (routeDoc.exists) {
          await routesRef.doc(routeId).update({
            totalStops,
            totalPallets,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(
            `📊 [onRoutePointChanged] Route ${routeId}: ${totalStops} stops, ${totalPallets} pallets`
          );
        }
      } catch (e) {
        console.error(`❌ [onRoutePointChanged] Error updating route ${routeId}:`, e);
      }
    }

    return null;
  });
