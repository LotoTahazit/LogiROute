import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_selection_service.dart';
import '../../../widgets/company_selector_widget.dart';
import 'owner_app_bar_actions.dart';
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

/// Группы боковой навигации Owner Dashboard.
const _navGroups = <(String labelKey, List<String> sectionKeys)>[
  ('ownerNavOverview', ['overview']),
  ('ownerNavManagement', ['users_roles', 'billing', 'settings']),
  ('ownerNavOperations', ['ops_health', 'reports']),
  ('ownerNavCompliance', ['audit', 'accounting']),
];

String _groupLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'ownerNavOverview':
      return l10n.ownerNavOverview;
    case 'ownerNavManagement':
      return l10n.ownerNavManagement;
    case 'ownerNavOperations':
      return l10n.ownerNavOperations;
    case 'ownerNavCompliance':
      return l10n.ownerNavCompliance;
    default:
      return key;
  }
}

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
  bool _accountantDefaultSectionSet = false;

  bool _isSectionUnderConstruction(String key) => key == 'accounting';

  String _sectionLabelForUi(String key, AppLocalizations l10n) {
    final base = _sectionLabel(key, l10n);
    return _isSectionUnderConstruction(key) ? '$base (בפיתוח)' : base;
  }

  Future<void> _showUnderConstructionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('בפיתוח'),
        content: Text('מודול חשבוניות יהיה זמין בקרוב'),
      ),
    );
  }

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
            .where((s) => !_isSectionUnderConstruction(s.key))
            .toList();

        if (visibleSections.isEmpty) {
          return _ErrorScreen(
              message: AppLocalizations.of(context)?.noSectionsAvailable ??
                  'No sections available');
        }

        // Бухгалтер по умолчанию видит секцию «Бухгалтерия» (инвойсы и документы)
        if (appRole == AppRole.accountant &&
            !_accountantDefaultSectionSet &&
            visibleSections.any((s) => s.key == 'accounting') &&
            !_isSectionUnderConstruction('accounting')) {
          _accountantDefaultSectionSet = true;
          final idx = visibleSections.indexWhere((s) => s.key == 'accounting');
          if (idx >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedIndex = idx);
            });
          }
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

        final theme = Theme.of(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: _buildTopBar(
              context,
              isNarrow: isNarrow,
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 220,
                              child: ListView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                children: _buildGroupedNavWidgets(
                                  context,
                                  l10n,
                                  visibleSections,
                                  safeIndex,
                                  onSelect: (index) {
                                    final section = visibleSections[index];
                                    if (_isSectionUnderConstruction(
                                        section.key)) {
                                      _showUnderConstructionDialog();
                                      return;
                                    }
                                    setState(() => _selectedIndex = index);
                                  },
                                ),
                              ),
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
                      fontWeight: FontWeight.w700,
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

  List<Widget> _buildGroupedNavWidgets(
    BuildContext context,
    AppLocalizations l10n,
    List<_DashboardSection> sections,
    int selectedIndex, {
    required void Function(int index) onSelect,
  }) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (final (groupKey, keys) in _navGroups) {
      final inGroup =
          sections.where((s) => keys.contains(s.key)).toList(growable: false);
      if (inGroup.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const Divider(height: 1, indent: 12, endIndent: 12));
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            _groupLabel(groupKey, l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );

      for (final section in inGroup) {
        final i = sections.indexOf(section);
        final selected = i == selectedIndex;
        widgets.add(
          ListTile(
            leading: Icon(section.icon,
                size: 22, color: selected ? theme.primaryColor : null),
            title: Text(
              _sectionLabelForUi(section.key, l10n),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? theme.primaryColor : null,
              ),
            ),
            selected: selected,
            dense: true,
            onTap: () => onSelect(i),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n,
      List<_DashboardSection> sections, int selectedIndex) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.menuLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            ..._buildGroupedNavWidgets(
              context,
              l10n,
              sections,
              selectedIndex,
              onSelect: (i) {
                final section = sections[i];
                if (_isSectionUnderConstruction(section.key)) {
                  _showUnderConstructionDialog();
                  Navigator.pop(context);
                  return;
                }
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(
    BuildContext context, {
    required bool isNarrow,
    required CompanySettings companySettings,
    required dynamic userModel,
    required String companyId,
  }) {
    final theme = Theme.of(context);
    final companyName = companySettings.nameHebrew.isNotEmpty
        ? companySettings.nameHebrew
        : companySettings.id;

    return AppBar(
      titleSpacing: isNarrow ? 0 : null,
      title: isNarrow
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.business,
                      size: 18, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      companyName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                if (userModel.isSuperAdmin) ...[
                  const CompanySelectorWidget(),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            companyName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                ),
              ],
            ),
      actions: [
        OwnerAppBarActions(
          companyId: companyId,
          userModel: userModel,
          onRefresh: () => setState(() {}),
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
