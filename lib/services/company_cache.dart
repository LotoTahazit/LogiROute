import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../models/company_config.dart';
import 'client_service.dart';
import 'box_type_service.dart';
import 'auth_service.dart';

/// Единый кеш данных компании.
/// Загружается один раз при входе, используется всеми экранами.
/// Уменьшает Firestore reads на 70-90%.
class CompanyCache {
  static CompanyCache? _instance;
  static String? _currentCompanyId;

  List<ClientModel> _clients = [];
  List<UserModel> _drivers = [];
  List<Map<String, dynamic>> _boxTypes = [];
  CompanyConfig _config = CompanyConfig.defaults;
  bool _isLoaded = false;

  CompanyCache._();

  /// Получить инстанс для компании (singleton per company)
  static CompanyCache instance(String companyId) {
    if (_instance == null || _currentCompanyId != companyId) {
      _instance = CompanyCache._();
      _currentCompanyId = companyId;
    }
    return _instance!;
  }

  bool get isLoaded => _isLoaded;
  List<ClientModel> get clients => _clients;
  List<UserModel> get drivers => _drivers;
  List<Map<String, dynamic>> get boxTypes => _boxTypes;
  CompanyConfig get config => _config;
  double get warehouseLat => _config.warehouseLat;
  double get warehouseLng => _config.warehouseLng;
  String get warehouseAddress => _config.warehouseAddress;

  /// Предзагрузка всех данных компании
  Future<void> preload(String companyId, AuthService authService) async {
    if (_isLoaded && _currentCompanyId == companyId) return;

    final stopwatch = Stopwatch()..start();

    try {
      // Параллельная загрузка всех данных
      final results = await Future.wait([
        ClientService(companyId: companyId).getAllClients(),
        authService.getAllUsers(),
        BoxTypeService(companyId: companyId).getAllBoxTypes(),
        _loadCompanyConfig(companyId),
      ]);

      _clients = results[0] as List<ClientModel>;
      final allUsers = results[1] as List<UserModel>;
      _drivers = allUsers.where((u) => u.isDriver).toList();
      _boxTypes = results[2] as List<Map<String, dynamic>>;
      // config loaded via side-effect in _loadCompanyConfig
      _isLoaded = true;

      stopwatch.stop();
      debugPrint(
          '✅ [CompanyCache] Preloaded in ${stopwatch.elapsedMilliseconds}ms: '
          '${_clients.length} clients, ${_drivers.length} drivers, '
          '${_boxTypes.length} boxTypes, warehouse=(${_config.warehouseLat}, ${_config.warehouseLng})');
    } catch (e) {
      debugPrint('❌ [CompanyCache] Preload error: $e');
    }
  }

  Future<void> _loadCompanyConfig(String companyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('config')
          .get();

      if (doc.exists) {
        _config = CompanyConfig.fromMap(doc.data()!);
        debugPrint(
            '🏭 [CompanyCache] Config loaded: warehouse=(${_config.warehouseLat}, ${_config.warehouseLng})');
      } else {
        _config = CompanyConfig.defaults;
        debugPrint('🏭 [CompanyCache] No config doc, using defaults');
      }
    } catch (e) {
      debugPrint('⚠️ [CompanyCache] Config load error (using defaults): $e');
      _config = CompanyConfig.defaults;
    }
  }

  /// Обновить координаты склада
  Future<void> updateWarehouseLocation(
      double lat, double lng, String address) async {
    if (_currentCompanyId == null) return;
    _config = CompanyConfig(
      warehouseLat: lat,
      warehouseLng: lng,
      warehouseAddress: address,
      workStartHour: _config.workStartHour,
      workStartMinute: _config.workStartMinute,
      workEndHour: _config.workEndHour,
      workEndMinute: _config.workEndMinute,
      workDays: _config.workDays,
      autoCompleteRadiusMeters: _config.autoCompleteRadiusMeters,
      autoCompleteWaitMinutes: _config.autoCompleteWaitMinutes,
      maxPointsPerRoute: _config.maxPointsPerRoute,
      geofenceMinLat: _config.geofenceMinLat,
      geofenceMaxLat: _config.geofenceMaxLat,
      geofenceMinLng: _config.geofenceMinLng,
      geofenceMaxLng: _config.geofenceMaxLng,
      defaultPalletCapacity: _config.defaultPalletCapacity,
      minBoxesPerPallet: _config.minBoxesPerPallet,
      maxBoxesPerPallet: _config.maxBoxesPerPallet,
    );

    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_currentCompanyId!)
          .collection('settings')
          .doc('config')
          .set(_config.toMap());
      debugPrint('✅ [CompanyCache] Warehouse updated: ($lat, $lng)');
    } catch (e) {
      debugPrint('❌ [CompanyCache] Warehouse update error: $e');
    }
  }

  /// Обновить всю конфигурацию
  Future<void> updateConfig(CompanyConfig newConfig) async {
    if (_currentCompanyId == null) return;
    _config = newConfig;

    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_currentCompanyId!)
          .collection('settings')
          .doc('config')
          .set(_config.toMap());
      debugPrint('✅ [CompanyCache] Config updated');
    } catch (e) {
      debugPrint('❌ [CompanyCache] Config update error: $e');
    }
  }

  /// Инвалидировать кеш (после изменений)
  void invalidateClients() {
    _clients = [];
    if (_currentCompanyId != null) {
      ClientService.clearCache(_currentCompanyId!);
    }
  }

  void invalidateBoxTypes() {
    _boxTypes = [];
    if (_currentCompanyId != null) {
      BoxTypeService.clearCache(_currentCompanyId!);
    }
  }

  void invalidateDrivers() {
    _drivers = [];
  }

  /// Перезагрузить только водителей (без полного preload)
  Future<void> reloadDrivers(AuthService authService) async {
    try {
      final allUsers = await authService.getAllUsers();
      _drivers = allUsers.where((u) => u.isDriver).toList();
      debugPrint(
          '🔄 [CompanyCache] Drivers reloaded: ${_drivers.length} drivers');
    } catch (e) {
      debugPrint('❌ [CompanyCache] Drivers reload error: $e');
    }
  }

  /// Полный сброс
  static void reset() {
    _instance = null;
    _currentCompanyId = null;
  }
}
