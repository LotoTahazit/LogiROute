import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_selection_service.dart';
import '../../../widgets/company_selector_widget.dart';
import '../../../widgets/notification_bell.dart';
import '../../../models/company_settings.dart';
import '../models/role_hierarchy.dart';
import '../services/entitlements_service.dart';
import '../services/permissions_service.dart';
import 'sections/accounting_section.dart';
import 'sections/billing_section.dart';
import 'sections/overview_section.dart';
import 'sections/reports_section.dart';
import 'sections/settings_section.dart';
import 'sections/audit_section.dart';
import 'sections/ops_health_section.dart';
import 'sections/users_roles_section.dart';

/// Описание секции навигации Owner Dashboard.
class _DashboardSection {
  final String key;
  final String label;
  final IconData icon;
  final String moduleKey;

  const _DashboardSection({
    required this.key,
    required this.label,
    required this.icon,
    required this.moduleKey,
  });
}

const _allSections = <_DashboardSection>[
  _DashboardSection(
      key: 'overview',
      label: 'overview',
      icon: Icons.dashboard_outlined,
      moduleKey: 'overview'),
  _DashboardSection(
      key: 'users_roles',
      label: 'users_roles',
      icon: Icons.people_outlined,
      moduleKey: 'users'),
  _DashboardSection(
      key: 'billing',
      label: 'billing',
      icon: Icons.payment_outlined,
      moduleKey: 'billing'),
  _DashboardSection(
      key: 'settings',
      label: 'settings',
      icon: Icons.settings_outlined,
      moduleKey: 'settings'),
  _DashboardSection(
      key: 'audit',
      label: 'audit',
      icon: Icons.policy_outlined,
      moduleKey: 'audit'),
  _DashboardSection(
      key: 'ops_health',
      label: 'ops_health',
      icon: Icons.monitor_heart_outlined,
      moduleKey: 'ops_health'),
  _DashboardSection(
      key: 'accounting',
      label: 'accounting',
      icon: Icons.receipt_long_outlined,
      moduleKey: 'accounting'),
  _DashboardSection(
      key: 'reports',
      label: 'reports',
      icon: Icons.bar_chart_outlined,
      moduleKey: 'reports'),
];

String _sectionLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'overview':
      return l10n.overviewSection;
    case 'users_roles':
      return l10n.usersAndRoles;
    case 'billing':
      return l10n.billingSection;
    case 'settings':
      return l10n.settings;
    case 'audit':
      return l10n.auditAndCompliance;
    case 'ops_health':
      return l10n.operationsSection;
    case 'accounting':
      return l10n.accountingSection;
    case 'reports':
      return l10n.reports;
    default:
      return key;
  }
}

class OwnerDashboardShell extends StatefulWidget {
  const OwnerDashboardShell({super.key});

  @override
  State<OwnerDashboardShell> createState() => _OwnerDashboardShellState();
}

class _OwnerDashboardShellState extends State<OwnerDashboardShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final companySelection = context.watch<CompanySelectionService>();
    final companyId = companySelection.getEffectiveCompanyId(authService);

    if (companyId == null || companyId.isEmpty) {
      return _NoCompanyScreen();
    }

    final userModel = authService.userModel;
    if (userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return _ErrorScreen(
              message: AppLocalizations.of(context)?.companyDataNotFound ??
                  'Company data not found');
        }

        final companySettings = CompanySettings.fromFirestore(snapshot.data!);
        final billingStatus = companySettings.billingStatus;
        final visibleSectionKeys =
            EntitlementsService.getVisibleSections(billingStatus);

        final appRole = AppRole.fromString(userModel.role);
        final permissions =
            PermissionsService(role: appRole, userCompanyId: companyId);

        final visibleSections = _allSections
            .where((s) => visibleSectionKeys.contains(s.key))
            .where((s) => permissions.canRead(s.moduleKey))
            .toList();

        if (visibleSections.isEmpty) {
          return _ErrorScreen(
              message: AppLocalizations.of(context)?.noSectionsAvailable ??
                  'No sections available');
        }

        final safeIndex = _selectedIndex.clamp(0, visibleSections.length - 1);
        final currentSection = visibleSections[safeIndex];

        try {
          AppRole.fromString(userModel.role);
        } catch (_) {
          return _ErrorScreen(
              message: AppLocalizations.of(context)
                      ?.unknownRoleError(userModel.role) ??
                  'Unknown role: ${userModel.role}');
        }

        final l10n = AppLocalizations.of(context)!;
        final isNarrow = MediaQuery.of(context).size.width < 600;
        final isViewMode = authService.userModel?.isAdmin == true &&
            authService.viewAsRole != null;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: _buildTopBar(
              context,
              companySettings: companySettings,
              userModel: userModel,
              companyId: companyId,
            ),
            drawer: isNarrow
                ? _buildDrawer(context, l10n, visibleSections, safeIndex)
                : null,
            body: Column(
              children: [
                // View-as-role banner
                if (isViewMode)
                  _buildViewModeBanner(context, authService, l10n),
                // Main content
                Expanded(
                  child: isNarrow
                      ? _buildSectionContent(
                          currentSection.key, companyId, companySettings)
                      : Row(
                          children: [
                            NavigationRail(
                              selectedIndex: safeIndex,
                              onDestinationSelected: (index) {
                                setState(() => _selectedIndex = index);
                              },
                              labelType: NavigationRailLabelType.all,
                              leading: const SizedBox(height: 8),
                              destinations: visibleSections.map((section) {
                                return NavigationRailDestination(
                                  icon: Icon(section.icon),
                                  selectedIcon: Icon(section.icon),
                                  label: Text(_sectionLabel(section.key, l10n)),
                                );
                              }).toList(),
                            ),
                            const VerticalDivider(thickness: 1, width: 1),
                            Expanded(
                              child: _buildSectionContent(currentSection.key,
                                  companyId, companySettings),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewModeBanner(
      BuildContext context, AuthService authService, AppLocalizations l10n) {
    final roleName = authService.viewAsRole ?? '';
    String roleLabel;
    switch (roleName) {
      case 'accountant':
        roleLabel = l10n.accountingSection;
      case 'owner':
        roleLabel = roleName;
      default:
        roleLabel = roleName;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border:
            Border(bottom: BorderSide(color: Colors.blue.shade300, width: 2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, color: Colors.blue.shade900, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${l10n.viewingAs} $roleLabel',
                  style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => authService.setViewAsRole(null),
            icon: const Icon(Icons.admin_panel_settings, size: 18),
            label: Text(l10n.backToAdmin),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n,
      List<_DashboardSection> sections, int selectedIndex) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 16),
            ...sections.asMap().entries.map((entry) {
              final i = entry.key;
              final section = entry.value;
              final isSelected = i == selectedIndex;
              return ListTile(
                leading: Icon(section.icon,
                    color: isSelected ? Theme.of(context).primaryColor : null),
                title: Text(_sectionLabel(section.key, l10n),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    )),
                selected: isSelected,
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context); // close drawer
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(
    BuildContext context, {
    required CompanySettings companySettings,
    required dynamic userModel,
    required String companyId,
  }) {
    final theme = Theme.of(context);

    return AppBar(
      title: Row(
        children: [
          if (userModel.isSuperAdmin) ...[
            const CompanySelectorWidget(),
            const SizedBox(width: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business,
                    size: 18, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  companySettings.nameHebrew.isNotEmpty
                      ? companySettings.nameHebrew
                      : companySettings.id,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    companySettings.plan,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: AppLocalizations.of(context)?.refresh ?? 'Refresh',
          onPressed: () => setState(() {}),
        ),
        NotificationBell(companyId: companyId),
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: AppLocalizations.of(context)?.userMenu ?? 'User menu',
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
              child:
                  Text(userModel.role ?? '', style: theme.textTheme.bodySmall),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionContent(
      String sectionKey, String companyId, CompanySettings companySettings) {
    switch (sectionKey) {
      case 'overview':
        return OverviewSection(
            companyId: companyId, companySettings: companySettings);
      case 'users_roles':
        return UsersRolesSection(
            companyId: companyId, companySettings: companySettings);
      case 'billing':
        return BillingSection(
            companyId: companyId, companySettings: companySettings);
      case 'settings':
        return SettingsSection(
            companyId: companyId, companySettings: companySettings);
      case 'audit':
        return AuditSection(
            companyId: companyId, companySettings: companySettings);
      case 'ops_health':
        return OpsHealthSection(
            companyId: companyId, companySettings: companySettings);
      case 'accounting':
        return AccountingSection(
            companyId: companyId, companySettings: companySettings);
      case 'reports':
        return ReportsSection(
            companyId: companyId, companySettings: companySettings);
      default:
        return Center(
            child: Text(sectionKey, style: const TextStyle(fontSize: 24)));
    }
  }
}

class _NoCompanyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined,
                    size: 72, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  l10n?.noCompanySelected ?? 'No company selected',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.pleaseSelectCompany ??
                      'Please select a company to continue.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.error ?? 'Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
