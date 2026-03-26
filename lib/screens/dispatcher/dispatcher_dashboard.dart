import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/route_balance_service.dart';
import '../../services/locale_service.dart';
import '../../services/print_service.dart';
import '../../services/invoice_print_service.dart';
import '../../services/invoice_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../models/user_model.dart';
import '../../models/invoice.dart';
import 'add_point_dialog.dart';
import 'edit_point_dialog.dart';
import 'add_product_to_point_dialog.dart';
import 'create_invoice_dialog.dart';
import 'widgets/dispatcher_app_bar_actions.dart';
import 'widgets/pending_points_tab.dart';
import 'widgets/active_routes_tab.dart';
import 'widgets/map_tab.dart';
import 'widgets/dispatcher_demo_process_visual.dart';
import 'widgets/driver_workload_panel.dart';
import '../../widgets/notification_bell.dart';
import '../../services/company_cache.dart';

class DispatcherDashboard extends StatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  State<DispatcherDashboard> createState() => _DispatcherDashboardState();
}

class _DispatcherDashboardState extends State<DispatcherDashboard> {
  List<UserModel> _drivers = [];
  bool _isLoadingMap = false;
  List<DeliveryPoint> _lastNonEmptyRoutes = [];
  DateTime? _lastNonEmptyRoutesDate;
  String? _selectedDriverId;
  int _currentTabIndex = 0;

  Stream<List<DeliveryPoint>>? _pendingPointsStream;
  Stream<List<DeliveryPoint>>? _routesStream;
  Stream<List<DeliveryPoint>>? _mapRoutesStream;
  Stream<List<DeliveryPoint>>? _autoCompletedStream;
  String? _currentCompanyId;
  List<DeliveryPoint> _lastMapPoints = [];

  /// סיור הדגמה: נקודות → מסלולים → דמו מפה (ללא שינוי לוגיקת prod).
  Timer? _tourTimer;
  bool _tourActive = false;
  int _tourIndex = 0;
  bool _forceMapDemo = false;

  static const Duration _kTourStepDuration = Duration(seconds: 10);

  String _tourStepMessage(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.dispatcherTourStep1;
      case 1:
        return l10n.dispatcherTourStep2;
      case 2:
        return l10n.dispatcherTourStep3;
      case 3:
        return l10n.dispatcherTourStep4;
      case 4:
        return l10n.dispatcherTourStep5;
      default:
        return '';
    }
  }

  bool _shouldApplyUpdate(DeliveryPoint incoming, DeliveryPoint? local) {
    if (local == null) return true;
    if (incoming.updatedAt == null) return true;
    if (local.updatedAt == null) return true;

    return incoming.updatedAt!.isAfter(local.updatedAt!);
  }

  List<DeliveryPoint> _mergePointsByUpdatedAt(
    List<DeliveryPoint> incoming,
    List<DeliveryPoint> local,
  ) {
    final map = {for (var p in local) p.id: p};

    for (final p in incoming) {
      final existing = map[p.id];
      if (_shouldApplyUpdate(p, existing)) {
        map[p.id] = p;
      }
    }

    return map.values.toList();
  }

  /// Инициализация потоков — вынесено из build() для предотвращения race condition
  void _initStreams(String companyId) {
    final routeService = RouteService(companyId: companyId);
    _pendingPointsStream = routeService.getAllPendingPoints();
    _mapRoutesStream = routeService.getTodayRoutes();
    _routesStream = routeService.getTodayRoutes(includeCompleted: true).map((
      routes,
    ) {
      if (routes.isNotEmpty) {
        _lastNonEmptyRoutes = List<DeliveryPoint>.from(routes);
        _lastNonEmptyRoutesDate = DateTime.now();
      } else {
        if (_lastNonEmptyRoutesDate != null) {
          final now = DateTime.now();
          final todayMidnight = DateTime(now.year, now.month, now.day);
          if (_lastNonEmptyRoutesDate!.isBefore(todayMidnight)) {
            _lastNonEmptyRoutes = [];
            _lastNonEmptyRoutesDate = null;
          }
        }
      }
      return routes;
    });
    _autoCompletedStream = routeService.getAutoCompletedPoints();

    // ⚡ Предзагрузка кеша компании (clients, drivers, boxTypes — параллельно)
    final authService = context.read<AuthService>();
    CompanyCache.instance(companyId).preload(companyId, authService);
  }

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _tourTimer?.cancel();
    // Streams are created from Firestore snapshots() and managed by StreamBuilder,
    // so no manual cancellation needed — but clear references.
    _pendingPointsStream = null;
    _routesStream = null;
    _mapRoutesStream = null;
    _autoCompletedStream = null;
    super.dispose();
  }

  void _startProductTour() {
    _tourTimer?.cancel();
    setState(() {
      _tourActive = true;
      _tourIndex = 0;
      _currentTabIndex = 0;
      _forceMapDemo = false;
    });
    _scheduleTourNextStep();
  }

  void _scheduleTourNextStep() {
    _tourTimer?.cancel();
    _tourTimer = Timer(_kTourStepDuration, () {
      if (!mounted) return;
      setState(() {
        _tourIndex++;
        if (_tourIndex == 3) {
          _currentTabIndex = 1;
        } else if (_tourIndex == 5) {
          _currentTabIndex = 2;
          _tourActive = false;
          _forceMapDemo = true;
        }
      });
      if (_tourIndex < 5) {
        _scheduleTourNextStep();
      }
    });
  }

  void _cancelProductTour() {
    _tourTimer?.cancel();
    setState(() {
      _tourActive = false;
      _forceMapDemo = false;
      _tourIndex = 0;
    });
  }

  void _onMapTourDemoFinished() {
    if (!mounted) return;
    setState(() {
      _forceMapDemo = false;
    });
  }

  Future<void> _loadDrivers() async {
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    if (companyId.isEmpty) return;

    final cache = CompanyCache.instance(companyId);
    if (!cache.isLoaded) {
      await cache.preload(companyId, authService);
    } else if (cache.drivers.isEmpty) {
      await cache.reloadDrivers(authService);
    }
    if (!mounted) return;
    setState(() {
      _drivers = cache.drivers;
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
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
            context, l10n.autoDistributeFailed(e.toString()));
      }
    } finally {
      setState(() => _isLoadingMap = false);
    }
  }

  Future<void> _setWarehouseLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final uid = context.read<AuthService>().currentUser?.uid;
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: InputDecoration(
                labelText: l10n.longitudeWarehouse,
                hintText: '34.982121',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
      if (!mounted) return;
      try {
        final latitude = double.parse(latController.text);
        final longitude = double.parse(lngController.text);

        final companyCtx = CompanyContext.of(context);
        final companyId = companyCtx.requireCompanyId;
        await companyCtx.paths.companySettings(companyId).doc('config').set({
          'warehouseLat': latitude,
          'warehouseLng': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        }, SetOptions(merge: true));

        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            l10n.dispatcherWarehouseSaved('($latitude, $longitude)'),
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherInvalidCoordinates(e.toString()),
          );
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
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final companyId = auth.userModel?.companyId ?? '';

    // Создаём счета для всех точек маршрута
    final invoices = <Invoice>[];
    int skippedMakor = 0;

    for (final point in routePoints) {
      // === Проверка: מקור уже напечатан для этой точки? ===
      if (companyId.isNotEmpty && point.id.isNotEmpty) {
        final invoiceService = InvoiceService(companyId: companyId);
        final existing = await invoiceService.getInvoiceForDeliveryPoint(
          point.id,
          InvoiceDocumentType.invoice,
        );
        if (existing != null && existing.originalPrinted) {
          skippedMakor++;
          continue; // מקור כבר הודפס — пропускаем
        }
      }

      final driver = _drivers.firstWhere(
        (d) => d.uid == point.driverId,
        orElse: () => UserModel(
          uid: point.driverId ?? '',
          email: '',
          name: point.driverName ?? l10n.unknownDriver,
          role: 'driver',
          vehicleNumber: '',
        ),
      );

      if (!mounted) break;
      final invoice = await showDialog<Invoice>(
        context: context,
        builder: (context) => CreateInvoiceDialog(point: point, driver: driver),
      );

      if (invoice == null) {
        // Пользователь отменил - спрашиваем продолжить ли
        if (mounted) {
          final skip = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.skipClientTitle),
              content: Text(l10n.skipClientContent(point.clientName)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.stopAllButton),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.skipAndContinueButton),
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

    if (skippedMakor > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dispatcherSkippedInvoicesMakor(skippedMakor)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    if (invoices.isNotEmpty && mounted) {
      final auth = context.read<AuthService>();
      try {
        await InvoicePrintService.printAllRouteInvoices(
          invoices,
          actorUid: auth.currentUser?.uid,
          actorName: auth.userModel?.name,
        );
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            l10n.invoicesPrintedSuccess(invoices.length),
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, l10n.printingErrorMessage(e));
        }
      }
    }
  }

  Future<void> _createRoute(
    String companyId,
    List<DeliveryPoint> points,
  ) async {
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
                    title: Text(
                      d.name,
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      '${d.palletCapacity} ${l10n.pallets}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => Navigator.pop(context, d),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    if (driver != null) {
      try {
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
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _cancelRoute(
    String companyId,
    String driverId,
    String? routeId,
  ) async {
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
      await routeService.cancelRoutePoints(driverId, routeId);
      if (mounted) {
        setState(() {
          _lastNonEmptyRoutes = [];
          _lastNonEmptyRoutesDate = null;
        });
        SnackbarHelper.showSuccess(context, l10n.routeCancelled);
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

    if (drivers.isEmpty && mounted) {
      SnackbarHelper.showWarning(context, l10n.noDriversAvailable);
      return;
    }

    if (!mounted) return;
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
                    title: Text(
                      driver.name,
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      '${driver.palletCapacity} ${l10n.pallets}',
                      style: const TextStyle(color: Colors.black),
                    ),
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
          context,
          l10n.driverChangedTo(newDriver.name),
        );
      }
    }
  }

  Future<void> _createInvoiceForPoint(
    DeliveryPoint point, {
    InvoiceDocumentType documentType = InvoiceDocumentType.invoice,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final driver = _drivers.firstWhere(
      (d) => d.uid == point.driverId,
      orElse: () => UserModel(
        uid: point.driverId ?? '',
        email: '',
        name: point.driverName ?? l10n.unknownDriver,
        role: 'driver',
        vehicleNumber: '',
      ),
    );

    final auth = context.read<AuthService>();
    final companyId = auth.userModel?.companyId ?? '';

    // === УРОВЕНЬ 1: Pre-check — существует ли уже документ для этой точки ===
    if (companyId.isNotEmpty && point.id.isNotEmpty) {
      try {
        final invoiceService = InvoiceService(companyId: companyId);
        final existing = await invoiceService.getInvoiceForDeliveryPoint(
          point.id,
          documentType,
        );
        debugPrint(
          '🔍 [Makor] Pre-check: deliveryPoint=${point.id}, '
          'type=${documentType.name}, existing=${existing?.id}, '
          'originalPrinted=${existing?.originalPrinted}',
        );

        if (existing != null && mounted) {
          // Документ уже существует — показываем диалог повторной печати
          final result = await _showReprintDialog(existing);
          if (result != null && mounted) {
            await _executeReprint(existing, result, auth);
          }
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [Makor] Pre-check failed: $e — proceeding to dialog');
      }
    }

    // === Документ не найден — создаём через CreateInvoiceDialog ===
    if (!mounted) return;
    final invoice = await showDialog<Invoice>(
      context: context,
      builder: (context) => CreateInvoiceDialog(
        point: point,
        driver: driver,
        documentType: documentType,
      ),
    );

    if (invoice == null || !mounted) return;

    // === УРОВЕНЬ 2: Post-check — если CreateInvoiceDialog вернул существующий документ ===
    debugPrint(
      '🔍 [Makor] Post-check: invoice=${invoice.id}, '
      'originalPrinted=${invoice.originalPrinted}, '
      'seq=${invoice.sequentialNumber}, status=${invoice.status.name}',
    );

    if (invoice.originalPrinted) {
      // מקור כבר הודפס — НЕ вызываем printFirstTime!
      debugPrint(
          '🛡️ [Makor] Post-check caught: originalPrinted=true, showing reprint dialog');
      final result = await _showReprintDialog(invoice);
      if (result != null && mounted) {
        await _executeReprint(invoice, result, auth);
      }
      return;
    }

    // === Новый документ — печатаем впервые ===
    final messenger = ScaffoldMessenger.of(context);
    try {
      await InvoicePrintService.printFirstTime(
        invoice,
        actorUid: auth.currentUser?.uid,
        actorName: auth.userModel?.name,
      );
      // הצגת אזהרה אם הודפסו עותקים בלבד (ממתין למספר הקצאה)
      if (mounted &&
          invoice.requiresAssignment &&
          invoice.assignmentStatus != AssignmentStatus.approved) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.dispatcherCopiesOnlyPendingTax),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        SnackbarHelper.showError(
          context,
          loc.dispatcherPrintError(e.toString()),
        );
      }
    }
  }

  /// Показать диалог повторной печати (только העתק / נאמן למקור)
  Future<Map<String, dynamic>?> _showReprintDialog(Invoice invoice) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MakorExistsReprintDialog(invoice: invoice),
    );
  }

  /// Выполнить повторную печать
  Future<void> _executeReprint(
    Invoice invoice,
    Map<String, dynamic> result,
    AuthService auth,
  ) async {
    try {
      final copyType = result['copyType'] as InvoiceCopyType;
      final copies = result['copies'] as int;
      await InvoicePrintService.printInvoice(
        invoice,
        copyType: copyType,
        copies: copies,
        actorUid: auth.currentUser?.uid,
        actorName: auth.userModel?.name,
      );
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        SnackbarHelper.showError(
          context,
          loc.dispatcherPrintError(e.toString()),
        );
      }
    }
  }

  Future<void> _createDeliveryNoteForPoint(DeliveryPoint point) async {
    await _createInvoiceForPoint(
      point,
      documentType: InvoiceDocumentType.delivery,
    );
  }

  Future<void> _deletePoint(
    String companyId,
    String pointId,
    String clientName,
  ) async {
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
            context,
            '${l10n.pointDeleted}: $clientName',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _removePointFromRoute(
    String companyId,
    DeliveryPoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await DialogHelper.showDeleteConfirmation(
      context: context,
      title: l10n.removeFromRoute,
      content: l10n.removeFromRouteConfirm(point.clientName),
    );

    if (confirmed) {
      try {
        final routeService = RouteService(companyId: companyId);
        await routeService.removePointFromRoute(point.id);
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            '${l10n.pointRemovedFromRoute}: ${point.clientName}',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _editPoint(String companyId, DeliveryPoint point) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditPointDialog(point: point),
    );

    if (result != null) {
      try {
        final routeService = RouteService(companyId: companyId);

        if (result['cancelPoint'] == true) {
          await routeService.cancelPoint(point.id);
          if (mounted) {
            SnackbarHelper.showWarning(
              context,
              '${l10n.pointCancelled}: ${point.clientName}',
            );
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
          SnackbarHelper.show(
            context,
            l10n.pointUpdatedSuccess(point.clientName),
          );
        }
      } catch (e) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          SnackbarHelper.showError(
            context,
            loc.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _addProductToPoint(
    String companyId,
    DeliveryPoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (context) => AddProductToPointDialog(point: point),
    );

    if (result != null) {
      try {
        final routeService = RouteService(companyId: companyId);
        await routeService.updatePointBoxTypes(point.id, result);
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            '${l10n.productAdded}: ${point.clientName}',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _assignDriverToPoint(
    String companyId,
    DeliveryPoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    final drivers = allUsers.where((u) => u.isDriver).toList();

    if (drivers.isEmpty && mounted) {
      SnackbarHelper.showWarning(context, l10n.noDriversAvailable);
      return;
    }

    if (!mounted) return;
    final selectedDriver = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dispatcherAssignDriverTitle(point.clientName)),
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
        final driverRoutes = await routeService.getDriverPointsSnapshot(
          selectedDriver.uid,
        );
        final currentLoad = driverRoutes.fold<int>(
          0,
          (runningTotal, p) => runningTotal + p.pallets,
        );
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
            l10n.dispatcherPointAssignedToDriver(
              point.clientName,
              selectedDriver.name,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            l10n.dispatcherGenericError(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _reopenPoint(String companyId, DeliveryPoint point) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final routeService = RouteService(companyId: companyId);
      await routeService.reopenPoint(point.id);
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          l10n.dispatcherPointReturnedToRoute(point.clientName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.dispatcherGenericError(e.toString()),
        );
      }
    }
  }

  /// Ручное закрытие точки, если авто-закрытие не сработало.
  Future<void> _completePointManually(
    String companyId,
    DeliveryPoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogHelper.showConfirmation(
      context: context,
      title: l10n.dispatcherManualCompleteTitle,
      content: l10n.dispatcherManualCompleteMessage(point.clientName),
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
      confirmColor: Colors.green,
    );
    if (!confirmed || !mounted) return;
    try {
      final uid = context.read<AuthService>().currentUser?.uid ?? '';
      final routeService = RouteService(companyId: companyId);
      await routeService.updatePointStatus(
        point.id,
        DeliveryPoint.statusCompleted,
        updatedByUid: uid.isEmpty ? null : uid,
        autoCompleted: false,
      );
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          l10n.dispatcherPointCompletedManually(point.clientName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.dispatcherGenericError(e.toString()),
        );
      }
    }
  }

  /// 🖐️ Drag & Drop: назначить точку водителю через перетаскивание на карте
  Future<void> _handleDragAssign(
    String companyId,
    String pointId,
    String driverId,
    String driverName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Находим capacity водителя
      final driver = _drivers.firstWhere(
        (d) => d.uid == driverId,
        orElse: () => UserModel(
          uid: driverId,
          email: '',
          name: driverName,
          role: 'driver',
        ),
      );

      final routeService = RouteService(companyId: companyId);
      await routeService.assignPointToDriver(
        pointId,
        driverId,
        driverName,
        driver.palletCapacity ?? 0,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          l10n.dispatcherDragAssignSuccess(driverName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.dispatcherGenericError(e.toString()),
        );
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

      final balanceService = RouteBalanceService(companyId: effectiveCompanyId);
      await balanceService.recalculateETAsForPoints(reorderedRoutes);

      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.routePointsReordered);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.dispatcherGenericError(e.toString()),
        );
      }
    }
  }

  /// Автоматическая балансировка маршрутов
  /// Переносит точки с перегруженных маршрутов на лёгкие
  Future<void> _optimizeRouteByTime(
    String companyId,
    String driverId,
    String? routeId,
    List<DeliveryPoint> points,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text(l10n.optimizeTime),
        ]),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final routeService = RouteService(companyId: companyId);
      final changed =
          await routeService.optimizeRouteByTime(driverId, routeId, points);

      messenger.hideCurrentSnackBar();
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content:
              Text(changed ? l10n.routeOptimized : l10n.routeAlreadyOptimal),
          backgroundColor: changed ? Colors.green : null,
        ));
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.routeOptimizationFailed),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _balanceRoutes() async {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.balanceRoutes),
        content: Text(l10n.balanceRoutesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.balanceRoutes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (mounted) {
      SnackbarHelper.showInfo(context, l10n.balancingRoutes);
    }

    try {
      final balanceService = RouteBalanceService(companyId: effectiveCompanyId);
      final movedCount = await balanceService.balanceRoutes();

      if (mounted) {
        if (movedCount == -1) {
          SnackbarHelper.showInfo(context, l10n.routesAlreadyBalanced);
        } else if (movedCount > 0) {
          SnackbarHelper.showSuccess(
            context,
            l10n.movedPoints(movedCount.toString()),
          );
        } else {
          SnackbarHelper.showInfo(context, l10n.routesAlreadyBalanced);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          l10n.dispatcherGenericError(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();
    final narrow = MediaQuery.sizeOf(context).width < 600;

    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    if (_currentCompanyId != effectiveCompanyId &&
        effectiveCompanyId.isNotEmpty) {
      _currentCompanyId = effectiveCompanyId;
      _initStreams(effectiveCompanyId);
    }

    // Если companyId ещё не загружен — показываем loader
    if (effectiveCompanyId.isEmpty || _pendingPointsStream == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            IconButton(
              tooltip: _tourActive || _forceMapDemo
                  ? l10n.dispatcherTourStopTooltip
                  : l10n.dispatcherTourStartTooltip,
              icon: Icon(
                _tourActive || _forceMapDemo
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                color: Colors.white,
              ),
              onPressed: _tourActive || _forceMapDemo
                  ? _cancelProductTour
                  : _startProductTour,
            ),
            NotificationBell(companyId: effectiveCompanyId),
            DispatcherAppBarActions(
              onSetWarehouseLocation: _setWarehouseLocation,
              authService: authService,
            ),
          ],
        ),
        body: Stack(
          children: [
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  if (authService.userModel?.isAdmin == true &&
                      authService.viewAsRole == 'dispatcher')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.blue.shade300, width: 2),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.blue.shade900,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${l10n.viewingAs} ${l10n.dispatcher}',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => authService.setViewAsRole(null),
                            icon: const Icon(
                              Icons.admin_panel_settings,
                              size: 18,
                            ),
                            label: Text(l10n.backToAdmin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 🚛 Driver Workload Panel — горизонтальная полоса загрузки водителей
                  StreamBuilder<List<DeliveryPoint>>(
                    stream: _routesStream,
                    initialData: _lastNonEmptyRoutes,
                    builder: (context, snapshot) {
                      final routes = snapshot.data ?? [];
                      if (routes.isEmpty) return const SizedBox.shrink();
                      return DriverWorkloadPanel(
                          routes: routes, drivers: _drivers);
                    },
                  ),
                  TabBar(
                    isScrollable: narrow,
                    onTap: (index) => setState(() => _currentTabIndex = index),
                    tabs: [
                      Tab(text: l10n.deliveryPoints),
                      Tab(text: l10n.routes),
                      Tab(text: l10n.map),
                    ],
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        StreamBuilder<List<DeliveryPoint>>(
                          stream: _pendingPointsStream,
                          initialData: const [],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PendingPointsTab(
                              points: snapshot.data ?? const [],
                              companyId: effectiveCompanyId,
                              isLoadingMap: _isLoadingMap,
                              onCreateRoute: () => _createRoute(
                                effectiveCompanyId,
                                snapshot.data ?? const [],
                              ),
                              onAutoDistribute: () =>
                                  _autoDistributePallets(effectiveCompanyId),
                              onDeletePoint: (pointId, clientName) =>
                                  _deletePoint(
                                effectiveCompanyId,
                                pointId,
                                clientName,
                              ),
                              onEditPoint: (point) =>
                                  _editPoint(effectiveCompanyId, point),
                              onAssignDriver: (point) => _assignDriverToPoint(
                                  effectiveCompanyId, point),
                              onAddProduct: (point) =>
                                  _addProductToPoint(effectiveCompanyId, point),
                            );
                          },
                        ),
                        StreamBuilder<List<DeliveryPoint>>(
                          stream: _routesStream,
                          initialData: const [],
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  l10n.dispatcherGenericError(
                                    snapshot.error.toString(),
                                  ),
                                ),
                              );
                            }
                            return StreamBuilder<List<DeliveryPoint>>(
                              stream: _autoCompletedStream,
                              initialData: const [],
                              builder: (context, autoSnapshot) {
                                return ActiveRoutesTab(
                                  companyId: effectiveCompanyId,
                                  routes: snapshot.data ?? [],
                                  lastNonEmptyRoutes: _lastNonEmptyRoutes,
                                  autoCompletedPoints: autoSnapshot.data ?? [],
                                  onChangeDriver:
                                      (driverId, driverName, routeId) =>
                                          _changeDriver(
                                    effectiveCompanyId,
                                    driverId,
                                    driverName,
                                    routeId,
                                  ),
                                  onCancelRoute: (driverId, routeId) =>
                                      _cancelRoute(
                                    effectiveCompanyId,
                                    driverId,
                                    routeId,
                                  ),
                                  onPrintRoute: _printDriverRoute,
                                  onReorderPoints: _reorderRoutePoints,
                                  onCreateInvoice: _createInvoiceForPoint,
                                  onCreateDeliveryNote:
                                      _createDeliveryNoteForPoint,
                                  onPrintAllInvoices: _printAllRouteInvoices,
                                  onEditPoint: (point) =>
                                      _editPoint(effectiveCompanyId, point),
                                  onRemovePoint: (point) =>
                                      _removePointFromRoute(
                                    effectiveCompanyId,
                                    point,
                                  ),
                                  onReopenPoint: (point) =>
                                      _reopenPoint(effectiveCompanyId, point),
                                  onCompletePointManually: (point) =>
                                      _completePointManually(
                                    effectiveCompanyId,
                                    point,
                                  ),
                                  onBalanceRoutes: _balanceRoutes,
                                  onOptimizeRoute:
                                      (driverId, routeId, points) =>
                                          _optimizeRouteByTime(
                                    effectiveCompanyId,
                                    driverId,
                                    routeId,
                                    points,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        StreamBuilder<List<DeliveryPoint>>(
                          stream: _mapRoutesStream,
                          initialData: _lastNonEmptyRoutes,
                          builder: (context, pointsSnapshot) {
                            if (pointsSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  l10n.dispatcherGenericError(
                                    pointsSnapshot.error.toString(),
                                  ),
                                ),
                              );
                            }
                            final incomingPoints = pointsSnapshot.data ?? [];
                            final points = _mergePointsByUpdatedAt(
                              incomingPoints,
                              _lastMapPoints,
                            );
                            _lastMapPoints = points;
                            final carryRouteIds = incomingPoints
                                .where(
                                  (p) =>
                                      p.routeId != null &&
                                      p.routeId!.isNotEmpty &&
                                      DeliveryPoint.activeRouteStatuses
                                          .contains(p.status),
                                )
                                .map((p) => p.routeId!)
                                .toSet();
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future:
                                  RouteService(companyId: effectiveCompanyId)
                                      .getTodayRoutesForMap(
                                additionalRouteIds: carryRouteIds,
                              ),
                              initialData: const [],
                              builder: (context, routesSnapshot) {
                                final polylines = <String, String>{};
                                for (final doc in routesSnapshot.data ?? []) {
                                  if (doc == null) continue;
                                  // id документа routes == routeId; поле routeId иногда отсутствует у старых записей
                                  final id = doc['routeId']?.toString() ??
                                      doc['id']?.toString();
                                  final pl = doc['polyline']?.toString();
                                  if (id != null &&
                                      pl != null &&
                                      pl.isNotEmpty) {
                                    polylines[id] = pl;
                                  }
                                }
                                return MapTab(
                                  routes: points,
                                  lastNonEmptyRoutes: _lastNonEmptyRoutes,
                                  drivers: _drivers,
                                  selectedDriverId: _selectedDriverId,
                                  routePolylines: polylines,
                                  companyId: effectiveCompanyId,
                                  warehouseLat: CompanyCache.instance(
                                    effectiveCompanyId,
                                  ).warehouseLat,
                                  warehouseLng: CompanyCache.instance(
                                    effectiveCompanyId,
                                  ).warehouseLng,
                                  demoModeFromTour: _forceMapDemo,
                                  onTourDemoFinished: _onMapTourDemoFinished,
                                  onDriverFilterChanged: (driverId) => setState(
                                      () => _selectedDriverId = driverId),
                                  onPointDragToDriver:
                                      (pointId, driverId, driverName) =>
                                          _handleDragAssign(
                                    effectiveCompanyId,
                                    pointId,
                                    driverId,
                                    driverName,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_tourActive && _tourIndex < 5)
              Positioned.fill(
                child: Material(
                  color: Colors.black54,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              tooltip: l10n.close,
                              onPressed: _cancelProductTour,
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 450),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: DispatcherDemoProcessVisual(
                                          key: ValueKey(_tourIndex),
                                          stepIndex: _tourIndex,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Divider(),
                                      const SizedBox(height: 14),
                                      Text(
                                        _tourStepMessage(l10n, _tourIndex),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            l10n.dispatcherTourProgress(_tourIndex + 1, 5),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: !_tourActive && _currentTabIndex == 0
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

/// Диалог: מקור уже напечатан — только נאמן למקור или העתק
class _MakorExistsReprintDialog extends StatefulWidget {
  final Invoice invoice;
  const _MakorExistsReprintDialog({required this.invoice});

  @override
  State<_MakorExistsReprintDialog> createState() =>
      _MakorExistsReprintDialogState();
}

class _MakorExistsReprintDialogState extends State<_MakorExistsReprintDialog> {
  InvoiceCopyType _selectedType = InvoiceCopyType.copy;
  int _copies = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final docTypeLabel = widget.invoice.documentType ==
            InvoiceDocumentType.delivery
        ? l10n.makorDocTypeDeliveryNote
        : widget.invoice.documentType == InvoiceDocumentType.taxInvoiceReceipt
            ? l10n.makorDocTypeTaxInvoiceReceipt
            : l10n.makorDocTypeTaxInvoice;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.makorOriginalPrintedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.makorInvoiceLineNumbered(
                    docTypeLabel,
                    '${widget.invoice.sequentialNumber}',
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(l10n.makorClientLine(widget.invoice.clientName)),
                const SizedBox(height: 8),
                Text(
                  l10n.makorBooksLawWarning,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.makorChoosePrintType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: Icon(
              _selectedType == InvoiceCopyType.copy
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(l10n.makorCopy),
            subtitle: Text(
              l10n.makorCopySubtitle(widget.invoice.copiesPrinted + 1),
            ),
            onTap: () => setState(() => _selectedType = InvoiceCopyType.copy),
          ),
          ListTile(
            leading: Icon(
              _selectedType == InvoiceCopyType.replacesOriginal
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(l10n.makorTrueToOriginal),
            subtitle: Text(l10n.makorTrueToOriginalSubtitle),
            onTap: () => setState(
              () => _selectedType = InvoiceCopyType.replacesOriginal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.makorCopyQuantity),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
              ),
              Text(
                '$_copies',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _copies < 5 ? () => setState(() => _copies++) : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, {
            'copyType': _selectedType,
            'copies': _copies,
          }),
          icon: const Icon(Icons.print),
          label: Text(l10n.makorPrintButton),
        ),
      ],
    );
  }
}
