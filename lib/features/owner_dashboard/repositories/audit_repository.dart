import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_event.dart';

/// Репозиторий для чтения cross-module аудит-лога компании.
///
/// Работает с коллекцией `/companies/{companyId}/audit/{eventId}`.
/// Read-only: owner не может редактировать или удалять записи (append-only).
///
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class AuditRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  AuditRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию audit компании.
  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _firestore.collection('companies').doc(companyId).collection('audit');

  /// Стрим аудит-лога в реальном времени, отсортированный по убыванию `createdAt`.
  ///
  /// Применяет [filter] для серверной фильтрации (Firestore equality filters)
  /// и клиентской фильтрации (dateRange).
  Stream<List<CrossModuleAuditEvent>> watchAuditLog({AuditFilter? filter}) {
    var query = _applyServerFilters(_auditCollection, filter);
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final events = snapshot.docs
          .map((doc) => CrossModuleAuditEvent.fromMap(doc.data(), doc.id))
          .toList();
      return _applyClientFilters(events, filter);
    });
  }

  /// Одноразовая загрузка аудит-лога с лимитом.
  ///
  /// По умолчанию возвращает до [limit] записей (default 100),
  /// отсортированных по убыванию `createdAt`.
  Future<List<CrossModuleAuditEvent>> getAuditLog({
    AuditFilter? filter,
    int limit = 100,
  }) async {
    var query = _applyServerFilters(_auditCollection, filter);
    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    final events = snapshot.docs
        .map((doc) => CrossModuleAuditEvent.fromMap(doc.data(), doc.id))
        .toList();
    return _applyClientFilters(events, filter);
  }

  /// Экспортирует аудит-лог в CSV-строку.
  ///
  /// Колонки: дата, модуль, тип события, пользователь, сущность, детали.
  Future<String> exportToCsv(AuditFilter filter) async {
    final events = await getAuditLog(filter: filter, limit: 10000);
    return _buildCsv(events);
  }

  /// Применяет серверные (Firestore equality) фильтры к запросу.
  Query<Map<String, dynamic>> _applyServerFilters(
    CollectionReference<Map<String, dynamic>> ref,
    AuditFilter? filter,
  ) {
    Query<Map<String, dynamic>> query = ref;
    if (filter == null) return query;

    if (filter.moduleKey != null) {
      query = query.where('moduleKey', isEqualTo: filter.moduleKey);
    }
    if (filter.type != null) {
      query = query.where('type', isEqualTo: filter.type);
    }
    if (filter.createdBy != null) {
      query = query.where('createdBy', isEqualTo: filter.createdBy);
    }
    return query;
  }

  /// Применяет клиентскую фильтрацию по диапазону дат.
  ///
  /// Firestore не поддерживает range-фильтр на поле, по которому идёт orderBy,
  /// одновременно с equality-фильтрами на других полях без составного индекса.
  /// Поэтому dateRange фильтруется на клиенте.
  List<CrossModuleAuditEvent> _applyClientFilters(
    List<CrossModuleAuditEvent> events,
    AuditFilter? filter,
  ) {
    if (filter == null) return events;
    var result = events;

    if (filter.from != null) {
      result = result
          .where((e) =>
              e.createdAt != null && !e.createdAt!.isBefore(filter.from!))
          .toList();
    }
    if (filter.to != null) {
      result = result
          .where(
              (e) => e.createdAt != null && !e.createdAt!.isAfter(filter.to!))
          .toList();
    }
    return result;
  }

  /// Формирует CSV-строку из списка событий.
  String _buildCsv(List<CrossModuleAuditEvent> events) {
    final buffer = StringBuffer();
    buffer.writeln('תאריך,מודול,סוג אירוע,משתמש,ישות,פרטים');

    for (final event in events) {
      final date = event.createdAt?.toIso8601String() ?? '';
      final module = _escapeCsv(event.moduleKey);
      final type = _escapeCsv(event.type);
      final user = _escapeCsv(event.createdBy);
      final entity =
          _escapeCsv('${event.entity.collection}/${event.entity.docId}');
      final details = _escapeCsv(
        event.extra.entries.map((e) => '${e.key}=${e.value}').join('; '),
      );
      buffer.writeln('$date,$module,$type,$user,$entity,$details');
    }
    return buffer.toString();
  }

  /// Экранирует значение для CSV (оборачивает в кавычки при наличии спецсимволов).
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for AuditRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
