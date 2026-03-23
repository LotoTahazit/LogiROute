part of '../delivery_map_widget.dart';

/// Drag & drop точек на водителей: зоны, привязка, уведомление.
mixin _DragDropMixin on _DeliveryMapWidgetStateBase {
  /// При начале перетаскивания — показываем зоны водителей
  @override
  void _onPointDragStart(DeliveryPoint point) {
    _showDriverZones();
    debugPrint('🖐️ [DragDrop] Started dragging: ${point.clientName}');
  }

  /// При отпускании — ищем ближайшего водителя и назначаем
  @override
  void _onPointDragEnd(DeliveryPoint point, LatLng newPosition) {
    // Убираем зоны водителей
    setState(() {
      _driverZoneCircles = {};
    });

    // Ищем ближайшего водителя (исключаем текущего водителя точки)
    final nearest = _findNearestDriver(
      newPosition,
      excludeDriverId: point.driverId,
    );
    if (nearest == null) {
      debugPrint('⚠️ [DragDrop] No driver found near drop position');
      _updateMapData();
      return;
    }

    final driverId = nearest['driverId'] as String;
    final driverName = nearest['driverName'] as String;
    final distKm = nearest['distKm'] as double;

    debugPrint(
      '🖐️ [DragDrop] Dropped ${point.clientName} near $driverName (${distKm.toStringAsFixed(1)} km)',
    );

    // Сразу назначаем точку водителю
    widget.onPointDragToDriver?.call(point.id, driverId, driverName);

    // Показываем уведомление
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📦 ${point.clientName} → 🚛 $driverName',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Ищем ближайшего водителя к позиции drop
  /// Сначала по GPS-позициям водителей, затем по точкам маршрутов на карте
  /// Возвращает {driverId, driverName, distKm} или null
  Map<String, dynamic>? _findNearestDriver(
    LatLng position, {
    String? excludeDriverId,
  }) {
    String? nearestId;
    String? nearestName;
    double minDist = double.infinity;

    // 1️⃣ Ищем по GPS-позициям водителей (если доступны)
    for (final entry in _driverCurrentPositions.entries) {
      final driverId = entry.key;
      if (driverId == excludeDriverId) continue;
      final driverPos = entry.value;
      final name = _driverNames[driverId] ?? 'Driver';

      final dist = _gpsDistanceKm(
        position.latitude,
        position.longitude,
        driverPos.latitude,
        driverPos.longitude,
      );

      if (dist < minDist) {
        minDist = dist;
        nearestId = driverId;
        nearestName = name;
      }
    }

    // 2️⃣ Ищем по точкам маршрутов (для случаев когда GPS недоступен)
    for (final point in widget.points) {
      if (point.driverId == null || point.driverId!.isEmpty) continue;
      if (point.driverId == excludeDriverId) continue;

      final dist = _gpsDistanceKm(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );

      if (dist < minDist) {
        minDist = dist;
        nearestId = point.driverId;
        nearestName = point.driverName ?? 'Driver';
      }
    }

    // Максимальное расстояние для привязки — 50 км (вся территория Израиля)
    if (nearestId == null || minDist > 50.0) return null;

    debugPrint(
      '🎯 [DragDrop] Nearest driver: $nearestName ($nearestId), dist: ${minDist.toStringAsFixed(1)} km',
    );

    return {
      'driverId': nearestId,
      'driverName': nearestName ?? 'Driver',
      'distKm': minDist,
    };
  }

  /// Показываем полупрозрачные круги вокруг водителей при drag
  void _showDriverZones() {
    if (_driverCurrentPositions.isEmpty) return;

    final circles = <Circle>{};
    final driverIds = _driverCurrentPositions.keys.toList();

    for (int i = 0; i < driverIds.length; i++) {
      final driverId = driverIds[i];
      final pos = _driverCurrentPositions[driverId];
      if (pos == null) continue;

      final color = _getRouteLoadColor(driverId);

      circles.add(
        Circle(
          circleId: CircleId('zone_$driverId'),
          center: pos,
          radius: 3000, // 3 км радиус зоны
          fillColor: color.withValues(alpha: (color.a * 0.15).clamp(0.0, 1.0)),
          strokeColor:
              color.withValues(alpha: (color.a * 0.5).clamp(0.0, 1.0)),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _driverZoneCircles = circles;
    });
  }
}
