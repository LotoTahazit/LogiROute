import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../core/correlation/correlation_context.dart';
import '../models/platform_system_error.dart';
import 'firestore_paths.dart';
import 'platform_error_fingerprint.dart';

/// Отчёт и чтение Platform Error Center (super_admin).
class PlatformErrorService {
  PlatformErrorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static String? _appVersion;
  static String? _buildNumber;
  static String? _deviceId;

  static void configureAppInfo({
    String? appVersion,
    String? buildNumber,
    String? deviceId,
  }) {
    _appVersion = appVersion;
    _buildNumber = buildNumber;
    _deviceId = deviceId;
  }

  CollectionReference<Map<String, dynamic>> get _errors =>
      FirestorePaths(firestore: _firestore).platformSystemErrors();

  /// Fire-and-forget отчёт через CF (группировка на сервере).
  static Future<void> report({
    required Object error,
    StackTrace? stack,
    String? operation,
    String? correlationId,
    String? companyId,
    String? companyName,
    String? userId,
    String? role,
    String? route,
    String source = 'flutter',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final errorType = _errorTypeOf(error);
      final message = sanitizePlatformErrorText(
        error is CorrelatedException ? error.message : error.toString(),
      );
      final cid = correlationId ??
          (error is CorrelatedException ? error.ctx.correlationId : null) ??
          CorrelationContext.resolveId();

      final callable = FirebaseFunctions.instance.httpsCallable(
        'reportPlatformError',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      unawaited(callable.call<Map<String, dynamic>>({
        'source': source,
        'errorType': errorType,
        'errorMessage': message,
        'stackTrace': sanitizePlatformErrorText(stack?.toString()),
        'operation': operation ??
            (error is CorrelatedException ? error.ctx.operation.code : null),
        'correlationId': cid,
        'companyId': companyId ??
            (error is CorrelatedException ? error.ctx.companyId : null),
        'companyName': companyName,
        'userId': userId ??
            (error is CorrelatedException ? error.ctx.userId : null),
        'role': role,
        'route': route,
        'platform': _platformLabel(),
        'appVersion': _appVersion,
        'buildNumber': _buildNumber,
        'deviceId': _deviceId,
        'environment': kReleaseMode ? 'production' : 'debug',
        if (metadata != null) 'metadata': metadata,
      }));
    } catch (e) {
      debugPrint('⚠️ [PlatformErrorService] report failed: $e');
    }
  }

  static String _errorTypeOf(Object error) {
    if (error is CorrelatedException) return 'CorrelatedException';
    if (error is FirebaseFunctionsException) return error.code;
    final name = error.runtimeType.toString();
    if (name.contains('FirebaseAuth')) return 'FirebaseAuthException';
    if (name.contains('FirebaseException')) return 'FirebaseException';
    if (name.contains('PlatformException')) return 'PlatformException';
    return name;
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  Stream<List<PlatformSystemError>> watchErrors({
    PlatformErrorSeverity? severity,
    bool? openOnly,
    String? companyId,
    int limit = 100,
  }) {
    return _errors
        .orderBy('lastSeen', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snap) {
      var list = snap.docs.map(PlatformSystemError.fromFirestore).toList();
      if (openOnly == true) {
        list = list.where((e) => !e.resolved).toList();
      }
      if (severity != null) {
        list = list.where((e) => e.severity == severity).toList();
      }
      if (companyId != null && companyId.isNotEmpty) {
        list = list.where((e) => e.companyId == companyId).toList();
      }
      if (list.length > limit) list = list.take(limit).toList();
      return list;
    });
  }

  Stream<int> watchOpenCriticalCount() {
    return _errors.snapshots().map((s) => s.docs
        .where((d) =>
            d.data()['resolved'] != true &&
            d.data()['severity'] == 'critical')
        .length);
  }

  Future<String?> loadStackTrace(String errorId) async {
    final snap = await FirestorePaths(firestore: _firestore)
        .platformErrorPrivate(errorId)
        .get();
    return snap.data()?['stackTrace'] as String?;
  }

  Future<void> markResolved({
    required String errorId,
    required String uid,
    String? note,
  }) async {
    await _errors.doc(errorId).update({
      'resolved': true,
      'status': 'resolved',
      'resolvedBy': uid,
      'resolvedAt': FieldValue.serverTimestamp(),
      if (note != null && note.trim().isNotEmpty) 'resolutionNote': note.trim(),
    });
  }

  Future<void> reopen(String errorId) async {
    await _errors.doc(errorId).update({
      'resolved': false,
      'status': 'open',
      'resolvedBy': null,
      'resolvedAt': null,
      'resolutionNote': null,
    });
  }
}
