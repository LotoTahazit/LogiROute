import 'package:cloud_firestore/cloud_firestore.dart';

/// Событие cross-module аудита из `/companies/{companyId}/audit/{eventId}`.
///
/// Append-only: owner не может редактировать или удалять записи.
class CrossModuleAuditEvent {
  final String id;
  final String moduleKey;
  final String type;
  final AuditEntity entity;
  final String createdBy;
  final DateTime? createdAt;

  /// Дополнительные поля, специфичные для конкретного события.
  final Map<String, dynamic> extra;

  const CrossModuleAuditEvent({
    required this.id,
    required this.moduleKey,
    required this.type,
    required this.entity,
    required this.createdBy,
    this.createdAt,
    this.extra = const {},
  });

  factory CrossModuleAuditEvent.fromMap(Map<String, dynamic> map, String id) {
    final rawEntity = map['entity'];
    final entityMap = rawEntity != null
        ? Map<String, dynamic>.from(rawEntity as Map)
        : <String, dynamic>{};
    // Collect extra fields (everything except known keys).
    final knownKeys = {'moduleKey', 'type', 'entity', 'createdBy', 'createdAt'};
    final extra = Map<String, dynamic>.fromEntries(
      map.entries.where((e) => !knownKeys.contains(e.key)),
    );

    return CrossModuleAuditEvent(
      id: id,
      moduleKey: map['moduleKey'] as String? ?? '',
      type: map['type'] as String? ?? '',
      entity: AuditEntity(
        collection: entityMap['collection'] as String? ?? '',
        docId: entityMap['docId'] as String? ?? '',
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      extra: extra,
    );
  }
}

/// Сущность, затронутая событием аудита.
class AuditEntity {
  final String collection;
  final String docId;

  const AuditEntity({required this.collection, required this.docId});
}

/// Фильтр для запросов к аудит-логу.
class AuditFilter {
  final String? moduleKey;
  final String? type;
  final String? createdBy;
  final DateTime? from;
  final DateTime? to;

  const AuditFilter({
    this.moduleKey,
    this.type,
    this.createdBy,
    this.from,
    this.to,
  });
}
