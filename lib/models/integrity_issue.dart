import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Integrity Checker — модель проблемы и прогона проверки.

enum IntegritySeverity { critical, high, medium, low, unknown }

enum IntegrityIssueStatus { open, ignored, resolved, unknown }

IntegritySeverity severityFromString(String? raw) {
  switch (raw) {
    case 'critical':
      return IntegritySeverity.critical;
    case 'high':
      return IntegritySeverity.high;
    case 'medium':
      return IntegritySeverity.medium;
    case 'low':
      return IntegritySeverity.low;
    default:
      return IntegritySeverity.unknown;
  }
}

IntegrityIssueStatus statusFromString(String? raw) {
  switch (raw) {
    case 'open':
      return IntegrityIssueStatus.open;
    case 'ignored':
      return IntegrityIssueStatus.ignored;
    case 'resolved':
      return IntegrityIssueStatus.resolved;
    default:
      return IntegrityIssueStatus.unknown;
  }
}

/// Порядок сортировки: critical → low.
int severityRank(IntegritySeverity s) {
  switch (s) {
    case IntegritySeverity.critical:
      return 0;
    case IntegritySeverity.high:
      return 1;
    case IntegritySeverity.medium:
      return 2;
    case IntegritySeverity.low:
      return 3;
    case IntegritySeverity.unknown:
      return 4;
  }
}

class IntegrityIssue {
  final String id;
  final String companyId;
  final IntegritySeverity severity;
  final IntegrityIssueStatus status;
  final String entityType;
  final String entityId;
  final String issueCode;
  final String title;
  final String description;
  final DateTime? detectedAt;
  final DateTime? lastSeenAt;
  final DateTime? resolvedAt;
  final DateTime? ignoredAt;
  final String? ignoredBy;
  final String? correlationId;
  final String? checkId;
  final Map<String, dynamic> metadata;
  final bool isDemo;

  const IntegrityIssue({
    required this.id,
    required this.companyId,
    required this.severity,
    required this.status,
    required this.entityType,
    required this.entityId,
    required this.issueCode,
    required this.title,
    required this.description,
    this.detectedAt,
    this.lastSeenAt,
    this.resolvedAt,
    this.ignoredAt,
    this.ignoredBy,
    this.correlationId,
    this.checkId,
    this.metadata = const {},
    this.isDemo = false,
  });

  static DateTime? _ts(dynamic v) =>
      v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

  factory IntegrityIssue.fromFirestore(String id, Map<String, dynamic> map) {
    return IntegrityIssue(
      id: id,
      companyId: map['companyId']?.toString() ?? '',
      severity: severityFromString(map['severity']?.toString()),
      status: statusFromString(map['status']?.toString()),
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      issueCode: map['issueCode']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      detectedAt: _ts(map['detectedAt']),
      lastSeenAt: _ts(map['lastSeenAt']),
      resolvedAt: _ts(map['resolvedAt']),
      ignoredAt: _ts(map['ignoredAt']),
      ignoredBy: map['ignoredBy']?.toString(),
      correlationId: map['correlationId']?.toString(),
      checkId: map['checkId']?.toString(),
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      isDemo: map['isDemo'] == true,
    );
  }

  /// CSV-строка (порядок колонок — см. экспорт экрана).
  List<String> toCsvRow() => [
        severity.name,
        status.name,
        entityType,
        entityId,
        issueCode,
        title,
        description.replaceAll('\n', ' '),
        detectedAt?.toIso8601String() ?? '',
        lastSeenAt?.toIso8601String() ?? '',
      ];
}

class IntegrityCheck {
  final String id;
  final String status; // running | completed | failed
  final String trigger; // manual | scheduled
  final String startedBy;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int foundIssues;
  final int openIssues;
  final Map<String, int> bySeverity;
  final bool isDemo;

  const IntegrityCheck({
    required this.id,
    required this.status,
    required this.trigger,
    required this.startedBy,
    this.startedAt,
    this.completedAt,
    this.foundIssues = 0,
    this.openIssues = 0,
    this.bySeverity = const {},
    this.isDemo = false,
  });

  int severityCount(IntegritySeverity s) => bySeverity[s.name] ?? 0;

  factory IntegrityCheck.fromFirestore(String id, Map<String, dynamic> map) {
    final raw = (map['bySeverity'] as Map?)?.cast<String, dynamic>() ?? const {};
    return IntegrityCheck(
      id: id,
      status: map['status']?.toString() ?? 'unknown',
      trigger: map['trigger']?.toString() ?? 'manual',
      startedBy: map['startedBy']?.toString() ?? '',
      startedAt: IntegrityIssue._ts(map['startedAt']),
      completedAt: IntegrityIssue._ts(map['completedAt']),
      foundIssues: (map['foundIssues'] as num?)?.toInt() ?? 0,
      openIssues: (map['openIssues'] as num?)?.toInt() ?? 0,
      bySeverity: {
        for (final e in raw.entries) e.key: (e.value as num?)?.toInt() ?? 0,
      },
      isDemo: map['isDemo'] == true,
    );
  }
}
