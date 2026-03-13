import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип системного события.
enum SystemEventType {
  integrationError,
  webhookFailure,
  printError,
  retryAttempt;

  String get value {
    switch (this) {
      case SystemEventType.integrationError:
        return 'integration_error';
      case SystemEventType.webhookFailure:
        return 'webhook_failure';
      case SystemEventType.printError:
        return 'print_error';
      case SystemEventType.retryAttempt:
        return 'retry_attempt';
    }
  }

  static SystemEventType fromString(String type) {
    switch (type) {
      case 'integration_error':
        return SystemEventType.integrationError;
      case 'webhook_failure':
        return SystemEventType.webhookFailure;
      case 'print_error':
        return SystemEventType.printError;
      case 'retry_attempt':
        return SystemEventType.retryAttempt;
      default:
        throw ArgumentError('Unknown system event type: $type');
    }
  }
}

/// Источник системного события.
enum SystemEventSource {
  print,
  email,
  whatsapp,
  webhook,
  api;

  String get value => name;

  static SystemEventSource fromString(String source) {
    switch (source) {
      case 'print':
        return SystemEventSource.print;
      case 'email':
        return SystemEventSource.email;
      case 'whatsapp':
        return SystemEventSource.whatsapp;
      case 'webhook':
        return SystemEventSource.webhook;
      case 'api':
        return SystemEventSource.api;
      default:
        throw ArgumentError('Unknown system event source: $source');
    }
  }
}

/// Статус системного события.
enum SystemEventStatus {
  error,
  failed,
  success,
  retrying;

  String get value => name;

  static SystemEventStatus fromString(String status) {
    switch (status) {
      case 'error':
        return SystemEventStatus.error;
      case 'failed':
        return SystemEventStatus.failed;
      case 'success':
        return SystemEventStatus.success;
      case 'retrying':
        return SystemEventStatus.retrying;
      default:
        throw ArgumentError('Unknown system event status: $status');
    }
  }
}

/// SystemEvent-документ: `/companies/{companyId}/systemEvents/{eventId}`
///
/// Системное событие: ошибки интеграций, сбои вебхуков, ошибки печати, ретраи.
class SystemEvent {
  final SystemEventType type;
  final SystemEventSource source;
  final SystemEventStatus status;
  final String message;
  final String? endpoint;
  final int? responseStatus;
  final int? responseTime;
  final int retryCount;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  SystemEvent({
    required this.type,
    required this.source,
    required this.status,
    required this.message,
    this.endpoint,
    this.responseStatus,
    this.responseTime,
    this.retryCount = 0,
    this.createdAt,
    this.resolvedAt,
  });

  factory SystemEvent.fromMap(Map<String, dynamic> map) {
    return SystemEvent(
      type: SystemEventType.fromString(map['type'] ?? 'integration_error'),
      source: SystemEventSource.fromString(map['source'] ?? 'api'),
      status: SystemEventStatus.fromString(map['status'] ?? 'error'),
      message: map['message'] ?? '',
      endpoint: map['endpoint'],
      responseStatus: map['responseStatus'] != null
          ? (map['responseStatus'] as num).toInt()
          : null,
      responseTime: map['responseTime'] != null
          ? (map['responseTime'] as num).toInt()
          : null,
      retryCount: ((map['retryCount'] ?? 0) as num).toInt(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'source': source.value,
      'status': status.value,
      'message': message,
      if (endpoint != null) 'endpoint': endpoint,
      if (responseStatus != null) 'responseStatus': responseStatus,
      if (responseTime != null) 'responseTime': responseTime,
      'retryCount': retryCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    };
  }
}
