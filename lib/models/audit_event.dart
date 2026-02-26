import 'package:cloud_firestore/cloud_firestore.dart';

/// סוגי אירועי ביקורת
enum AuditEventType {
  created, // מסמך נוצר
  finalized, // מסמך עבר סיום
  printed, // הודפס
  exported, // יוצא
  cancelled, // בוטל
  creditNoteCreated, // נוצר זיכוי
  statusChanged, // סטטוס שונה
  technicalUpdate, // עדכון טכני
}

/// אירוע ביקורת — append-only, לא ניתן לשינוי לאחר יצירה
class AuditEvent {
  final String id;
  final String entityId;
  final String entityType;
  final String companyId;
  final AuditEventType eventType;
  final DateTime? timestamp;
  final String actorUid;
  final String? actorName;
  final String requestId;
  final Map<String, dynamic>? metadata;

  AuditEvent({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.companyId,
    required this.eventType,
    this.timestamp,
    required this.actorUid,
    this.actorName,
    required this.requestId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'companyId': companyId,
      'eventType': eventType.name,
      'timestamp': FieldValue.serverTimestamp(),
      'actorUid': actorUid,
      if (actorName != null) 'actorName': actorName,
      'requestId': requestId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AuditEvent.fromMap(Map<String, dynamic> map, String id) {
    return AuditEvent(
      id: id,
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      companyId: map['companyId'] ?? '',
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => AuditEventType.technicalUpdate,
      ),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      actorUid: map['actorUid'] ?? '',
      actorName: map['actorName'],
      requestId: map['requestId'] ?? '',
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  /// תיאור האירוע בעברית ל-UI
  String get localizedDescription {
    switch (eventType) {
      case AuditEventType.created:
        return 'מסמך נוצר';
      case AuditEventType.finalized:
        return 'מסמך עבר סיום';
      case AuditEventType.printed:
        final copyType = metadata?['copyType'] ?? '';
        return 'הודפס ($copyType)';
      case AuditEventType.exported:
        final format = metadata?['format'] ?? '';
        return 'יוצא ($format)';
      case AuditEventType.cancelled:
        final reason = metadata?['reason'] ?? '';
        return 'בוטל: $reason';
      case AuditEventType.creditNoteCreated:
        return 'נוצר זיכוי';
      case AuditEventType.statusChanged:
        final from = metadata?['from'] ?? '';
        final to = metadata?['to'] ?? '';
        return 'סטטוס שונה: $from → $to';
      case AuditEventType.technicalUpdate:
        final field = metadata?['field'] ?? '';
        return 'עדכון טכני: $field';
    }
  }
}
