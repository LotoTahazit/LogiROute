import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_route.dart';
import '../models/route_status.dart';
import '../config/app_config.dart';
import 'firestore_paths.dart';

/// Сервис для построения маршрутов и определения стартовой точки
class RouteBuilderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  RouteBuilderService(this.companyId);

  /// Определяет стартовую точку маршрута
  ///
  /// Логика:
  /// - planned → warehouse
  /// - active → driver GPS
  Future<Map<String, double>?> getRouteStartPoint(
    String driverId,
    RouteStatus status,
  ) async {
    switch (status) {
      case RouteStatus.planned:
        return await _getWarehouseLocation();
      case RouteStatus.active:
        return await _getDriverCurrentLocation(driverId);
      default:
        return await _getWarehouseLocation();
    }
  }

  /// Получает координаты склада из настроек компании
  Future<Map<String, double>?> _getWarehouseLocation() async {
    try {
      // 1. Company config (основной путь)
      final configDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('config')
          .get();

      if (configDoc.exists) {
        final data = configDoc.data()!;
        final lat = (data['warehouseLat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          print(
              '🏭 [RouteBuilder] Warehouse from company config: ($lat, $lng)');
          return {'latitude': lat, 'longitude': lng};
        }
      }

      // 2. Legacy warehouse doc
      final legacyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('warehouse')
          .get();

      if (legacyDoc.exists) {
        final data = legacyDoc.data()!;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          print('🏭 [RouteBuilder] Warehouse from legacy doc: ($lat, $lng)');
          return {'latitude': lat, 'longitude': lng};
        }
      }

      // 3. Fallback to AppConfig defaults
      print('⚠️ [RouteBuilder] No warehouse config, using AppConfig defaults');
      return {
        'latitude': AppConfig.defaultWarehouseLat,
        'longitude': AppConfig.defaultWarehouseLng,
      };
    } catch (e) {
      print('❌ [RouteBuilder] Error getting warehouse location: $e');
      return {
        'latitude': AppConfig.defaultWarehouseLat,
        'longitude': AppConfig.defaultWarehouseLng,
      };
    }
  }

  /// Получает текущее GPS положение водителя
  Future<Map<String, double>?> _getDriverCurrentLocation(
      String driverId) async {
    try {
      final driverDoc =
          await FirestorePaths.driverLocationsOf(companyId).doc(driverId).get();

      if (driverDoc.exists) {
        final data = driverDoc.data();
        if (data != null) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();

          if (lat != null && lng != null && lat != 0 && lng != 0) {
            print('🚛 [RouteBuilder] Driver GPS location: ($lat, $lng)');
            return {'latitude': lat, 'longitude': lng};
          }
        }
      }

      print('⚠️ [RouteBuilder] Driver GPS not available, using warehouse');
      return await _getWarehouseLocation();
    } catch (e) {
      print('❌ [RouteBuilder] Error getting driver location: $e');
      return await _getWarehouseLocation();
    }
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
        // Создание нового маршрута
        final docRef = await routesRef.add(route.toMap());
        print('✅ [RouteBuilder] Route created with ID: ${docRef.id}');
        return docRef.id;
      } else {
        // Обновление существующего маршрута
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
