import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/locale_service.dart';
import '../../services/print_service.dart';
import '../../services/invoice_print_service.dart';
import '../../services/company_context.dart';
import '../../utils/time_formatter.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../models/user_model.dart';
import '../../models/invoice.dart';
import 'add_point_dialog.dart';
import 'edit_point_dialog.dart';
import 'create_invoice_dialog.dart';
import 'widgets/dispatcher_app_bar_actions.dart';
import 'widgets/pending_points_tab.dart';
import 'widgets/active_routes_tab.dart';
import 'widgets/map_tab.dart';

class DispatcherDashboard extends StatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  State<DispatcherDashboard> createState() => _DispatcherDashboardState();
}

class _DispatcherDashboardState extends State<DispatcherDashboard> {
  List<UserModel> _drivers = [];
  bool _isLoadingMap = false;
  List<DeliveryPoint> _lastNonEmptyRoutes = [];
  String? _selectedDriverId;
  int _currentTabIndex = 0;

  Stream<List<DeliveryPoint>>? _pendingPointsStream;
  Stream<List<DeliveryPoint>>? _routesStream;
  Stream<List<DeliveryPoint>>? _autoCompletedStream;
  String? _currentCompanyId;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    setState(() {
      _drivers = allUsers.where((u) => u.isDriver).toList();
    });
  }

  Future<void> _autoDistributePallets(String companyId) async {
    final l10n = AppLocalizations.of(context)!;
    if (_drivers.isEmpty) {
      SnackbarHelper.showWarning(context, l10n.noDriversAvailable);
      return;
    }
    setState(() => _isLoadingMap = true);
    try {
      final routeService = RouteService(companyId: companyId);
      await routeService.autoDistributePalletsToDrivers(_drivers);
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.autoDistributeSuccess);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n.autoDistributeError}: $e');
      }
    } finally {
      setState(() => _isLoadingMap = false);
    }
  }

  Future<void> _setWarehouseLocation() async {
    final l10n = AppLocalizations.of(context)!;

    final latController = TextEditingController(text: '32.48698');
    final lngController = TextEditingController(text: '34.982121');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setWarehouseLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: InputDecoration(
                labelText: l10n.latitudeWarehouse,
                hintText: '32.48698',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: InputDecoration(
                labelText: l10n.longitudeWarehouse,
                hintText: '34.982121',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true &&
        latController.text.isNotEmpty &&
        lngController.text.isNotEmpty) {
      try {
        final latitude = double.parse(latController.text);
        final longitude = double.parse(lngController.text);

        await FirebaseFirestore.instance
            .collection('settings')
            .doc('warehouse_location')
            .set({
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': context.read<AuthService>().currentUser?.uid,
        });

        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Warehouse location saved: ($latitude, $longitude)',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Invalid coordinates: $e');
        }
      }
    }
  }

  Future<void> _printDriverRoute(List<DeliveryPoint> routes) async {
    if (routes.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final driverId = routes.first.driverId ?? '';
    final driverName = routes.first.driverName ?? l10n.unknownDriver;
    final driverCapacity = routes.first.driverCapacity ?? 0;

    final driver = UserModel(
      uid: driverId,
      email: '',
      name: driverName,
      role: l10n.roleDriver,
      palletCapacity: driverCapacity,
    );

    try {
      await PrintService.printRoute(driver: driver, points: routes);
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.routeCopiedToClipboard);
      }
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(context, l10n.printError);
      }
    }
  }

  Future<void> _printAllRouteInvoices(List<DeliveryPoint> routePoints) async {
    if (routePoints.isEmpty) return;

    // Создаём счета для всех точек маршрута
    final invoices = <Invoice>[];

    for (final point in routePoints) {
      final driver = _drivers.firstWhere(
        (d) => d.uid == point.driverId,
        orElse: () => UserModel(
          uid: point.driverId ?? '',
          email: '',
          name: point.driverName ?? 'Unknown',
          role: 'driver',
          vehicleNumber: '',
        ),
      );

      final invoice = await showDialog<Invoice>(
        context: context,
        builder: (context) => CreateInvoiceDialog(
          point: point,
          driver: driver,
        ),
      );

      if (invoice == null) {
        // Пользователь отменил - спрашиваем продолжить ли
        if (mounted) {
          final skip = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('דלג על לקוח?'),
              content: Text('דלג על ${point.clientName} והמשך?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('עצור הכל'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('דלג והמשך'),
                ),
              ],
            ),
          );
          if (skip != true) break;
        }
        continue;
      }
      invoices.add(invoice);
    }

    if (invoices.isNotEmpty && mounted) {
      try {
        final auth = context.read<AuthService>();
        await InvoicePrintService.printAllRouteInvoices(
          invoices,
          actorUid: auth.currentUser?.uid,
          actorName: auth.userModel?.name,
        );
        SnackbarHelper.showSuccess(
            context, '✅ ${invoices.length} חשבוניות הודפסו');
      } catch (e) {
        SnackbarHelper.showError(context, '❌ שגיאה בהדפסה: $e');
      }
    }
  }

  Future<void> _createRoute(
      String companyId, List<DeliveryPoint> points) async {
    final l10n = AppLocalizations.of(context)!;
    if (points.isEmpty) {
      SnackbarHelper.showWarning(context, l10n.noPointsForRoute);
      return;
    }

    final driver = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDriver),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _drivers
                .map(
                  (d) => ListTile(
                    title: Text(d.name,
                        style: const TextStyle(color: Colors.black)),
                    subtitle: Text('${d.palletCapacity} ${l10n.pallets}',
                        style: const TextStyle(color: Colors.black)),
                    onTap: () => Navigator.pop(context, d),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    if (driver != null) {
      final routeService = RouteService(companyId: companyId);
      await routeService.createOptimizedRoute(
        driver.uid,
        driver.name,
        points,
        driver.palletCapacity ?? 0,
        useDispatcherLocation: true,
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.routeCreated);
        setState(() {});
      }
    }
  }

  Future<void> _cancelRoute(
      String companyId, String driverId, String? routeId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogHelper.showConfirmation(
      context: context,
      title: l10n.cancelRouteTitle,
      content: l10n.cancelRouteDescription,
      confirmText: l10n.cancelRoute,
      cancelText: l10n.no,
      confirmColor: Colors.red.shade700,
    );

    if (confirmed) {
      final routeService = RouteService(companyId: companyId);
      await routeService.cancelRoute(driverId, routeId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.routeCancelled);
        setState(() {});
      }
    }
  }

  Future<void> _changeDriver(
    String companyId,
    String currentDriverId,
    String currentDriverName,
    String? routeId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    final drivers = allUsers.where((u) => u.isDriver).toList();

    if (drivers.isEmpty) {
      SnackbarHelper.showWarning(context, l10n.noDriversAvailable);
      return;
    }

    final newDriver = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectNewDriver),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drivers
                .where((d) => d.uid != currentDriverId)
                .map(
                  (driver) => ListTile(
                    title: Text(driver.name,
                        style: const TextStyle(color: Colors.black)),
                    subtitle: Text('${driver.palletCapacity} ${l10n.pallets}',
                        style: const TextStyle(color: Colors.black)),
                    onTap: () => Navigator.pop(context, driver),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (newDriver != null) {
      final routeService = RouteService(companyId: companyId);
      await routeService.changeRouteDriver(
        currentDriverId,
        newDriver.uid,
        newDriver.name,
        newDriver.palletCapacity ?? 0,
        routeId,
      );
      if (mounted) {
        SnackbarHelper.showSuccess(
            context, l10n.driverChangedTo(newDriver.name));
        setState(() {});
      }
    }
  }

  Future<void> _createInvoiceForPoint(DeliveryPoint point) async {
    final driver = _drivers.firstWhere(
      (d) => d.uid == point.driverId,
      orElse: () => UserModel(
        uid: point.driverId ?? '',
        email: '',
        name: point.driverName ?? 'Unknown',
        role: 'driver',
        vehicleNumber: '',
      ),
    );

    final invoice = await showDialog<Invoice>(
      context: context,
      builder: (context) => CreateInvoiceDialog(
        point: point,
        driver: driver,
      ),
    );

    if (invoice != null && mounted) {
      try {
        final auth = context.read<AuthService>();
        await InvoicePrintService.printFirstTime(
          invoice,
          actorUid: auth.currentUser?.uid,
          actorName: auth.userModel?.name,
        );
        // הצגת אזהרה אם הודפסו עותקים בלבד (ממתין למספר הקצאה)
        if (mounted &&
            invoice.requiresAssignment &&
            invoice.assignmentStatus != AssignmentStatus.approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ הודפסו עותקים בלבד — ממתין למספר הקצאה. המקור יודפס לאחר אישור רשות המסים.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        }
      } catch (e) {
        SnackbarHelper.showError(context, '❌ שגיאה בהדפסה: $e');
      }
    }
  }

  Future<void> _createDeliveryNoteForPoint(DeliveryPoint point) async {
    final driver = _drivers.firstWhere(
      (d) => d.uid == point.driverId,
      orElse: () => UserModel(
        uid: point.driverId ?? '',
        email: '',
        name: point.driverName ?? 'Unknown',
        role: 'driver',
        vehicleNumber: '',
      ),
    );

    final invoice = await showDialog<Invoice>(
      context: context,
      builder: (context) => CreateInvoiceDialog(
        point: point,
        driver: driver,
        documentType: InvoiceDocumentType.delivery,
      ),
    );

    if (invoice != null && mounted) {
      try {
        final auth = context.read<AuthService>();
        await InvoicePrintService.printFirstTime(
          invoice,
          actorUid: auth.currentUser?.uid,
          actorName: auth.userModel?.name,
        );
      } catch (e) {
        SnackbarHelper.showError(context, '❌ שגיאה בהדפסה: $e');
      }
    }
  }

  Future<void> _deletePoint(
      String companyId, String pointId, String clientName) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await DialogHelper.showDeleteConfirmation(
      context: context,
      title: l10n.delete,
      content: '${l10n.deletePoint} "$clientName"?',
    );

    if (confirmed) {
      try {
        final routeService = RouteService(companyId: companyId);
        await routeService.deletePoint(pointId);
        if (mounted) {
          SnackbarHelper.showSuccess(
              context, '${l10n.pointDeleted}: $clientName');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, '${l10n.error}: $e');
        }
      }
    }
  }

  Future<void> _editPoint(String companyId, DeliveryPoint point) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditPointDialog(point: point),
    );

    if (result != null) {
      try {
        final routeService = RouteService(companyId: companyId);

        if (result['cancelPoint'] == true) {
          final l10n = AppLocalizations.of(context)!;
          await routeService.cancelPoint(point.id);
          if (mounted) {
            SnackbarHelper.showWarning(
                context, '${l10n.pointCancelled}: ${point.clientName}');
            setState(() {});
          }
          return;
        }

        await routeService.updatePoint(
          point.id,
          result['urgency'] as String,
          result['orderInRoute'] as int?,
          result['address'] as String?,
        );
        if (mounted) {
          SnackbarHelper.show(context, 'Point updated: ${point.clientName}');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error: $e');
        }
      }
    }
  }

  Future<void> _assignDriverToPoint(
      String companyId, DeliveryPoint point) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    final drivers = allUsers.where((u) => u.isDriver).toList();

    if (drivers.isEmpty) {
      SnackbarHelper.showWarning(context, l10n.noDriversAvailable);
      return;
    }

    final selectedDriver = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.assignDriver} - ${point.clientName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drivers
                .map(
                  (driver) => ListTile(
                    title: Text(driver.name),
                    subtitle: Text('${driver.palletCapacity} ${l10n.pallets}'),
                    onTap: () => Navigator.pop(context, driver),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedDriver != null) {
      try {
        final routeService = RouteService(companyId: companyId);

        // ✅ Проверяем текущую загрузку водителя
        final driverRoutes =
            await routeService.getDriverPointsSnapshot(selectedDriver.uid);
        final currentLoad =
            driverRoutes.fold<int>(0, (sum, p) => sum + p.pallets);
        final newLoad = point.pallets;
        final totalLoad = currentLoad + newLoad;
        final capacity = selectedDriver.palletCapacity ?? 0;

        // ⚠️ Если превышает вместимость - показываем предупреждение
        bool shouldContinue = true;
        if (totalLoad > capacity && mounted) {
          shouldContinue = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.overloadWarning),
                  content: Text(
                    l10n.overloadWarningMessage(
                      selectedDriver.name,
                      currentLoad,
                      newLoad,
                      totalLoad,
                      capacity,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text(l10n.continueAnyway),
                    ),
                  ],
                ),
              ) ??
              false;
        }

        if (!shouldContinue) return;

        await routeService.assignPointToDriver(
          point.id,
          selectedDriver.uid,
          selectedDriver.name,
          selectedDriver.palletCapacity ?? 0,
        );
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            '${l10n.pointAssigned}: ${point.clientName} → ${selectedDriver.name}',
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, '${l10n.error}: $e');
        }
      }
    }
  }

  Future<void> _reopenPoint(String companyId, DeliveryPoint point) async {
    try {
      final routeService = RouteService(companyId: companyId);
      await routeService.reopenPoint(point.id);
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '✅ ${point.clientName} הוחזר למסלול',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '❌ שגיאה: $e');
      }
    }
  }

  Future<void> _reorderRoutePoints(
    List<DeliveryPoint> routes,
    int oldIndex,
    int newIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    try {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final reorderedRoutes = List<DeliveryPoint>.from(routes);
      final item = reorderedRoutes.removeAt(oldIndex);
      reorderedRoutes.insert(newIndex, item);

      double cumulativeTimeMinutes = 0;
      const double avgSpeedKmh = 50.0;
      const double stopTimeMinutes = 10.0;

      for (int i = 0; i < reorderedRoutes.length; i++) {
        final point = reorderedRoutes[i];

        double distanceKm = 0;
        if (i == 0) {
          distanceKm = _calculateDistance(
            32.48698,
            34.982121,
            point.latitude,
            point.longitude,
          );
        } else {
          final prevPoint = reorderedRoutes[i - 1];
          distanceKm = _calculateDistance(
            prevPoint.latitude,
            prevPoint.longitude,
            point.latitude,
            point.longitude,
          );
        }

        final travelTimeMinutes = (distanceKm / avgSpeedKmh) * 60;
        cumulativeTimeMinutes += travelTimeMinutes + stopTimeMinutes;

        final eta = TimeFormatter.formatDuration(cumulativeTimeMinutes);

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(effectiveCompanyId)
            .collection('delivery_points')
            .doc(point.id)
            .update({
          'orderInRoute': i,
          'eta': eta,
        });
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, '✅ ${l10n.routePointsReordered}');
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '❌ Ошибка: $e');
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    if (_currentCompanyId != effectiveCompanyId) {
      _currentCompanyId = effectiveCompanyId;
      final routeService = RouteService(companyId: effectiveCompanyId);
      _pendingPointsStream = routeService.getAllPendingPoints();
      _routesStream = routeService.getAllRoutes().map((routes) {
        _lastNonEmptyRoutes = List<DeliveryPoint>.from(routes);
        return routes;
      });
      _autoCompletedStream = routeService.getAutoCompletedPoints();
    }

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(l10n.dispatcher),
          actions: [
            DispatcherAppBarActions(
              onSetWarehouseLocation: _setWarehouseLocation,
              authService: authService,
            ),
          ],
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              if (authService.userModel?.isAdmin == true &&
                  authService.viewAsRole == 'dispatcher')
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.blue.shade300, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility,
                          color: Colors.blue.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.viewingAs} ${l10n.dispatcher}',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => authService.setViewAsRole(null),
                        icon: const Icon(Icons.admin_panel_settings, size: 18),
                        label: Text(l10n.backToAdmin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              TabBar(
                onTap: (index) => setState(() => _currentTabIndex = index),
                tabs: [
                  Tab(text: l10n.deliveryPoints),
                  Tab(text: l10n.routes),
                  Tab(text: l10n.map),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StreamBuilder<List<DeliveryPoint>>(
                      stream: _pendingPointsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return PendingPointsTab(
                          points: snapshot.data!,
                          companyId: effectiveCompanyId,
                          isLoadingMap: _isLoadingMap,
                          onCreateRoute: () =>
                              _createRoute(effectiveCompanyId, snapshot.data!),
                          onAutoDistribute: () =>
                              _autoDistributePallets(effectiveCompanyId),
                          onDeletePoint: (pointId, clientName) => _deletePoint(
                              effectiveCompanyId, pointId, clientName),
                          onEditPoint: (point) =>
                              _editPoint(effectiveCompanyId, point),
                          onAssignDriver: (point) =>
                              _assignDriverToPoint(effectiveCompanyId, point),
                        );
                      },
                    ),
                    StreamBuilder<List<DeliveryPoint>>(
                      stream: _routesStream,
                      initialData: const [],
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        return StreamBuilder<List<DeliveryPoint>>(
                          stream: _autoCompletedStream,
                          initialData: const [],
                          builder: (context, autoSnapshot) {
                            return ActiveRoutesTab(
                              routes: snapshot.data ?? [],
                              lastNonEmptyRoutes: _lastNonEmptyRoutes,
                              autoCompletedPoints: autoSnapshot.data ?? [],
                              onChangeDriver: (driverId, driverName, routeId) =>
                                  _changeDriver(effectiveCompanyId, driverId,
                                      driverName, routeId),
                              onCancelRoute: (driverId, routeId) =>
                                  _cancelRoute(
                                      effectiveCompanyId, driverId, routeId),
                              onPrintRoute: _printDriverRoute,
                              onReorderPoints: _reorderRoutePoints,
                              onCreateInvoice: _createInvoiceForPoint,
                              onCreateDeliveryNote: _createDeliveryNoteForPoint,
                              onPrintAllInvoices: _printAllRouteInvoices,
                              onEditPoint: (point) =>
                                  _editPoint(effectiveCompanyId, point),
                              onReopenPoint: (point) =>
                                  _reopenPoint(effectiveCompanyId, point),
                            );
                          },
                        );
                      },
                    ),
                    StreamBuilder<List<DeliveryPoint>>(
                      stream: _routesStream,
                      initialData: _lastNonEmptyRoutes,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        return MapTab(
                          routes: snapshot.data ?? [],
                          lastNonEmptyRoutes: _lastNonEmptyRoutes,
                          drivers: _drivers,
                          selectedDriverId: _selectedDriverId,
                          onDriverFilterChanged: (driverId) =>
                              setState(() => _selectedDriverId = driverId),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _currentTabIndex == 0
            ? FloatingActionButton(
                tooltip: l10n.addPoint,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddPointDialog(),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
