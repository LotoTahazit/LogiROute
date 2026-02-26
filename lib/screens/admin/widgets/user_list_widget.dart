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
        return 'מחסנאי / Warehouse Keeper';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (users.isEmpty) {
      return Center(child: Text(l10n.noUsersFound));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () => onUserTap(user),
            leading: Icon(
              user.role == 'driver'
                  ? Icons.local_shipping
                  : user.role == 'dispatcher'
                      ? Icons.assignment
                      : user.role == 'warehouse_keeper'
                          ? Icons.inventory_2
                          : Icons.admin_panel_settings,
              color: Colors.blue,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${user.email} • ${_getLocalizedRole(user.role, l10n)}${user.role == 'driver' && user.vehicleNumber != null ? ' • 🚗 ${user.vehicleNumber}' : ''}',
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: user.role == 'driver'
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                  )
                : null,
          ),
        );
      },
    );
  }
}
