import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_point.dart';

/// Централизованный persistent-кеш для delivery points.
/// Используется и водителем, и диспетчером — один механизм.
class RouteCacheService {
  static const _maxCacheAgeMs = 12 * 60 * 60 * 1000; // 12 часов

  /// Ключ кеша: prefix_companyId[_driverId]
  final String _keyPrefix;

  RouteCacheService._({required String keyPrefix}) : _keyPrefix = keyPrefix;

  /// Кеш для водителя (фильтр по driverId)
  factory RouteCacheService.driver({
    required String companyId,
    required String driverId,
  }) =>
      RouteCacheService._(keyPrefix: 'rc_${companyId}_$driverId');

  /// Кеш для диспетчера (все точки компании)
  factory RouteCacheService.dispatcher({required String companyId}) =>
      RouteCacheService._(keyPrefix: 'rc_dispatch_$companyId');

  String get _pointsKey => '${_keyPrefix}_pts';
  String get _routeKeyKey => '${_keyPrefix}_rk';
  String get _tsKey => '${_keyPrefix}_ts';

  // ═══════════════════════════════════════════════════════════════════
  // Serialization (JSON-safe, без Firestore Timestamp/FieldValue)
  // ═══════════════════════════════════════════════════════════════════

  static Map<String, dynamic> pointToJson(DeliveryPoint p) => {
        'id': p.id,
        'companyId': p.companyId,
        'address': p.address,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'clientName': p.clientName,
        'clientNumber': p.clientNumber,
        'urgency': p.urgency,
        'pallets': p.pallets,
        'boxes': p.boxes,
        'status': p.status,
        'orderInRoute': p.orderInRoute,
        'driverId': p.driverId,
        'driverName': p.driverName,
        'driverCapacity': p.driverCapacity,
        'temporaryAddress': p.temporaryAddress,
        'autoCompleted': p.autoCompleted,
        'routeId': p.routeId,
        'routePolyline': p.routePolyline,
        'zone': p.zone,
        'eta': p.eta,
        'distanceKm': p.distanceKm,
        if (p.openingTime != null)
          'openingTime': p.openingTime!.millisecondsSinceEpoch,
        if (p.completedAt != null)
          'completedAt': p.completedAt!.millisecondsSinceEpoch,
        if (p.arrivedAt != null)
          'arrivedAt': p.arrivedAt!.millisecondsSinceEpoch,
        if (p.updatedAt != null)
          'updatedAt': p.updatedAt!.millisecondsSinceEpoch,
        if (p.createdAt != null)
          'createdAt': p.createdAt!.millisecondsSinceEpoch,
      };

  static DeliveryPoint pointFromJson(Map<String, dynamic> m) => DeliveryPoint(
        id: m['id'] ?? '',
        companyId: m['companyId'] ?? '',
        address: m['address'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
        clientName: m['clientName'] ?? '',
        clientNumber: m['clientNumber'],
        urgency: m['urgency'] ?? 'normal',
        pallets: m['pallets'] ?? 0,
        boxes: m['boxes'] ?? 0,
        status: m['status'] ?? 'pending',
        orderInRoute: m['orderInRoute'] ?? 0,
        driverId: m['driverId'],
        driverName: m['driverName'],
        driverCapacity: m['driverCapacity'],
        temporaryAddress: m['temporaryAddress'],
        autoCompleted: m['autoCompleted'] ?? false,
        routeId: m['routeId'],
        routePolyline: m['routePolyline'],
        zone: m['zone'],
        eta: m['eta'],
        distanceKm: (m['distanceKm'] as num?)?.toDouble(),
        openingTime: m['openingTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['openingTime'])
            : null,
        completedAt: m['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['completedAt'])
            : null,
        arrivedAt: m['arrivedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['arrivedAt'])
            : null,
        updatedAt: m['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['updatedAt'])
            : null,
        createdAt: m['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'])
            : null,
      );

  // ═══════════════════════════════════════════════════════════════════
  // Save / Restore
  // ═══════════════════════════════════════════════════════════════════

  Future<void> savePoints(List<DeliveryPoint> points,
      {String? visibleRouteKey}) async {
    if (points.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          points.map((p) => jsonEncode(pointToJson(p))).toList();
      await prefs.setStringList(_pointsKey, jsonList);
      if (visibleRouteKey != null) {
        await prefs.setString(_routeKeyKey, visibleRouteKey);
      }
      await prefs.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ [RouteCache] Save failed ($_keyPrefix): $e');
    }
  }

  /// Восстанавливает точки из кеша. Возвращает null если кеш пуст или устарел.
  Future<RouteCacheResult?> restorePoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_tsKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - ts;
      if (cacheAge > _maxCacheAgeMs) {
        debugPrint(
            '🗑️ [RouteCache] Cache too old (${cacheAge ~/ 3600000}h), ignoring');
        return null;
      }
      final jsonList = prefs.getStringList(_pointsKey);
      if (jsonList == null || jsonList.isEmpty) return null;

      final restored = <DeliveryPoint>[];
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          restored.add(pointFromJson(map));
        } catch (_) {}
      }
      if (restored.isEmpty) return null;

      final routeKey = prefs.getString(_routeKeyKey);
      debugPrint(
          '✅ [RouteCache] Restored ${restored.length} points ($_keyPrefix), '
          'routeKey=$routeKey');
      return RouteCacheResult(points: restored, visibleRouteKey: routeKey);
    } catch (e) {
      debugPrint('⚠️ [RouteCache] Restore failed ($_keyPrefix): $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsKey);
      await prefs.remove(_routeKeyKey);
      await prefs.remove(_tsKey);
    } catch (_) {}
  }
}

class RouteCacheResult {
  final List<DeliveryPoint> points;
  final String? visibleRouteKey;

  const RouteCacheResult({required this.points, this.visibleRouteKey});
}
