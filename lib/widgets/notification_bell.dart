import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/in_app_notification_service.dart';
import '../screens/shared/notifications_screen.dart';

/// Bell icon с badge для непрочитанных уведомлений.
/// Используется в AppBar любого dashboard.
class NotificationBell extends StatefulWidget {
  final String companyId;

  const NotificationBell({super.key, required this.companyId});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  InAppNotificationService? _service;
  String? _lastRole;

  void _rebuildService(String? userRole) {
    if (_service == null || _lastRole != userRole) {
      _lastRole = userRole;
      _service = InAppNotificationService(
          companyId: widget.companyId, userRole: userRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companyId.isEmpty) return const SizedBox.shrink();

    final userRole = context.watch<AuthService>().userRole;
    _rebuildService(userRole);

    return StreamBuilder<int>(
      stream: _service!.watchUnreadCount(),
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
          tooltip:
              AppLocalizations.of(context)?.notifications ?? 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                  companyId: widget.companyId,
                  userRole: userRole,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
