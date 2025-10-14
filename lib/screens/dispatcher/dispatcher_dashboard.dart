import 'add_point_dialog.dart';
import 'edit_point_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/route_service.dart';
import '../../services/client_service.dart';
import '../../services/locale_service.dart';
import '../../services/print_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_point.dart';
import '../../models/user_model.dart';
import '../../widgets/delivery_map_widget.dart';

class DispatcherDashboard extends StatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  State<DispatcherDashboard> createState() => _DispatcherDashboardState();
}

class _DispatcherDashboardState extends State<DispatcherDashboard> {
  final RouteService _routeService = RouteService();

  List<UserModel> _drivers = [];
  List<DeliveryPoint> _mapPoints = [];
  bool _isLoadingMap = false;
  String _lastUpdatedText = '';
  int _selectedTabIndex = 0;

  late final Stream<List<DeliveryPoint>> _pendingPointsStream;
  late final Stream<List<DeliveryPoint>> _routesStream;

  @override
  void initState() {
    super.initState();
    _loadDrivers();

    // ✅ Инициализация потоков один раз
    _pendingPointsStream = _routeService.getAllPendingPoints();
    _routesStream = _routeService.getAllRoutes();
  }

  Future<void> _loadDrivers() async {
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    setState(() {
      _drivers = allUsers.where((u) => u.isDriver).toList();
    });
  }

  /// 🏭 Устанавливает позицию склада для маршрутизации
  Future<void> _setWarehouseLocation() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Простой диалог для ввода координат склада
    final latController = TextEditingController(text: '32.48698');
    final lngController = TextEditingController(text: '34.982121');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Warehouse Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: InputDecoration(
                labelText: 'Latitude (Warehouse in Mishmarot)',
                hintText: '32.48698',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              decoration: InputDecoration(
                labelText: 'Longitude (Warehouse in Mishmarot)',
                hintText: '34.982121',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            child: Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true && latController.text.isNotEmpty && lngController.text.isNotEmpty) {
      try {
        final latitude = double.parse(latController.text);
        final longitude = double.parse(lngController.text);
        
        // Сохраняем позицию склада в Firestore
        await FirebaseFirestore.instance.collection('settings').doc('warehouse_location').set({
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': context.read<AuthService>().currentUser?.uid,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warehouse location saved: ($latitude, $longitude)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid coordinates: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    if (status == l10n.statusAssigned) return l10n.assigned;
    if (status == l10n.statusInProgress) return l10n.inProgress;
    if (status == l10n.statusCompleted) return l10n.completed;
    if (status == l10n.statusCancelled) return l10n.cancelled;
    if (status == l10n.statusPending) return l10n.pending;
      return status;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.routeCopiedToClipboard),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.printError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createRoute(List<DeliveryPoint> points) async {
    final l10n = AppLocalizations.of(context)!;
    if (points.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noPointsForRoute)));
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
                .map((d) => ListTile(
                      title: Text(d.name,
                          style: const TextStyle(color: Colors.black)),
                      subtitle: Text(
                        '${d.palletCapacity} ${l10n.pallets}',
                        style: const TextStyle(color: Colors.black),
                      ),
            onTap: () => Navigator.pop(context, d),
                    ))
                .toList(),
          ),
        ),
      ),
    );

    if (driver != null) {
      await _routeService.createOptimizedRoute(
        driver.uid,
        driver.name,
        points,
        driver.palletCapacity ?? 0,
        useDispatcherLocation: true, // Диспетчер использует позицию склада
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.routeCreated)));
        setState(() {}); // Обновляем UI
      }
    }
  }

  Future<void> _cancelRoute(String driverId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelRouteTitle),
        content: Text(l10n.cancelRouteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(l10n.cancelRoute),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('🛑 [Dispatcher] Cancelling route for driverId: $driverId');
      await _routeService.cancelRoute(driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.routeCancelled)),
        );
        setState(() {}); // Обновляем UI
      }
    }
  }

  Future<void> _changeDriver(String currentDriverId, String currentDriverName) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    final drivers = allUsers.where((u) => u.isDriver).toList();

    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDriversAvailable)),
      );
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
                .map((driver) => ListTile(
                      title: Text(driver.name,
                          style: const TextStyle(color: Colors.black)),
                      subtitle: Text(
                        '${driver.palletCapacity} ${l10n.pallets}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      onTap: () => Navigator.pop(context, driver),
                    ))
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
      await _routeService.changeRouteDriver(
        currentDriverId,
        newDriver.uid,
        newDriver.name,
        newDriver.palletCapacity ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.driverChangedTo(newDriver.name))),
        );
        setState(() {}); // Обновляем UI
      }
    }
  }

  /// Удалить отдельную точку доставки
  Future<void> _deletePoint(String pointId, String clientName) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.deletePoint} "$clientName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deletePoint(pointId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.pointDeleted}: $clientName')),
          );
          setState(() {}); // Обновляем UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  /// Редактировать точку доставки
  Future<void> _editPoint(DeliveryPoint point) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditPointDialog(point: point),
    );

    if (result != null) {
      try {
        // Проверяем, нужно ли отменить точку
        if (result['cancelPoint'] == true) {
          final l10n = AppLocalizations.of(context)!;
          await _routeService.cancelPoint(point.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.pointCancelled}: ${point.clientName}'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {}); // Обновляем UI
          }
          return;
        }

        // Обычное обновление точки
        await _routeService.updatePoint(
          point.id,
          result['urgency'] as String,
          result['orderInRoute'] as int?,
          result['address'] as String?,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Point updated: ${point.clientName}')),
          );
          setState(() {}); // Обновляем UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  /// Назначить водителя отдельной точке
  Future<void> _assignDriverToPoint(DeliveryPoint point) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final allUsers = await authService.getAllUsers();
    final drivers = allUsers.where((u) => u.isDriver).toList();

    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDriversAvailable)),
      );
      return;
    }

    final selectedDriver = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.assignDriver} - ${point.clientName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drivers.map((driver) => ListTile(
              title: Text(driver.name),
              subtitle: Text('${driver.palletCapacity} ${l10n.pallets}'),
              onTap: () => Navigator.pop(context, driver),
            )).toList(),
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
        await _routeService.assignPointToDriver(
          point.id,
          selectedDriver.uid,
          selectedDriver.name,
          selectedDriver.palletCapacity ?? 0,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.pointAssigned}: ${point.clientName} → ${selectedDriver.name}')),
          );
          setState(() {}); // Обновляем UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  /// Очистить только старые pending данные (не активные маршруты)
  Future<void> _clearOldData() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Pending Points'),
        content: Text('This will delete ONLY pending delivery points (not active routes). Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear Pending'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _routeService.clearOldTestData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pending points cleared, active routes preserved')),
        );
        setState(() {}); // Обновляем UI
      }
    }
  }

  /// Очистить все данные
  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('This will delete ALL delivery points. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _routeService.clearAllTestData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All data cleared')),
        );
        setState(() {}); // Обновляем UI
      }
    }
  }

  Future<void> _refreshMapPoints() async {
    setState(() => _isLoadingMap = true);
    try {
      final snapshot = await _routeService.getAllRoutes().first;
      
      // 🔍 Логируем что именно попадает на карту
      print('🗺️ [Map] Loaded ${snapshot.length} route points:');
      for (var p in snapshot) {
        print('  - ${p.clientName}: (${p.latitude}, ${p.longitude}) status=${p.status} order=${p.orderInRoute}');
      }
      
      if (mounted) {
        setState(() {
          _mapPoints = snapshot;
          _isLoadingMap = false;
          _lastUpdatedText = '🕓 ${TimeOfDay.now().format(context)}';
        });
      }
    } catch (e) {
      print('❌ [Map] Error loading points: $e');
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  Future<void> _showAllPointsOnMap() async {
    setState(() => _isLoadingMap = true);
    try {
      final snapshot = await _routeService.getAllPointsForMapTesting().first;
      
      // 🔍 Логируем ВСЕ точки
      print('🗺️ [Map] Loaded ALL ${snapshot.length} points:');
      for (var p in snapshot) {
        print('  - ${p.clientName}: (${p.latitude}, ${p.longitude}) status=${p.status} order=${p.orderInRoute}');
      }
      
      if (mounted) {
        setState(() {
          _mapPoints = snapshot;
          _isLoadingMap = false;
          _lastUpdatedText = '🕓 ${TimeOfDay.now().format(context)} (ALL)';
        });
      }
    } catch (e) {
      print('❌ [Map] Error loading all points: $e');
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  /// ❌ УДАЛЕНО: _fixOldCoordinates больше не нужна
  /// Все координаты теперь геокодируются корректно

  Future<void> _fixHebrewSearch() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fixHebrewSearch),
        content: Text(l10n.fixHebrewSearchDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(l10n.fixHebrewSearch),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final clientService = ClientService();
      await clientService.fixHebrewSearchIndex();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${l10n.hebrewSearchFixed}')),
        );
        setState(() {}); // Обновляем UI
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he' 
          ? TextDirection.rtl 
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dispatcher),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _setWarehouseLocation,
              tooltip: 'Set warehouse location',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.logout,
              onPressed: () => authService.signOut(),
            ),
          ],
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                onTap: (index) {
                  setState(() => _selectedTabIndex = index);
                  // Загружаем данные карты только при переходе на вкладку карты
                  if (index == 2 && _mapPoints.isEmpty && !_isLoadingMap) {
                    _refreshMapPoints();
                  }
                },
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
                          return const Center(child: CircularProgressIndicator());
                        }
                        final points = snapshot.data!;
                        return Column(
                          children: [
                            if (points.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.route),
                                  label: Text(l10n.createRoute),
                                  onPressed: () => _createRoute(points),
                                ),
                              ),
                            Expanded(
                              child: points.isEmpty
                                  ? Center(child: Text(l10n.noDeliveryPoints))
                                  : ListView.builder(
                                      itemCount: points.length,
                                      itemBuilder: (context, index) {
                                        final point = points[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          child: ListTile(
                                            title: Text(point.clientName),
                                            subtitle: Text(_getDisplayAddress(point)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${point.pallets} ${l10n.pallets}',
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                                          const SizedBox(width: 8),
                                                // Кнопка удаления точки
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  tooltip: l10n.delete,
                                                  onPressed: () => _deletePoint(point.id, point.clientName),
                                                ),
                                                // Кнопка редактирования
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                                  tooltip: 'Edit Point',
                                                  onPressed: () => _editPoint(point),
                                                ),
                                                // Кнопка назначения водителя
                                                IconButton(
                                                  icon: const Icon(Icons.person_add, color: Colors.blue),
                                                  tooltip: l10n.assignDriver,
                                                  onPressed: () => _assignDriverToPoint(point),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                    StreamBuilder<List<DeliveryPoint>>(
                      stream: _routesStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final allRoutes = snapshot.data!;
                        final Map<String, List<DeliveryPoint>> routesByDriver = {};
                        for (final route in allRoutes) {
                          final driverId = route.driverId ?? '';
                          routesByDriver.putIfAbsent(driverId, () => []).add(route);
                        }
                        
                        if (routesByDriver.isEmpty) {
                          return Center(child: Text(l10n.noRoutesYet));
                        }

                        return ListView(
                          children: routesByDriver.entries.map((entry) {
                            final driverId = entry.key;
                            final routes = entry.value;
                            final driverName =
                                routes.first.driverName ?? l10n.unknownDriver;
                            final totalPallets =
                                routes.fold(0, (sum, r) => sum + r.pallets);
                            
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ExpansionTile(
                                title: Text(driverName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${routes.length} ${l10n.points} • $totalPallets ${l10n.pallets}'),
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz),
                                        tooltip: l10n.changeDriver,
                                        onPressed: () =>
                                            _changeDriver(driverId, driverName),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel),
                                        tooltip: l10n.cancelRoute,
                                        onPressed: () => _cancelRoute(driverId),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print),
                                        tooltip: l10n.printRoute,
                                        onPressed: () =>
                                            _printDriverRoute(routes),
                                            ),
                                          ],
                                        ),
                                  ...routes.map((r) => ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Text(
                                            '${(r.orderInRoute ?? 0) + 1}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        title: Text(r.clientName),
                                        subtitle: Text(
                                            '${r.pallets} ${l10n.pallets} • ${_getDisplayAddress(r)}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          tooltip: 'Edit Point',
                                          onPressed: () => _editPoint(r),
                                        ),
                                      )),
                                      ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoadingMap ? null : _refreshMapPoints,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.refreshMap),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _clearOldData,
                                icon: const Icon(Icons.delete_sweep, color: Colors.orange),
                                label: const Text('Clear Pending'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _clearAllData,
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                label: const Text('Clear ALL'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showAllPointsOnMap,
                                icon: const Icon(Icons.visibility, color: Colors.purple),
                                label: const Text('Show All'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade100),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _fixHebrewSearch,
                                icon: const Icon(Icons.search, color: Colors.blue),
                                label: Text(l10n.fixHebrewSearch),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100),
                              ),
                              if (_lastUpdatedText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    _lastUpdatedText,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isLoadingMap
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : _mapPoints.isEmpty
                                  ? Center(
                                      child: Text(l10n.noDeliveryPoints),
                                    )
                                  : DeliveryMapWidget(points: _mapPoints),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: l10n.addPoint,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddPointDialog(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// 🏠 Получить адрес для отображения (временный приоритетнее основного)
  String _getDisplayAddress(DeliveryPoint point) {
    if (point.temporaryAddress != null && point.temporaryAddress!.isNotEmpty) {
      return point.temporaryAddress!;
    }
    return point.address;
  }
}
