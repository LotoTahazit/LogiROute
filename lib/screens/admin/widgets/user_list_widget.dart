import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';

/// Виджет списка пользователей
class UserListWidget extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel user) onUserTap;

  const UserListWidget({
    super.key,
    required this.users,
    required this.onUserTap,
  });

  String _getLocalizedRole(String role, AppLocalizations l10n) {
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'dispatcher':
        return l10n.roleDispatcher;
      case 'driver':
        return l10n.roleDriver;
      case 'warehouse_keeper':
        return l10n.roleWarehouseKeeper;
      case 'accountant':
        return l10n.roleAccountant;
      case 'owner':
        return l10n.roleOwner;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;

    if (users.isEmpty) {
      return Center(child: Text(l10n.noUsersFound));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final subtitleParts = [
          user.email,
          _getLocalizedRole(user.role, l10n),
          if (user.role == 'driver' && user.vehicleNumber != null)
            '🚗 ${user.vehicleNumber}',
        ];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => onUserTap(user),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    user.role == 'driver'
                        ? Icons.local_shipping
                        : user.role == 'dispatcher'
                            ? Icons.assignment
                            : user.role == 'warehouse_keeper'
                                ? Icons.inventory_2
                                : user.role == 'accountant'
                                    ? Icons.calculate
                                    : Icons.admin_panel_settings,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleParts.join(' • '),
                          style: const TextStyle(color: Colors.black54),
                          maxLines: narrow ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.role == 'driver' &&
                            (user.palletCapacity != null ||
                                user.truckWeight != null)) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (user.palletCapacity != null)
                                Text(
                                  '${user.palletCapacity} ${l10n.pallets}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              if (user.truckWeight != null)
                                Text(
                                  '${user.truckWeight!.toStringAsFixed(1)}ט',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
