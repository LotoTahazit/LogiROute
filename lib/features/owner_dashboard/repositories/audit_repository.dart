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

  /// Формирует tab-separated строку из списка событий.
  /// Включает колонку «קישור» с deep-link URL для открытия документа в приложении.
  String _buildCsv(List<CrossModuleAuditEvent> events) {
    const t = '\t';
    const baseUrl = 'https://logiroute-app.web.app';
    final buffer = StringBuffer();
    buffer.writeln(
        'תאריך${t}מודול${t}סוג אירוע${t}משתמש${t}ישות${t}פרטים${t}קישור');

    for (final event in events) {
      final date = event.createdAt != null
          ? '${event.createdAt!.day.toString().padLeft(2, '0')}/${event.createdAt!.month.toString().padLeft(2, '0')}/${event.createdAt!.year} ${event.createdAt!.hour.toString().padLeft(2, '0')}:${event.createdAt!.minute.toString().padLeft(2, '0')}'
          : '';
      final module = _moduleLabel(event.moduleKey);
      final type = _eventTypeLabel(event.type);
      final user = event.createdBy == 'system' ? 'מערכת' : event.createdBy;
      final entity =
          '${_collectionLabel(event.entity.collection)}/${event.entity.docId}';
      final details =
          event.extra.entries.map((e) => '${e.key}=${e.value}').join('; ');
      final link =
          '$baseUrl/#/doc?id=${event.entity.docId}&company=$companyId&col=${event.entity.collection}';
      buffer.writeln('$date$t$module$t$type$t$user$t$entity$t$details$t$link');
    }
    return buffer.toString();
  }

  static String _moduleLabel(String key) {
    switch (key) {
      case 'accounting':
        return 'הנהלת חשבונות';
      case 'inventory':
        return 'מלאי';
      case 'routes':
        return 'מסלולים';
      case 'clients':
        return 'לקוחות';
      case 'drivers':
        return 'נהגים';
      case 'company':
        return 'חברה';
      default:
        return key;
    }
  }

  static String _eventTypeLabel(String type) {
    switch (type) {
      case 'invoice_issued':
        return 'הנפקת חשבונית';
      case 'invoice_cancelled':
        return 'ביטול חשבונית';
      case 'credit_note_issued':
        return 'הנפקת זיכוי';
      case 'receipt_issued':
        return 'הנפקת קבלה';
      case 'delivery_note_issued':
        return 'הנפקת תעודת משלוח';
      case 'created':
        return 'נוצר';
      case 'updated':
        return 'עודכן';
      case 'deleted':
        return 'נמחק';
      case 'exported':
        return 'יוצא';
      case 'chain_invoice':
        return 'שרשור חשבונית';
      case 'chain_taxInvoiceReceipt':
        return 'שרשור חשבונית מס קבלה';
      case 'chain_delivery':
        return 'שרשור תעודת משלוח';
      default:
        return type;
    }
  }

  static String _collectionLabel(String collection) {
    switch (collection) {
      case 'invoices':
        return 'חשבוניות';
      case 'creditNotes':
        return 'זיכויים';
      case 'deliveryNotes':
        return 'תעודות משלוח';
      case 'receipts':
        return 'קבלות';
      case 'inventory':
        return 'מלאי';
      case 'clients':
        return 'לקוחות';
      case 'routes':
        return 'מסלולים';
      default:
        return collection;
    }
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
