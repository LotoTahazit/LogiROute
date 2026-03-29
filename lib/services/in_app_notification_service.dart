import 'package:cloud_firestore/cloud_firestore.dart';

/// Роли, которым показываются уведомления об integrity/billing
const _adminRoles = {'super_admin', 'owner', 'admin', 'accountant'};

/// Типы уведомлений только для admin-ролей
const _adminOnlyTypes = {
  'integrity_chain_broken',
  'billing_grace',
  'billing_suspended',
  'payment_received',
  'welcome',
};

/// Сервис для in-app уведомлений из Firestore.
/// Уведомления хранятся в companies/{companyId}/notifications/
/// Записываются серверными функциями (billingEnforcer, webhook и т.д.)
class InAppNotificationService {
  final String companyId;
  final String? userRole;
  final String? currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InAppNotificationService({
    required this.companyId,
    this.userRole,
    this.currentUserId,
  });

  bool _canSeeNotification(InAppNotification n) {
    if (_adminOnlyTypes.contains(n.type)) {
      return _adminRoles.contains(userRole);
    }
    final explicitUserIds = {
      if (n.driverId != null && n.driverId!.isNotEmpty) n.driverId!,
      if (n.userId != null && n.userId!.isNotEmpty) n.userId!,
      if (n.uid != null && n.uid!.isNotEmpty) n.uid!,
      if (n.recipientId != null && n.recipientId!.isNotEmpty) n.recipientId!,
      ...n.targetUserIds,
    };
    if (explicitUserIds.isNotEmpty) {
      return currentUserId != null && explicitUserIds.contains(currentUserId);
    }
    if (n.targetRoles.isNotEmpty) {
      return userRole != null && n.targetRoles.contains(userRole);
    }
    if (n.broadcast) return true;
    return true;
  }

  CollectionReference<Map<String, dynamic>> _ref() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('notifications');
  }

  /// Stream всех уведомлений (новые сверху), отфильтрованных по роли
  Stream<List<InAppNotification>> watchAll({int limit = 50}) {
    return _ref()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => InAppNotification.fromMap(doc.data(), doc.id))
            .where(_canSeeNotification)
            .toList());
  }

  /// Stream количества непрочитанных (с учётом роли)
  Stream<int> watchUnreadCount() {
    return _ref().where('read', isEqualTo: false).snapshots().map((snap) => snap
        .docs
        .map((doc) => InAppNotification.fromMap(doc.data(), doc.id))
        .where(_canSeeNotification)
        .length);
  }

  /// Пометить как прочитанное
  Future<void> markRead(String notificationId) async {
    await _ref().doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Пометить все как прочитанные
  Future<void> markAllRead() async {
    final snap = await _ref().where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final notification = InAppNotification.fromMap(doc.data(), doc.id);
      if (!_canSeeNotification(notification)) continue;
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Удалить уведомление
  Future<void> delete(String notificationId) async {
    await _ref().doc(notificationId).delete();
  }
}

/// Модель in-app уведомления
class InAppNotification {
  final String id;
  final String type; // billing_suspended, billing_grace, payment_received, etc.
  final String title;
  final String body;
  final String severity; // info, warning, critical
  final bool read;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final String? driverId;
  final String? userId;
  final String? uid;
  final String? recipientId;
  final List<String> targetUserIds;
  final List<String> targetRoles;
  final bool broadcast;

  InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.severity = 'info',
    this.read = false,
    this.createdAt,
    this.readAt,
    this.metadata,
    this.driverId,
    this.userId,
    this.uid,
    this.recipientId,
    this.targetUserIds = const [],
    this.targetRoles = const [],
    this.broadcast = false,
  });

  factory InAppNotification.fromMap(Map<String, dynamic> map, String id) {
    return InAppNotification(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      severity: map['severity'] ?? 'info',
      read: map['read'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      readAt:
          map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      driverId: map['driverId'] as String?,
      userId: map['userId'] as String?,
      uid: map['uid'] as String?,
      recipientId: map['recipientId'] as String?,
      targetUserIds: ((map['targetUserIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      targetRoles:
          ((map['targetRoles'] as List?) ?? const []).whereType<String>().toList(),
      broadcast: map['broadcast'] == true,
    );
  }

  IconInfo get iconInfo {
    switch (severity) {
      case 'critical':
        return const IconInfo('error', 0xFFD32F2F); // red
      case 'warning':
        return const IconInfo('warning_amber', 0xFFF57C00); // orange
      default:
        return const IconInfo('info_outline', 0xFF1976D2); // blue
    }
  }
}

/// Helper for icon data without importing flutter
class IconInfo {
  final String name;
  final int colorValue;
  const IconInfo(this.name, this.colorValue);
}
