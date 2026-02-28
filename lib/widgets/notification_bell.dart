import 'package:flutter/material.dart';
import '../services/in_app_notification_service.dart';
import '../screens/shared/notifications_screen.dart';

/// Bell icon с badge для непрочитанных уведомлений.
/// Используется в AppBar любого dashboard.
class NotificationBell extends StatelessWidget {
  final String companyId;

  const NotificationBell({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (companyId.isEmpty) return const SizedBox.shrink();

    final service = InAppNotificationService(companyId: companyId);

    return StreamBuilder<int>(
      stream: service.watchUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'התראות',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(companyId: companyId),
              ),
            );
          },
        );
      },
    );
  }
}
