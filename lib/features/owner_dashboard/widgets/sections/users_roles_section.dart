import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/auth_service.dart';
import '../../models/member_with_user.dart';
import '../../models/membership.dart';
import '../../models/role_hierarchy.dart';
import '../../repositories/members_repository.dart';
import '../../services/entitlements_service.dart';
import '../../services/permissions_service.dart';

/// Секция «Пользователи и роли» Owner Dashboard.
///
/// Отображает:
/// - Список membership-документов с данными из Global User
/// - Статус каждого пользователя: active, invited, suspended
/// - Форма создания приглашения: emailOrPhone, role
/// - Кнопки: одобрить/отклонить приглашение, изменить роль, удалить участника
/// - Предупреждение при достижении лимита пользователей
///
/// Ограничения назначения ролей (Task 10.2):
/// - Owner: admin, dispatcher, driver, warehouse_keeper, accountant, viewer (NOT owner, super_admin)
/// - Admin: admin, dispatcher, driver, warehouse_keeper, accountant, viewer (NOT owner, super_admin)
/// - Super_admin: все роли
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11
class UsersRolesSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const UsersRolesSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<UsersRolesSection> createState() => _UsersRolesSectionState();
}

class _UsersRolesSectionState extends State<UsersRolesSection> {
  late final MembersRepository _membersRepo;
  late PermissionsService _permissions;

  @override
  void initState() {
    super.initState();
    _membersRepo = MembersRepository(companyId: widget.companyId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    if (userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentRole = AppRole.fromString(userModel.role);
    _permissions = PermissionsService(
      role: currentRole,
      userCompanyId: userModel.companyId ?? '',
    );

    final narrow = MediaQuery.sizeOf(context).width < 500;
    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMembersSection(context, userModel),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Members List — Requirement 5.1, 5.10
  // ---------------------------------------------------------------------------

  Widget _buildMembersSection(BuildContext context, dynamic userModel) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.teamMembers, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<MemberWithUser>>(
          stream: _membersRepo.watchMembers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.errorLoadingUsers,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              );
            }

            final members = snapshot.data ?? [];

            // User limit warning — Requirement 5.9
            final activeCount = members
                .where((m) => m.status == MembershipStatus.active)
                .length;
            final usersLimit = widget.companySettings.limits.maxUsers;
            final canInvite =
                EntitlementsService.canCreateInvite(activeCount, usersLimit);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canInvite)
                  _UserLimitWarning(
                    activeCount: activeCount,
                    usersLimit: usersLimit,
                  ),
                if (members.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.noTeamMembers)),
                    ),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) => _MemberTile(
                        member: members[index],
                        permissions: _permissions,
                        onChangeRole: (newRole) =>
                            _handleChangeRole(members[index].uid, newRole),
                        onRemove: () =>
                            _handleRemoveMember(context, members[index]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Action handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleChangeRole(String uid, AppRole newRole) async {
    try {
      await _membersRepo.updateRole(uid, newRole.value);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, l10n.roleUpdatedSuccess);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(context, l10n.errorUpdatingRole(e), isError: true);
      }
    }
  }

  Future<void> _handleRemoveMember(
      BuildContext context, MemberWithUser member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeUserTitle),
        content: Text(l10n.removeUserConfirm(member.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeUser),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _membersRepo.removeMember(member.uid);
      if (context.mounted) {
        _showSnackBar(context, l10n.userRemovedSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, l10n.errorRemovingUser(e), isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

// =============================================================================
// Helper function
// =============================================================================

/// Localized display name for each role.
String _roleDisplayName(AppRole role, AppLocalizations l10n) {
  switch (role) {
    case AppRole.superAdmin:
      return l10n.roleSuperAdmin;
    case AppRole.owner:
      return l10n.roleOwner;
    case AppRole.admin:
      return l10n.roleAdmin;
    case AppRole.dispatcher:
      return l10n.roleDispatcher;
    case AppRole.driver:
      return l10n.roleDriverLabel;
    case AppRole.warehouseKeeper:
      return l10n.roleWarehouseKeeper;
    case AppRole.accountant:
      return l10n.roleAccountant;
    case AppRole.viewer:
      return l10n.roleViewer;
  }
}

/// Status chip color and label.
({Color color, String label}) _statusInfo(
    MembershipStatus status, AppLocalizations l10n) {
  switch (status) {
    case MembershipStatus.active:
      return (color: Colors.green, label: l10n.statusActive);
    case MembershipStatus.invited:
      return (color: Colors.orange, label: l10n.statusInvited);
    case MembershipStatus.suspended:
      return (color: Colors.red, label: l10n.statusSuspended);
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// Warning banner when user limit is reached — Requirement 5.9.
class _UserLimitWarning extends StatelessWidget {
  final int activeCount;
  final int usersLimit;

  const _UserLimitWarning({
    required this.activeCount,
    required this.usersLimit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
        title: Text(
          l10n.usersLimitReached(activeCount, usersLimit),
          style: TextStyle(color: Colors.red.shade700),
        ),
        subtitle: Text(
          l10n.usersLimitUpgrade,
          style: TextStyle(color: Colors.red.shade600),
        ),
      ),
    );
  }
}

/// Single member row with role change and remove actions.
class _MemberTile extends StatelessWidget {
  final MemberWithUser member;
  final PermissionsService permissions;
  final ValueChanged<AppRole> onChangeRole;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.permissions,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = _statusInfo(member.status, l10n);
    final displayName =
        member.displayName.isNotEmpty ? member.displayName : member.email;
    final subtitle = '${_roleDisplayName(member.role, l10n)}'
        '${member.email.isNotEmpty ? ' · ${member.email}' : ''}'
        '${member.phone.isNotEmpty ? ' · ${member.phone}' : ''}';

    final assignableRoles =
        AppRole.values.where((r) => permissions.canAssignRole(r)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        info.label,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: info.color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (assignableRoles.isNotEmpty &&
              permissions.canWrite('members', 'update'))
            SizedBox(
              width: 48,
              height: 48,
              child: PopupMenuButton<AppRole>(
                icon: const Icon(Icons.swap_horiz, size: 22),
                tooltip: l10n.changeRole,
                padding: EdgeInsets.zero,
                onSelected: onChangeRole,
                itemBuilder: (context) => assignableRoles.map((role) {
                  return PopupMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        if (role == member.role)
                          Icon(Icons.check,
                              size: 16, color: theme.colorScheme.primary),
                        if (role == member.role) const SizedBox(width: 8),
                        Flexible(
                            child: Text(_roleDisplayName(role, l10n),
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (permissions.canWrite('members', 'delete'))
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(Icons.person_remove_outlined,
                    size: 22, color: theme.colorScheme.error),
                tooltip: l10n.removeUser,
                onPressed: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}
