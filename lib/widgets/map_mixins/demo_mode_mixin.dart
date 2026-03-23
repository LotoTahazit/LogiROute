part of '../delivery_map_widget.dart';

/// Демо-режим карты: сценарий поверх UI без изменения Firestore / фильтров.
mixin _DemoModeMixin on _DeliveryMapWidgetStateBase {
  // 🎬 AUTO DEMO MODE
  Timer? _demoTimer;
  int _demoStep = 0;
  double _demoOverlayOpacity = 0.0;
  double _demoMapScale = 1.0;
  double _demoPulseScale = 1.0;
  Timer? _pulseTimer;
  bool _demoTooltipVisible = false;
  double _demoTooltipOpacity = 0.0;
  int _demoActiveDriversCount = 0;
  bool _demoShowInactive = false;
  bool _demoShowDriverCard = false;
  Set<Polyline> _demoPolylines = {};
  Set<Marker> _demoMarkers = {};
  String? _demoTopMessage;
  double _demoTopMessageOpacity = 0.0;

  /// Сегменты по дорогам (OSRM); иначе пусто до загрузки / fallback.
  List<LatLng> _demoRoadWhToDriver = [];
  List<LatLng> _demoRoadDriverToTarget = [];
  Future<void>? _demoRoadsFuture;
  Timer? _demoDriverMoveTimer;

  /// Темп сценария демо (только `demoMode`).
  static const Duration _kDemoStepInterval = Duration(seconds: 5);
  static const Duration _kDemoBannerVisible = Duration(seconds: 3);
  static const Duration _kDemoBannerClearDelay = Duration(milliseconds: 550);
  static const Duration _kDemoRouteDrawDelay = Duration(milliseconds: 900);
  static const Duration _kDemoDriverMoveTick = Duration(milliseconds: 140);
  static const Duration _kDemoPulseTick = Duration(milliseconds: 1100);
  static const Duration _kDemoCameraDelay = Duration(milliseconds: 800);

  Marker _demoWarehouseMarker() {
    return Marker(
      markerId: const MarkerId('demo_warehouse'),
      position: LatLng(widget.warehouseLat, widget.warehouseLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'מחסן'),
    );
  }

  /// Точки демо рядом со складом — иначе фиксированные LatLng уезжают с экрана.
  LatLng get _demoDriverPosition {
    final w = LatLng(widget.warehouseLat, widget.warehouseLng);
    return LatLng(w.latitude + 0.007, w.longitude + 0.009);
  }

  LatLng get _demoTargetPosition {
    final d = _demoDriverPosition;
    return LatLng(d.latitude + 0.004, d.longitude + 0.005);
  }

  Marker _demoDriverMarker() => _demoDriverMarkerAt(_demoDriverPosition);

  Marker _demoDriverMarkerAt(LatLng position) {
    return Marker(
      markerId: const MarkerId('demo_driver'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'נהג'),
    );
  }

  Future<void> _ensureDemoRoadGeometry() async {
    if (_demoRoadWhToDriver.length >= 2 &&
        _demoRoadDriverToTarget.length >= 2) {
      return;
    }
    _demoRoadsFuture ??= _fetchDemoRoadsOnce();
    await _demoRoadsFuture;
  }

  Future<void> _fetchDemoRoadsOnce() async {
    final w = LatLng(widget.warehouseLat, widget.warehouseLng);
    final d = _demoDriverPosition;
    final t = _demoTargetPosition;
    final osrm = OsrmDirectionsService();
    try {
      final r1 = await osrm.getRoute(
        originLat: w.latitude,
        originLng: w.longitude,
        destinationLat: d.latitude,
        destinationLng: d.longitude,
      );
      final r2 = await osrm.getRoute(
        originLat: d.latitude,
        originLng: d.longitude,
        destinationLat: t.latitude,
        destinationLng: t.longitude,
      );
      if (!mounted) return;
      if (r1 != null && r2 != null) {
        final p1 =
            PolylineDecoder.decode(PolylineDecoder.sanitize(r1.polyline));
        final p2 =
            PolylineDecoder.decode(PolylineDecoder.sanitize(r2.polyline));
        if (p1.isNotEmpty && p2.isNotEmpty) {
          setState(() {
            _demoRoadWhToDriver = p1;
            _demoRoadDriverToTarget = p2;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('DEMO: OSRM $e');
    }
    if (!mounted) return;
    setState(() {
      _demoRoadWhToDriver = [w, d];
      _demoRoadDriverToTarget = [d, t];
    });
  }

  List<LatLng> _subsampleDemoPath(List<LatLng> path, {int maxLen = 96}) {
    if (path.length <= maxLen) return List<LatLng>.from(path);
    final out = <LatLng>[];
    final n = path.length;
    for (var i = 0; i < maxLen; i++) {
      final idx = ((i * (n - 1)) / (maxLen - 1)).round().clamp(0, n - 1);
      out.add(path[idx]);
    }
    return out;
  }

  void _startDemoDriverMoveAlongPath() {
    _demoDriverMoveTimer?.cancel();
    final w = LatLng(widget.warehouseLat, widget.warehouseLng);
    final path = <LatLng>[];
    if (_demoRoadWhToDriver.length >= 2) {
      path.addAll(_demoRoadWhToDriver);
      if (_demoRoadDriverToTarget.length >= 2) {
        path.addAll(_demoRoadDriverToTarget.skip(1));
      }
    } else {
      path.addAll([w, _demoDriverPosition, _demoTargetPosition]);
    }
    final animPath = _subsampleDemoPath(path);
    if (animPath.length < 2) return;
    var idx = 0;
    _demoDriverMoveTimer = Timer.periodic(_kDemoDriverMoveTick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      idx = math.min(idx + 1, animPath.length - 1);
      final pos = animPath[idx];
      setState(() {
        _demoMarkers = {
          _demoWarehouseMarker(),
          _demoDriverMarkerAt(pos),
          Marker(
            markerId: const MarkerId('demo_target'),
            position: _demoTargetPosition,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
      if (idx >= animPath.length - 1) {
        timer.cancel();
      }
    });
  }

  void _fitDemoSceneCamera() {
    if (_controller == null || !widget.demoMode || !mounted) return;
    final w = LatLng(widget.warehouseLat, widget.warehouseLng);
    final d = _demoDriverPosition;
    final t = _demoTargetPosition;
    final minLat =
        [w.latitude, d.latitude, t.latitude].reduce((a, b) => a < b ? a : b);
    final maxLat =
        [w.latitude, d.latitude, t.latitude].reduce((a, b) => a > b ? a : b);
    final minLng =
        [w.longitude, d.longitude, t.longitude].reduce((a, b) => a < b ? a : b);
    final maxLng =
        [w.longitude, d.longitude, t.longitude].reduce((a, b) => a > b ? a : b);
    const pad = 0.004;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - pad, minLng - pad),
      northeast: LatLng(maxLat + pad, maxLng + pad),
    );
    try {
      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
    } catch (e) {
      debugPrint('DEMO: fit camera: $e');
    }
  }

  /// Сброс демо (таймеры + UI) — при выключении demoMode или завершении сценария.
  void _stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _pulseTimer?.cancel();
    _pulseTimer = null;
    _demoDriverMoveTimer?.cancel();
    _demoDriverMoveTimer = null;
    _demoRoadsFuture = null;
    _demoStep = 0;
    if (!mounted) return;
    setState(() {
      _demoOverlayOpacity = 0.0;
      _demoMapScale = 1.0;
      _demoPulseScale = 1.0;
      _demoTooltipVisible = false;
      _demoTooltipOpacity = 0.0;
      _demoActiveDriversCount = 0;
      _demoShowInactive = false;
      _demoShowDriverCard = false;
      _demoPolylines = {};
      _demoMarkers = {};
      _demoRoadWhToDriver = [];
      _demoRoadDriverToTarget = [];
      _demoTopMessage = null;
      _demoTopMessageOpacity = 0.0;
    });
  }

  /// Запуск сценария с нуля (вкл. demoMode из родителя без remount карты).
  void _beginDemoFromToggle() {
    if (_demoTimer != null) return;
    _demoTimer?.cancel();
    _demoTimer = null;
    _pulseTimer?.cancel();
    _pulseTimer = null;
    _demoDriverMoveTimer?.cancel();
    _demoDriverMoveTimer = null;
    _demoRoadsFuture = null;
    _demoStep = 0;
    if (!mounted) return;
    setState(() {
      _demoOverlayOpacity = 0.0;
      _demoMapScale = 1.0;
      _demoPulseScale = 1.0;
      _demoTooltipVisible = false;
      _demoTooltipOpacity = 0.0;
      _demoActiveDriversCount = 0;
      _demoShowInactive = false;
      _demoShowDriverCard = false;
      _demoPolylines = {};
      _demoRoadWhToDriver = [];
      _demoRoadDriverToTarget = [];
      _demoMarkers = {_demoWarehouseMarker(), _demoDriverMarker()};
      _demoTopMessage = null;
      _demoTopMessageOpacity = 0.0;
    });
    _startDemo();
    _ensureDemoRoadGeometry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_kDemoCameraDelay, () {
        if (mounted) _fitDemoSceneCamera();
      });
    });
  }

  void _showDemoMessage(String text) {
    if (!mounted) return;
    setState(() {
      _demoTopMessage = text;
      _demoTopMessageOpacity = 1.0;
    });
    Future.delayed(_kDemoBannerVisible, () {
      if (!mounted) return;
      setState(() {
        _demoTopMessageOpacity = 0.0;
      });
      Future.delayed(_kDemoBannerClearDelay, () {
        if (!mounted) return;
        setState(() {
          if (_demoTopMessage == text) _demoTopMessage = null;
        });
      });
    });
  }

  /// Линия склад → «водитель» + то же сообщение, что маршруты построены.
  void _demoShowRoutesBuiltVisual() {
    if (!mounted) return;
    Future(() async {
      await _ensureDemoRoadGeometry();
      if (!mounted) return;
      final warehouse = LatLng(widget.warehouseLat, widget.warehouseLng);
      final seg = _demoRoadWhToDriver.length >= 2
          ? _demoRoadWhToDriver
          : [warehouse, _demoDriverPosition];
      final wNudge = LatLng(
        warehouse.latitude + 0.00015,
        warehouse.longitude + 0.00012,
      );
      setState(() {
        _demoPolylines = {
          Polyline(
            polylineId: const PolylineId('demo_from_warehouse'),
            color: Colors.greenAccent,
            width: 4,
            points: [seg.first, wNudge],
          ),
        };
      });
      _showDemoMessage('נבנו 3 מסלולים אופטימליים');
      Future.delayed(_kDemoRouteDrawDelay, () {
        if (!mounted) return;
        setState(() {
          _demoPolylines = {
            Polyline(
              polylineId: const PolylineId('demo_from_warehouse'),
              color: Colors.greenAccent,
              width: 4,
              points: seg,
            ),
          };
        });
        _fitDemoSceneCamera();
      });
    });
  }

  /// Каркас демо: шаги по `_kDemoStepInterval`.
  void _startDemo() {
    _demoTimer = Timer.periodic(_kDemoStepInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _demoStep++;

      switch (_demoStep) {
        case 1:
          _showDemoMessage('המחסן יצר 12 משלוחים');
          break;
        case 2:
          // דמו בלבד: פעולת טעינה מהמחסן למשאית (ללא שינוי לוגיקת prod).
          _showDemoMessage(
            'טעינה למשאית: 12 משלוחים הועמסו מהמחסן',
          );
          break;
        case 3:
          _demoShowRoutesBuiltVisual();
          break;
        case 4:
          _showDemoMessage('המשימות נשלחו לנהגים');
          break;
        case 5:
          _demoFadeInMap();
          break;
        case 6:
          _demoShowOnlyActiveDrivers();
          break;
        case 7:
          _demoHighlightDriver();
          break;
        case 8:
          _demoShowTooltip();
          break;
        case 9:
          _demoToggleInactiveDrivers();
          break;
        case 10:
          _stopPulse();
          timer.cancel();
          widget.onDemoFinished?.call();
          _stopDemo();
          break;
      }
    });
  }

  void _startPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(_kDemoPulseTick, (timer) {
      if (!mounted) return;
      setState(() {
        _demoPulseScale = _demoPulseScale == 1.0 ? 1.15 : 1.0;
      });
    });
  }

  void _stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    if (mounted) {
      setState(() => _demoPulseScale = 1.0);
    }
  }

  void _demoFadeInMap() {
    if (!mounted) return;
    setState(() {
      _demoOverlayOpacity = 0.0;
      _demoMapScale = 1.0;
    });
    debugPrint('DEMO: Fade in map');
  }

  void _demoShowOnlyActiveDrivers() {
    debugPrint('DEMO: Filter active drivers');
    if (!mounted) return;
    setState(() {
      _demoActiveDriversCount = 4;
      _demoShowInactive = false;
    });
  }

  void _demoHighlightDriver() {
    debugPrint('DEMO: Highlight driver');
    if (!mounted) return;
    Future(() async {
      await _ensureDemoRoadGeometry();
      if (!mounted) return;
      final w = LatLng(widget.warehouseLat, widget.warehouseLng);
      final demoDriver = _demoDriverPosition;
      final demoTarget = _demoTargetPosition;
      final ptsWh = _demoRoadWhToDriver.length >= 2
          ? _demoRoadWhToDriver
          : [w, demoDriver];
      final ptsDt = _demoRoadDriverToTarget.length >= 2
          ? _demoRoadDriverToTarget
          : [demoDriver, demoTarget];
      final startDriver = ptsWh.isNotEmpty ? ptsWh.first : w;
      setState(() {
        _demoShowDriverCard = true;
        _demoPolylines = {
          Polyline(
            polylineId: const PolylineId('demo_from_warehouse'),
            color: Colors.greenAccent,
            width: 4,
            points: ptsWh,
          ),
          Polyline(
            polylineId: const PolylineId('demo_route'),
            color: Colors.blueAccent,
            width: 5,
            points: ptsDt,
          ),
        };
        _demoMarkers = {
          _demoWarehouseMarker(),
          _demoDriverMarkerAt(startDriver),
          Marker(
            markerId: const MarkerId('demo_target'),
            position: demoTarget,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitDemoSceneCamera();
      });
      _startPulse();
      _startDemoDriverMoveAlongPath();
      Future.delayed(_kDemoCameraDelay, () {
        if (!mounted || _controller == null) return;
        _controller!.animateCamera(CameraUpdate.zoomIn());
      });
    });
  }

  void _demoShowTooltip() {
    debugPrint('DEMO: Show tooltip');
    if (!mounted) return;
    setState(() {
      _demoTooltipVisible = true;
      _demoTooltipOpacity = 1.0;
    });
  }

  void _demoToggleInactiveDrivers() {
    debugPrint('DEMO: Toggle inactive drivers');
    if (!mounted) return;
    setState(() {
      _demoShowInactive = true;
      _demoActiveDriversCount = 7;
    });
  }

  void _disposeDemo() {
    _demoTimer?.cancel();
    _pulseTimer?.cancel();
    _demoDriverMoveTimer?.cancel();
  }
}
