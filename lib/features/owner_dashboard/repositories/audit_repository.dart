import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore_paths.dart';

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
      FirestorePaths(firestore: _firestore).audit(companyId);

  /// Стрим аудит-лога в реальном времени, отсортированный по убыванию `createdAt`.
  /// Фильтры — на клиенте (Firestore composite index не нужен).
  Stream<List<CrossModuleAuditEvent>> watchAuditLog({AuditFilter? filter}) {
    return _auditCollection
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => CrossModuleAuditEvent.fromMap(doc.data(), doc.id))
          .toList();
      return _applyClientFilters(events, filter);
    });
  }

  /// Одноразовая загрузка аудит-лога с лимитом.
  Future<List<CrossModuleAuditEvent>> getAuditLog({
    AuditFilter? filter,
    int limit = 100,
  }) async {
    final fetchLimit = filter == null ? limit : 1000;
    final snapshot = await _auditCollection
        .orderBy('createdAt', descending: true)
        .limit(fetchLimit)
        .get();
    final events = snapshot.docs
        .map((doc) => CrossModuleAuditEvent.fromMap(doc.data(), doc.id))
        .toList();
    return _applyClientFilters(events, filter).take(limit).toList();
  }

  /// Экспортирует аудит-лог в CSV-строку.
  ///
  /// Колонки: дата, модуль, тип события, пользователь, сущность, детали.
  Future<String> exportToCsv(AuditFilter filter) async {
    final events = await getAuditLog(filter: filter, limit: 10000);
    return _buildCsv(events);
  }

  /// Фильтры moduleKey / type / createdBy — на клиенте (без composite index).
  List<CrossModuleAuditEvent> _applyClientFilters(
    List<CrossModuleAuditEvent> events,
    AuditFilter? filter,
  ) {
    if (filter == null) return events;
    var result = events;

    if (filter.moduleKey != null) {
      result =
          result.where((e) => e.moduleKey == filter.moduleKey).toList();
    }
    if (filter.type != null) {
      result = result.where((e) => e.type == filter.type).toList();
    }
    if (filter.createdBy != null) {
      result =
          result.where((e) => e.createdBy == filter.createdBy).toList();
    }

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
        'תאריך$tמודול$tסוג אירוע$tמשתמש$tישות$tפרטים$tקישור');

    for (final event in events) {
      final date = event.createdAt != null
          ? '${event.createdAt!.day.toString().padLeft(2, '0')}/${event.createdAt!.month.toString().padLeft(2, '0')}/${event.createdAt!.year} ${event.createdAt!.hour.toString().padLeft(2, '0')}:${event.createdAt!.minute.toString().padLeft(2, '0')}'
          : '';
      final module = _moduleLabel(event.moduleKey);
      final type = _eventTypeLabel(event);
      final user = event.createdBy == 'system' ? 'מערכת' : event.createdBy;
      final entity =
          '${_collectionLabel(event.entity.collection)}/${event.entity.docId}';
      final details =
          event.extra.entries.map((e) => '${e.key}=${e.value}').join('; ');
      final link =
          '$baseUrl/doc?id=${event.entity.docId}&company=$companyId&col=${event.entity.collection}';
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

  static String _eventTypeLabel(CrossModuleAuditEvent event) {
    final raw = event.extra['documentType']?.toString();
    if (event.type == 'invoice_issued' && raw != null && raw.isNotEmpty) {
      switch (raw) {
        case 'delivery':
        case 'delivery_note':
          return 'הנפקת תעודת משלוח';
        case 'invoice':
        case 'tax_invoice':
          return 'הנפקת חשבונית מס';
        case 'taxInvoiceReceipt':
        case 'tax_invoice_receipt':
          return 'הנפקת חשבונית מס/קבלה';
        case 'receipt':
          return 'הנפקת קבלה';
        case 'creditNote':
        case 'credit_note':
          return 'הנפקת זיכוי';
      }
    }
    return _eventTypeLabelPlain(event.type);
  }

  static String _eventTypeLabelPlain(String type) {
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
