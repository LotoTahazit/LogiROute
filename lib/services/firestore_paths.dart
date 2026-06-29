import 'package:cloud_firestore/cloud_firestore.dart';

/// FIRESTORE SCHEMA
/// This file is the single source of truth for all Firestore paths.
/// Direct Firestore paths are forbidden elsewhere in the codebase
/// (except logging/debug strings).
///
/// Централизованный хелпер для путей Firestore
///
/// ВАЖНО: Используйте этот класс для всех путей к коллекциям!
/// Это гарантирует что все данные читаются/пишутся в правильные места.
class FirestorePaths {
  final FirebaseFirestore _firestore;

  FirestorePaths({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  /// Platform Error Center — platform/system/errors
  CollectionReference<Map<String, dynamic>> platformSystemErrors() {
    return _firestore
        .collection('platform')
        .doc('system')
        .collection('errors');
  }

  /// Stack trace / private metadata (super_admin only)
  DocumentReference<Map<String, dynamic>> platformErrorPrivate(String errorId) {
    return _firestore
        .collection('platform')
        .doc('system')
        .collection('error_private')
        .doc(errorId);
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

  /// Typed ref: product_types
  CollectionReference<Map<String, dynamic>> productTypesRef(String companyId) {
    return productTypes(companyId);
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

  /// Typed ref: delivery_points
  CollectionReference<Map<String, dynamic>> deliveryPointsRef(
      String companyId) {
    return deliveryPoints(companyId);
  }

  /// Коллекция маршрутов компании (1 документ = 1 маршрут водителя за день)
  CollectionReference<Map<String, dynamic>> routes(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('routes');
  }

  /// Typed ref: routes
  CollectionReference<Map<String, dynamic>> routesRef(String companyId) {
    return routes(companyId);
  }

  /// Коллекция drivers компании (логистический справочник водителей)
  CollectionReference<Map<String, dynamic>> drivers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('drivers');
  }

  /// Typed ref: drivers
  CollectionReference<Map<String, dynamic>> driversRef(String companyId) {
    return drivers(companyId);
  }

  /// Коллекция trucks компании
  CollectionReference<Map<String, dynamic>> trucks(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('trucks');
  }

  /// Документ маршрута
  DocumentReference<Map<String, dynamic>> routeDoc(
      String companyId, String routeId) {
    return routes(companyId).doc(routeId);
  }

  /// Подколлекция stop-ов внутри маршрута
  CollectionReference<Map<String, dynamic>> routeStops(
      String companyId, String routeId) {
    return routeDoc(companyId, routeId).collection('stops');
  }

  /// Документ stop-а внутри маршрута
  DocumentReference<Map<String, dynamic>> stopDoc(
      String companyId, String routeId, String stopId) {
    return routeStops(companyId, routeId).doc(stopId);
  }

  /// Подколлекция событий внутри stop-а
  CollectionReference<Map<String, dynamic>> stopEvents(
      String companyId, String routeId, String stopId) {
    return stopDoc(companyId, routeId, stopId).collection('events');
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

  /// История маршрутов компании
  CollectionReference<Map<String, dynamic>> routeHistory(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('route_history');
  }

  /// События доставки компании
  CollectionReference<Map<String, dynamic>> deliveryEvents(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_events');
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

  /// Live GPS: companies/{companyId}/driver_locations/{driverId}
  /// (единственный runtime path для health/onboarding/dispatcher map)
  CollectionReference<Map<String, dynamic>> driverLocations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('driver_locations');
  }

  /// Alias — тот же path, что [driverLocations].
  CollectionReference<Map<String, dynamic>> driverLocationsRef(
      String companyId) {
    return driverLocations(companyId);
  }

  /// Документ GPS конкретного водителя
  DocumentReference<Map<String, dynamic>> driverLocation(
      String companyId, String driverId) {
    return driverLocations(companyId).doc(driverId);
  }

  /// История GPS: driver_locations/{driverId}/history
  CollectionReference<Map<String, dynamic>> driverLocationHistory(
      String companyId, String driverId) {
    return driverLocation(companyId, driverId).collection('history');
  }

  // --- Static shortcuts (для сервисов без инстанса FirestorePaths) ---

  /// Static: коллекция delivery_points компании
  static CollectionReference<Map<String, dynamic>> deliveryPointsOf(
      String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_points');
  }

  /// Static: коллекция routes компании
  static CollectionReference<Map<String, dynamic>> routesOf(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('routes');
  }

  /// Static: архив завершённых точек маршрута (Cloud Function archiveOldRoutes).
  static CollectionReference<Map<String, dynamic>> archiveRoutesOf(
      String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('archive_routes');
  }

  /// Device session lock: companies/{companyId}/driver_sessions/{driverId}
  CollectionReference<Map<String, dynamic>> driverSessions(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('driver_sessions');
  }

  /// Saved import column mappings: companies/{companyId}/import_mappings/{id}
  CollectionReference<Map<String, dynamic>> importMappings(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('import_mappings');
  }

  /// Static: коллекция driver_locations компании (GPS runtime path)
  static CollectionReference<Map<String, dynamic>> driverLocationsOf(
      String companyId) {
    return FirestorePaths(firestore: FirebaseFirestore.instance)
        .driverLocations(companyId);
  }

  /// Static: driver_sessions (device lock)
  static CollectionReference<Map<String, dynamic>> driverSessionsOf(
      String companyId) {
    return FirestorePaths(firestore: FirebaseFirestore.instance)
        .driverSessions(companyId);
  }

  /// Static: import_mappings
  static CollectionReference<Map<String, dynamic>> importMappingsOf(
      String companyId) {
    return FirestorePaths(firestore: FirebaseFirestore.instance)
        .importMappings(companyId);
  }

  /// Static: история GPS водителя
  static CollectionReference<Map<String, dynamic>> driverHistoryOf(
      String companyId, String driverId) {
    return driverLocationsOf(companyId).doc(driverId).collection('history');
  }

  /// Static: документ конфигурации компании
  static DocumentReference<Map<String, dynamic>> companyConfigOf(
      String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('config');
  }

  /// График смен для карты / логики «на смене»:
  /// `companies/{companyId}/settings/shifts`
  static DocumentReference<Map<String, dynamic>> companyShiftsOf(
      String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('shifts');
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

  /// Typed ref: invoices
  CollectionReference<Map<String, dynamic>> invoicesRef(String companyId) {
    return invoices(companyId);
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

  /// Коллекция резервных копий (company-level, не в accounting namespace)
  CollectionReference<Map<String, dynamic>> backups(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
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

  /// @Deprecated Legacy — не используется runtime (C5). KPI → metrics/daily/days.
  @Deprecated('Use MetricsService / recalculateDailyMetrics instead')
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
  // OWNER DASHBOARD — companies/{companyId}/*
  // ============================================================================

  /// Коллекция участников компании (membership)
  CollectionReference<Map<String, dynamic>> members(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members');
  }

  /// Коллекция приглашений компании
  CollectionReference<Map<String, dynamic>> invites(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invites');
  }

  /// Коллекция счетов биллинга компании
  CollectionReference<Map<String, dynamic>> billingInvoices(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('billing_invoices');
  }

  /// Коллекция дневных метрик компании (подколлекция metrics/daily)
  CollectionReference<Map<String, dynamic>> dailyMetrics(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('metrics')
        .doc('daily')
        .collection('days');
  }

  /// Коллекция системных событий компании
  CollectionReference<Map<String, dynamic>> systemEvents(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('systemEvents');
  }

  /// Коллекция событий печати компании
  CollectionReference<Map<String, dynamic>> printEvents(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('printEvents');
  }

  /// Коллекция аудит-логов компании (cross-module audit)
  CollectionReference<Map<String, dynamic>> audit(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('audit');
  }

  /// Data Integrity Checker — прогоны проверок (read-only, CF пишет).
  CollectionReference<Map<String, dynamic>> integrityChecks(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('integrity_checks');
  }

  /// Data Integrity Checker — найденные проблемы (CF пишет, owner+ меняет статус).
  CollectionReference<Map<String, dynamic>> integrityIssues(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('integrity_issues');
  }

  /// Pilot product usage events (append-only, no PII).
  CollectionReference<Map<String, dynamic>> usageEvents(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('usage_events');
  }

  /// Support: коллекция платёжных событий компании
  CollectionReference<Map<String, dynamic>> paymentEvents(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('payment_events');
  }

  /// Support: алиас для аудит-логов (текущий источник — collection('audit'))
  CollectionReference<Map<String, dynamic>> auditLogs(String companyId) {
    return audit(companyId);
  }

  /// Support: тикеты поддержки компании
  CollectionReference<Map<String, dynamic>> supportTickets(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('support_tickets');
  }

  /// Support: логи push-доставки компании
  CollectionReference<Map<String, dynamic>> pushDeliveryLogs(String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('push_delivery_logs');
  }

  /// Support: логи email-доставки компании
  CollectionReference<Map<String, dynamic>> emailDeliveryLogs(
      String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('email_delivery_logs');
  }

  /// Коллекция счётчиков нумерации бухгалтерских документов
  CollectionReference<Map<String, dynamic>> accountingCounters(
      String companyId) {
    validateCompanyId(companyId);
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('counters');
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
