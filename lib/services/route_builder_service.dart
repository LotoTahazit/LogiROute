import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_route.dart';
import '../models/route_status.dart';
import '../config/app_config.dart';

/// Сервис для построения маршрутов.
/// **План (Route):** старт всегда склад из [AppConfig] — фиксированный, не меняется.
class RouteBuilderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  RouteBuilderService(this.companyId);

  /// Только склад (TSP / метаданные маршрута). Без Firestore, без GPS, без смен.
  Future<Map<String, double>?> getRouteStartPoint(
    String driverId,
    RouteStatus status,
  ) async {
    return {
      'latitude': AppConfig.defaultWarehouseLat,
      'longitude': AppConfig.defaultWarehouseLng,
    };
  }

  /// Создаёт новый маршрут
  Future<DeliveryRoute> createRoute({
    required String driverId,
    required String driverName,
    required List<String> pointIds,
    RouteStatus status = RouteStatus.planned,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final startPoint = await getRouteStartPoint(driverId, status);

    final route = DeliveryRoute(
      companyId: companyId,
      driverId: driverId,
      driverName: driverName,
      pointIds: pointIds,
      status: status,
      createdAt: now,
      updatedAt: now,
      routeDate: DateTime(now.year, now.month, now.day),
      metadata: {
        'startPoint': startPoint,
        ...?metadata,
      },
    );

    print('✅ [RouteBuilder] Route created: ${route.toString()}');
    return route;
  }

  /// Обновляет статус маршрута
  Future<void> updateRouteStatus(String routeId, RouteStatus newStatus) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(routeId)
          .update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

      print(
          '✅ [RouteBuilder] Route $routeId status updated to ${newStatus.name}');
    } catch (e) {
      print('❌ [RouteBuilder] Error updating route status: $e');
      rethrow;
    }
  }

  /// Получает маршрут по ID
  Future<DeliveryRoute?> getRoute(String routeId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(routeId)
          .get();

      if (doc.exists) {
        return DeliveryRoute.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      print('❌ [RouteBuilder] Error getting route: $e');
      return null;
    }
  }

  /// Получает все маршруты водителя
  Future<List<DeliveryRoute>> getDriverRoutes(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DeliveryRoute.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print('❌ [RouteBuilder] Error getting driver routes: $e');
      return [];
    }
  }

  /// Сохраняет маршрут в Firestore
  Future<String> saveRoute(DeliveryRoute route) async {
    try {
      final routesRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes');

      if (route.id == null) {
        final docRef = await routesRef.add(route.toMap());
        print('✅ [RouteBuilder] Route created with ID: ${docRef.id}');
        return docRef.id;
      } else {
        await routesRef.doc(route.id).update(route.toMap());
        print('✅ [RouteBuilder] Route updated: ${route.id}');
        return route.id!;
      }
    } catch (e) {
      print(' [RouteBuilder] Error saving route: $e');
      rethrow;
    }
  }

  /// Удаляет маршрут
  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(routeId)
          .delete();

      print(' [RouteBuilder] Route deleted: $routeId');
    } catch (e) {
      print(' [RouteBuilder] Error deleting route: $e');
      rethrow;
    }
  }
}
