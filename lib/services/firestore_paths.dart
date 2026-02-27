import 'package:cloud_firestore/cloud_firestore.dart';

/// Централизованный хелпер для путей Firestore
///
/// ВАЖНО: Используйте этот класс для всех путей к коллекциям!
/// Это гарантирует что все данные читаются/пишутся в правильные места.
class FirestorePaths {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // ROOT LEVEL COLLECTIONS (глобальные, не зависят от компании)
  // ============================================================================

  /// Коллекция пользователей (глобальная)
  CollectionReference<Map<String, dynamic>> users() {
    return _firestore.collection('users');
  }

  /// Коллекция компаний (глобальная)
  CollectionReference<Map<String, dynamic>> companies() {
    return _firestore.collection('companies');
  }

  /// Документ компании
  DocumentReference<Map<String, dynamic>> companyDoc(String companyId) {
    return _firestore.collection('companies').doc(companyId);
  }

  /// Коллекция конфигурации (глобальная)
  CollectionReference<Map<String, dynamic>> config() {
    return _firestore.collection('config');
  }

  /// Коллекция адресов Израиля (глобальная, кеш)
  CollectionReference<Map<String, dynamic>> ilAddresses() {
    return _firestore.collection('il_addresses');
  }

  /// Коллекция мостов (глобальная)
  CollectionReference<Map<String, dynamic>> bridges() {
    return _firestore.collection('bridges');
  }

  // ============================================================================
  // COMPANY-SCOPED COLLECTIONS (зависят от компании)
  // ============================================================================

  // ============================================================================
  // WAREHOUSE MODULE — companies/{companyId}/warehouse/*
  // ============================================================================

  /// Коллекция типов коробок компании
  CollectionReference<Map<String, dynamic>> boxTypes(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('box_types');
  }

  /// Коллекция инвентаря компании
  CollectionReference<Map<String, dynamic>> inventory(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('inventory');
  }

  /// Коллекция типов товаров компании
  CollectionReference<Map<String, dynamic>> productTypes(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('product_types');
  }

  /// Коллекция инвентаризаций компании
  CollectionReference<Map<String, dynamic>> inventoryCounts(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('inventory_counts');
  }

  /// Коллекция истории инвентаря компании
  CollectionReference<Map<String, dynamic>> inventoryHistory(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('inventory_history');
  }

  // ============================================================================
  // LOGISTICS MODULE — companies/{companyId}/logistics/*
  // ============================================================================

  /// Коллекция клиентов компании (shared: logistics + accounting)
  CollectionReference<Map<String, dynamic>> clients(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('clients');
  }

  /// Коллекция точек доставки компании
  CollectionReference<Map<String, dynamic>> deliveryPoints(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_points');
  }

  /// Коллекция кешированных маршрутов компании
  CollectionReference<Map<String, dynamic>> cachedRoutes(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('cached_routes');
  }

  /// Коллекция цен компании
  CollectionReference<Map<String, dynamic>> prices(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('prices');
  }

  // ============================================================================
  // DISPATCHER MODULE — companies/{companyId}/dispatcher/*
  // ============================================================================

  /// Коллекция локаций водителей компании
  CollectionReference<Map<String, dynamic>> driverLocations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('dispatcher')
        .doc('_root')
        .collection('driver_locations');
  }

  // ============================================================================
  // ACCOUNTING MODULE — companies/{companyId}/accounting/* (ИЗОЛИРОВАННЫЙ)
  // ============================================================================

  /// Коллекция счетов компании (accounting)
  CollectionReference<Map<String, dynamic>> invoices(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices');
  }

  /// Коллекция счётчиков компании (accounting)
  CollectionReference<Map<String, dynamic>> counters(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('counters');
  }

  /// Документ счётчика счетов (accounting)
  DocumentReference<Map<String, dynamic>> invoiceCounter(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('counters')
        .doc('invoices');
  }

  /// Коллекция резервных копий (accounting)
  CollectionReference<Map<String, dynamic>> backups(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('backups');
  }

  // ============================================================================
  // CORE / SHARED — companies/{companyId}/*
  // ============================================================================

  /// Коллекция настроек компании
  CollectionReference<Map<String, dynamic>> companySettings(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings');
  }

  /// Коллекция дневных сводок компании
  CollectionReference<Map<String, dynamic>> dailySummaries(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('daily_summaries');
  }

  /// Коллекция уведомлений компании
  CollectionReference<Map<String, dynamic>> notifications(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('notifications');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Проверить что companyId не пустой
  void validateCompanyId(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      throw Exception(
        'CompanyId is required! Use CompanySelectionService.getEffectiveCompanyId() to get the correct companyId.',
      );
    }
  }
}
