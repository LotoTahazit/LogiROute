import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../services/cross_module_audit_service.dart';
import '../../models/usage_event.dart';
import '../../services/usage_analytics_service.dart';
import '../../services/platform_error_service.dart';

/// Критичные операции с единым correlationId.
enum CorrelatedOperation {
  createRoute('create_route'),
  assignDriver('assign_driver'),
  closePoint('close_point'),
  pod('pod'),
  createInvoice('create_invoice'),
  accountingSync('accounting_sync'),
  stripeCheckout('stripe_checkout'),
  importExcel('import_excel'),
  exportExcel('export_excel'),
  driverSession('driver_session'),
  createCompany('create_company');

  const CorrelatedOperation(this.code);
  final String code;
}

/// Контекст трассировки операции. [requestId] переиспользуется как correlationId.
class CorrelationContext {
  static const _uuid = Uuid();

  final String correlationId;
  final CorrelatedOperation operation;
  final String companyId;
  final String userId;
  final DateTime timestamp;

  CorrelationContext._({
    required this.correlationId,
    required this.operation,
    required this.companyId,
    required this.userId,
    required this.timestamp,
  });

  /// Если есть requestId — используем его (audit idempotency).
  static String resolveId({String? requestId, String? correlationId}) {
    final r = requestId?.trim();
    if (r != null && r.isNotEmpty) return r;
    final c = correlationId?.trim();
    if (c != null && c.isNotEmpty) return c;
    return _uuid.v4();
  }

  factory CorrelationContext.start({
    required CorrelatedOperation operation,
    required String companyId,
    required String userId,
    String? requestId,
    String? correlationId,
  }) {
    return CorrelationContext._(
      correlationId:
          resolveId(requestId: requestId, correlationId: correlationId),
      operation: operation,
      companyId: companyId,
      userId: userId,
      timestamp: DateTime.now().toUtc(),
    );
  }

  String get requestId => correlationId;

  void log(String message, {String level = 'info'}) {
    debugPrint(
      '[$level][${operation.code}] cid=$correlationId '
      'company=$companyId user=$userId ts=${timestamp.toIso8601String()} — $message',
    );
  }

  void logError(Object error, [StackTrace? st]) {
    log(error.toString(), level: 'error');
    if (st != null) debugPrint('$st');
    PlatformErrorService.report(
      error: error,
      stack: st,
      operation: operation.code,
      correlationId: correlationId,
      companyId: companyId,
      userId: userId,
      source: 'correlation_context',
    );
  }

  Map<String, dynamic> auditExtra([Map<String, dynamic>? extra]) => {
        'correlationId': correlationId,
        'operation': operation.code,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        if (extra != null) ...extra,
      };

  Map<String, dynamic> cfPayload([Map<String, dynamic>? extra]) => {
        'correlationId': correlationId,
        if (extra != null) ...extra,
      };

  Map<String, dynamic> toErrorMap({String? message, Object? cause}) => {
        'companyId': companyId,
        'userId': userId,
        'correlationId': correlationId,
        'operation': operation.code,
        'timestamp': timestamp.toIso8601String(),
        if (message != null) 'message': message,
        if (cause != null) 'cause': cause.toString(),
      };

  CorrelatedException toException(Object error, {String? message}) =>
      CorrelatedException(
        ctx: this,
        message: message ?? error.toString(),
        cause: error,
      );

  Never rethrowAs(Object error, {String? message}) {
    logError(error);
    throw toException(error, message: message);
  }

  Future<void> audit({
    required String moduleKey,
    required String type,
    required String entityCollection,
    required String entityDocId,
    Map<String, dynamic>? extra,
  }) async {
    log('audit $type → $entityCollection/$entityDocId');
    await CrossModuleAuditService(companyId: companyId).log(
      moduleKey: moduleKey,
      type: type,
      entityCollection: entityCollection,
      entityDocId: entityDocId,
      uid: userId,
      extra: auditExtra(extra),
    );
  }

  /// Pilot usage event (fire-and-forget, не блокирует flow).
  Future<void> trackPilot(
    UsageEventName event, {
    String? role,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) {
    return UsageAnalyticsService.track(
      companyId: companyId,
      userId: userId,
      role: role ?? 'unknown',
      event: event,
      correlationId: correlationId,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
  }

  Future<T> run<T>(Future<T> Function() body, {String? successMsg}) async {
    log('start');
    try {
      final result = await body();
      log(successMsg ?? 'ok');
      return result;
    } catch (e, st) {
      logError(e, st);
      throw toException(e);
    }
  }
}

class CorrelatedException implements Exception {
  final CorrelationContext ctx;
  final String message;
  final Object? cause;

  CorrelatedException({
    required this.ctx,
    required this.message,
    this.cause,
  });

  Map<String, dynamic> toMap() =>
      ctx.toErrorMap(message: message, cause: cause);

  @override
  String toString() =>
      'CorrelatedException(${ctx.operation.code}): cid=${ctx.correlationId} '
      'company=${ctx.companyId} user=${ctx.userId} '
      'ts=${ctx.timestamp.toIso8601String()} — $message';
}

/// Хелпер: создать контекст или null если нет userId.
CorrelationContext? correlationIf({
  required CorrelatedOperation operation,
  required String companyId,
  String? userId,
  String? requestId,
  String? correlationId,
}) {
  final uid = userId?.trim();
  if (uid == null || uid.isEmpty) return null;
  return CorrelationContext.start(
    operation: operation,
    companyId: companyId,
    userId: uid,
    requestId: requestId,
    correlationId: correlationId,
  );
}

String correlatedErrorMessage(Object error) {
  if (error is CorrelatedException) return error.toString();
  return error.toString();
}
