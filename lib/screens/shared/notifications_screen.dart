import 'package:flutter/material.dart';
import '../../services/in_app_notification_service.dart';

/// מסך התראות — inbox של כל ההתראות של החברה
class NotificationsScreen extends StatelessWidget {
  final String companyId;

  const NotificationsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final service = InAppNotificationService(companyId: companyId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('התראות'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await service.markAllRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('כל ההתראות סומנו כנקראו'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('סמן הכל כנקרא'),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<List<InAppNotification>>(
          stream: service.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('אין התראות',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade500)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    if (!n.read) await service.markRead(n.id);
                  },
                  onDismiss: () => service.delete(n.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _icon() {
    switch (notification.severity) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.info_outline;
    }
  }

  Color _color() {
    switch (notification.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final isUnread = !notification.read;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread ? color.withValues(alpha: 0.04) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(), size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
