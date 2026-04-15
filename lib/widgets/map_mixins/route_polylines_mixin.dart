part of '../delivery_map_widget.dart';

/// Полилинии маршрутов, прогресс водителей (Waze-эффект), треки, camera fit.
mixin _RoutePolylinesMixin on _DeliveryMapWidgetStateBase {
  /// ✅ ВАЖНО: не вызываем async внутри setState
  /// Debounce + guard от конкурентных вызовов.
  /// Маркеры показываются сразу, полилинии подгружаются асинхронно.
  /// Камера анимируется только при первой загрузке polylines.
  @override
  Future<void> _updateMapData() async {
    if (!mounted || _isUpdatingMap) return;
    _isUpdatingMap = true;

    try {
      final markers = _buildPointMarkers();

      // Показываем маркеры сразу, не дожидаясь OSRM
      if (!mounted) return;
      debugPrint(
          'MAP BUILD: delivery=${markers.length} drivers=${_driverMarkersNotifier.value.length}');
      setState(() {
        _deliveryMarkers = markers;
        // Driver markers управляются через ValueNotifier
      });

      // Фитим камеру по маркерам при первой загрузке (пока нет полилиний)
      if (!_initialCameraFitDone && markers.isNotEmpty && _controller != null) {
        _fitCameraToMarkers(markers);
      }

      // Полилинии подгружаются в фоне
      final polylines = await _buildRoutePolylines();

      if (!mounted) return;
      _syncDriverRoadCacheFromPolylines(polylines);
      setState(() {
        _polylines = polylines;
        // Driver markers управляются через ValueNotifier
      });
      _updateDriverProgressPolylines();

      // Фитим камеру по полилиниям (точнее, чем по маркерам)
      if (!_initialCameraFitDone &&
          _polylines.isNotEmpty &&
          _controller != null) {
        _initialCameraFitDone = true;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted || _controller == null) return;
        final allPolyPoints = <LatLng>[];
        for (final pl in _polylines) {
          allPolyPoints.addAll(pl.points);
        }
        if (allPolyPoints.isEmpty) return;
        final bounds = _calculatePolylineBounds(allPolyPoints);
        await _moveToBoundsSafe(bounds, animated: true);
      }
    } finally {
      _isUpdatingMap = false;
    }
  }

  /// Фитим камеру по маркерам (быстрый первый фит, пока полилинии не загрузились)
  void _fitCameraToMarkers(Set<Marker> markers) {
    if (markers.isEmpty || _controller == null) return;
    final positions = markers
        .map((m) => m.position)
        .where((p) => DeliveryPoint.isValidCoordinates(p.latitude, p.longitude))
        .toList();
    if (positions.length < 2) return;

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _moveToBoundsSafe(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      animated: true,
    );
  }

  /// Исполнение: подключение водителя к плану (не меняет основной маршрут).
  Set<Polyline> _buildDriverToRoutePolyline(
    String driverId,
    List<DeliveryPoint> activePoints,
  ) {
    final r = <Polyline>{};
    if (!_executionUsesDriverOrigin) return r;
    final driverPos = _driverCurrentPositions[driverId];
    if (driverPos == null || activePoints.isEmpty) return r;
    final firstPoint = activePoints.first;
    const epsilon = 0.00005; // ~5 м (шум GPS)
    if ((driverPos.latitude - firstPoint.latitude).abs() < epsilon &&
        (driverPos.longitude - firstPoint.longitude).abs() < epsilon) {
      return r;
    }
    r.add(
      Polyline(
        polylineId: PolylineId('driver_to_route_$driverId'),
        points: [
          driverPos,
          LatLng(firstPoint.latitude, firstPoint.longitude),
        ],
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
        color: Colors.blue,
        zIndex: 2,
      ),
    );
    return r;
  }

  Set<Marker> _buildPointMarkers() {
    debugPrint(
      '🗺️ [Map] Updating markers with ${widget.points.length} points',
    );
    final l10n = AppLocalizations.of(context);

    final markers = <Marker>{};

    // 🏭 Добавляем маркер склада (ВСЕГДА первый)
    markers.add(
      Marker(
        markerId: const MarkerId('warehouse'),
        position: LatLng(widget.warehouseLat, widget.warehouseLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🏭 ${l10n?.warehouse ?? "Склад"}',
          snippet: l10n?.warehouseStartPoint ?? 'Starting point for all routes',
        ),
        zIndexInt: 999, // Склад всегда сверху
      ),
    );

    // Добавляем маркеры точек доставки
    for (final point in widget.points) {
      // 🛡️ Пропускаем точки с невалидными координатами (за пределами Израиля)
      if (!_isInIsraelBounds(point.latitude, point.longitude)) continue;

      // Определяем цвет маркера в зависимости от статуса
      BitmapDescriptor markerColor;
      if (point.status == DeliveryPoint.statusCompleted ||
          point.status == DeliveryPoint.statusCancelled) {
        // Серый для завершенных/отмененных
        markerColor = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      } else {
        // Цвет водителя для активных точек
        final driverKey = point.driverId ?? 'unknown';
        final driverIndex = widget.points
            .where((p) => p.driverId != null)
            .map((p) => p.driverId)
            .toSet()
            .toList()
            .indexOf(driverKey);
        final driverColor = _getDriverColor(driverKey, driverIndex);
        final hue = HSVColor.fromColor(driverColor).hue;
        markerColor = BitmapDescriptor.defaultMarkerWithHue(hue);
      }

      // Определяем, можно ли перетаскивать эту точку
      final isDraggable = widget.enableDragDrop &&
          point.status != DeliveryPoint.statusCompleted &&
          point.status != DeliveryPoint.statusCancelled;

      markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: markerColor,
          draggable: isDraggable,
          onDragStart:
              isDraggable ? (position) => _onPointDragStart(point) : null,
          onDragEnd: isDraggable
              ? (newPosition) => _onPointDragEnd(point, newPosition)
              : null,
          infoWindow: InfoWindow(
            title: point.clientName,
            snippet: _buildMarkerSnippet(point, l10n),
          ),
          alpha: (point.status == DeliveryPoint.statusCompleted ||
                  point.status == DeliveryPoint.statusCancelled)
              ? 0.32
              : 1.0, // Полупрозрачные для завершенных
        ),
      );
    }

    debugPrint(
      '🗺️ [Map] Created ${markers.length} markers (including warehouse)',
    );
    return markers;
  }

  Future<Set<Polyline>> _buildRoutePolylines() async {
    debugPrint(
      '🗺️ [Map] Updating polylines with ${widget.points.length} points',
    );

    // Если нет точек доставки, не строим маршрут
    if (widget.points.isEmpty) {
      return {};
    }

    final validRoutePoints = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .toList();

    // Если нет назначенных точек, не строим маршрут
    if (validRoutePoints.isEmpty) {
      return {};
    }

    // Сортируем по driverName, затем по orderInRoute
    validRoutePoints.sort((a, b) {
      final driverCompare = (a.driverName ?? '').compareTo(b.driverName ?? '');
      if (driverCompare != 0) return driverCompare;
      return a.orderInRoute.compareTo(b.orderInRoute);
    });

    // Создаем сигнатуру маршрута для кеширования
    final routeSignature = validRoutePoints
        .map(
          (p) => '${p.driverId}:${p.orderInRoute}:${p.latitude}:${p.longitude}',
        )
        .join('|');

    // Если маршрут не изменился, возвращаем текущие полилинии
    if (_lastRouteSignature == routeSignature && _polylines.isNotEmpty) {
      return _polylines;
    }

    // Маршрут изменился — очищаем кеш декодированных полилиний
    _decodedPolylineCache.clear();
    debugPrint('🔄 [Map] Route signature changed, clearing polyline cache');

    for (var p in validRoutePoints) {
      debugPrint(
        '  - ${p.clientName}: driver=${p.driverName}, order=${p.orderInRoute}',
      );
    }

    // Если уже загружаем маршрут, возвращаем текущие полилинии (не пустые!)
    if (_isLoadingRoute) {
      debugPrint(
        '⏳ [Map] Route loading in progress, keeping current polylines',
      );
      return _polylines.isNotEmpty ? _polylines : {};
    }
    _isLoadingRoute = true;
    _lastRouteSignature =
        routeSignature; // Сохраняем сигнатуру сразу, чтобы не дублировать запросы

    try {
      if (mounted) setState(() => _polylines = {});
      final Map<String, List<DeliveryPoint>> routesByKey = {};

      for (final p in validRoutePoints) {
        final routeKey = (p.routeId != null && p.routeId!.isNotEmpty)
            ? p.routeId!
            : (p.driverId ?? p.driverName ?? 'unknown');
        routesByKey.putIfAbsent(routeKey, () => []).add(p);
      }

      final Set<Polyline> result = {};

      for (final entry in routesByKey.entries) {
        final routeKey = entry.key;
        final points = entry.value;
        final driverKey = points.first.driverId ?? routeKey;

        if (points.isEmpty) continue;

        // Сортируем точки по orderInRoute
        points.sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

        // Разделяем на завершённые и активные (с учётом HE/RU статусов в Firestore)
        final completedPoints = points.where((p) {
          final s = DeliveryPoint.normalizeStatus(p.status);
          return s == DeliveryPoint.statusCompleted ||
              s == DeliveryPoint.statusCancelled;
        }).toList();
        final activePoints = points.where((p) {
          final s = DeliveryPoint.normalizeStatus(p.status);
          return s != DeliveryPoint.statusCompleted &&
              s != DeliveryPoint.statusCancelled;
        }).toList();

        debugPrint(
          '🏭 [Map] Route $routeKey / driver $driverKey: ${completedPoints.length} completed, ${activePoints.length} active',
        );

        // 🏭 ВАЖНО: новый маршрут на карте НЕ проводим через выполненные остановки —
        // только «хвост» от последней выполненной к оставшимся активным (и кэш целиком
        // не используем после появления completed, иначе линия тянется через старые точки).

        final warehouseLat = widget.warehouseLat;
        final warehouseLng = widget.warehouseLng;
        const activeRouteColor = Color(0xFF1FA34A);
        const passedRouteColor = Color(0xFF78A887);

        String? persistedPolyline;
        for (final point in points) {
          final encoded = point.routePolyline;
          if (encoded != null && encoded.isNotEmpty) {
            persistedPolyline = encoded;
            break;
          }
        }
        final routeId = points.first.routeId;
        final cachedPolyline = routeId != null
            ? (widget.routePolylines[routeId] ?? persistedPolyline)
            : persistedPolyline;

        if (cachedPolyline != null && cachedPolyline.isNotEmpty) {
          final cacheKey = routeId ?? routeKey;
          var decoded = _decodedPolylineCache[cacheKey];
          if (decoded == null) {
            decoded = PolylineDecoder.decode(cachedPolyline, precision: 5);
            if (PolylineDecoder.isValid(decoded)) {
              if (decoded.length > 500) {
                final simplified = <LatLng>[];
                for (var i = 0; i < decoded.length; i += 3) {
                  simplified.add(decoded[i]);
                }
                simplified.add(decoded.last);
                decoded = simplified;
              }
              _decodedPolylineCache[cacheKey] = decoded;
            }
          }
          if (decoded.isNotEmpty && PolylineDecoder.isValid(decoded)) {
            result.add(
              Polyline(
                polylineId: PolylineId('route_${routeKey}_active'),
                points: decoded,
                width: 8,
                color: activeRouteColor,
                zIndex: 1,
              ),
            );
            if (completedPoints.isNotEmpty) {
              final completedHead = _polylineHeadToAnchor(
                decoded,
                LatLng(
                  completedPoints.last.latitude,
                  completedPoints.last.longitude,
                ),
              );
              if (completedHead != null && completedHead.length > 1) {
                result.add(
                  Polyline(
                    polylineId: PolylineId('route_${routeKey}_completed'),
                    points: completedHead,
                    width: 8,
                    color: passedRouteColor,
                    zIndex: 10,
                  ),
                );
              }
            }
            if (activePoints.isNotEmpty) {
              result.addAll(
                _buildDriverToRoutePolyline(driverKey, activePoints),
              );
            }
            continue;
          }
        }

        // Возврат на склад — прямая пунктирная линия (без OSRM запроса)
        if (activePoints.isEmpty && completedPoints.isNotEmpty) {
          final lastCompleted = completedPoints.last;
          result.add(
            Polyline(
              polylineId: PolylineId('route_${routeKey}_return'),
              points: [
                LatLng(lastCompleted.latitude, lastCompleted.longitude),
                LatLng(warehouseLat, warehouseLng),
              ],
              width: 6,
              color: Colors.grey.shade300,
              patterns: [PatternItem.dash(12), PatternItem.gap(8)],
              zIndex: 4,
            ),
          );
        }

        // Строим цветной маршрут для активных точек
        if (activePoints.isNotEmpty) {
          // Нет cached polyline — ждём пока _saveOsrmPolylineBackground
          // сохранит его в Firestore. StreamBuilder подхватит автоматически.
          debugPrint(
            '⏳ [Map] No cached polyline for route $routeKey — waiting for background OSRM save',
          );
          result.addAll(_buildDriverToRoutePolyline(driverKey, activePoints));
        }
      }

      _lastRouteSignature = routeSignature;
      return result;
    } catch (e, st) {
      _lastRouteSignature = null;
      debugPrint('❌ [Map] _buildRoutePolylines: $e');
      debugPrint('$st');
      // Не рисуем «прямые» при любой ошибке (часто CORS OSRM на web).
      return {};
    } finally {
      _isLoadingRoute = false;
    }
  }

  void _fitBounds() async {
    if (widget.points.isEmpty || _controller == null) return;

    try {
      // Фильтруем точки с нулевыми координатами и за пределами Израиля
      final validPoints =
          widget.points.where((p) => p.hasValidCoordinates).toList();
      if (validPoints.isEmpty) return;

      final latLngPoints =
          validPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
      final bounds = _calculatePolylineBounds(latLngPoints);
      await _moveToBoundsSafe(bounds, animated: true);
    } catch (e) {
      debugPrint('❌ [DeliveryMap] Error animating camera to bounds: $e');
    }
  }

  /// GPS-треки за последние 24 часа.
  /// Только водители из текущих/показанных точек; фильтр GPS-прыжков > 2 км.
  Future<void> _loadDriverTracks() async {
    debugPrint('🛤️ [Track] _loadDriverTracks called');

    if (widget.clearMapMode) {
      if (!mounted) return;
      setState(() {
        _trackPolylines = {};
      });
      return;
    }

    // Обычно треки привязаны к водителям из текущего маршрута.
    // Fallback нужен, когда GPS есть, а points временно пусты/не догрузились.
    final routeDriverIds = widget.points
        .where((p) => p.driverId != null && p.driverId!.isNotEmpty)
        .map((p) => p.driverId!)
        .toSet()
        .toList();
    final allDriverIds = routeDriverIds.isNotEmpty
        ? routeDriverIds
        : _driverCurrentPositions.keys.where((id) => id.isNotEmpty).toList();

    debugPrint(
      routeDriverIds.isNotEmpty
          ? '🛤️ [Track] Found ${allDriverIds.length} drivers in route: $allDriverIds'
          : '🛤️ [Track] Route drivers missing, fallback to live GPS drivers: $allDriverIds',
    );

    if (allDriverIds.isEmpty) {
      debugPrint('🛤️ [Track] No drivers in current route, skipping tracks');
      if (!mounted) return;
      setState(() {
        _trackPolylines = {};
      });
      return;
    }

    try {
      final tracks = <Polyline>{};
      final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)),
      );

      for (final driverId in allDriverIds) {
        final driverRef = FirestorePaths.driverLocationsOf(
          widget.companyId,
        ).doc(driverId);

        // Загружаем историю (retention/cleanup — в сервисе локации, не по календарю)
        QuerySnapshot historySnap;
        try {
          historySnap = await driverRef
              .collection('history')
              .where('timestamp', isGreaterThanOrEqualTo: cutoff)
              .orderBy('timestamp')
              .get();
        } catch (e) {
          debugPrint('⚠️ [Track] Firestore query failed for $driverId: $e');
          // Fallback: последние 200 записей с локальной фильтрацией по 24 часам
          try {
            historySnap = await driverRef
                .collection('history')
                .orderBy('timestamp', descending: true)
                .limit(200)
                .get();
          } catch (e2) {
            debugPrint(
              '❌ [Track] Fallback query also failed for $driverId: $e2',
            );
            continue;
          }
        }

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${historySnap.docs.length} history docs',
        );

        // Фильтруем точки: убираем плохую точность и готовим их в хронологическом порядке.
        final rawPoints = <Map<String, dynamic>>[];
        for (final doc in historySnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 50.0;
          final timestamp = data['timestamp'];
          final trackTime = timestamp is Timestamp ? timestamp.toDate() : null;
          if (lat == null || lng == null) continue;
          if (lat == 0 && lng == 0) continue;
          if (trackTime == null || trackTime.isBefore(cutoff.toDate()))
            continue;
          // Отбрасываем точки с плохой точностью (> 200м)
          if (accuracy > 200) continue;
          rawPoints.add({'lat': lat, 'lng': lng, 'ts': trackTime});
        }

        try {
          final currentDoc = await driverRef.get();
          final currentData = currentDoc.data();
          final lat = (currentData?['latitude'] as num?)?.toDouble();
          final lng = (currentData?['longitude'] as num?)?.toDouble();
          final accuracy =
              (currentData?['accuracy'] as num?)?.toDouble() ?? 50.0;
          final timestamp = currentData?['timestamp'];
          final trackTime = timestamp is Timestamp ? timestamp.toDate() : null;
          if (lat != null &&
              lng != null &&
              (lat != 0 || lng != 0) &&
              trackTime != null &&
              !trackTime.isBefore(cutoff.toDate()) &&
              accuracy <= 200) {
            rawPoints.add({'lat': lat, 'lng': lng, 'ts': trackTime});
          }
        } catch (e) {
          debugPrint(
              '⚠️ [Track] Failed to read current driver doc for $driverId: $e');
        }

        rawPoints.sort(
            (a, b) => (a['ts'] as DateTime).compareTo(b['ts'] as DateTime));

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${rawPoints.length} valid points after filtering',
        );

        if (rawPoints.length < 2) continue;

        // Режем только нереалистичные "телепорты".
        // Простого порога по расстоянию мало: между редкими валидными GPS-точками
        // водитель может реально проехать >2 км, особенно между двумя маршрутами.
        final segments = <List<LatLng>>[];
        var currentSegment = <LatLng>[];
        for (int i = 0; i < rawPoints.length; i++) {
          final curr = rawPoints[i];
          final currLatLng =
              LatLng(curr['lat'] as double, curr['lng'] as double);
          if (currentSegment.isEmpty) {
            currentSegment.add(currLatLng);
            continue;
          }
          final prev = rawPoints[i - 1];
          final dist = _gpsDistanceKm(
            (prev['lat'] as double),
            (prev['lng'] as double),
            (curr['lat'] as double),
            (curr['lng'] as double),
          );
          final prevTs = prev['ts'] as DateTime;
          final currTs = curr['ts'] as DateTime;
          final seconds = math.max(1, currTs.difference(prevTs).inSeconds);
          final impliedSpeedKmh = dist / (seconds / 3600.0);
          final isTeleport =
              dist > 20.0 || (dist > 3.0 && impliedSpeedKmh > 160.0);
          if (isTeleport) {
            if (currentSegment.length >= 2) {
              segments.add(currentSegment);
            }
            currentSegment = [currLatLng];
          } else {
            currentSegment.add(currLatLng);
          }
        }
        if (currentSegment.length >= 2) {
          segments.add(currentSegment);
        }

        if (segments.isEmpty) {
          debugPrint(
            '🛤️ [Track] Driver $driverId: no valid segments after gap split',
          );
          continue;
        }

        const trackOuterColor = Color(0x6677AFFF);
        const trackInnerColor = Color(0xFF2F80ED);

        for (int i = 0; i < segments.length; i++) {
          tracks.add(
            Polyline(
              polylineId: PolylineId('track_${driverId}_${i}_outer'),
              points: segments[i],
              width: 12,
              color: trackOuterColor,
              zIndex: 5,
            ),
          );
          tracks.add(
            Polyline(
              polylineId: PolylineId('track_${driverId}_${i}_inner'),
              points: segments[i],
              width: 7,
              color: trackInnerColor,
              zIndex: 6,
            ),
          );
        }

        debugPrint(
          '🛤️ [Track] Driver $driverId: ${segments.length} track segments added',
        );
      }

      if (!mounted) return;
      setState(() {
        _trackPolylines = tracks;
      });
      debugPrint('🛤️ [Track] Loaded ${tracks.length} driver tracks total');
    } catch (e) {
      debugPrint('❌ [Track] Error loading tracks: $e');
    }
  }

  /// Кэш дорожной геометрии из основного слоя полилиний (OSRM), для прогресса водителя.
  void _syncDriverRoadCacheFromPolylines(Set<Polyline> polylines) {
    _driverRoadPolylinePoints.clear();
    for (final pl in polylines) {
      final id = pl.polylineId.value;
      if (!id.startsWith('route_') || !id.endsWith('_active')) continue;
      if (pl.points.length < 2) continue;
      final routeKey = id.substring(6, id.length - 7);
      String? driverKey;
      for (final point in widget.points) {
        final pointKey =
            point.routeId ?? point.driverId ?? point.driverName ?? 'unknown';
        if (pointKey == routeKey &&
            point.driverId != null &&
            point.driverId!.isNotEmpty) {
          driverKey = point.driverId;
          break;
        }
      }
      if (driverKey == null || driverKey.isEmpty) continue;
      _driverRoadPolylinePoints[driverKey] = List<LatLng>.from(pl.points);
    }
  }

  /// Polyline маршрута для водителя — только дороги (как в основном слое / Firestore), без хорд между стопами.
  List<LatLng> _getDriverRoutePolyline(String driverId) {
    final built = _driverRoadPolylinePoints[driverId];
    if (built != null && built.length >= 2) return built;

    for (final entry in widget.routePolylines.entries) {
      final routeId = entry.key;
      final encodedPolyline = entry.value;
      final routePoints =
          widget.points.where((p) => p.routeId == routeId).toList();
      if (routePoints.isNotEmpty && routePoints.first.driverId == driverId) {
        try {
          final decoded = PolylineDecoder.decode(encodedPolyline, precision: 5);
          if (decoded.length >= 2) return decoded;
        } catch (e) {
          debugPrint('❌ [Map] Error decoding polyline for route $routeId: $e');
        }
      }
    }

    final driverPoints =
        widget.points.where((p) => p.driverId == driverId).where((p) {
      final s = DeliveryPoint.normalizeStatus(p.status);
      return s != DeliveryPoint.statusCompleted &&
          s != DeliveryPoint.statusCancelled;
    }).toList()
          ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    for (final p in driverPoints) {
      final enc = p.routePolyline;
      if (enc != null && enc.isNotEmpty) {
        try {
          final decoded = PolylineDecoder.decode(enc, precision: 5);
          if (decoded.length >= 2) return decoded;
        } catch (_) {}
      }
    }

    return [];
  }

  /// Обновляет полилинии прогресса для всех водителей (эффект Waze)
  @override
  void _updateDriverProgressPolylines() {
    if (!mounted) return;

    final progressPolylines = <Polyline>{};

    // Получаем всех активных водителей
    final activeDrivers = _driverCurrentPositions.keys.toList();

    for (final driverId in activeDrivers) {
      final driverPos = _driverCurrentPositions[driverId];
      if (driverPos == null) continue;

      // Получаем маршрут водителя
      final routePolylines = _getDriverRoutePolyline(driverId);
      if (routePolylines.isEmpty) continue;

      // Разделяем маршрут на пройденную и оставшуюся части
      final routeSplit = RouteProgressService.splitRouteAtDriverPosition(
        driverPos,
        routePolylines,
      );
      final passedRoute = routeSplit['passedRoute'] as List<LatLng>;
      final remainingRoute = routeSplit['remainingRoute'] as List<LatLng>;

      const activeRouteColor = Color(0xFF1FA34A);
      const passedRouteColor = Color(0xFF78A887);

      // 🛣️ Пройденный маршрут: приглушённый зелёный, той же толщины.
      if (passedRoute.length > 1) {
        progressPolylines.add(
          Polyline(
            polylineId: PolylineId('passed_$driverId'),
            points: passedRoute,
            color: passedRouteColor,
            width: 8,
            zIndex: 12,
          ),
        );
      }

      // 🛣️ Оставшийся маршрут (цвет водителя)
      if (remainingRoute.length > 1) {
        progressPolylines.add(
          Polyline(
            polylineId: PolylineId('remaining_$driverId'),
            points: remainingRoute,
            color: activeRouteColor,
            width: 8,
            zIndex: 13, // над полным polyline (zIndex 1)
          ),
        );
      }
    }

    setState(() {
      _driverProgressPolylines = progressPolylines;
    });
  }
}
