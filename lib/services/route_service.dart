// lib/services/route_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_point.dart';
import '../models/user_model.dart';
import '../models/route_status.dart';
import '../config/app_config.dart';
import 'api_config_service.dart';
import 'client_learning_service.dart';
import '../utils/time_formatter.dart';
import 'route_optimizer.dart';
import 'route_balance_service.dart';
import 'osrm_navigation_service.dart';
import 'route_builder_service.dart';
import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_paths.dart';
import 'inventory_service.dart';
import 'company_settings_service.dart';

class RouteService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestorePaths _paths = FirestorePaths();
  static bool _isDistributing = false;

  /// Один раз за сессию на компанию: архив completed + частичные маршруты → pending.
  static final Set<String> _scheduledPointHygiene = {};

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

  /// Параметры ETA из настроек компании (единый расчёт с RouteOptimizer).
  Future<({double avgSpeedKmh, double serviceMinutes})>
      _companyRoutingParams() async {
    final cs = await CompanySettingsService(companyId: companyId).getSettings();
    return (
      avgSpeedKmh: cs?.avgSpeedKmh ?? RouteOptimizer.avgSpeedKmh,
      serviceMinutes:
          (cs?.serviceMinutes ?? RouteOptimizer.serviceMinutes).toDouble(),
    );
  }

  Future<void> _updatePoint(String pointId, Map<String, dynamic> data) async {
    data['companyId'] = companyId;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _deliveryPointsCollection().doc(pointId).update(data);
  }

  String _buildUniqueRouteId(String driverId, DateTime now) =>
      '${driverId}_${now.year}_${now.month}_${now.day}_${now.millisecondsSinceEpoch}';

  Future<String> _resolveRouteIdForDriver(String driverId, DateTime now,
      {bool forceNew = false}) async {
    if (forceNew) return _buildUniqueRouteId(driverId, now);

    final activeSnapshot = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();

    String? latestRouteId;
    DateTime? latestAt;
    for (final doc in activeSnapshot.docs) {
      final data = doc.data();
      final routeId = data['routeId'] as String?;
      if (routeId != null && routeId.isNotEmpty) {
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
            (data['routeDate'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (latestAt == null || updatedAt.isAfter(latestAt)) {
          latestAt = updatedAt;
          latestRouteId = routeId;
        }
      }
    }

    if (latestRouteId != null) {
      return latestRouteId;
    }

    return _buildUniqueRouteId(driverId, now);
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
        (acc, doc) => acc + ((doc.data()['pallets'] as num?)?.toInt() ?? 0),
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
    final routing = await _companyRoutingParams();
    final double avgSpeedKmh = routing.avgSpeedKmh;
    final double serviceTimeMinutes = routing.serviceMinutes;
    const double parkingTimeMinutes = 0.0;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (final driver in activeDrivers) {
      final assigned = assignments[driver.uid]!;
      if (assigned.isEmpty) continue;

      final routeId = await _resolveRouteIdForDriver(driver.uid, now);

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

    if (!_scheduledPointHygiene.contains(companyId)) {
      _scheduledPointHygiene.add(companyId);
      unawaited(_syncPointHygiene());
    }

    Query query = _deliveryPointsCollection();

    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }

    final statuses = <String>[
      ...DeliveryPoint.activeRouteStatuses,
      if (includeCompleted) ...[
        DeliveryPoint.statusCompleted,
        DeliveryPoint.statusCompletedHe,
        DeliveryPoint.statusCompletedRu,
        DeliveryPoint.statusCompletedRuAlt,
      ],
    ];
    query = query.where('status', whereIn: statuses).limit(300);

    return query.snapshots(includeMetadataChanges: false).map((snapshot) {
      final allPoints = snapshot.docs
          .map((doc) =>
              DeliveryPoint.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => !p.archived)
          .toList();

      // Per-driver: если у водителя есть active точки — completed показываем только из его active маршрута
      final activeRouteIdsByDriver = <String, Set<String>>{};
      for (final p in allPoints) {
        final did = p.driverId ?? '';
        if (did.isEmpty) continue;
        if (DeliveryPoint.activeRouteStatuses
            .contains(DeliveryPoint.normalizeStatus(p.status))) {
          if (p.routeId != null) {
            activeRouteIdsByDriver.putIfAbsent(did, () => {}).add(p.routeId!);
          }
        }
      }

      final points = allPoints.where((p) {
        final normalizedStatus = DeliveryPoint.normalizeStatus(p.status);

        // Active точки — всегда показываем
        if (DeliveryPoint.activeRouteStatuses.contains(normalizedStatus)) {
          return true;
        }

        // Completed/cancelled
        if (normalizedStatus == DeliveryPoint.statusCompleted ||
            normalizedStatus == DeliveryPoint.statusCancelled) {
          if (!includeCompleted) return false;
          // Экран водителя: все завершённые за сегодня (несколько маршрутов)
          if (driverId != null) {
            if (p.completedAt != null &&
                p.completedAt!.isAfter(todayMidnight)) {
              return true;
            }
            return false;
          }
          final did = p.driverId ?? '';
          final driverActiveRoutes = activeRouteIdsByDriver[did];
          // Водитель имеет active маршрут → completed только из него
          if (driverActiveRoutes != null && driverActiveRoutes.isNotEmpty) {
            return p.routeId != null && driverActiveRoutes.contains(p.routeId);
          }
          // Нет active маршрута → completed за сегодня
          if (p.completedAt != null && p.completedAt!.isAfter(todayMidnight)) {
            return true;
          }
          return false;
        }

        return true;
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

  /// Архив completed (до сегодняшней полночи), затем частичные маршруты → pending.
  Future<void> _syncPointHygiene() async {
    await archiveStaleCompletedPoints();
    // releasePartialRouteIncompleteToPending отключён —
    // маршруты с active точками не разбираются автоматически.
  }

  /// Завершённые точки с completedAt до начала сегодняшнего дня → в архив (поле archived).
  Future<void> archiveStaleCompletedPoints() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final cutoff = Timestamp.fromDate(todayMidnight);
    DocumentSnapshot<Map<String, dynamic>>? cursorDoc;
    try {
      while (true) {
        Query<Map<String, dynamic>> q = _deliveryPointsCollection()
            .where('status', isEqualTo: DeliveryPoint.statusCompleted)
            .where('completedAt', isLessThan: cutoff)
            .orderBy('completedAt')
            .limit(500);
        if (cursorDoc != null) {
          q = q.startAfterDocument(cursorDoc);
        }
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        cursorDoc = snap.docs.last;
        final batch = _firestore.batch();
        var n = 0;
        for (final doc in snap.docs) {
          if (doc.data()['archived'] == true) continue;
          // 🛡️ DOUBLE SAFETY: не архивируем точки сегодняшнего маршрута
          final rid = doc.data()['routeId'] as String?;
          if (rid != null && _isRouteFromToday(rid, todayMidnight)) {
            debugPrint(
                '🛡️ [RouteService] BLOCKED archive of today\'s point: ${doc.id}');
            continue;
          }
          batch.update(doc.reference, {
            'archived': true,
            'archivedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          n++;
        }
        if (n > 0) {
          await batch.commit();
          debugPrint('🗄️ [RouteService] Archived $n stale completed points');
        }
        if (snap.docs.length < 500) break;
      }
    } catch (e) {
      debugPrint('⚠️ [RouteService] archiveStaleCompletedPoints: $e');
    }
  }

  /// Если по [routeId] уже есть хотя бы одна completed и есть active — active → pending.
  /// Если ни одной доставки не завершено — маршрут не трогаем (тот же routeId).
  Future<void> releasePartialRouteIncompleteToPending() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final processed = <String>{};
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    try {
      while (true) {
        Query<Map<String, dynamic>> q = _deliveryPointsCollection()
            .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
            .orderBy(FieldPath.documentId)
            .limit(100);
        if (cursor != null) {
          q = q.startAfterDocument(cursor);
        }
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        cursor = snap.docs.last;
        for (final doc in snap.docs) {
          final routeId = doc.data()['routeId'] as String?;
          if (routeId == null || routeId.isEmpty) continue;
          if (_isRouteFromToday(routeId, todayMidnight)) continue;
          if (processed.contains(routeId)) continue;
          processed.add(routeId);
          await _releasePartialRouteIfNeeded(routeId);
        }
        if (snap.docs.length < 100) break;
      }
    } catch (e) {
      debugPrint(
          '⚠️ [RouteService] releasePartialRouteIncompleteToPending: $e');
    }
  }

  Future<void> _releasePartialRouteIfNeeded(String routeId) async {
    // 🛡️ Не трогаем маршруты с активными точками — они в работе.
    // Эта функция только для полностью "мёртвых" маршрутов:
    // все точки completed/cancelled, routeId старый, но не архивированы.
    // Такие маршруты обрабатывает archiveStaleCompletedPoints.
    // Частично выполненные маршруты (completed + active) — НЕ ТРОГАЕМ.
    debugPrint(
        '🛡️ [RouteService] _releasePartialRouteIfNeeded DISABLED for $routeId — active points stay in route');
    return;
  }

  /// Проверяет, относится ли routeId к сегодняшнему дню
  /// Формат routeId: driverId_year_month_day(_uniqueSuffix)?
  bool _isRouteFromToday(String routeId, DateTime today) {
    final match =
        RegExp(r'_(\d{4})_(\d{1,2})_(\d{1,2})(?:_\d+)?$').firstMatch(routeId);
    if (match == null) return false;
    try {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return year == today.year && month == today.month && day == today.day;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Stream маршрутов для карты — обновляется в реальном времени.
  /// Возвращает ВСЕ routes с polyline — карта сама фильтрует по routeId точек.
  Stream<List<Map<String, dynamic>>> watchTodayRoutesForMap() {
    return _routesCollection()
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            // Только routes с polyline (остальные бесполезны для карты)
            final polyline = data['polyline'] as String?;
            return polyline != null && polyline.isNotEmpty;
          })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// ✅ Получить маршруты для карты (из коллекции routes — 1 чтение)
  /// [additionalRouteIds] — документы не за «сегодня», но нужны для polyline
  /// (незавершённый маршрут с вчерашней датой в routeId).
  Future<List<Map<String, dynamic>>> getTodayRoutesForMap({
    Set<String>? additionalRouteIds,
  }) async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Пробуем из кэша, fallback на сервер
    final snapshot = await _routesCollection()
        .get(const GetOptions(source: Source.cache))
        .catchError((_) => _routesCollection().get());

    // Фильтруем на клиенте: routeDate == сегодня ИЛИ routeId содержит сегодняшнюю дату
    final todayList = snapshot.docs
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

    final haveIds = todayList
        .map((m) => m['id'] as String? ?? m['routeId']?.toString())
        .whereType<String>()
        .toSet();

    final extra = <Map<String, dynamic>>[];
    for (final id in additionalRouteIds ?? {}) {
      if (id.isEmpty || haveIds.contains(id)) continue;
      final doc = await _routesCollection().doc(id).get();
      if (doc.exists && doc.data() != null) {
        extra.add({'id': doc.id, ...doc.data()!});
        haveIds.add(doc.id);
      }
    }

    return [...todayList, ...extra];
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
        if (p.archived) return false;
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
        .limit(300)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      final points = snapshot.docs
          .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
          .where((p) {
        final normalized = DeliveryPoint.normalizeStatus(p.status);
        final isPending = normalized == DeliveryPoint.statusPending ||
            DeliveryPoint.pendingStatuses.contains(normalized);
        final isUnassigned = (p.driverId == null || p.driverId!.isEmpty) &&
            (p.routeId == null || p.routeId!.isEmpty);
        return isPending && isUnassigned;
      }).toList();

      // Важно: у части старых документов может отсутствовать createdAt.
      // Сортируем на клиенте, чтобы они не выпадали из списка pending.
      points.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      if (points.length > 50) {
        return points.sublist(0, 50);
      }
      return points;
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

    // 🛡️ GUARD: фильтруем точки с невалидными координатами
    final invalidPoints = points.where((p) => !p.hasValidCoordinates).toList();
    if (invalidPoints.isNotEmpty) {
      for (final p in invalidPoints) {
        print(
            '⚠️ [RouteService] SKIPPING point "${p.clientName}" — invalid coords '
            '(${p.latitude}, ${p.longitude})');
      }
      points = points.where((p) => p.hasValidCoordinates).toList();
      if (points.isEmpty) {
        print('❌ [RouteService] No valid points left after filtering!');
        return;
      }
    }

    // Guard: если все точки уже назначены этому водителю — не создаём заново
    final alreadyAssigned = points.every((p) =>
        p.driverId == driverId &&
        p.status == DeliveryPoint.statusAssigned &&
        p.routeId != null &&
        p.routeId!.isNotEmpty);
    if (alreadyAssigned) {
      print(
          '⚠️ [RouteService] Route already exists for $driverName — skipping');
      return;
    }

    print(
        '🧭 [RouteService] Creating optimized route for $driverName (${points.length} points)');

    // Получаем информацию о водителе для проверки тоннажа
    final truckWeight = await _getDriverTruckWeight(driverId);
    print(
        '⚖️ [RouteService] Driver truck weight: ${truckWeight.toStringAsFixed(1)}t');

    // Определяем стартовую точку через RouteBuilderService
    final routeBuilder = RouteBuilderService(companyId);

    // Бизнес-правило: построение маршрута всегда от склада.
    // useDispatcherLocation оставляем только для совместимости сигнатуры.
    Map<String, double>? startLocation =
        await routeBuilder.getRouteStartPoint(driverId, RouteStatus.planned);
    print(
        '🏭 [RouteService] Route build start (forced warehouse): ${startLocation != null ? "(${startLocation['latitude']}, ${startLocation['longitude']})" : "null"}');

    // Оптимизация порядка через OSRM Trip (реальное время на дорогах)
    List<DeliveryPoint> optimizedPoints;
    String? tripPolyline;
    double? tripDurationMinutes;
    double? tripDistanceKm;

    if (points.length >= 2) {
      final osrm = OsrmNavigationService();
      final waypoints =
          points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
      final whLat = startLocation?['latitude'] ?? AppConfig.defaultWarehouseLat;
      final whLng =
          startLocation?['longitude'] ?? AppConfig.defaultWarehouseLng;

      final tripResult = await osrm.getOptimizedTripOrder(
        warehouseLat: whLat,
        warehouseLng: whLng,
        waypoints: waypoints,
      );

      if (tripResult != null &&
          tripResult.waypointOrder.length == points.length) {
        optimizedPoints = [
          for (final idx in tripResult.waypointOrder)
            if (idx >= 0 && idx < points.length) points[idx],
        ];
        tripPolyline = tripResult.polyline;
        tripDurationMinutes = tripResult.durationMinutes;
        tripDistanceKm = tripResult.distanceKm;
        print('🧭 [RouteService] OSRM Trip order: ${tripResult.waypointOrder}, '
            '${tripResult.distanceKm.toStringAsFixed(1)}km, '
            '${tripResult.durationMinutes.toStringAsFixed(0)}min');
      } else {
        // Fallback: nearest-neighbor если OSRM недоступен
        optimizedPoints =
            RouteOptimizer.optimizeRouteOrder(points, startLocation);
        print('⚠️ [RouteService] OSRM Trip failed, using nearest-neighbor');
      }
    } else {
      optimizedPoints = List.from(points);
    }

    print('✅ [RouteService] Route approved - no restrictions');

    // Назначаем точки водителю
    await _assignPointsToDriver(
        driverId, driverName, driverCapacity, optimizedPoints,
        startLocation: startLocation,
        tripPolyline: tripPolyline,
        tripDurationMinutes: tripDurationMinutes,
        tripDistanceKm: tripDistanceKm,
        separateRoute: true);
  }

  /// � Начать маршрут — установить статус active
  Future<void> startRoute(String routeId,
      {Map<String, dynamic>? metadata}) async {
    try {
      final now = Timestamp.now();

      await _routesCollection().doc(routeId).update({
        'status': RouteStatus.active.name,
        'startedAt': now,
        'updatedAt': now,
        if (metadata != null) ...metadata,
      });

      print('✅ [RouteService] Route $routeId started (status: active)');
    } catch (e) {
      print('❌ [RouteService] Error starting route: $e');
      rethrow;
    }
  }

  /// 🏁 Завершить маршрут — установить статус completed
  Future<void> finishRoute(String routeId,
      {Map<String, dynamic>? metadata}) async {
    try {
      final now = Timestamp.now();

      await _routesCollection().doc(routeId).update({
        'status': RouteStatus.completed.name,
        'completedAt': now,
        'updatedAt': now,
        if (metadata != null) ...metadata,
      });

      print('✅ [RouteService] Route $routeId finished (status: completed)');
    } catch (e) {
      print('❌ [RouteService] Error finishing route: $e');
      rethrow;
    }
  }

  /// ❌ Отменить маршрут — установить статус cancelled
  Future<void> cancelRoute(String routeId,
      {String? reason, Map<String, dynamic>? metadata}) async {
    try {
      final now = Timestamp.now();

      await _routesCollection().doc(routeId).update({
        'status': RouteStatus.cancelled.name,
        'cancelledAt': now,
        'updatedAt': now,
        if (reason != null) 'cancelReason': reason,
        if (metadata != null) ...metadata,
      });

      print('✅ [RouteService] Route $routeId cancelled (reason: $reason)');
    } catch (e) {
      print('❌ [RouteService] Error cancelling route: $e');
      rethrow;
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

  /// Парсит ETA строку "07:50 (50 m)" или "10:51 (3 h 51 m)" → минуты от 07:00
  double _parseEtaToMinutes(String eta) {
    // Пробуем парсить из скобок: "(50 m)" или "(3 h 51 m)"
    final bracketMatch = RegExp(r'\((\d+)\s*h\s*(\d+)\s*m\)').firstMatch(eta);
    if (bracketMatch != null) {
      final h = int.tryParse(bracketMatch.group(1) ?? '') ?? 0;
      final m = int.tryParse(bracketMatch.group(2) ?? '') ?? 0;
      return h * 60.0 + m;
    }
    final minOnly = RegExp(r'\((\d+)\s*m\)').firstMatch(eta);
    if (minOnly != null) {
      return (int.tryParse(minOnly.group(1) ?? '') ?? 0).toDouble();
    }
    // Fallback: парсим время "10:51" → минуты от 07:00
    final timeParts = eta.split(' ').first.split(':');
    if (timeParts.length == 2) {
      final h = int.tryParse(timeParts[0]) ?? 0;
      final m = int.tryParse(timeParts[1]) ?? 0;
      return (h - 7) * 60.0 + m;
    }
    return 0;
  }

  /// ✏️ Обновить точку доставки
  Future<void> updatePoint(
    String pointId,
    String urgency,
    int? orderInRoute,
    String? temporaryAddress, {
    bool updateWindow = false,
    DateTime? openingTime,
    DateTime? closingTime,
  }) async {
    print(
        '✏️ [RouteService] Updating point $pointId: urgency=$urgency, order=$orderInRoute, tempAddress=$temporaryAddress');

    final updateData = <String, dynamic>{
      'urgency': urgency,
    };

    if (orderInRoute != null) {
      updateData['orderInRoute'] = orderInRoute;
    }

    // Окно доставки: пишем при явном флаге; null → очистка поля в Firestore.
    if (updateWindow) {
      updateData['openingTime'] = openingTime != null
          ? Timestamp.fromDate(openingTime)
          : FieldValue.delete();
      updateData['closingTime'] = closingTime != null
          ? Timestamp.fromDate(closingTime)
          : FieldValue.delete();
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
      // Безопасное преобразование box types
      final boxMaps = <Map<String, dynamic>>[];
      int totalBoxes = 0;

      for (final boxType in boxTypes) {
        if (boxType is Map<String, dynamic>) {
          boxMaps.add(boxType);
          final quantity = boxType['quantity'] as num? ?? 0;
          totalBoxes += quantity.toInt();
        }
      }

      // Пересчитываем миштахи по данным инвентаря
      int totalPallets = 0;
      try {
        final inventoryService = InventoryService(companyId: companyId);
        final inventory = await inventoryService.getInventory();

        int fullPallets = 0;
        int remainderBoxes = 0;

        for (final box in boxMaps) {
          final boxType = box['type'] as String? ?? '';
          final boxNumber = box['number'] as String? ?? '';
          final boxQuantity = (box['quantity'] as num?)?.toInt() ?? 0;

          final match = inventory.where(
            (item) => item.type == boxType && item.number == boxNumber,
          );
          final perPallet =
              match.isNotEmpty ? match.first.quantityPerPallet : 20;

          if (perPallet > 0) {
            fullPallets += boxQuantity ~/ perPallet;
            remainderBoxes += boxQuantity % perPallet;
          } else {
            remainderBoxes += boxQuantity;
          }

          debugPrint(
            '🔍 [Calc] $boxType $boxNumber: qty=$boxQuantity, perPallet=$perPallet, full=${boxQuantity ~/ (perPallet > 0 ? perPallet : 1)}, rem=${perPallet > 0 ? boxQuantity % perPallet : boxQuantity}',
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

  /// Оптимизация порядка точек в маршруте по времени через OSRM Trip API.
  /// Возвращает true если порядок был изменён.
  static DateTime _lastOptimizeAt = DateTime(2000);
  static bool _lastOptimizeRejected = false;

  Future<bool> optimizeRouteByTime(
      String driverId, String? routeId, List<DeliveryPoint> points) async {
    if (points.length < 2) return false;

    // Кулдаун 10 секунд — защита от быстрых повторных нажатий
    if (DateTime.now().difference(_lastOptimizeAt) <
        const Duration(seconds: 10)) {
      debugPrint('⏳ [RouteService] Optimization cooldown — skipping');
      return false;
    }
    _lastOptimizeAt = DateTime.now();

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

    final reordered = <DeliveryPoint>[];
    for (final idx in result.waypointOrder) {
      if (idx >= 0 && idx < activePoints.length) {
        reordered.add(activePoints[idx]);
      }
    }

    // Сравниваем: текущий ETA vs OSRM Trip duration
    // Вычитаем service time из ETA для честного сравнения (движение vs движение)
    final lastEta = activePoints.last.eta ?? '';
    final oldEtaMin = _parseEtaToMinutes(lastEta);

    // Пробуем взять сохранённый tripDurationMinutes из routes документа (точнее чем ETA)
    double? savedTripDuration;
    if (routeId != null) {
      try {
        final routeDoc = await _routesCollection().doc(routeId).get();
        savedTripDuration =
            (routeDoc.data()?['tripDurationMinutes'] as num?)?.toDouble();
      } catch (_) {}
    }

    if (savedTripDuration != null && savedTripDuration > 0) {
      // Честное сравнение: оба с возвратом на склад, оба OSRM
      final totalServiceMin = activePoints.length * 9.0;
      final oldTotalMin = savedTripDuration + totalServiceMin;
      final newTotalMin = result.durationMinutes + totalServiceMin;

      final improvementMinutes = oldTotalMin - newTotalMin;
      final improvementPercent =
          oldTotalMin > 0 ? (improvementMinutes / oldTotalMin) * 100 : 0.0;

      debugPrint('📊 [RouteService] Optimization comparison (OSRM vs OSRM):\n'
          '   Current: ${oldTotalMin.toStringAsFixed(0)}min (saved trip ${savedTripDuration.toStringAsFixed(0)} + service ${totalServiceMin.toStringAsFixed(0)})\n'
          '   New:     ${newTotalMin.toStringAsFixed(0)}min (OSRM ${result.durationMinutes.toStringAsFixed(0)} + service ${totalServiceMin.toStringAsFixed(0)})\n'
          '   Includes return to warehouse: BOTH ✅\n'
          '   Improvement: ${improvementPercent.toStringAsFixed(1)}%, ${improvementMinutes.toStringAsFixed(1)}min');

      final pctThreshold = _lastOptimizeRejected ? 6.0 : 5.0;
      final minThreshold = _lastOptimizeRejected ? 3.5 : 3.0;

      if (improvementPercent <= pctThreshold &&
          improvementMinutes <= minThreshold) {
        debugPrint(
            '⚠️ [RouteService] Improvement too small — keeping current order');
        _lastOptimizeRejected = true;
        return false;
      }

      final reason = improvementPercent > pctThreshold
          ? '${improvementPercent.toStringAsFixed(1)}% faster'
          : '${improvementMinutes.toStringAsFixed(1)}min saved';
      debugPrint('✅ [RouteService] Applying optimization: $reason');
    } else if (oldEtaMin <= 0) {
      debugPrint(
          '⚠️ [RouteService] No saved trip duration, invalid ETA — applying optimization');
    } else {
      // ⚠️ OSRM Trip (roundtrip=true) включает возврат на склад.
      // ETA последней точки НЕ включает возврат.
      // Добавляем примерное время возврата к ETA для симметричного сравнения.
      final whLat = AppConfig.defaultWarehouseLat;
      final whLng = AppConfig.defaultWarehouseLng;
      final lastPoint = activePoints.last;
      final returnDistKm = RouteOptimizer.calculateDistance(
              lastPoint.latitude, lastPoint.longitude, whLat, whLng) *
          1.3;
      final routing = await _companyRoutingParams();
      final returnTimeMin =
          (returnDistKm / routing.avgSpeedKmh) * 60;

      final totalServiceMin = activePoints.length * routing.serviceMinutes;
      final oldTotalMin = oldEtaMin + returnTimeMin; // ETA + возврат на склад
      final newTotalMin = result.durationMinutes +
          totalServiceMin; // OSRM (с возвратом) + service

      final improvementMinutes = oldTotalMin - newTotalMin;
      final improvementPercent =
          oldTotalMin > 0 ? (improvementMinutes / oldTotalMin) * 100 : 0.0;

      debugPrint('📊 [RouteService] Optimization comparison:\n'
          '   Current: ~${oldTotalMin.toStringAsFixed(0)}min total (ETA ${oldEtaMin.toStringAsFixed(0)} + return ${returnTimeMin.toStringAsFixed(0)})\n'
          '   New:     ${newTotalMin.toStringAsFixed(0)}min total (OSRM ${result.durationMinutes.toStringAsFixed(0)} roundtrip + service ${totalServiceMin.toStringAsFixed(0)})\n'
          '   Includes return to warehouse: BOTH sides ✅\n'
          '   Improvement: ${improvementPercent.toStringAsFixed(1)}%, ${improvementMinutes.toStringAsFixed(1)}min');

      // Hysteresis: повышенный порог если прошлый раз отклонили (защита от дрожания)
      final pctThreshold = _lastOptimizeRejected ? 6.0 : 5.0;
      final minThreshold = _lastOptimizeRejected ? 3.5 : 3.0;

      if (improvementPercent <= pctThreshold &&
          improvementMinutes <= minThreshold) {
        debugPrint(
            '⚠️ [RouteService] Improvement too small — keeping current order');
        _lastOptimizeRejected = true;
        return false;
      }

      final reason = improvementPercent > pctThreshold
          ? '${improvementPercent.toStringAsFixed(1)}% faster'
          : '${improvementMinutes.toStringAsFixed(1)}min saved';
      debugPrint('✅ [RouteService] Applying optimization: $reason');
    }

    _lastOptimizeRejected = false;

    // Обновляем orderInRoute + ETA, используем polyline из Trip
    final balanceService = RouteBalanceService(companyId: companyId);
    await balanceService.recalculateETAsForPoints(
      reordered,
      polyline: result.polyline,
    );

    // Сохраняем новый tripDurationMinutes для следующего сравнения
    if (routeId != null) {
      try {
        await _routesCollection().doc(routeId).set({
          'tripDurationMinutes': result.durationMinutes,
          'tripDistanceKm': result.distanceKm,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    debugPrint(
        '✅ [RouteService] Route optimized: new order=${result.waypointOrder}');
    return true;
  }

  /// ✅ Отмена маршрута — точки возвращаются в пул ожидания (не удаляются).
  Future<void> cancelRoutePoints(String driverId, String? routeId) async {
    print(
        '🛑 [RouteService] Cancel route → pending: driverId="$driverId", routeId="$routeId"');

    Query query;

    if (driverId.isEmpty || driverId == 'null') {
      print('⚠️ [RouteService] Refusing (driverId is empty). Aborting.');
      return;
    } else if (routeId != null) {
      query = _deliveryPointsCollection().where('routeId', isEqualTo: routeId);
    } else {
      query =
          _deliveryPointsCollection().where('driverId', isEqualTo: driverId);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      print('⚠️ [RouteService] No points matched for cancel');
      return;
    }
    print(
        '📤 [RouteService] Returning ${snapshot.docs.length} points to pending');

    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': DeliveryPoint.statusPending,
        'routeId': FieldValue.delete(),
        'driverId': FieldValue.delete(),
        'driverName': FieldValue.delete(),
        'orderInRoute': FieldValue.delete(),
        'eta': FieldValue.delete(),
        'routeDate': FieldValue.delete(),
        'autoCompleted': false,
        'updatedAt': now,
      });
    }

    await batch.commit();
    print(
        '✅ [RouteService] Route cancelled — ${snapshot.docs.length} points → pending');
  }

  /// ✅ Смена водителя для конкретного маршрута
  Future<void> changeRouteDriver(
    String oldDriverId,
    String newDriverId,
    String newDriverName,
    int capacity,
    String? routeId, // ID конкретного маршрута
  ) async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final targetRouteId = await _resolveRouteIdForDriver(newDriverId, now);
    Query query =
        _deliveryPointsCollection().where('driverId', isEqualTo: oldDriverId);

    // Если указан routeId, фильтруем только по нему
    if (routeId != null) {
      query = query.where('routeId', isEqualTo: routeId);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;

    final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      snapshot.docs,
    )..sort((a, b) {
        final ao = (a.data()['orderInRoute'] as num?)?.toInt() ?? 0;
        final bo = (b.data()['orderInRoute'] as num?)?.toInt() ?? 0;
        return ao.compareTo(bo);
      });

    final targetMaxOrder = await _deliveryPointsCollection()
        .where('routeId', isEqualTo: targetRouteId)
        .orderBy('orderInRoute', descending: true)
        .limit(1)
        .get();
    final startOrder = targetMaxOrder.docs.isNotEmpty
        ? ((targetMaxOrder.docs.first.data()['orderInRoute'] as num?)
                    ?.toInt() ??
                0) +
            1
        : 0;

    print(
        '🔄 [RouteService] Changing driver from $oldDriverId to $newDriverName (${sortedDocs.length} points, routeId: $routeId -> $targetRouteId)');

    for (int i = 0; i < sortedDocs.length; i++) {
      final doc = sortedDocs[i];
      await doc.reference.update({
        'driverId': newDriverId,
        'driverName': newDriverName,
        'driverCapacity': capacity,
        'routeId': targetRouteId,
        'routeDate': Timestamp.fromDate(todayMidnight),
        'orderInRoute': startOrder + i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await _routesCollection().doc(targetRouteId).set({
        'routeId': targetRouteId,
        'driverId': newDriverId,
        'driverName': newDriverName,
        'routeDate': Timestamp.fromDate(todayMidnight),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [RouteService] Failed to upsert target route doc: $e');
    }

    final updatedRoute = await _deliveryPointsCollection()
        .where('routeId', isEqualTo: targetRouteId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();
    final updatedPoints = updatedRoute.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));
    if (updatedPoints.isNotEmpty) {
      final balanceService = RouteBalanceService(companyId: companyId);
      await balanceService.recalculateETAsForPoints(updatedPoints);
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

  /// Завершённые точки водителя — для экрана «История маршрутов».
  /// Показывает закрытые точки (включая 2-й маршрут того же дня, который
  /// уходит из активного дашборда). Сортировка клиентская — без orderBy,
  /// чтобы не требовать составной индекс Firestore.
  Future<List<DeliveryPoint>> getDriverCompletedPoints(
    String driverId, {
    int limit = 300,
  }) async {
    final snapshot = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: DeliveryPoint.statusCompleted)
        .limit(limit)
        .get();
    final points = snapshot.docs
        .map((doc) => DeliveryPoint.fromMap(doc.data(), doc.id))
        .toList();
    points.sort((a, b) {
      final da = a.completedAt ?? a.updatedAt ?? DateTime(1970);
      final db = b.completedAt ?? b.updatedAt ?? DateTime(1970);
      return db.compareTo(da);
    });
    return points;
  }

  /// Добавить новую точку доставки
  Future<void> addDeliveryPoint(DeliveryPoint point) async {
    // toMap() автоматически добавляет createdAt и updatedAt
    await _deliveryPointsCollection().add(point.toMap());
    print('✅ Delivery point added: ${point.clientName}');
  }

  /// Обновить статус точки (с аудитом: updatedByUid + updatedAt)
  /// ВАЖНО: водитель может менять только: status, completedAt, autoCompleted, updatedByUid, updatedAt, pod*
  Future<void> updatePointStatus(
    String pointId,
    String newStatus, {
    String? updatedByUid,
    bool autoCompleted = false,
    String? podPhotoUrl,
    double? podLat,
    double? podLng,
    int? podDistanceM,
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
      if (podPhotoUrl != null) {
        patch['podPhotoUrl'] = podPhotoUrl;
        patch['podLat'] = podLat;
        patch['podLng'] = podLng;
        patch['podAt'] = FieldValue.serverTimestamp();
        if (podDistanceM != null) patch['podDistanceM'] = podDistanceM;
      }
    }
    await _updatePoint(pointId, patch);
    print('✅ Point $pointId status updated to $newStatus');

    if (newStatus == DeliveryPoint.statusCompleted) {
      unawaited(_recordDeliveryLearning(pointId));
      // ETA пересчитывается на клиенте (в UI), без Firestore запросов
    }
  }

  /// Записывает данные доставки для самообучения клиента (visit_logs + сглаживание координат).
  Future<void> _recordDeliveryLearning(String pointId) async {
    try {
      final pointRef = _deliveryPointsCollection().doc(pointId);
      final doc = await pointRef.get();
      if (!doc.exists) return;
      final data = doc.data()!;

      final clientNumber = data['clientNumber'] as String? ?? '';
      final driverId = data['driverId'] as String? ?? '';
      if (clientNumber.isEmpty || driverId.isEmpty) return;

      // 1) Фиксируем факт закрытия в visit_logs (без изменения самой точки).
      final locDoc =
          await FirestorePaths.driverLocationsOf(companyId).doc(driverId).get();
      double driverLat = 0, driverLng = 0;
      if (locDoc.exists) {
        driverLat = (locDoc.data()?['latitude'] as num?)?.toDouble() ?? 0;
        driverLng = (locDoc.data()?['longitude'] as num?)?.toDouble() ?? 0;
      }
      final hasDriverCoord = driverLat != 0 && driverLng != 0;

      // 🛡️ Guard: не обучаем если водитель > 1 км от клиента (закрыл с дороги)
      final pointLat = (data['latitude'] as num?)?.toDouble() ?? 0;
      final pointLng = (data['longitude'] as num?)?.toDouble() ?? 0;
      if (hasDriverCoord && pointLat != 0 && pointLng != 0) {
        final distToClient =
            _calculateDistance(driverLat, driverLng, pointLat, pointLng);
        if (distToClient > 1.0) {
          debugPrint(
              '⚠️ [Learning] Skipping: driver ${distToClient.toStringAsFixed(1)}km from client');
          return;
        }
      }

      if (hasDriverCoord) {
        await pointRef.collection('visit_logs').add({
          'lat': driverLat,
          'lng': driverLng,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Оставляем текущее обучение клиента (service_time/GPS) как было.
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

      // 2) Асинхронное "мягкое" обучение координаты точки по visit_logs.
      // Не трогаем UI и не делаем резких прыжков.
      final visitsSnap = await pointRef
          .collection('visit_logs')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      final rawVisits = visitsSnap.docs
          .map((d) => d.data())
          .where(
            (v) =>
                (v['lat'] is num) &&
                (v['lng'] is num) &&
                ((v['lat'] as num).toDouble() != 0) &&
                ((v['lng'] as num).toDouble() != 0),
          )
          .map(
            (v) => (
              lat: (v['lat'] as num).toDouble(),
              lng: (v['lng'] as num).toDouble(),
            ),
          )
          .toList();

      if (rawVisits.length < 5) return; // Порог накопления

      // Центроид по всем наблюдениям
      double baseLat = 0, baseLng = 0;
      for (final v in rawVisits) {
        baseLat += v.lat;
        baseLng += v.lng;
      }
      baseLat /= rawVisits.length;
      baseLng /= rawVisits.length;

      // 3) Убираем выбросы: далеко от массы (>70м)
      final inliers = rawVisits.where((v) {
        final meters =
            _calculateDistance(baseLat, baseLng, v.lat, v.lng) * 1000;
        return meters <= 70;
      }).toList();
      if (inliers.length < 5) return;

      // "Истинная точка" = центроид по inliers
      double learnedLat = 0, learnedLng = 0;
      for (final v in inliers) {
        learnedLat += v.lat;
        learnedLng += v.lng;
      }
      learnedLat /= inliers.length;
      learnedLng /= inliers.length;

      // Проверка разброса (variance по расстоянию, м^2)
      double variance = 0;
      for (final v in inliers) {
        final meters =
            _calculateDistance(learnedLat, learnedLng, v.lat, v.lng) * 1000;
        variance += meters * meters;
      }
      variance /= inliers.length;
      const varianceThreshold = 1600.0; // ~40м стандартное отклонение
      if (variance > varianceThreshold) return;

      final oldLat = (data['latitude'] as num?)?.toDouble() ?? 0;
      final oldLng = (data['longitude'] as num?)?.toDouble() ?? 0;
      if (oldLat == 0 || oldLng == 0) return;

      // 4) Мягкое обновление (без рывков)
      final newLat = oldLat * 0.7 + learnedLat * 0.3;
      final newLng = oldLng * 0.7 + learnedLng * 0.3;

      // 5) Обновляем координаты точки
      await pointRef.update({
        'latitude': newLat,
        'longitude': newLng,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    final routeId = await _resolveRouteIdForDriver(driverId, now);

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

    // Авто-оптимизация отключена — вызывает каскад OSRM запросов.
    // Диспетчер может оптимизировать вручную через кнопку.
  }

  /// Road safety checks moved to RouteSafetyService
  /// Route alternative generation moved to RouteOptimizer

  /// 🚚 Назначает точки водителю (вынесенный метод)
  Future<void> _assignPointsToDriver(String driverId, String driverName,
      int driverCapacity, List<DeliveryPoint> points,
      {Map<String, double>? startLocation,
      String? tripPolyline,
      double? tripDurationMinutes,
      double? tripDistanceKm,
      bool separateRoute = false}) async {
    // 🛡️ Жёсткая проверка перегрузки
    final existingLoad = await _deliveryPointsCollection()
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
        .get();
    final currentPallets = existingLoad.docs.fold<int>(
        0, (acc, doc) => acc + ((doc.data()['pallets'] as num?)?.toInt() ?? 0));
    final newPallets = points.fold<int>(0, (acc, p) => acc + p.pallets);
    if (driverCapacity > 0 && currentPallets + newPallets > driverCapacity) {
      throw Exception(
          'עומס יתר: $driverName — ${currentPallets + newPallets} משטחים מתוך $driverCapacity מותרים');
    }

    // Генерируем routeId для этого маршрута
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final routeId = separateRoute
        ? _buildUniqueRouteId(driverId, now)
        : await _resolveRouteIdForDriver(driverId, now);

    // Отдельный маршрут — не трогаем точки других маршрутов того же водителя.
    if (!separateRoute) {
      final orphanedPoints = await _deliveryPointsCollection()
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: DeliveryPoint.activeRouteStatuses)
          .get();

      int orphanedCount = 0;
      for (final doc in orphanedPoints.docs) {
        final data = doc.data();
        final oldRouteId = data['routeId'] as String?;
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
      if (data['archived'] == true) return false;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      return completedAt != null && completedAt.isAfter(todayMidnight);
    }).toList();

    final startOrder = separateRoute
        ? 0
        : existingPoints.docs
            .where((d) => (d.data()['routeId'] as String?) == routeId)
            .length;
    print(
        '📊 [RouteService] Driver has $startOrder active points, ${todayCompleted.length} completed today');

    // ETA = drive_time + service_time (+ parking включено в serviceMinutes)
    double cumulativeTimeMinutes = 0;
    final routing = await _companyRoutingParams();
    final double avgSpeedKmh = routing.avgSpeedKmh;
    final double defaultServiceTimeMinutes = routing.serviceMinutes;
    const double parkingTimeMinutes = 0.0;

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
        // 🏭 Первая точка: startLocation (GPS) > последняя завершённая > склад
        if (startLocation != null) {
          distanceKm = _calculateDistance(
            startLocation['latitude']!,
            startLocation['longitude']!,
            pointLat,
            pointLng,
          );
          print(
              '🚛 [RouteService] ETA starting from driver GPS / resolved location');
        } else if (todayCompleted.isNotEmpty) {
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
          print('📍 [RouteService] ETA starting from last completed point');
        } else {
          distanceKm = _calculateDistance(
            AppConfig.defaultWarehouseLat,
            AppConfig.defaultWarehouseLng,
            pointLat,
            pointLng,
          );
          print(
              '🏭 [RouteService] ETA starting from warehouse (no GPS, no completed points)');
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

    // Расчёт ETA возврата на склад (после последней точки)
    String? returnEta;
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final lastCn = lastPoint.clientNumber ?? '';
      final lastNav = clientNavPoints[lastCn];
      final lastLat = lastNav?['lat'] ?? lastPoint.latitude;
      final lastLng = lastNav?['lng'] ?? lastPoint.longitude;
      final returnDistKm = _calculateDistance(lastLat, lastLng,
          AppConfig.defaultWarehouseLat, AppConfig.defaultWarehouseLng);
      final returnTravelMin = (returnDistKm / avgSpeedKmh) * 60;
      cumulativeTimeMinutes += returnTravelMin;
      returnEta = TimeFormatter.formatArrivalTime(cumulativeTimeMinutes);
      print(
          '🏭 [RouteService] Return to warehouse ETA: $returnEta (${returnDistKm.toStringAsFixed(1)}km)');
    }

    print('✅ [RouteService] Route successfully created for $driverName');

    // 📦 Сразу после назначения точек — документ маршрута (не ждём OSRM)
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
        if (tripDurationMinutes != null)
          'tripDurationMinutes': tripDurationMinutes,
        if (tripDistanceKm != null) 'tripDistanceKm': tripDistanceKm,
        if (returnEta != null) 'returnEta': returnEta,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('📦 [RouteService] Route document saved: $routeId');
    } catch (e) {
      print('⚠️ [RouteService] Failed to save route document: $e');
    }

    // 🗺️ Polyline: если OSRM Trip уже дал polyline — сохраняем напрямую.
    // Иначе запрашиваем OSRM Route в фоне (для 1 точки или fallback).
    if (tripPolyline != null && tripPolyline.isNotEmpty) {
      try {
        await _routesCollection().doc(routeId).set({
          'polyline': tripPolyline,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ [RouteService] Trip polyline saved for $driverName');
      } catch (e) {
        print('⚠️ [RouteService] Failed to save trip polyline: $e');
      }
    } else {
      unawaited(_saveOsrmPolylineBackground(
        routeId: routeId,
        startLocation: startLocation,
        clientNavPoints: clientNavPoints,
        points: points,
        driverName: driverName,
      ));
    }
  }

  /// Получает polyline от OSRM и сохраняет в routes документ.
  /// Вызывается через unawaited — не блокирует создание маршрута.
  Future<void> _saveOsrmPolylineBackground({
    required String routeId,
    Map<String, double>? startLocation,
    required Map<String, Map<String, double>> clientNavPoints,
    required List<DeliveryPoint> points,
    required String driverName,
  }) async {
    try {
      final originLat =
          startLocation?['latitude'] ?? AppConfig.defaultWarehouseLat;
      final originLng =
          startLocation?['longitude'] ?? AppConfig.defaultWarehouseLng;
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

      // endLat/endLng = склад → OSRM строит маршрут с возвратом
      final osrmRoute = await osrm.getOptimizedRoute(
        startLat: originLat,
        startLng: originLng,
        waypoints: waypoints,
        endLat: originLat,
        endLng: originLng,
      );

      if (osrmRoute != null && osrmRoute.polyline.isNotEmpty) {
        await _routesCollection().doc(routeId).set({
          'polyline': osrmRoute.polyline,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print(
            '✅ [RouteService] Polyline saved for $driverName: ${osrmRoute.polyline.length} chars');
      }
    } catch (e) {
      print('⚠️ [RouteService] OSRM polyline save failed: $e');
    }
  }

  /// Отменить ошибочное автозакрытие (водитель: «Отменить» в snackbar).
  Future<void> undoAutoComplete(String pointId, {String? updatedByUid}) async {
    final patch = <String, dynamic>{
      'status': DeliveryPoint.statusInProgress,
      'autoCompleted': false,
      'completedAt': FieldValue.delete(),
      'arrivedAt': FieldValue.serverTimestamp(),
    };
    if (updatedByUid != null) patch['updatedByUid'] = updatedByUid;
    await _updatePoint(pointId, patch);
    print('↩️ [RouteService] Auto-complete undone for $pointId');
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
        'driverCapacity': null,
        'orderInRoute': null,
        'routeId': null,
        'routeDate': null,
        'eta': null,
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
