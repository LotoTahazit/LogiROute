part of '../delivery_map_widget.dart';

/// Маркеры водителей: GPS-фильтры, состояния, кластеризация, анимация, ETA.
mixin _DriverMarkersMixin on _DeliveryMapWidgetStateBase {
  void _startDriverLocationTracking() {
    // ⚡ Поток позиций: фильтрация по активным маршрутам — в _updateDriverMarkers / UI.
    _driverLocationsSubscription = _locationService
        .getAllDriverLocationsStream(driverIds: null)
        .listen((driverLocations) {
      _updateDriverMarkers(driverLocations);
    }, onError: (error) {});
  }

  /// Запускает таймер плавной анимации маркеров (60fps → ~16ms)
  void _startMarkerAnimation() {
    _markerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 50), // 20fps — достаточно для плавности
      (_) => _interpolateDriverPositions(),
    );
    // Батчинг setState — не чаще 1 раза в 200ms
    _markerBatchTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_markersDirty && mounted) {
        _markersDirty = false;
        _rebuildDriverMarkers();
      }
    });
  }

  /// Интерполяция позиций водителей к целевым координатам
  /// Адаптивная скорость: далеко → быстрее, близко → медленнее (как Uber)
  void _interpolateDriverPositions() {
    bool changed = false;

    for (final driverId in _driverTargetPositions.keys) {
      final target = _driverTargetPositions[driverId]!;
      final current = _driverCurrentPositions[driverId];

      if (current == null) {
        _driverCurrentPositions[driverId] = target;
        changed = true;
        continue;
      }

      // Если уже на месте — пропускаем
      final distLat = (target.latitude - current.latitude).abs();
      final distLng = (target.longitude - current.longitude).abs();
      if (distLat < 0.000001 && distLng < 0.000001) continue;

      final distance = distLat + distLng;

      // Адаптивная скорость
      double speed;
      if (distance > 0.01) {
        speed = 0.35; // Далеко — быстро
      } else if (distance > 0.001) {
        speed = 0.25; // Средне
      } else {
        speed = 0.15; // Близко — плавно
      }

      final newLat =
          current.latitude + (target.latitude - current.latitude) * speed;
      final newLng =
          current.longitude + (target.longitude - current.longitude) * speed;
      _driverCurrentPositions[driverId] = LatLng(newLat, newLng);

      changed = true;
    }

    if (changed) {
      _markersDirty = true;
    }
  }

  /// Пересоздаёт маркеры водителей из текущих (анимированных) позиций
  void _rebuildDriverMarkers() {
    if (!mounted) return;

    final isZoomedOut = _currentZoom < 11; // 🎯 Zoom-aware режим готов

    debugPrint(
        '🔄 REBUILDING MARKERS FROM _driverCurrentPositions (single source of truth)');

    final driverMarkers = <Marker>{};
    final renderedIds = <String>{}; //

    if (isZoomedOut) {
      // 🔵 ТОЛЬКО кластеры
      final Map<String, List<MapEntry<String, LatLng>>> clusters =
          {}; // 🎯 Grid-кластеризация

      for (final entry in _driverCurrentPositions.entries) {
        final position = entry.value;

        // 🎯 Кластеризация по сетке
        final gridSize = 0.02; // ~2км клетки

        final latKey = (position.latitude / gridSize).floor();
        final lngKey = (position.longitude / gridSize).floor();
        final key = '$latKey:$lngKey';

        clusters.putIfAbsent(key, () => []).add(entry);
      }

      // 🎯 Создаем кластерные маркеры
      for (final entry in clusters.entries) {
        final key = entry.key;
        final cluster = entry.value;
        final count = cluster.length;

        final avgLat =
            cluster.map((e) => e.value.latitude).reduce((a, b) => a + b) /
                count;
        final avgLng =
            cluster.map((e) => e.value.longitude).reduce((a, b) => a + b) /
                count;

        final position = LatLng(avgLat, avgLng);

        driverMarkers.add(
          Marker(
            markerId: MarkerId('cluster_$key'), // 🎯 Стабильный ID по grid key
            position: position,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            zIndexInt: 10, // 🎯 Под обычными маркерами
            infoWindow: InfoWindow(
              title: '$count drivers',
            ),
          ),
        );
      }
    } else {
      // 🟢 ТОЛЬКО обычные водители
      for (final entry in _driverCurrentPositions.entries) {
        final driverId = entry.key;
        final position = entry.value;
        final name = _driverNames[driverId] ?? '';
        final eta = _driverETAs[driverId] ?? '';
        final heading = _driverHeadings[driverId] ?? 0.0;
        final freshnessSec = _driverFreshnessSec(driverId);
        final driverState = _getDriverState(driverId);

        // 🔘 Скрываем OFF_SHIFT водителей если toggle выключен
        if (driverState == 'OFF_SHIFT' && !_showOffShiftDrivers) continue;

        final hue = _driverHeartbeatHue(freshnessSec, driverState);
        final stateLabel = _driverHeartbeatLabel(freshnessSec, driverState);

        //
        final targetAlpha = driverState == 'OFF_SHIFT' ? 0.6 : 1.0;
        final currentAlpha = _driverAlphas[driverId] ?? targetAlpha; //
        final newAlpha = currentAlpha + (targetAlpha - currentAlpha) * 0.2;
        _driverAlphas[driverId] = newAlpha;

        driverMarkers.add(
          Marker(
            markerId: MarkerId('driver_$driverId'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            rotation: heading, //
            anchor: const Offset(0.5, 0.5), //
            alpha: newAlpha, //
            infoWindow: InfoWindow(
              title: ' $name',
              snippet: eta.isNotEmpty ? '$stateLabel • ETA: $eta' : stateLabel,
            ),
            zIndexInt: 100, //
          ),
        );

        renderedIds.add(driverId); //
      }
    }

    if (kDebugMode) {
      debugPrint(
          'MODE: ${isZoomedOut ? "CLUSTER" : "NORMAL"} markers=${driverMarkers.length}');
    }

    // ( = UI)
    _driverAlphas.removeWhere((id, _) => !renderedIds.contains(id));

    //
    _driverMarkersNotifier.value = driverMarkers;
  }

  String _getDriverState(String driverId) {
    final rawState = _driverStates[driverId];
    if (rawState is Map) {
      return rawState['state'] as String? ?? 'UNKNOWN';
    } else if (rawState is String) {
      return rawState;
    }
    return 'UNKNOWN';
  }

  int _driverFreshnessSec(String driverId) {
    final ts = _driverLocations[driverId]?['timestamp'];
    DateTime? updatedAt;
    if (ts is DateTime) updatedAt = ts;
    if (ts is Timestamp) updatedAt = ts.toDate();
    if (updatedAt == null) return 9999;
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.difference(updatedAt.toUtc()).inSeconds;
  }

  double _driverHeartbeatHue(int sec, String driverState) {
    // OFF_SHIFT - спокойный голубой (не в игре)
    if (driverState == 'OFF_SHIFT') return BitmapDescriptor.hueAzure;

    // Остальные состояния как раньше
    if (sec < 15) return BitmapDescriptor.hueGreen;
    if (sec <= 30) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  String _driverHeartbeatLabel(int sec, String driverState) {
    // OFF_SHIFT всегда показывает вне смены
    if (driverState == 'OFF_SHIFT') return '🔘 off shift';

    // Остальные состояния как раньше
    if (sec < 15) return '🟢 online';
    if (sec <= 30) return '🟡 delayed';
    return '🔴 offline';
  }

  Future<void> _updateDriverMarkers(
    List<Map<String, dynamic>> driverLocations,
  ) async {
    if (!mounted) return;

    if (kDebugMode) debugPrint('📡 DRIVERS INPUT: ${driverLocations.length}');

    // 🕐 Единое время для всех вычислений в этом цикле
    final now = DateTime.now();

    // Сохраняем позиции водителей для расчета ETA
    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;
      _driverLocations[driverId] = driverLocation;
    }

    // Пересчитываем ETA для всех водителей (с debounce — не чаще раз в 5 сек)
    _etaDebounce?.cancel();
    _etaDebounce = Timer(const Duration(seconds: 5), () => _calculateETAs());

    final activeDriverIds = <String>{};

    for (final driverLocation in driverLocations) {
      final driverId = driverLocation['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;

      final driverName = driverLocation['driverName']?.toString() ?? '';
      _driverNames[driverId] = driverName;

      final latitude = (driverLocation['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude =
          (driverLocation['longitude'] as num?)?.toDouble() ?? 0.0;
      final timestamp = driverLocation['timestamp'];

      final newPosition = GpsLatLng(latitude, longitude);

      // ⏱️ Фильтр дёргания: пропускаем обновление ПОЗИЦИИ если движение < 20м за < 3с
      // НО: состояние/имя/heading обновляются ВСЕГДА
      bool skipPositionUpdate = false;
      final lastPos = _lastDriverPositions[driverId];
      final lastTime = _lastPositionTimes[driverId] ?? now;
      final secondsDiff = now.difference(lastTime).inSeconds;

      if (lastPos != null) {
        final distanceMoved = GpsUtils.distanceMeters(
          lastPos.latitude,
          lastPos.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        if (distanceMoved < 20.0 && secondsDiff < 3) {
          skipPositionUpdate = true;
        }
      }

      // 🧭 Вычисляем heading (направление движения)
      double newHeading = _driverHeadings[driverId] ?? 0.0;
      double speed = 0.0;

      if (lastPos != null) {
        // Вычисляем скорость и heading
        final secondsDiff = now.difference(lastTime).inSeconds;

        if (secondsDiff > 0) {
          speed = GpsUtils.calculateSpeed(lastPos, newPosition, secondsDiff);

          // Обновляем heading только если скорость > 5 км/ч (чтобы не дергалось на парковке)
          if (speed > 5.0) {
            newHeading = GpsUtils.calculateHeading(
              lastPos.latitude,
              lastPos.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );
          }
        }
      }

      // 🚦 Надежное определение стоянки (двойная проверка)
      final lastPosForStop = _lastDriverPositions[driverId];
      double moved = 0;
      if (lastPosForStop != null) {
        moved = GpsUtils.distanceMeters(
          lastPosForStop.latitude,
          lastPosForStop.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
      }

      // Двойная проверка: скорость < 5 км/ч И движение < 8 метров (AND - оба условия)
      final isStopped = (speed <= 5.0) && (moved < 8.0);

      if (isStopped) {
        _driverStopStartTimes.putIfAbsent(driverId, () => now);
      } else {
        _driverStopStartTimes.remove(driverId);
      }

      _lastDriverPositions[driverId] =
          newPosition; // Сохраняем последнюю позицию
      _driverHeadings[driverId] = newHeading; // Сохраняем heading
      _lastPositionTimes[driverId] = now; // Сохраняем время

      // 🕐 Проверка рабочей смены и свежести GPS
      if (timestamp != null) {
        try {
          final locationTime =
              (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();

          // 🎯 Проверяем должен ли водитель отображаться на карте
          if (!shouldShowDriver(locationTime)) {
            _driverCurrentPositions.remove(driverId);
            _driverTargetPositions.remove(driverId);
            continue;
          }

          // Минимальная логика определения состояния водителя
          final minutesSinceUpdate = now.difference(locationTime).inMinutes;

          // Читаем предыдущее состояние из _driverStates
          final rawState = _driverStates[driverId];
          String? prevState;

          if (rawState is Map) {
            prevState = rawState['state'] as String?;
          } else if (rawState is String) {
            prevState = rawState;
          } else {
            prevState = null;
          }

          String newState;

          // Только факт из Firestore (без расписания смен на карте)
          final driverClaimsOnShift =
              (driverLocation['isOnShift'] as bool?) ?? true;
          if (!driverClaimsOnShift) {
            newState = 'OFF_SHIFT';
          } else if (minutesSinceUpdate < 4) {
            // мгновенное улучшение
            newState = 'ACTIVE';
          } else if (minutesSinceUpdate >= 6 && minutesSinceUpdate < 30) {
            newState = 'STALE';
          } else if (minutesSinceUpdate >= 30) {
            newState = 'HIDDEN';
          } else {
            // буфер 4–6 минут
            if (prevState == 'ACTIVE') {
              newState = 'ACTIVE'; // удерживаем ACTIVE
            } else {
              newState = 'STALE';
            }
          }

          // 🕐 Записываем состояние в _driverStates с TTL
          _driverStates[driverId] = {
            'state': newState,
            'updatedAt': now,
          };
        } catch (e) {
          debugPrint('⚠️ [DeliveryMap] Error parsing timestamp: $e');
          continue;
        }
      } else {
        continue;
      }

      // Фильтруем нулевые координаты
      if (latitude == 0 && longitude == 0) continue;

      // 📍 Обновляем позиции водителя (только если двигался)
      if (!skipPositionUpdate) {
        // 🛡️ GPS фильтр: игнорируем прыжки > 5 км (ошибка GPS)
        final currentPos = _driverCurrentPositions[driverId];
        if (currentPos != null) {
          final jumpDist = (latitude - currentPos.latitude).abs() +
              (longitude - currentPos.longitude).abs();
          if (jumpDist > 0.05) continue; // ~5 км — GPS глюк
        }

        _driverCurrentPositions[driverId] = LatLng(latitude, longitude);
        _driverTargetPositions[driverId] = LatLng(latitude, longitude);
      } else {
        // Даже при skipPositionUpdate — убедимся что водитель есть на карте (первый раз)
        _driverCurrentPositions.putIfAbsent(
            driverId, () => LatLng(latitude, longitude));
        _driverTargetPositions.putIfAbsent(
            driverId, () => LatLng(latitude, longitude));
      }

      activeDriverIds.add(driverId);
    }

    // 🧹 Очистка водителей-призраков: удаляем тех, кого нет в текущем snapshot
    _driverCurrentPositions
        .removeWhere((id, _) => !activeDriverIds.contains(id));
    _driverTargetPositions
        .removeWhere((id, _) => !activeDriverIds.contains(id));

    // 🧹 TTL очистка _driverStates от старых данных (>60 минут)
    _driverStates.removeWhere((driverId, data) {
      if (data is! Map) return false;

      final updatedAt = data['updatedAt'] as DateTime?;
      if (updatedAt == null) return false;

      return now.difference(updatedAt).inMinutes > 60;
    });

    if (kDebugMode) {
      debugPrint(
          '📍 AFTER FILTER: ${_driverCurrentPositions.length} drivers on map');
    }

    // 🔄 Пересобираем маркеры после всех обновлений
    _rebuildDriverMarkers();

    // Обновляем линии прогресса маршрутов
    _updateDriverProgressPolylines();
  }

  // Рассчитываем ETA для всех водителей (локально, без OSRM)
  void _calculateETAs() {
    // ...
    // Защита от crash при пустых данных
    if (widget.points.isEmpty || _driverLocations.isEmpty) return;

    for (final entry in _driverLocations.entries) {
      final driverId = entry.key;
      final location = entry.value;
      final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      final speed = (location['speed'] as num?)?.toDouble() ?? 0.0;

      // Находим следующую незавершенную точку для этого водителя
      DeliveryPoint? nextPoint;
      try {
        nextPoint = widget.points.firstWhere(
          (p) =>
              p.driverId == driverId &&
              p.status != DeliveryPoint.statusCompleted &&
              p.status != DeliveryPoint.statusCancelled,
        );
      } catch (_) {
        continue; // Нет активных точек
      }

      // Расстояние по прямой (км)
      final distKm = _gpsDistanceKm(
        latitude,
        longitude,
        nextPoint.latitude,
        nextPoint.longitude,
      );

      // Средняя скорость: если GPS speed > 5 км/ч — используем её, иначе 30 км/ч (город)
      final avgSpeedKmh = (speed * 3.6 > 5) ? speed * 3.6 : 30.0;
      // Коэффициент дороги: реальный путь ~1.4x от прямой
      final rawEtaMinutes = (distKm * 1.4 / avgSpeedKmh * 60).round();
      final etaMinutes = _smoothEtaMinutes(driverId, rawEtaMinutes);

      if (etaMinutes > 0 && etaMinutes < 999) {
        _driverETAs[driverId] = '$etaMinutes min';
      }
    }

    // Обновляем маркеры через батчинг
    if (mounted) {
      _markersDirty = true;
    }
  }

  int _smoothEtaMinutes(String driverId, int newEta) {
    final prev = _lastEtaByDriver[driverId];
    if (prev == null) {
      _lastEtaByDriver[driverId] = newEta.toDouble();
      return newEta;
    }
    const alpha = 0.2;
    final smoothed = (prev * (1 - alpha)) + (newEta * alpha);
    _lastEtaByDriver[driverId] = smoothed;
    return smoothed.round();
  }

  void _disposeDriverMarkers() {
    _driverLocationsSubscription?.cancel();
    _markerAnimationTimer?.cancel();
    _markerBatchTimer?.cancel();
    _etaDebounce?.cancel();
    _driverMarkersNotifier.dispose();
  }
}
