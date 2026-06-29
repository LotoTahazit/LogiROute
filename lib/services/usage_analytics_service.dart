import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usage_event.dart';
import 'firestore_paths.dart';

/// Сводка usage за период (bounded reads).
class UsageSummary {
  const UsageSummary({
    required this.countsByEvent,
    required this.activeUsers,
    this.lastEventAt,
    this.sampleSize = 0,
  });

  final Map<String, int> countsByEvent;
  final int activeUsers;
  final DateTime? lastEventAt;
  final int sampleSize;

  int get totalEvents =>
      countsByEvent.values.fold(0, (total, c) => total + c);
}

/// Минимальная product usage analytics — Firestore only, без SDK.
class UsageAnalyticsService {
  UsageAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _sampleLimit = 200;

  static const _blockedMetadataKeys = {
    'email',
    'name',
    'phone',
    'clientname',
    'address',
    'displayname',
    'drivername',
    'taxid',
    'password',
    'token',
    'fcmtoken',
    'body',
    'title',
  };

  CollectionReference<Map<String, dynamic>> _events(String companyId) =>
      FirestorePaths(firestore: _firestore).usageEvents(companyId);

  /// Append-only write; ошибки не блокируют основной flow.
  static Future<void> track({
    required String companyId,
    required String userId,
    required String role,
    required UsageEventName event,
    String? correlationId,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    FirebaseFirestore? firestore,
  }) async {
    if (companyId.isEmpty || userId.isEmpty) return;
    try {
      final svc = UsageAnalyticsService(firestore: firestore);
      await svc._events(companyId).add({
        'companyId': companyId,
        'userId': userId,
        'role': role,
        'eventName': event.value,
        'timestamp': FieldValue.serverTimestamp(),
        if (correlationId != null && correlationId.isNotEmpty)
          'correlationId': correlationId,
        if (entityType != null && entityType.isNotEmpty) 'entityType': entityType,
        if (entityId != null && entityId.isNotEmpty) 'entityId': entityId,
        ...() {
          final meta = _sanitizeMetadata(metadata);
          return meta == null ? <String, dynamic>{} : {'metadata': meta};
        }(),
      });
    } catch (e) {
      debugPrint('⚠️ [UsageAnalytics] ${event.value}: $e');
    }
  }

  static Future<void> trackFromAuth({
    required String companyId,
    required UsageEventName event,
    String? role,
    String? correlationId,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return track(
      companyId: companyId,
      userId: uid,
      role: role ?? 'unknown',
      event: event,
      correlationId: correlationId,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
  }

  static Map<String, dynamic>? _sanitizeMetadata(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final e in raw.entries) {
      if (_blockedMetadataKeys.contains(e.key.toLowerCase())) continue;
      final v = e.value;
      if (v is num || v is bool) {
        out[e.key] = v;
      } else if (v is String && v.length <= 64) {
        out[e.key] = v;
      }
    }
    return out.isEmpty ? null : out;
  }

  /// Count по eventName (parallel count queries) + active users из sample limit 200.
  Future<UsageSummary> loadSummary({
    required String companyId,
    required int days,
  }) async {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    final ref = _events(companyId);

    final counts = <String, int>{};
    await Future.wait(
      UsageEventName.allValues.map((event) async {
        try {
          final snap = await ref
              .where('eventName', isEqualTo: event.value)
              .where('timestamp', isGreaterThanOrEqualTo: since)
              .count()
              .get();
          counts[event.value] = snap.count ?? 0;
        } catch (_) {
          counts[event.value] = 0;
        }
      }),
    );

    DateTime? lastAt;
    final userIds = <String>{};
    try {
      final sample = await ref
          .where('timestamp', isGreaterThanOrEqualTo: since)
          .orderBy('timestamp', descending: true)
          .limit(_sampleLimit)
          .get();
      for (final doc in sample.docs) {
        final data = doc.data();
        final uid = data['userId'] as String? ?? '';
        if (uid.isNotEmpty) userIds.add(uid);
        lastAt ??= (data['timestamp'] as Timestamp?)?.toDate();
      }
      return UsageSummary(
        countsByEvent: counts,
        activeUsers: userIds.length,
        lastEventAt: lastAt,
        sampleSize: sample.docs.length,
      );
    } catch (_) {
      return UsageSummary(
        countsByEvent: counts,
        activeUsers: userIds.length,
        lastEventAt: lastAt,
      );
    }
  }
}
