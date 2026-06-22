import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/notification_bell.dart';

/// AppBar Owner Dashboard — обновить, уведомления, аккаунт.
class OwnerAppBarActions extends StatelessWidget {
  final String companyId;
  final dynamic userModel;
  final VoidCallback onRefresh;

  const OwnerAppBarActions({
    super.key,
    required this.companyId,
    required this.userModel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.refresh,
          onPressed: onRefresh,
        ),
        NotificationBell(companyId: companyId),
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: l10n.userMenu,
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthService>().signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                userModel.name ?? userModel.email ?? '',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuItem(
              enabled: false,
              child: Text(userModel.role ?? '', style: theme.textTheme.bodySmall),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.logout),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
