import 'package:cloud_firestore/cloud_firestore.dart';

enum PlatformErrorSeverity { critical, high, medium, low }

enum PlatformErrorStatus { open, resolved }

PlatformErrorSeverity severityFromString(String? raw) {
  switch (raw) {
    case 'critical':
      return PlatformErrorSeverity.critical;
    case 'high':
      return PlatformErrorSeverity.high;
    case 'medium':
      return PlatformErrorSeverity.medium;
    default:
      return PlatformErrorSeverity.low;
  }
}

String severityToString(PlatformErrorSeverity s) => s.name;

class PlatformSystemError {
  final String errorId;
  final String fingerprint;
  final String? companyId;
  final String? companyName;
  final String? userId;
  final String? role;
  final String? deviceId;
  final String? platform;
  final String? appVersion;
  final String? buildNumber;
  final String? environment;
  final DateTime? timestamp;
  final PlatformErrorSeverity severity;
  final PlatformErrorStatus status;
  final String? correlationId;
  final List<String> recentCorrelationIds;
  final String? operation;
  final String errorType;
  final String errorMessage;
  final String? route;
  final Map<String, dynamic> metadata;
  final int occurrences;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String source;
  final bool incidentSuggested;

  const PlatformSystemError({
    required this.errorId,
    required this.fingerprint,
    required this.severity,
    required this.status,
    required this.errorType,
    required this.errorMessage,
    required this.metadata,
    required this.occurrences,
    required this.resolved,
    required this.source,
    required this.recentCorrelationIds,
    this.companyId,
    this.companyName,
    this.userId,
    this.role,
    this.deviceId,
    this.platform,
    this.appVersion,
    this.buildNumber,
    this.environment,
    this.timestamp,
    this.correlationId,
    this.operation,
    this.route,
    this.firstSeen,
    this.lastSeen,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNote,
    this.incidentSuggested = false,
  });

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  factory PlatformSystemError.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return PlatformSystemError(
      errorId: doc.id,
      fingerprint: d['fingerprint'] as String? ?? doc.id,
      companyId: d['companyId'] as String?,
      companyName: d['companyName'] as String?,
      userId: d['userId'] as String?,
      role: d['role'] as String?,
      deviceId: d['deviceId'] as String?,
      platform: d['platform'] as String?,
      appVersion: d['appVersion'] as String?,
      buildNumber: d['buildNumber'] as String?,
      environment: d['environment'] as String?,
      timestamp: _ts(d['timestamp']),
      severity: severityFromString(d['severity'] as String?),
      status: d['status'] == 'resolved'
          ? PlatformErrorStatus.resolved
          : PlatformErrorStatus.open,
      correlationId: d['correlationId'] as String?,
      recentCorrelationIds: (d['recentCorrelationIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      operation: d['operation'] as String?,
      errorType: d['errorType'] as String? ?? 'unknown',
      errorMessage: d['errorMessage'] as String? ?? '',
      route: d['route'] as String?,
      metadata: Map<String, dynamic>.from(d['metadata'] as Map? ?? {}),
      occurrences: (d['occurrences'] as num?)?.toInt() ?? 1,
      firstSeen: _ts(d['firstSeen']),
      lastSeen: _ts(d['lastSeen']),
      resolved: d['resolved'] == true,
      resolvedBy: d['resolvedBy'] as String?,
      resolvedAt: _ts(d['resolvedAt']),
      resolutionNote: d['resolutionNote'] as String?,
      source: d['source'] as String? ?? 'unknown',
      incidentSuggested: d['incidentSuggested'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'errorId': errorId,
        'fingerprint': fingerprint,
        'companyId': companyId,
        'companyName': companyName,
        'userId': userId,
        'role': role,
        'severity': severityToString(severity),
        'status': status.name,
        'correlationId': correlationId,
        'recentCorrelationIds': recentCorrelationIds,
        'operation': operation,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'occurrences': occurrences,
        'resolved': resolved,
        'source': source,
      };
}
