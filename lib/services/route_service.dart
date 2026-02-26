// lib/services/route_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/delivery_point.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import 'api_config_service.dart';
import '../utils/time_formatter.dart';

class RouteService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RouteService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию точек доставки компании
  CollectionReference<Map<String, dynamic>> _deliveryPointsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('delivery_points');
  }

  /// 🚚 Автоматически распределяет все pending точки между всеми водителями по palletCapacity
  Future<void> autoDistributePalletsToDrivers(List<UserModel> drivers) async {
    // Получаем все точки, которые ещё не назначены (pending)
    final pendingSnapshot = await _deliveryPointsCollection()
        .where('status', isEqualTo: 'pending')
        .get();

    final pendingPoints = pendingSnapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
    if (pendingPoints.isEmpty || drivers.isEmpty) return;

    // Сортируем водителей по palletCapacity (по убыванию)
    final sortedDrivers = List<UserModel>.from(drivers)
      ..sort(
          (a, b) => (b.palletCapacity ?? 0).compareTo(a.palletCapacity ?? 0));

    // Копируем список точек для распределения
    final pointsToAssign = List<DeliveryPoint>.from(pendingPoints);

    int pointIndex = 0;
    for (final driver in sortedDrivers) {
      int capacity = driver.palletCapacity ?? 0;
      int used = 0;
      List<DeliveryPoint> assigned = [];
      while (pointIndex < pointsToAssign.length &&
          used + pointsToAssign[pointIndex].pallets <= capacity) {
        assigned.add(pointsToAssign[pointIndex]);
        used += pointsToAssign[pointIndex].pallets;
        pointIndex++;
      }

      if (assigned.isEmpty)
        continue; // Пропускаем если нет точек для назначения

      // Генерируем уникальный routeId для этого маршрута
      final routeId = '${driver.uid}_${DateTime.now().millisecondsSinceEpoch}';

      // Получаем текущее количество точек у водителя
      final existingPoints = await _deliveryPointsCollection()
          .where('driverId', isEqualTo: driver.uid)
          .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
          .get();

      final startOrder = existingPoints.docs.length;

      // Рассчитываем ETA для каждой точки
      double cumulativeTimeMinutes = 0;
      const double avgSpeedKmh = 38.0; // Средняя скорость 38 км/ч
      const double stopTimeMinutes = 10.0; // Время остановки 10 минут

      // Назначаем найденные точки этому водителю
      for (int i = 0; i < assigned.length; i++) {
        final point = assigned[i];

        // Рассчитываем расстояние от предыдущей точки
        double distanceKm = 0;
        if (i == 0 && existingPoints.docs.isEmpty) {
          // Первая точка - расстояние от склада (Mishmarot)
          distanceKm = _calculateDistance(
            32.48698,
            34.982121,
            point.latitude,
            point.longitude,
          );
        } else if (i == 0 && existingPoints.docs.isNotEmpty) {
          // Первая новая точка - расстояние от последней существующей точки
          final lastExisting = existingPoints.docs.last.data();
          distanceKm = _calculateDistance(
            (lastExisting['latitude'] ?? 0).toDouble(),
            (lastExisting['longitude'] ?? 0).toDouble(),
            point.latitude,
            point.longitude,
          );
        } else {
          // Расстояние от предыдущей точки в списке
          final prevPoint = assigned[i - 1];
          distanceKm = _calculateDistance(
            prevPoint.latitude,
            prevPoint.longitude,
            point.latitude,
            point.longitude,
          );
        }

        // Время в пути (минуты) = расстояние / скорость * 60
        final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
        cumulativeTimeMinutes += travelTimeMinutes + stopTimeMinutes;

        // Форматируем ETA используя утилиту
        final eta = TimeFormatter.formatDuration(cumulativeTimeMinutes);

        await _deliveryPointsCollection().doc(point.id).update({
          'driverId': driver.uid,
          'driverName': driver.name,
          'driverCapacity': driver.palletCapacity,
          'orderInRoute': startOrder + i, // Нумерация с 0 (в UI будет +1)
          'status': 'assigned',
          'eta': eta,
          'routeId': routeId, // Добавляем routeId
        });
      }
    }
  }

  /// ✅ Поток всех активных маршрутов (для вкладки "מסלולים")
  /// ⚡ OPTIMIZED: Added limit
  Stream<List<DeliveryPoint>> getAllRoutes() {
    Query query = _deliveryPointsCollection()
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses);

    // Limit to prevent excessive reads
    query = query.limit(200);

    return query.snapshots().map((snapshot) {
      final points = snapshot.docs
          .map((doc) =>
              DeliveryPoint.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Сортируем по driverName и orderInRoute
      points.sort((a, b) {
        final driverCompare =
            (a.driverName ?? '').compareTo(b.driverName ?? '');
        if (driverCompare != 0) return driverCompare;
        return a.orderInRoute.compareTo(b.orderInRoute);
      });

      return points;
    });
  }

  /// ✅ Поток всех ожидающих точек (для вкладки "נקודות משלוח")
  /// ⚡ OPTIMIZED: Added limit
  Stream<List<DeliveryPoint>> getAllPendingPoints() {
    return _deliveryPointsCollection()
        .where('status', whereIn: DeliveryPoint.pendingStatuses)
        .limit(100) // Limit pending points
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .toList();
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

    // Комбинированный алгоритм оптимизации с учетом реальной позиции
    final optimizedPoints = _optimizeRouteOrder(points, startLocation);

    // 🚧 Проверяем высоту мостов на маршруте
    final bridgeCheckPassed = await _checkBridgeHeights(optimizedPoints);

    // ⚖️ Проверяем ограничения по весу на дорогах (используем реальный тоннаж)
    final weightCheckPassed =
        await _checkRoadWeightLimits(optimizedPoints, truckWeight);

    if (!bridgeCheckPassed || !weightCheckPassed) {
      final reason = !bridgeCheckPassed
          ? 'low bridge (< ${AppConfig.minBridgeHeight}m)'
          : 'weight restriction (< ${AppConfig.minRoadWeightLimit}t)';
      print(
          '🚧 [RouteService] Route blocked by $reason! Trying alternative route...');

      // Пробуем альтернативную оптимизацию
      final alternativePoints = _createAlternativeRoute(points, startLocation);
      final altBridgeCheck = await _checkBridgeHeights(alternativePoints);
      final altWeightCheck =
          await _checkRoadWeightLimits(alternativePoints, truckWeight);

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
          await _firestore.collection('driver_locations').doc(driverId).get();

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
      final doc = await _firestore.collection('users').doc(driverId).get();

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

  /// 🧠 Комбинированный алгоритм оптимизации маршрута с учетом реальной позиции водителя
  List<DeliveryPoint> _optimizeRouteOrder(
      List<DeliveryPoint> points, Map<String, double>? driverLocation) {
    if (points.length <= 1) return points;

    // Используем реальную позицию водителя или дефолтную (позиция склада из конфига)
    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
      print('📍 [RouteService] Using driver location: ($baseLat, $baseLng)');
    } else {
      print('📍 [RouteService] Using warehouse location: ($baseLat, $baseLng)');
    }

    // 1. Разделяем точки по приоритету
    final urgentPoints = points.where((p) => p.urgency == 'urgent').toList();
    final normalPoints = points.where((p) => p.urgency != 'urgent').toList();

    // 2. Сортируем все точки по расстоянию от склада
    urgentPoints.sort((a, b) {
      // Сначала по времени открытия
      if (a.openingTime != null && b.openingTime != null) {
        final timeCompare = a.openingTime!.compareTo(b.openingTime!);
        if (timeCompare != 0) return timeCompare;
      }
      final distA =
          _calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          _calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    normalPoints.sort((a, b) {
      final distA =
          _calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          _calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    // 3. Комбинированный алгоритм nearest neighbor:
    // - urgent точки имеют небольшой "бонус" к расстоянию, но не абсолютный приоритет
    // - первая точка всегда ближайшая к складу
    final optimizedOrder = <DeliveryPoint>[];
    final remainingPoints =
        List<DeliveryPoint>.from([...urgentPoints, ...normalPoints]);

    double currentLat = baseLat;
    double currentLng = baseLng;

    while (remainingPoints.isNotEmpty) {
      DeliveryPoint? nextPoint;
      double minScore = double.infinity;
      int nextIndex = -1;

      for (int i = 0; i < remainingPoints.length; i++) {
        final p = remainingPoints[i];
        final dist =
            _calculateDistance(currentLat, currentLng, p.latitude, p.longitude);

        // Urgent точки получают 20% бонус (уменьшаем их "расстояние" на 20%)
        // Это даёт им приоритет при примерно равных расстояниях
        final score = p.urgency == 'urgent' ? dist * 0.8 : dist;

        if (score < minScore) {
          minScore = score;
          nextPoint = p;
          nextIndex = i;
        }
      }

      if (nextPoint != null) {
        optimizedOrder.add(nextPoint);
        currentLat = nextPoint.latitude;
        currentLng = nextPoint.longitude;
        remainingPoints.removeAt(nextIndex);
      } else {
        break;
      }
    }

    // Мягкий приоритет: если есть urgent, но ближайшая обычная точка сильно ближе (например, в 2 раза), то допускаем вставку обычной точки раньше urgent
    // (уже реализовано выше, т.к. всегда выбирается ближайшая urgent, если есть, иначе ближайшая обычная)

    print('🎯 [RouteService] Route optimization complete:');
    for (int i = 0; i < optimizedOrder.length; i++) {
      final point = optimizedOrder[i];
      print(
          '  ${i + 1}. ${point.clientName} (${point.urgency == 'urgent' ? 'URGENT' : 'normal'})');
    }

    return optimizedOrder;
  }

  /// 📏 Вычисление расстояния между двумя точками (формула гаверсинуса)
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return AppConfig.earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
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
      await _deliveryPointsCollection().doc(pointId).update(updateData);
      print('✅ [RouteService] Point $pointId updated successfully');
    } catch (e) {
      print('❌ [RouteService] Error updating point $pointId: $e');
      rethrow;
    }
  }

  /// 🌍 Геокодирование адреса (внутренний метод)
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          '${ApiConfigService.googleGeocodingApiUrl}?address=$encodedAddress&key=${ApiConfigService.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url)).timeout(
        AppConfig.geocodingTimeout,
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];

          return {
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };
        }
      }

      print('❌ [RouteService] Geocoding failed for: $address');
      return null;
    } catch (e) {
      print('❌ [RouteService] Geocoding error for $address: $e');
      return null;
    }
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
      // Если driverId пустой, удаляем ВСЕ точки (для тестирования)
      print('🗑️ [RouteService] Deleting ALL points (driverId is empty)');
      query = _deliveryPointsCollection();
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
      });
    }

    print('✅ [RouteService] Driver changed to $newDriverName');
  }

  /// Получить активные точки конкретного водителя
  Stream<List<DeliveryPoint>> getDriverPoints(String driverId) {
    return _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
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
        .get();

    return snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Добавить новую точку доставки
  Future<void> addDeliveryPoint(DeliveryPoint point) async {
    await _deliveryPointsCollection().add(point.toMap());
    print('✅ Delivery point added: ${point.clientName}');
  }

  /// Обновить статус точки
  Future<void> updatePointStatus(String pointId, String newStatus) async {
    await _deliveryPointsCollection().doc(pointId).update({
      'status': newStatus,
    });
    print('✅ Point $pointId status updated to $newStatus');
  }

  /// Обновить текущую точку водителя
  Future<void> updateCurrentPoint(String pointId) async {
    await _deliveryPointsCollection().doc(pointId).update({
      'status': DeliveryPoint.statusInProgress,
    });
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
      batch.update(doc.reference, {'status': DeliveryPoint.statusInProgress});
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
    // ✅ ИСПРАВЛЕНО: Ищем существующий активный маршрут водителя
    String? routeId;

    try {
      final existingRoutes = await _deliveryPointsCollection()
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            DeliveryPoint.statusAssigned,
            DeliveryPoint.statusInProgress
          ])
          .limit(1)
          .get();

      if (existingRoutes.docs.isNotEmpty) {
        // Используем routeId существующего маршрута
        routeId = existingRoutes.docs.first.data()['routeId'] as String?;
        print('✅ Found existing route for driver $driverName: $routeId');
      }
    } catch (e) {
      print('⚠️ Error finding existing route: $e');
    }

    // Если не нашли существующий маршрут - создаем новый
    if (routeId == null) {
      routeId = '${driverId}_${DateTime.now().millisecondsSinceEpoch}';
      print('🆕 Creating new route for driver $driverName: $routeId');
    }

    // Получаем максимальный orderInRoute для этого маршрута
    int nextOrder = 0;
    try {
      final routePoints = await _deliveryPointsCollection()
          .where('routeId', isEqualTo: routeId)
          .get();

      if (routePoints.docs.isNotEmpty) {
        final orders = routePoints.docs
            .map((doc) => doc.data()['orderInRoute'] as int? ?? 0)
            .toList();
        nextOrder = orders.reduce((a, b) => a > b ? a : b) + 1;
        print('📍 Adding point as #$nextOrder in route $routeId');
      }
    } catch (e) {
      print('⚠️ Error calculating order: $e');
    }

    await _deliveryPointsCollection().doc(pointId).update({
      'driverId': driverId,
      'driverName': driverName,
      'driverCapacity': capacity,
      'status': DeliveryPoint.statusAssigned,
      'orderInRoute': nextOrder,
      'routeId': routeId,
    });
    print(
        '👤 Point $pointId assigned to $driverName with routeId: $routeId (order: $nextOrder)');
  }

  /// 🚧 Проверяет высоту мостов на маршруте через Google Roads API
  Future<bool> _checkBridgeHeights(List<DeliveryPoint> route) async {
    try {
      // Формируем путь из координат маршрута
      final List<String> coordinates = [];
      for (final point in route) {
        coordinates.add('${point.latitude},${point.longitude}');
      }
      final String path = coordinates.join('|');

      final String url =
          '${ApiConfigService.googleRoadsApiUrl}?path=$path&interpolate=true&key=${ApiConfigService.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем каждый участок дороги
        if (data['snappedPoints'] != null) {
          for (final point in data['snappedPoints']) {
            // Здесь можно добавить проверку высоты мостов
            // Google Roads API предоставляет информацию о дорожных ограничениях
            final placeId = point['placeId'];

            if (placeId != null) {
              // Дополнительная проверка через Places API для получения информации о мостах
              final hasLowBridge = await _checkPlaceForLowBridge(
                  placeId, ApiConfigService.googleMapsApiKey);
              if (hasLowBridge) {
                print(
                    '🚧 [RouteService] Low bridge detected on route! Height < ${AppConfig.minBridgeHeight}m');
                return false; // Маршрут не подходит
              }
            }
          }
        }
      }

      return true; // Маршрут подходит
    } catch (e) {
      print('❌ [RouteService] Error checking bridge heights: $e');
      return true; // В случае ошибки разрешаем маршрут
    }
  }

  /// 🚧 Проверяет конкретное место на наличие низких мостов
  Future<bool> _checkPlaceForLowBridge(String placeId, String apiKey) async {
    try {
      final String url =
          '${ApiConfigService.googlePlacesApiUrl}?place_id=$placeId&fields=geometry,types&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          final result = data['result'];
          final types = result['types'] as List<dynamic>?;

          // Проверяем, является ли место мостом
          if (types != null && types.contains('bridge')) {
            // Дополнительная логика для проверки высоты моста
            // Здесь можно использовать дополнительные API или базу данных
            print('🌉 [RouteService] Bridge detected at place: $placeId');

            // Для демонстрации: считаем что 30% мостов могут быть низкими
            return math.Random().nextDouble() < 0.3;
          }
        }
      }

      return false; // Нет моста или мост подходит
    } catch (e) {
      print('❌ [RouteService] Error checking place for bridge: $e');
      return false;
    }
  }

  /// ⚖️ Проверяет ограничения по весу на дорогах маршрута
  Future<bool> _checkRoadWeightLimits(
      List<DeliveryPoint> route, double truckWeight) async {
    try {
      print(
          '⚖️ [RouteService] Checking weight restrictions for truck: ${truckWeight.toStringAsFixed(1)}t');

      // Если грузовик легче минимального ограничения, проверка не нужна
      if (truckWeight < AppConfig.minRoadWeightLimit) {
        print(
            '✅ [RouteService] Truck weight (${truckWeight.toStringAsFixed(1)}t) is below restriction threshold');
        return true;
      }

      // Формируем путь из координат маршрута
      final List<String> coordinates = [];
      for (final point in route) {
        coordinates.add('${point.latitude},${point.longitude}');
      }
      final String path = coordinates.join('|');

      final String url =
          '${ApiConfigService.googleRoadsApiUrl}?path=$path&interpolate=true&key=${ApiConfigService.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем каждый участок дороги
        if (data['snappedPoints'] != null) {
          for (final point in data['snappedPoints']) {
            final placeId = point['placeId'];

            if (placeId != null) {
              // Проверяем ограничения по весу через Places API
              final hasWeightRestriction =
                  await _checkPlaceForWeightRestriction(
                placeId,
                ApiConfigService.googleMapsApiKey,
                truckWeight,
              );

              if (hasWeightRestriction) {
                print(
                    '⚖️ [RouteService] Weight restriction detected on route! Limit < ${AppConfig.minRoadWeightLimit}t, truck: ${truckWeight.toStringAsFixed(1)}t');
                return false; // Маршрут не подходит
              }
            }
          }
        }
      }

      return true; // Маршрут подходит
    } catch (e) {
      print('❌ [RouteService] Error checking road weight limits: $e');
      return true; // В случае ошибки разрешаем маршрут
    }
  }

  /// ⚖️ Проверяет конкретное место на наличие ограничений по весу
  Future<bool> _checkPlaceForWeightRestriction(
      String placeId, String apiKey, double truckWeight) async {
    try {
      final String url =
          '${ApiConfigService.googlePlacesApiUrl}?place_id=$placeId&fields=geometry,types,name&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          final result = data['result'];
          final types = result['types'] as List<dynamic>?;
          final name = result['name'] as String?;

          // Проверяем признаки улиц с ограничениями по весу
          if (types != null || name != null) {
            // Ключевые слова в названиях улиц, которые могут указывать на ограничения
            final restrictedKeywords = [
              'residential', // Жилая зона
              'local', // Локальная дорога
              'narrow', // Узкая улица
              'רחוב', // Улица (иврит)
              'סימטה', // Переулок (иврит)
            ];

            // Проверяем типы места
            final hasRestrictedType = types?.any((type) =>
                    type == 'route' &&
                    name != null &&
                    restrictedKeywords.any((keyword) =>
                        name.toLowerCase().contains(keyword.toLowerCase()))) ??
                false;

            if (hasRestrictedType) {
              print(
                  '⚖️ [RouteService] Potential weight restriction detected at: $name');

              // Для демонстрации: считаем что 20% улиц могут иметь ограничения
              // В реальности нужно использовать специализированную базу данных
              final hasRestriction = math.Random().nextDouble() < 0.2;

              if (hasRestriction) {
                print(
                    '🚫 [RouteService] Weight restriction confirmed: < ${AppConfig.minRoadWeightLimit}t');
                return true;
              }
            }
          }
        }
      }

      return false; // Нет ограничений или дорога подходит
    } catch (e) {
      print('❌ [RouteService] Error checking place for weight restriction: $e');
      return false;
    }
  }

  /// 🔄 Создает альтернативный маршрут с учетом реальной позиции водителя
  List<DeliveryPoint> _createAlternativeRoute(
      List<DeliveryPoint> points, Map<String, double>? driverLocation) {
    if (points.length <= 1) return points;

    // Используем реальную позицию водителя или дефолтную (из конфига)
    double baseLat = AppConfig.defaultWarehouseLat;
    double baseLng = AppConfig.defaultWarehouseLng;

    if (driverLocation != null) {
      baseLat = driverLocation['latitude']!;
      baseLng = driverLocation['longitude']!;
    }

    // Простая сортировка по расстоянию от базы (без учета приоритетов)
    final sortedPoints = List<DeliveryPoint>.from(points);
    sortedPoints.sort((a, b) {
      final distA =
          _calculateDistance(baseLat, baseLng, a.latitude, a.longitude);
      final distB =
          _calculateDistance(baseLat, baseLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    print(
        '🔄 [RouteService] Alternative route created from driver location ($baseLat, $baseLng)');
    return sortedPoints;
  }

  /// 🚚 Назначает точки водителю (вынесенный метод)
  Future<void> _assignPointsToDriver(String driverId, String driverName,
      int driverCapacity, List<DeliveryPoint> points) async {
    // Генерируем routeId для этого маршрута
    final routeId = '${driverId}_${DateTime.now().millisecondsSinceEpoch}';

    // Сначала получаем все существующие точки водителя
    final existingPoints = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    final startOrder = existingPoints.docs.length;
    print(
        '📊 [RouteService] Driver already has $startOrder points, starting from ${startOrder + 1}');

    // Рассчитываем ETA для каждой точки
    double cumulativeTimeMinutes = 0;
    const double avgSpeedKmh = 38.0; // Средняя скорость 38 км/ч
    const double stopTimeMinutes = 10.0; // Время остановки 10 минут

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Рассчитываем расстояние от предыдущей точки
      double distanceKm = 0;
      if (i == 0 && existingPoints.docs.isEmpty) {
        // Первая точка - расстояние от склада (Mishmarot)
        distanceKm = _calculateDistance(
          32.48698,
          34.982121,
          point.latitude,
          point.longitude,
        );
      } else if (i == 0 && existingPoints.docs.isNotEmpty) {
        // Первая новая точка - расстояние от последней существующей точки
        final lastExisting = existingPoints.docs.last.data();
        distanceKm = _calculateDistance(
          (lastExisting['latitude'] ?? 0).toDouble(),
          (lastExisting['longitude'] ?? 0).toDouble(),
          point.latitude,
          point.longitude,
        );
      } else {
        // Расстояние от предыдущей точки в списке
        final prevPoint = points[i - 1];
        distanceKm = _calculateDistance(
          prevPoint.latitude,
          prevPoint.longitude,
          point.latitude,
          point.longitude,
        );
      }

      // Время в пути (минуты) = расстояние / скорость * 60
      final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
      cumulativeTimeMinutes += travelTimeMinutes + stopTimeMinutes;

      // Форматируем ETA используя утилиту
      final eta = TimeFormatter.formatDuration(cumulativeTimeMinutes);

      try {
        await _deliveryPointsCollection().doc(point.id).update({
          'driverId': driverId,
          'driverName': driverName,
          'driverCapacity': driverCapacity,
          'orderInRoute': startOrder + i, // Нумерация с 0 (в UI будет +1)
          'status': 'assigned',
          'eta': eta,
          'routeId': routeId, // Добавляем routeId
        });
        print(
            '✅ [RouteService] Point ${point.clientName} assigned to $driverName (order: ${startOrder + i}, ETA: $eta)');
      } catch (e) {
        print('❌ [RouteService] Error assigning point ${point.clientName}: $e');
      }
    }

    print('✅ [RouteService] Route successfully created for $driverName');
  }

  /// ❌ Отменить точку доставки
  Future<void> cancelPoint(String pointId) async {
    try {
      await _deliveryPointsCollection().doc(pointId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'driverId': null,
        'driverName': null,
        'orderInRoute': null,
      });

      print('❌ [RouteService] Point $pointId cancelled');
    } catch (e) {
      print('❌ [RouteService] Error cancelling point $pointId: $e');
      throw Exception('Failed to cancel point: $e');
    }
  }
}
