import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для in-app уведомлений из Firestore.
/// Уведомления хранятся в companies/{companyId}/notifications/
/// Записываются серверными функциями (billingEnforcer, webhook и т.д.)
class InAppNotificationService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InAppNotificationService({required this.companyId});

  CollectionReference<Map<String, dynamic>> _ref() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('notifications');
  }

  /// Stream всех уведомлений (новые сверху)
  Stream<List<InAppNotification>> watchAll({int limit = 50}) {
    return _ref()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => InAppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream количества непрочитанных
  Stream<int> watchUnreadCount() {
    return _ref()
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
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
