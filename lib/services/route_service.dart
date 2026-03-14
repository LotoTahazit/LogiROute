// lib/services/route_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_point.dart';
import '../models/user_model.dart';
import '../models/box_type.dart';
import '../config/app_config.dart';
import 'api_config_service.dart';
import 'client_learning_service.dart';
import '../utils/time_formatter.dart';
import 'route_optimizer.dart';
import 'route_safety_service.dart';
import 'route_balance_service.dart';
import 'osrm_navigation_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_paths.dart';
import 'inventory_service.dart';

class RouteService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestorePaths _paths = FirestorePaths();
  static bool _isDistributing = false;

  RouteService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Централизованный доступ к коллекции точек доставки через FirestorePaths
  CollectionReference<Map<String, dynamic>> _deliveryPointsCollection() {
    return _paths.deliveryPoints(companyId);
  }

  /// Централизованный доступ к коллекции маршрутов через FirestorePaths
  CollectionReference<Map<String, dynamic>> _routesCollection() {
    return _paths.routes(companyId);
  }

  /// Helper: обновляет точку доставки, автоматически добавляя updatedAt
  Future<void> _updatePoint(String pointId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _deliveryPointsCollection().doc(pointId).update(data);
  }

  /// 🚚 Автоматически распределяет все pending точки между всеми водителями по palletCapacity
  Future<void> autoDistributePalletsToDrivers(List<UserModel> drivers) async {
    // Prevent concurrent distribution
    if (_isDistributing) {
      print('⚠️ [RouteService] autoDistribute already in progress, skipping');
      return;
    }
    _isDistributing = true;
    try {
      await _doAutoDistribute(drivers);
    } finally {
      _isDistributing = false;
    }
  }

  Future<void> _doAutoDistribute(List<UserModel> drivers) async {
    // Получаем все точки, которые ещё не назначены (pending)
    final pendingSnapshot = await _deliveryPointsCollection()
        .where('status', isEqualTo: 'pending')
        .get();

    final pendingPoints = pendingSnapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
    if (pendingPoints.isEmpty || drivers.isEmpty) return;

    // Фильтруем только водителей с capacity > 0
    final activeDrivers =
        drivers.where((d) => (d.palletCapacity ?? 0) > 0).toList();
    if (activeDrivers.isEmpty) return;

    // === Балансировка загрузки с учётом ближайших точек ===
    final totalPallets = pendingPoints.fold<int>(0, (s, p) => s + p.pallets);
    final targetPerDriver = totalPallets / activeDrivers.length;
    print(
      '📊 [AutoDist] ${pendingPoints.length} points, $totalPallets pallets, '
      '${activeDrivers.length} drivers, target ~${targetPerDriver.toStringAsFixed(1)} pallets/driver',
    );

    // Текущая загрузка каждого водителя (уже назначенные сегодня)
    final Map<String, int> driverCurrentLoad = {};
    for (final driver in activeDrivers) {
      final existing = await _deliveryPointsCollection()
          .where('driverId', isEqualTo: driver.uid)
          .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
          .get();
      final load = existing.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['pallets'] as num?)?.toInt() ?? 0),
      );
      driverCurrentLoad[driver.uid] = load;
    }

    // Распределяем точки: nearest-neighbor + балансировка
    final unassigned = List<DeliveryPoint>.from(pendingPoints);
    final Map<String, List<DeliveryPoint>> assignments = {
      for (final d in activeDrivers) d.uid: [],
    };
    final Map<String, int> driverPallets = Map.from(driverCurrentLoad);

    final warehouseLat = AppConfig.defaultWarehouseLat;
    final warehouseLng = AppConfig.defaultWarehouseLng;

    // Для каждого водителя отслеживаем последнюю позицию (начинаем со склада)
    final Map<String, double> lastLat = {
      for (final d in activeDrivers) d.uid: warehouseLat,
    };
    final Map<String, double> lastLng = {
      for (final d in activeDrivers) d.uid: warehouseLng,
    };

    // Round-robin: каждый водитель по очереди берёт ближайшую к себе точку
    while (unassigned.isNotEmpty) {
      // Сортируем водителей по текущей загрузке (менее загруженные первые)
      final driversByLoad = List<UserModel>.from(activeDrivers)
        ..sort((a, b) =>
            (driverPallets[a.uid] ?? 0).compareTo(driverPallets[b.uid] ?? 0));

      bool anyAssigned = false;

      for (final driver in driversByLoad) {
        if (unassigned.isEmpty) break;
        final capacity = driver.palletCapacity ?? 0;
        final currentLoad = driverPallets[driver.uid] ?? 0;

        // Пропускаем если водитель уже перегружен
        if (currentLoad >= capacity) continue;

        // Ищем ближайшую к текущей позиции водителя точку, которая влезает
        final dLat = lastLat[driver.uid]!;
        final dLng = lastLng[driver.uid]!;

        DeliveryPoint? nearest;
        double nearestDist = double.infinity;
        for (final point in unassigned) {
          if (point.latitude == 0 && point.longitude == 0) continue;
          if (currentLoad + point.pallets > capacity) continue;
          final dist = _calculateDistance(
            dLat,
            dLng,
            point.latitude,
            point.longitude,
          );
          if (dist < nearestDist) {
            nearestDist = dist;
            nearest = point;
          }
        }

        if (nearest == null) {
          // Если не нашли с учётом capacity — попробуем без проверки (overflow)
          // чтобы не оставить точки без назначения
          double minDist = double.infinity;
          for (final point in unassigned) {
            if (point.latitude == 0 && point.longitude == 0) continue;
            final dist = _calculateDistance(
              dLat,
              dLng,
              point.latitude,
              point.longitude,
            );
            if (dist < minDist) {
              minDist = dist;
              nearest = point;
            }
          }
        }

        if (nearest != null) {
          assignments[driver.uid]!.add(nearest);
          driverPallets[driver.uid] =
              (driverPallets[driver.uid] ?? 0) + nearest.pallets;
          lastLat[driver.uid] = nearest.latitude;
          lastLng[driver.uid] = nearest.longitude;
          unassigned.remove(nearest);
          anyAssigned = true;
        }
      }

      // Защита от бесконечного цикла
      if (!anyAssigned) {
        print(
            '⚠️ [AutoDist] ${unassigned.length} points could not be assigned');
        break;
      }
    }

    // Логируем результат балансировки
    for (final driver in activeDrivers) {
      final pts = assignments[driver.uid]!;
      final load = driverPallets[driver.uid] ?? 0;
      print(
        '🚚 [AutoDist] ${driver.name}: ${pts.length} points, '
        '$load pallets (capacity: ${driver.palletCapacity})',
      );
    }

    // === Сохраняем назначения в Firestore ===
    const double avgSpeedKmh = 38.0;
    const double serviceTimeMinutes = 7.0;
    const double parkingTimeMinutes = 2.0;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (final driver in activeDrivers) {
      final assigned = assignments[driver.uid]!;
      if (assigned.isEmpty) continue;

      final routeId = '${driver.uid}_${now.year}_${now.month}_${now.day}';

      // Получаем текущее количество точек у водителя для orderInRoute
      final existingPoints = await _deliveryPointsCollection()
          .where('driverId', isEqualTo: driver.uid)
          .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
          .get();
      final startOrder = existingPoints.docs.length;

      double cumulativeTimeMinutes = 0;

      for (int i = 0; i < assigned.length; i++) {
        final point = assigned[i];

        double distanceKm;
        if (i == 0 && existingPoints.docs.isEmpty) {
          distanceKm = _calculateDistance(
            warehouseLat,
            warehouseLng,
            point.latitude,
            point.longitude,
          );
        } else if (i == 0 && existingPoints.docs.isNotEmpty) {
          final lastExisting = existingPoints.docs.last.data();
          distanceKm = _calculateDistance(
            (lastExisting['latitude'] ?? 0).toDouble(),
            (lastExisting['longitude'] ?? 0).toDouble(),
            point.latitude,
            point.longitude,
          );
        } else {
          final prevPoint = assigned[i - 1];
          distanceKm = _calculateDistance(
            prevPoint.latitude,
            prevPoint.longitude,
            point.latitude,
            point.longitude,
          );
        }

        final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
        cumulativeTimeMinutes +=
            travelTimeMinutes + serviceTimeMinutes + parkingTimeMinutes;
        final eta = TimeFormatter.formatArrivalTime(cumulativeTimeMinutes);

        await _updatePoint(point.id, {
          'driverId': driver.uid,
          'driverName': driver.name,
          'driverCapacity': driver.palletCapacity,
          'orderInRoute': startOrder + i,
          'status': 'assigned',
          'eta': eta,
          'distanceKm': double.parse(distanceKm.toStringAsFixed(1)),
          'routeId': routeId,
          'routeDate': Timestamp.fromDate(todayMidnight),
        });
      }
    }
  }

  /// ✅ Единый метод получения сегодняшних маршрутов
  /// [driverId] — фильтр по водителю (null = все)
  /// [includeCompleted] — включать завершённые точки (карта, водитель)
  Stream<List<DeliveryPoint>> getTodayRoutes({
    String? driverId,
    bool includeCompleted = true,
  }) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    Query query = _deliveryPointsCollection();

    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }

    final statuses = <String>[
      ...DeliveryPoint.activeRouteStatuses,
      if (includeCompleted) DeliveryPoint.statusCompleted,
    ];
    query = query.where('status', whereIn: statuses).limit(300);

    return query.snapshots(includeMetadataChanges: false).map((snapshot) {
      final points = snapshot.docs
          .map((doc) =>
              DeliveryPoint.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) {
        // 1️⃣ routeId = driverId_year_month_day → парсим дату
        if (p.routeId != null) {
          return _isRouteFromToday(p.routeId!, todayMidnight);
        }

        // 2️⃣ Completed сегодня (без routeId)
        if (p.status == DeliveryPoint.statusCompleted &&
            p.completedAt != null) {
          return p.completedAt!.isAfter(todayMidnight);
        }

        // 3️⃣ Активные точки без routeId — показываем (pending/assigned/in_progress)
        if (p.status != DeliveryPoint.statusCompleted) {
          return true;
        }

        return false;
      }).toList();

      points.sort((a, b) {
        final driverCompare =
            (a.driverName ?? '').compareTo(b.driverName ?? '');
        if (driverCompare != 0) return driverCompare;
        return a.orderInRoute.compareTo(b.orderInRoute);
      });

      return points;
    });
  }

  /// Проверяет, относится ли routeId к сегодняшнему дню
  /// Формат routeId: driverId_year_month_day
  bool _isRouteFromToday(String routeId, DateTime today) {
    final parts = routeId.split('_');
    if (parts.length < 4) return false;
    try {
      final year = int.parse(parts[parts.length - 3]);
      final month = int.parse(parts[parts.length - 2]);
      final day = int.parse(parts[parts.length - 1]);
      return year == today.year && month == today.month && day == today.day;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Получить маршруты для карты (из коллекции routes — 1 чтение)
  Future<List<Map<String, dynamic>>> getTodayRoutesForMap() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Пробуем из кэша, fallback на сервер
    final snapshot = await _routesCollection()
        .get(const GetOptions(source: Source.cache))
        .catchError((_) => _routesCollection().get());

    // Фильтруем на клиенте: routeDate == сегодня ИЛИ routeId содержит сегодняшнюю дату
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final routeDate = data['routeDate'] as Timestamp?;
          if (routeDate != null) {
            final rd = routeDate.toDate();
            return rd.year == todayMidnight.year &&
                rd.month == todayMidnight.month &&
                rd.day == todayMidnight.day;
          }
          // Fallback: парсим routeId
          final routeId = data['routeId'] as String? ?? doc.id;
          return _isRouteFromToday(routeId, todayMidnight);
        })
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Поток автозакрытых точек (для кнопки "החזר לנקודה פתוחה")
  /// Показываем только до полуночи текущего дня, после полуночи они исчезают
  Stream<List<DeliveryPoint>> getAutoCompletedPoints() {
    return _deliveryPointsCollection()
        .where('status', isEqualTo: DeliveryPoint.statusCompleted)
        .where('autoCompleted', isEqualTo: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      return snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .where((p) {
        // Показываем только точки, завершенные сегодня (после полуночи)
        if (p.completedAt == null) return false;
        return p.completedAt!.isAfter(midnight);
      }).toList();
    });
  }

  /// Поток всех ожидающих точек (для вкладки "נקודות משלוח")
  /// ⚡ OPTIMIZED: Added limit
  Stream<List<DeliveryPoint>> getAllPendingPoints() {
    return _deliveryPointsCollection()
        .where('status', whereIn: DeliveryPoint.pendingStatuses)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .where((p) {
        final normalized = DeliveryPoint.normalizeStatus(p.status);
        final isPending = normalized == DeliveryPoint.statusPending ||
            DeliveryPoint.pendingStatuses.contains(normalized);
        final isUnassigned = (p.driverId == null || p.driverId!.isEmpty) &&
            (p.routeId == null || p.routeId!.isEmpty);
        return isPending && isUnassigned;
      }).toList();
    });
  }

  /// ✅ Для карты — получить только активные маршруты
  /// ⚡ OPTIMIZED: Added limit
  Stream<List<DeliveryPoint>> getAllPointsForMap() {
    return _deliveryPointsCollection()
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<DeliveryPoint>> getAllPointsForMapTesting() {
    return _deliveryPointsCollection().limit(500).snapshots().map((snapshot) {
      print(
          '📊 [RouteService] Loaded ${snapshot.docs.length} points (testing mode)');
      return snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// ✅ Получить все маршруты как Future (для управления логикой)
  Future<List<DeliveryPoint>> getAllRouteModels() async {
    final snapshot =
        await _deliveryPointsCollection().where('status', whereIn: [
      DeliveryPoint.statusAssigned,
      DeliveryPoint.statusInProgress,
      DeliveryPoint.statusCompleted,
    ]).get();

    return snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// ✅ Создать оптимизированный маршрут с проверкой мостов и веса
  Future<void> createOptimizedRoute(String driverId, String driverName,
      List<DeliveryPoint> points, int driverCapacity,
      {bool useDispatcherLocation = false}) async {
    if (points.isEmpty) return;

    print(
        '🧭 [RouteService] Creating optimized route for $driverName (${points.length} points)');

    // Получаем информацию о водителе для проверки тоннажа
    final truckWeight = await _getDriverTruckWeight(driverId);
    print(
        '⚖️ [RouteService] Driver truck weight: ${truckWeight.toStringAsFixed(1)}t');

    // Получаем позицию: склада (диспетчер) или водителя
    Map<String, double>? startLocation;
    if (useDispatcherLocation) {
      startLocation = await _getDispatcherLocation();
      print(
          '🏭 [RouteService] Using dispatcher/warehouse location for route optimization');
    } else {
      startLocation = await _getDriverCurrentLocation(driverId);
      print('🚛 [RouteService] Using driver location for route optimization');
    }

    // Combined optimization algorithm with real position
    final optimizedPoints =
        RouteOptimizer.optimizeRouteOrder(points, startLocation);

    // Check bridge heights
    final bridgeCheckPassed =
        await RouteSafetyService.checkBridgeHeights(optimizedPoints);

    // Check weight restrictions
    final weightCheckPassed = await RouteSafetyService.checkRoadWeightLimits(
        optimizedPoints, truckWeight);

    if (!bridgeCheckPassed || !weightCheckPassed) {
      final reason = !bridgeCheckPassed
          ? 'low bridge (< ${AppConfig.minBridgeHeight}m)'
          : 'weight restriction (< ${AppConfig.minRoadWeightLimit}t)';
      print(
          '🚧 [RouteService] Route blocked by $reason! Trying alternative route...');

      // Try alternative optimization
      final alternativePoints =
          RouteOptimizer.createAlternativeRoute(points, startLocation);
      final altBridgeCheck =
          await RouteSafetyService.checkBridgeHeights(alternativePoints);
      final altWeightCheck = await RouteSafetyService.checkRoadWeightLimits(
          alternativePoints, truckWeight);

      if (!altBridgeCheck || !altWeightCheck) {
        print('❌ [RouteService] Alternative route also blocked!');
        final errorMsg = !altBridgeCheck
            ? 'Route blocked by low bridges (< ${AppConfig.minBridgeHeight}m height)'
            : 'Route blocked by weight restrictions (< ${AppConfig.minRoadWeightLimit}t limit)';
        throw Exception('$errorMsg. Please contact dispatcher.');
      } else {
        print('✅ [RouteService] Alternative route approved!');
        await _assignPointsToDriver(
            driverId, driverName, driverCapacity, alternativePoints);
        return;
      }
    }

    print('✅ [RouteService] Route approved - no restrictions');

    // Назначаем точки водителю
    await _assignPointsToDriver(
        driverId, driverName, driverCapacity, optimizedPoints);
  }

  /// 🏭 Получает позицию склада/диспетчера из настроек
  Future<Map<String, double>?> _getDispatcherLocation() async {
    try {
      // Пробуем получить настройки склада из Firestore
      final doc = await _firestore
          .collection('settings')
          .doc('warehouse_location')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      }

      print(
          '⚠️ [RouteService] Warehouse location not configured, using default location');
      return null;
    } catch (e) {
      print('❌ [RouteService] Error getting warehouse location: $e');
      return null;
    }
  }

  /// 📍 Получает текущую позицию водителя из Firestore
  Future<Map<String, double>?> _getDriverCurrentLocation(
      String driverId) async {
    try {
      final doc =
          await FirestorePaths.driverLocationsOf(companyId).doc(driverId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final timestamp = data['timestamp'];

        // Проверяем, что данные не старше 10 минут
        if (timestamp != null) {
          final locationTime = timestamp.toDate();
          final now = DateTime.now();
          final diffMinutes = now.difference(locationTime).inMinutes;

          if (diffMinutes <= 10) {
            return {
              'latitude': data['latitude'],
              'longitude': data['longitude'],
            };
          }
        }
      }

      print(
          '⚠️ [RouteService] Driver location not found or too old, using default location');
      return null;
    } catch (e) {
      print('❌ [RouteService] Error getting driver location: $e');
      return null;
    }
  }

  /// 🚛 Получает тоннаж грузовика водителя из Firestore
  Future<double> _getDriverTruckWeight(String driverId) async {
    try {
      final doc = await _paths.users().doc(driverId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final weight = data['truckWeight'];

        if (weight != null) {
          return weight is String
              ? double.parse(weight)
              : (weight as num).toDouble();
        }
      }

      print(
          '⚠️ [RouteService] Driver truck weight not found, using default (${AppConfig.maxTruckWeight}t)');
      return AppConfig.maxTruckWeight;
    } catch (e) {
      print('❌ [RouteService] Error getting driver truck weight: $e');
      return AppConfig.maxTruckWeight;
    }
  }

  /// 🧠 Route optimization moved to RouteOptimizer class

  /// 📏 Distance calculation delegated to RouteOptimizer
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return RouteOptimizer.calculateDistance(lat1, lng1, lat2, lng2);
  }

  /// ✏️ Обновить точку доставки
  Future<void> updatePoint(String pointId, String urgency, int? orderInRoute,
      String? temporaryAddress) async {
    print(
        '✏️ [RouteService] Updating point $pointId: urgency=$urgency, order=$orderInRoute, tempAddress=$temporaryAddress');

    final updateData = <String, dynamic>{
      'urgency': urgency,
    };

    if (orderInRoute != null) {
      updateData['orderInRoute'] = orderInRoute;
    }

    if (temporaryAddress != null && temporaryAddress.isNotEmpty) {
      updateData['temporaryAddress'] = temporaryAddress;

      // Геокодируем временный адрес и обновляем координаты
      try {
        final coordinates = await _geocodeAddress(temporaryAddress);
        if (coordinates != null) {
          updateData['latitude'] = coordinates['latitude'];
          updateData['longitude'] = coordinates['longitude'];
          print(
              '🗺️ [RouteService] Geocoded temporary address: (${coordinates['latitude']}, ${coordinates['longitude']})');
        }
      } catch (e) {
        print('❌ [RouteService] Failed to geocode temporary address: $e');
        // Не прерываем операцию, просто не обновляем координаты
      }
    }

    try {
      await _updatePoint(pointId, updateData);
      print('✅ [RouteService] Point $pointId updated successfully');
    } catch (e) {
      print('❌ [RouteService] Error updating point $pointId: $e');
      rethrow;
    }
  }

  /// 📦 Обновить товары (boxTypes) в точке доставки
  /// Пересчитывает boxes И pallets на основе инвентаря (quantityPerPallet)
  Future<void> updatePointBoxTypes(
      String pointId, List<dynamic> boxTypes) async {
    print(
        '📦 [RouteService] Updating boxTypes for point $pointId: ${boxTypes.length} items');
    try {
      final boxes = boxTypes.whereType<BoxType>().toList();
      final boxMaps = boxes.map((bt) => bt.toMap()).toList();
      final totalBoxes = boxes.fold<int>(0, (s, bt) => s + bt.quantity);

      // Пересчитываем миштахи по данным инвентаря
      int totalPallets = 0;
      try {
        final inventoryService = InventoryService(companyId: companyId);
        final inventory = await inventoryService.getInventory();

        int fullPallets = 0;
        int remainderBoxes = 0;

        for (final box in boxes) {
          final match = inventory.where(
            (item) => item.type == box.type && item.number == box.number,
          );
          final perPallet =
              match.isNotEmpty ? match.first.quantityPerPallet : 20;

          if (perPallet > 0) {
            fullPallets += box.quantity ~/ perPallet;
            remainderBoxes += box.quantity % perPallet;
          } else {
            remainderBoxes += box.quantity;
          }

          debugPrint(
            '🔍 [Calc] ${box.type} ${box.number}: qty=${box.quantity}, perPallet=$perPallet, full=${box.quantity ~/ (perPallet > 0 ? perPallet : 1)}, rem=${perPallet > 0 ? box.quantity % perPallet : box.quantity}',
          );
        }

        // Остатки от всех типов группируются по 20 шт на миштах
        final remainderPallets =
            remainderBoxes > 0 ? (remainderBoxes / 20).ceil() : 0;
        totalPallets = fullPallets + remainderPallets;

        debugPrint(
          '📊 [Calc] totalBoxes=$totalBoxes, fullPallets=$fullPallets, remainderBoxes=$remainderBoxes, totalPallets=$totalPallets',
        );
      } catch (e) {
        // Fallback: 20 коробок на миштах
        totalPallets = totalBoxes > 0 ? (totalBoxes / 20).ceil() : 0;
        debugPrint(
          '⚠️ [Calc] Fallback pallet calc: totalBoxes=$totalBoxes, pallets=$totalPallets. Error: $e',
        );
      }

      await _updatePoint(pointId, {
        'boxTypes': boxMaps,
        'boxes': totalBoxes,
        'pallets': totalPallets,
      });
      print(
          '✅ [RouteService] BoxTypes updated for point $pointId: $totalBoxes boxes, $totalPallets pallets');
    } catch (e) {
      print('❌ [RouteService] Error updating boxTypes for $pointId: $e');
      rethrow;
    }
  }

  /// 🌍 Геокодирование адреса (внутренний метод)
  /// Сначала пытается Google Geocoding, затем Nominatim (OpenStreetMap) как fallback
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    // 1. Сначала пробуем Google Geocoding
    final googleResult = await _geocodeWithGoogle(address);
    if (googleResult != null) {
      print('✅ [RouteService] Google geocoding successful for: $address');
      return googleResult;
    }

    // 2. Fallback на Nominatim (OpenStreetMap)
    print(
        '⚠️ [RouteService] Google geocoding failed, trying Nominatim fallback');
    final nominatimResult = await _geocodeWithNominatim(address);
    if (nominatimResult != null) {
      print('✅ [RouteService] Nominatim geocoding successful for: $address');
      return nominatimResult;
    }

    print('❌ [RouteService] All geocoding methods failed for: $address');
    return null;
  }

  /// Google Geocoding API
  Future<Map<String, double>?> _geocodeWithGoogle(String address) async {
    try {
      final apiKey = ApiConfigService.googleMapsApiKey;
      if (apiKey.isEmpty) {
        print('⚠️ [RouteService] Google Maps API key is empty');
        return null;
      }

      final encodedAddress = Uri.encodeComponent(address);
      final url =
          '${ApiConfigService.googleGeocodingApiUrl}?address=$encodedAddress&key=$apiKey';

      print('🔍 [RouteService] Google geocoding URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        AppConfig.geocodingTimeout,
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      print(
          '🔍 [RouteService] Google geocoding response: ${response.statusCode}');
      print('🔍 [RouteService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];

          return {
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };
        } else {
          print(
              '❌ [RouteService] Google geocoding API status: ${data['status']}');
          if (data['error_message'] != null) {
            print(
                '❌ [RouteService] Google API error: ${data['error_message']}');
          }
        }
      } else {
        print(
            '❌ [RouteService] HTTP error ${response.statusCode}: ${response.body}');
      }

      print('❌ [RouteService] Google geocoding failed for: $address');
      return null;
    } catch (e) {
      print('❌ [RouteService] Google geocoding error for $address: $e');
      return null;
    }
  }

  /// Nominatim (OpenStreetMap) Geocoding API - бесплатный fallback
  Future<Map<String, double>?> _geocodeWithNominatim(String address) async {
    try {
      // Добавляем "Israel" для лучших результатов по израильским адресам
      final searchAddress = '$address, Israel';
      final encodedAddress = Uri.encodeComponent(searchAddress);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1&countrycodes=il';

      print('🔍 [RouteService] Nominatim URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'LogiRoute/1.0 (geocoding fallback)',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      print('🔍 [RouteService] Nominatim response: ${response.statusCode}');
      print('🔍 [RouteService] Nominatim body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat'] as String);
          final lon = double.tryParse(result['lon'] as String);

          if (lat != null && lon != null) {
            print(
                '🗺️ [RouteService] Nominatim result: ($lat, $lon) for: $address');
            return {
              'latitude': lat,
              'longitude': lon,
            };
          } else {
            print(
                '❌ [RouteService] Nominatim invalid coordinates: lat=${result['lat']}, lon=${result['lon']}');
          }
        } else {
          print('❌ [RouteService] Nominatim empty results array');
        }
      } else {
        print(
            '❌ [RouteService] Nominatim HTTP error ${response.statusCode}: ${response.body}');
      }

      print('❌ [RouteService] Nominatim geocoding failed for: $address');
      return null;
    } catch (e) {
      print('❌ [RouteService] Nominatim geocoding error for $address: $e');
      return null;
    }
  }

  /// Проверяет, является ли текущий порядок точек неоптимальным по времени.
  /// Сравнивает длительность текущего маршрута с OSRM-оптимальным порядком.
  Future<bool> isRouteOrderSuboptimal(List<DeliveryPoint> points) async {
    final activePoints = points
        .where((p) =>
            p.status != 'completed' &&
            p.status != 'cancelled' &&
            p.status != 'delivered')
        .toList()
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
    if (activePoints.length < 2) return false;

    final osrm = OsrmNavigationService();
    final waypoints = activePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();
    final whLat = AppConfig.defaultWarehouseLat;
    final whLng = AppConfig.defaultWarehouseLng;

    final currentRoute = await osrm.getOptimizedRoute(
      startLat: whLat,
      startLng: whLng,
      waypoints: waypoints,
      endLat: whLat,
      endLng: whLng,
    );
    if (currentRoute == null) return false;

    final optimized = await osrm.getOptimizedTripOrder(
      warehouseLat: whLat,
      warehouseLng: whLng,
      waypoints: waypoints,
    );
    if (optimized == null) return false;

    final savedMinutes = currentRoute.duration - optimized.durationMinutes;
    return savedMinutes > 2.0 ||
        (currentRoute.duration > 0 &&
            savedMinutes / currentRoute.duration > 0.05);
  }

  /// Оптимизация порядка точек в маршруте по времени через OSRM Trip API.
  /// Возвращает true если порядок был изменён.
  Future<bool> optimizeRouteByTime(
      String driverId, String? routeId, List<DeliveryPoint> points) async {
    if (points.length < 2) return false;

    final activePoints = points
        .where((p) =>
            p.status != 'completed' &&
            p.status != 'cancelled' &&
            p.status != 'delivered')
        .toList()
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    if (activePoints.length < 2) return false;

    final osrm = OsrmNavigationService();
    final waypoints = activePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    final result = await osrm.getOptimizedTripOrder(
      warehouseLat: AppConfig.defaultWarehouseLat,
      warehouseLng: AppConfig.defaultWarehouseLng,
      waypoints: waypoints,
    );

    if (result == null) return false;

    // Проверяем, изменился ли порядок
    bool changed = false;
    if (result.waypointOrder.length == activePoints.length) {
      for (int i = 0; i < result.waypointOrder.length; i++) {
        if (result.waypointOrder[i] != i) {
          changed = true;
          break;
        }
      }
    }

    if (!changed) {
      debugPrint('✅ [RouteService] Route already optimal');
      return false;
    }

    // Применяем новый порядок
    final reordered = <DeliveryPoint>[];
    for (final idx in result.waypointOrder) {
      if (idx >= 0 && idx < activePoints.length) {
        reordered.add(activePoints[idx]);
      }
    }

    // Обновляем orderInRoute + ETA через RouteBalanceService
    final balanceService = RouteBalanceService(companyId: companyId);
    await balanceService.recalculateETAsForPoints(reordered);

    debugPrint(
        '✅ [RouteService] Route optimized: new order=${result.waypointOrder}');
    return true;
  }

  /// ✅ Отмена маршрута - удаляем все точки конкретного маршрута
  Future<void> cancelRoute(String driverId, String? routeId) async {
    print(
        '🛑 [RouteService] Starting route cancellation for driverId: "$driverId", routeId: "$routeId"');

    // Сначала посмотрим, что у нас есть в базе
    final allPoints = await _deliveryPointsCollection().get();
    print(
        '📊 [RouteService] Total points in database: ${allPoints.docs.length}');

    for (final doc in allPoints.docs) {
      final data = doc.data();
      print(
          '📍 [RouteService] Point: ${data['clientName']} - driverId: "${data['driverId']}" - routeId: "${data['routeId']}" - status: "${data['status']}"');
    }

    Query query;

    if (driverId.isEmpty || driverId == 'null') {
      // Safety: refuse to delete ALL points — require explicit driverId
      print(
          '⚠️ [RouteService] Refusing to delete ALL points (driverId is empty). Aborting.');
      return;
    } else if (routeId != null) {
      // Если есть routeId, удаляем только точки этого маршрута
      print('🗑️ [RouteService] Deleting points for routeId: "$routeId"');
      query = _deliveryPointsCollection().where('routeId', isEqualTo: routeId);
    } else {
      // Иначе удаляем точки конкретного водителя (для старых маршрутов без routeId)
      print(
          '🗑️ [RouteService] Deleting points for driverId: "$driverId" (no routeId)');
      query =
          _deliveryPointsCollection().where('driverId', isEqualTo: driverId);
    }

    final snapshot = await query.get();
    print('🛑 [RouteService] Found ${snapshot.docs.length} points to delete');

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('🗑️ [RouteService] Deleting point: ${data['clientName']}');
      await doc.reference.delete();
    }

    print(
        '✅ [RouteService] Route cancellation completed - ${snapshot.docs.length} points deleted');
  }

  /// ✅ Смена водителя для конкретного маршрута
  Future<void> changeRouteDriver(
    String oldDriverId,
    String newDriverId,
    String newDriverName,
    int capacity,
    String? routeId, // ID конкретного маршрута
  ) async {
    Query query =
        _deliveryPointsCollection().where('driverId', isEqualTo: oldDriverId);

    // Если указан routeId, фильтруем только по нему
    if (routeId != null) {
      query = query.where('routeId', isEqualTo: routeId);
    }

    final snapshot = await query.get();

    print(
        '🔄 [RouteService] Changing driver from $oldDriverId to $newDriverName (${snapshot.docs.length} points, routeId: $routeId)');

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'driverId': newDriverId,
        'driverName': newDriverName,
        'driverCapacity': capacity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    print('✅ [RouteService] Driver changed to $newDriverName');
  }

  /// Получить активные точки конкретного водителя
  Stream<List<DeliveryPoint>> getDriverPoints(String driverId) {
    return _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Получить активные точки водителя как Future (для проверки загрузки)
  Future<List<DeliveryPoint>> getDriverPointsSnapshot(String driverId) async {
    final snapshot = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Добавить новую точку доставки
  Future<void> addDeliveryPoint(DeliveryPoint point) async {
    // toMap() автоматически добавляет createdAt и updatedAt
    await _deliveryPointsCollection().add(point.toMap());
    print('✅ Delivery point added: ${point.clientName}');
  }

  /// Обновить статус точки (с аудитом: updatedByUid + updatedAt)
  /// ВАЖНО: водитель может менять только: status, completedAt, autoCompleted, updatedByUid, updatedAt
  Future<void> updatePointStatus(
    String pointId,
    String newStatus, {
    String? updatedByUid,
    bool autoCompleted = false,
  }) async {
    final Map<String, dynamic> patch = {
      'status': newStatus,
    };
    if (updatedByUid != null) {
      patch['updatedByUid'] = updatedByUid;
    }
    if (newStatus == DeliveryPoint.statusCompleted) {
      patch['completedAt'] = FieldValue.serverTimestamp();
      patch['autoCompleted'] = autoCompleted;
    }
    await _updatePoint(pointId, patch);
    print('✅ Point $pointId status updated to $newStatus');

    // Самообучение: записываем GPS и service_time при завершении
    if (newStatus == DeliveryPoint.statusCompleted) {
      _recordDeliveryLearning(pointId);
    }
  }

  /// Записывает данные доставки для самообучения клиента
  Future<void> _recordDeliveryLearning(String pointId) async {
    try {
      final doc = await _deliveryPointsCollection().doc(pointId).get();
      if (!doc.exists) return;
      final data = doc.data()!;

      final clientNumber = data['clientNumber'] as String? ?? '';
      final driverId = data['driverId'] as String? ?? '';
      if (clientNumber.isEmpty || driverId.isEmpty) return;

      // Получаем GPS водителя
      final locDoc =
          await FirestorePaths.driverLocationsOf(companyId).doc(driverId).get();
      double driverLat = 0, driverLng = 0;
      if (locDoc.exists) {
        driverLat = (locDoc.data()?['latitude'] as num?)?.toDouble() ?? 0;
        driverLng = (locDoc.data()?['longitude'] as num?)?.toDouble() ?? 0;
      }

      // arrivedAt — когда водитель начал (in_progress)
      DateTime? arrivedAt;
      if (data['arrivedAt'] != null) {
        arrivedAt = (data['arrivedAt'] as Timestamp).toDate();
      }

      final learning = ClientLearningService(companyId: companyId);
      await learning.recordDelivery(
        clientNumber: clientNumber,
        driverLat: driverLat,
        driverLng: driverLng,
        arrivedAt: arrivedAt,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ [Learning] Error in _recordDeliveryLearning: $e');
    }
  }

  /// Обновить текущую точку водителя (in_progress)
  Future<void> updateCurrentPoint(String pointId,
      {String? updatedByUid}) async {
    await updatePointStatus(pointId, DeliveryPoint.statusInProgress,
        updatedByUid: updatedByUid);
    print('✅ Point $pointId set to in_progress');
  }

  /// Активировать маршрут водителя (изменить статус всех точек с assigned на in_progress)
  Future<void> activateDriverRoute(String driverId) async {
    final snapshot = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: DeliveryPoint.statusAssigned)
        .get();

    if (snapshot.docs.isEmpty) {
      print('⚠️ No assigned points found for driver $driverId');
      return;
    }

    // Обновляем все точки водителя на in_progress
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': DeliveryPoint.statusInProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print(
        '✅ Route activated for driver $driverId (${snapshot.docs.length} points)');
  }

  /// Удалить отдельную точку доставки
  Future<void> deletePoint(String pointId) async {
    await _deliveryPointsCollection().doc(pointId).delete();
    print('🗑️ Point $pointId deleted');
  }

  /// Назначить точку водителю
  Future<void> assignPointToDriver(
      String pointId, String driverId, String driverName, int capacity) async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final routeId = '${driverId}_${now.year}_${now.month}_${now.day}';

    await _firestore.runTransaction((transaction) async {
      // Получаем максимальный orderInRoute за 1 чтение
      final maxOrderQuery = await _deliveryPointsCollection()
          .where('routeId', isEqualTo: routeId)
          .orderBy('orderInRoute', descending: true)
          .limit(1)
          .get();

      final nextOrder = maxOrderQuery.docs.isNotEmpty
          ? ((maxOrderQuery.docs.first.data()['orderInRoute'] as num?)
                      ?.toInt() ??
                  0) +
              1
          : 0;

      final docRef = _deliveryPointsCollection().doc(pointId);
      transaction.update(docRef, {
        'driverId': driverId,
        'driverName': driverName,
        'driverCapacity': capacity,
        'status': DeliveryPoint.statusAssigned,
        'orderInRoute': nextOrder,
        'routeId': routeId,
        'routeDate': Timestamp.fromDate(todayMidnight),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '👤 Point $pointId assigned to $driverName (order: $nextOrder, route: $routeId)');
    });
  }

  /// Road safety checks moved to RouteSafetyService
  /// Route alternative generation moved to RouteOptimizer

  /// 🚚 Назначает точки водителю (вынесенный метод)
  Future<void> _assignPointsToDriver(String driverId, String driverName,
      int driverCapacity, List<DeliveryPoint> points) async {
    // 🛡️ Жёсткая проверка перегрузки
    final existingLoad = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();
    final currentPallets = existingLoad.docs.fold<int>(
        0, (sum, doc) => sum + ((doc.data()['pallets'] as num?)?.toInt() ?? 0));
    final newPallets = points.fold<int>(0, (sum, p) => sum + p.pallets);
    if (driverCapacity > 0 && currentPallets + newPallets > driverCapacity) {
      throw Exception(
          'עומס יתר: $driverName — ${currentPallets + newPallets} משטחים מתוך $driverCapacity מותרים');
    }

    // Генерируем routeId для этого маршрута
    final now = DateTime.now();
    final routeId = '${driverId}_${now.year}_${now.month}_${now.day}';

    // 🧹 Очищаем ВЧЕРАШНИЕ завершенные маршруты (старше полуночи сегодня)
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final oldCompletedPoints = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: DeliveryPoint.statusCompleted)
        .get();

    int clearedCount = 0;
    for (final doc in oldCompletedPoints.docs) {
      final data = doc.data();
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();

      // Очищаем только точки, завершенные ДО полуночи сегодня
      if (completedAt != null && completedAt.isBefore(todayMidnight)) {
        await doc.reference.update({
          'routePolyline': null,
          'routeId': null,
          'routeDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        clearedCount++;
      }
    }

    print(
        '🧹 [RouteService] Cleared $clearedCount old completed points for driver $driverName');

    // 🧹 Очищаем осиротевшие assigned/in_progress точки от СТАРЫХ маршрутов
    // Возвращаем их в pending чтобы диспетчер мог перераспределить
    final orphanedPoints = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    int orphanedCount = 0;
    for (final doc in orphanedPoints.docs) {
      final data = doc.data();
      final oldRouteId = data['routeId'] as String?;
      // Если routeId отличается от нового — это осиротевшая точка
      if (oldRouteId != null && oldRouteId != routeId) {
        await doc.reference.update({
          'status': DeliveryPoint.statusPending,
          'driverId': null,
          'driverName': null,
          'routeId': null,
          'orderInRoute': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        orphanedCount++;
      }
    }
    if (orphanedCount > 0) {
      print(
          '🧹 [RouteService] Returned $orphanedCount orphaned points to pending for driver $driverName');
    }

    // Получаем активные точки водителя (незавершенные)
    final existingPoints = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    // Получаем сегодняшние завершенные точки для расчета начальной позиции
    final todayCompletedPoints = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: DeliveryPoint.statusCompleted)
        .get();

    final todayCompleted = todayCompletedPoints.docs.where((doc) {
      final data = doc.data();
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      return completedAt != null && completedAt.isAfter(todayMidnight);
    }).toList();

    final startOrder = existingPoints.docs.length;
    print(
        '📊 [RouteService] Driver has $startOrder active points, ${todayCompleted.length} completed today');

    // ETA = drive_time + service_time + parking_time
    // service_time берётся из самообучения клиента (или 7 мин по умолчанию)
    double cumulativeTimeMinutes = 0;
    const double avgSpeedKmh = 38.0;
    const double defaultServiceTimeMinutes = 7.0;
    const double parkingTimeMinutes = 2.0;

    // Загружаем данные самообучения для клиентов
    final clientServiceTimes = <String, double>{};
    final clientNavPoints = <String, Map<String, double>>{};
    for (final point in points) {
      final cn = point.clientNumber ?? '';
      if (cn.isEmpty || clientServiceTimes.containsKey(cn)) continue;
      try {
        final clientSnap = await _paths
            .clients(companyId)
            .where('clientNumber', isEqualTo: cn)
            .limit(1)
            .get();
        if (clientSnap.docs.isNotEmpty) {
          final cData = clientSnap.docs.first.data();
          final ast = (cData['avgServiceTimeMinutes'] as num?)?.toDouble();
          if (ast != null && ast > 0) clientServiceTimes[cn] = ast;
          final nLat = (cData['navigationLat'] as num?)?.toDouble();
          final nLng = (cData['navigationLng'] as num?)?.toDouble();
          if (nLat != null && nLng != null && nLat != 0 && nLng != 0) {
            clientNavPoints[cn] = {'lat': nLat, 'lng': nLng};
          }
        }
      } catch (e) {
        debugPrint(
            '⚠️ [RouteService] Error loading client $cn navigation data: $e');
      }
    }

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Координаты точки (navigation_point если есть, иначе оригинальные)
      final pCn = point.clientNumber ?? '';
      final navPoint = clientNavPoints[pCn];
      final pointLat = navPoint?['lat'] ?? point.latitude;
      final pointLng = navPoint?['lng'] ?? point.longitude;

      // Рассчитываем расстояние от предыдущей точки
      double distanceKm = 0;
      if (i == 0) {
        // 🏭 Первая точка нового маршрута:
        // - Если есть завершенные точки сегодня → от последней завершенной
        // - Иначе → от склада
        if (todayCompleted.isNotEmpty) {
          // Сортируем по orderInRoute и берем последнюю
          todayCompleted.sort((a, b) {
            final aOrder = (a.data()['orderInRoute'] as num?)?.toInt() ?? 0;
            final bOrder = (b.data()['orderInRoute'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });
          final lastCompleted = todayCompleted.last.data();
          final lastLat = (lastCompleted['latitude'] as num?)?.toDouble() ??
              AppConfig.defaultWarehouseLat;
          final lastLng = (lastCompleted['longitude'] as num?)?.toDouble() ??
              AppConfig.defaultWarehouseLng;

          distanceKm = _calculateDistance(lastLat, lastLng, pointLat, pointLng);
          print(
              '📍 [RouteService] Starting from last completed point (${lastCompleted['clientName']})');
        } else {
          distanceKm = _calculateDistance(
            AppConfig.defaultWarehouseLat,
            AppConfig.defaultWarehouseLng,
            pointLat,
            pointLng,
          );
          print(
              '🏭 [RouteService] Starting from warehouse (no completed points today)');
        }
      } else {
        final prevPoint = points[i - 1];
        final prevCn = prevPoint.clientNumber ?? '';
        final prevNav = clientNavPoints[prevCn];
        distanceKm = _calculateDistance(
          prevNav?['lat'] ?? prevPoint.latitude,
          prevNav?['lng'] ?? prevPoint.longitude,
          pointLat,
          pointLng,
        );
      }

      // Время в пути (минуты) = расстояние / скорость * 60
      final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
      // service_time из самообучения или дефолт
      final cn = point.clientNumber ?? '';
      final serviceTime = clientServiceTimes[cn] ?? defaultServiceTimeMinutes;
      cumulativeTimeMinutes +=
          travelTimeMinutes + serviceTime + parkingTimeMinutes;

      // ETA = абсолютное время прибытия от 07:00
      final eta = TimeFormatter.formatArrivalTime(cumulativeTimeMinutes);

      try {
        await _updatePoint(point.id, {
          'driverId': driverId,
          'driverName': driverName,
          'driverCapacity': driverCapacity,
          'orderInRoute': startOrder + i,
          'status': 'assigned',
          'eta': eta,
          'distanceKm': double.parse(distanceKm.toStringAsFixed(1)),
          'routeId': routeId,
          'routeDate': Timestamp.fromDate(DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day)),
        });
        print(
            '✅ [RouteService] Point ${point.clientName} assigned to $driverName (order: ${startOrder + i}, ETA: $eta)');
      } catch (e) {
        print('❌ [RouteService] Error assigning point ${point.clientName}: $e');
      }
    }

    // 🗺️ Получаем полилинию маршрута из OSRM и сохраняем в Firestore
    try {
      final warehouseLat = AppConfig.defaultWarehouseLat;
      final warehouseLng = AppConfig.defaultWarehouseLng;
      final osrm = OsrmNavigationService();

      final waypoints = <Map<String, double>>[];
      for (final point in points) {
        final cn = point.clientNumber ?? '';
        final nav = clientNavPoints[cn];
        waypoints.add({
          'lat': nav?['lat'] ?? point.latitude,
          'lng': nav?['lng'] ?? point.longitude,
        });
      }

      // Маршрут: махсан → все точки → махсан (кольцевой)
      OsrmRoute? osrmRoute;
      if (waypoints.length == 1) {
        osrmRoute = await osrm.getOptimizedRoute(
          startLat: warehouseLat,
          startLng: warehouseLng,
          waypoints: waypoints,
          endLat: warehouseLat,
          endLng: warehouseLng,
        );
      } else {
        osrmRoute = await osrm.getOptimizedRoute(
          startLat: warehouseLat,
          startLng: warehouseLng,
          waypoints: waypoints,
          endLat: warehouseLat,
          endLng: warehouseLng,
        );
      }

      if (osrmRoute != null && osrmRoute.polyline.isNotEmpty) {
        // Защита от слишком длинных polyline (Firestore doc limit 1MB)
        final polylineStr = osrmRoute.polyline.length > 20000
            ? osrmRoute.polyline.substring(0, 20000)
            : osrmRoute.polyline;
        // Сохраняем polyline в routes документ (не в каждую точку)
        await _routesCollection().doc(routeId).set({
          'polyline': polylineStr,
        }, SetOptions(merge: true));
        print(
            '✅ [RouteService] Route polyline saved to routes/$routeId (${osrmRoute.polyline.length} chars)');
      }
    } catch (e) {
      print('⚠️ [RouteService] Failed to cache route polyline: $e');
    }

    print('✅ [RouteService] Route successfully created for $driverName');

    // 📦 Сохраняем документ маршрута в коллекцию routes
    try {
      final expiresAt = todayMidnight.add(const Duration(days: 30));
      await _routesCollection().doc(routeId).set({
        'routeId': routeId,
        'driverId': driverId,
        'driverName': driverName,
        'routeDate': Timestamp.fromDate(todayMidnight),
        'pointIds': points.map((p) => p.id).toList(),
        'totalPallets': newPallets + currentPallets,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('📦 [RouteService] Route document saved: $routeId');
    } catch (e) {
      print('⚠️ [RouteService] Failed to save route document: $e');
    }
  }

  /// 🔄 Переоткрыть автозакрытую точку (вернуть в маршрут)
  /// completedAt НЕ сбрасываем — оставляем как историю
  Future<void> reopenPoint(String pointId, {String? updatedByUid}) async {
    print('🔄 [RouteService] Reopening point $pointId');
    try {
      final Map<String, dynamic> patch = {
        'status': DeliveryPoint.statusInProgress,
        'autoCompleted': false,
      };
      if (updatedByUid != null) {
        patch['updatedByUid'] = updatedByUid;
      }
      await _updatePoint(pointId, patch);
      print('✅ [RouteService] Point $pointId reopened');
    } catch (e) {
      print('❌ [RouteService] Error reopening point $pointId: $e');
      rethrow;
    }
  }

  /// 🔙 Убрать точку из маршрута (вернуть в ожидающие)
  Future<void> removePointFromRoute(String pointId) async {
    try {
      await _updatePoint(pointId, {
        'status': DeliveryPoint.statusPending,
        'driverId': null,
        'driverName': null,
        'driverCapacity': null,
        'orderInRoute': null,
        'routeId': null,
        'routeDate': null,
        'eta': null,
      });
      print('🔙 [RouteService] Point $pointId removed from route → pending');
    } catch (e) {
      print('❌ [RouteService] Error removing point $pointId from route: $e');
      rethrow;
    }
  }

  /// ❌ Отменить точку доставки
  Future<void> cancelPoint(String pointId, {String? updatedByUid}) async {
    try {
      final Map<String, dynamic> patch = {
        'status': 'cancelled',
        'driverId': null,
        'driverName': null,
        'orderInRoute': null,
      };
      if (updatedByUid != null) {
        patch['updatedByUid'] = updatedByUid;
      }
      await _updatePoint(pointId, patch);

      print('❌ [RouteService] Point $pointId cancelled');
    } catch (e) {
      print('❌ [RouteService] Error cancelling point $pointId: $e');
      throw Exception('Failed to cancel point: $e');
    }
  }
}
