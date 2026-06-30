import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_selection_service.dart';
import '../../../widgets/company_selector_widget.dart';
import '../../../widgets/stream_loading_gate.dart';
import 'owner_app_bar_actions.dart';
import '../../../models/company_settings.dart';
import '../../../models/launch_center_logic.dart';
import '../../../models/company_setup_wizard.dart';
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
import 'sections/create_accounting_doc_screen.dart';
import 'sections/users_roles_section.dart';
import 'sections/clients_section.dart';
import '../../../services/company_setup_wizard_service.dart';
import '../../../screens/setup/company_setup_wizard_screen.dart';
import 'sections/onboarding_section.dart';
import '../../../theme/app_theme.dart';

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
      key: 'onboarding',
      label: 'onboarding',
      icon: Icons.flag_outlined,
      moduleKey: 'overview'),
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
      key: 'create_document',
      label: 'create_document',
      icon: Icons.add_circle_outline,
      moduleKey: 'accounting'),
  _DashboardSection(
      key: 'clients',
      label: 'clients',
      icon: Icons.people_outline,
      moduleKey: 'accounting'),
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
  ('ownerNavOverview', ['onboarding', 'overview']),
  ('ownerNavManagement', ['users_roles', 'billing', 'settings']),
  ('ownerNavOperations', ['ops_health', 'reports', 'create_document', 'clients', 'accounting']),
  ('ownerNavCompliance', ['audit']),
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
    case 'onboarding':
      return l10n.onboardingCenterTitle;
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
    case 'create_document':
      return l10n.createDocument;
    case 'clients':
      return l10n.clientManagement;
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
  bool _onboardingDefaultSectionSet = false;
  bool _companyInitStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCompanyContext());
  }

  Future<void> _ensureCompanyContext() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    if (auth.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCompanyContext());
      return;
    }
    if (_companyInitStarted) return;
    final user = auth.userModel;
    if (user == null) return;
    _companyInitStarted = true;

    final cs = context.read<CompanySelectionService>();
    final needsPicker =
        user.isSuperAdmin || (user.isAdmin && auth.viewAsRole != null);
    if (!needsPicker) return;

    if (cs.selectedCompanyId == null) {
      await cs.ensureRestored();
      if (cs.selectedCompanyId == null && auth.virtualCompanyId != null) {
        cs.selectCompany(auth.virtualCompanyId!);
      }
      if (cs.selectedCompanyId == null) {
        await cs.loadCompanies();
      }
    }
    final id = cs.selectedCompanyId;
    if (id != null && id.isNotEmpty) {
      auth.setVirtualCompanyId(id);
    }
  }

  bool _isSectionUnderConstruction(String key, AppRole role) {
    if (key != 'accounting') return false;
    return role != AppRole.superAdmin &&
        role != AppRole.owner &&
        role != AppRole.admin &&
        role != AppRole.accountant;
  }

  String _sectionLabelForUi(String key, AppLocalizations l10n, AppRole role) {
    final base = _sectionLabel(key, l10n);
    return _isSectionUnderConstruction(key, role) ? '$base (בפיתוח)' : base;
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
      final user = authService.userModel;
      final needsPicker = user?.isSuperAdmin == true ||
          (user?.isAdmin == true && authService.viewAsRole != null);
      if (needsPicker) {
        return _PickCompanyScreen();
      }
      return _NoCompanyScreen();
    }

    final userModel = authService.userModel;
    if (userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamLoadingGate<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .snapshots(),
      onTimeout: (context) => _ErrorScreen(
        message: AppLocalizations.of(context)?.companyDataNotFound ??
            'Company data not found',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return _ErrorScreen(
              message: AppLocalizations.of(context)?.companyDataNotFound ??
                  'Company data not found');
        }

        final companySettings = CompanySettings.fromFirestore(snapshot.data!);
        final visibleSectionKeys =
            EntitlementsService.getVisibleSectionsForCompany(companySettings);

        final effectiveRole = effectiveAppRole(
          actualRole: userModel.role,
          viewAsRole: authService.viewAsRole,
        );
        final permissions = PermissionsService(
          role: effectiveRole,
          userCompanyId: companyId,
        );
        final canSeeOnboarding = LaunchCenterLogic.canSeeLaunchCenter(
          effectiveRole.value,
        );

        final wizardService = CompanySetupWizardService(companyId: companyId);
        return StreamBuilder<CompanySetupWizardState>(
          stream: wizardService.watchState(),
          builder: (context, wizardSnap) {
            final wizardState =
                wizardSnap.data ?? CompanySetupWizardState.initial();

            final visibleSections = _allSections
                .where((s) => visibleSectionKeys.contains(s.key))
                .where((s) => permissions.canRead(s.moduleKey))
                .where((s) => !_isSectionUnderConstruction(s.key, effectiveRole))
                .where((s) =>
                    s.key != 'onboarding' ||
                    (canSeeOnboarding && !wizardState.wizardCompleted))
                .toList();

            if (visibleSections.isEmpty) {
              return _ErrorScreen(
                  message: AppLocalizations.of(context)?.noSectionsAvailable ??
                      'No sections available');
            }

            if (canSeeOnboarding &&
                !wizardState.wizardCompleted &&
                !_onboardingDefaultSectionSet &&
                visibleSections.any((s) => s.key == 'onboarding')) {
              _onboardingDefaultSectionSet = true;
              final idx =
                  visibleSections.indexWhere((s) => s.key == 'onboarding');
              if (idx >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedIndex = idx);
                });
              }
            }

            // Бухгалтер по умолчанию видит секцию «Бухгалтерия» (инвойсы и документы)
            if (effectiveRole == AppRole.accountant &&
                !_accountantDefaultSectionSet &&
                visibleSections.any((s) => s.key == 'accounting')) {
              _accountantDefaultSectionSet = true;
              final idx =
                  visibleSections.indexWhere((s) => s.key == 'accounting');
              if (idx >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedIndex = idx);
                });
              }
            }

            final safeIndex =
                _selectedIndex.clamp(0, visibleSections.length - 1);
            final currentSection = visibleSections[safeIndex];

            try {
              effectiveAppRole(
                actualRole: userModel.role,
                viewAsRole: authService.viewAsRole,
              );
            } catch (_) {
              final unknownRole =
                  authService.effectiveRole ?? userModel.role ?? 'unknown';
              return _ErrorScreen(
                  message: AppLocalizations.of(context)
                          ?.unknownRoleError(unknownRole) ??
                      'Unknown role: $unknownRole');
            }

            final l10n = AppLocalizations.of(context)!;
            final isNarrow = MediaQuery.of(context).size.width < 600;
            final isViewMode = authService.viewAsRole != null;

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
                ? _buildDrawer(
                    context, l10n, visibleSections, safeIndex, effectiveRole)
                : null,
            body: Column(
              children: [
                // View-as-role banner
                if (isViewMode)
                  _buildViewModeBanner(context, authService, l10n),
                SetupWizardBanner(companyId: companyId),
                // Main content
                Expanded(
                  child: isNarrow
                      ? _buildSectionContent(
                          currentSection.key,
                          companyId,
                          companySettings,
                          permissions,
                        )
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
                                  effectiveRole,
                                  onSelect: (index) {
                                    final section = visibleSections[index];
                                    if (_isSectionUnderConstruction(
                                        section.key, effectiveRole)) {
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
                              child: _buildSectionContent(
                                currentSection.key,
                                companyId,
                                companySettings,
                                permissions,
                              ),
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
        color: AppTheme.surfaceHi,
        border: Border(bottom: BorderSide(color: AppTheme.accent, width: 2)),
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
              Icon(Icons.visibility, color: AppTheme.accentSoft, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${l10n.viewingAs} $roleLabel',
                  style: TextStyle(
                      color: AppTheme.accentSoft,
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
    int selectedIndex,
    AppRole role, {
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
              _sectionLabelForUi(section.key, l10n, role),
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
      List<_DashboardSection> sections, int selectedIndex, AppRole role) {
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
              role,
              onSelect: (i) {
                final section = sections[i];
                if (_isSectionUnderConstruction(section.key, role)) {
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
    String sectionKey,
    String companyId,
    CompanySettings companySettings,
    PermissionsService permissions,
  ) {
    switch (sectionKey) {
      case 'onboarding':
        return OnboardingSection(
          key: ValueKey('onboarding-$companyId'),
          companyId: companyId,
          companySettings: companySettings,
        );
      case 'overview':
        return OverviewSection(
          key: ValueKey('overview-$companyId'),
          companyId: companyId,
          companySettings: companySettings,
        );
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
          key: ValueKey('audit-$companyId'),
          companyId: companyId,
          companySettings: companySettings,
        );
      case 'ops_health':
        return OpsHealthSection(
            companyId: companyId, companySettings: companySettings);
      case 'accounting':
        return AccountingSection(
            companyId: companyId, companySettings: companySettings);
      case 'create_document':
        return CreateAccountingDocSection(
          key: ValueKey('create-doc-$companyId'),
          companyId: companyId,
          companySettings: companySettings,
        );
      case 'clients':
        return const ClientsSection(key: ValueKey('clients'));
      case 'reports':
        return ReportsSection(
          companyId: companyId,
          companySettings: companySettings,
          showStockReport: permissions.canRead('warehouse') &&
              companySettings.modules.warehouse,
        );
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
                    size: 72, color: AppTheme.muted),
                const SizedBox(height: 24),
                Text(
                  l10n?.noCompanySelected ?? 'No company selected',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.pleaseSelectCompany ??
                      'Please select a company to continue.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.muted),
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

class _PickCompanyScreen extends StatefulWidget {
  const _PickCompanyScreen();

  @override
  State<_PickCompanyScreen> createState() => _PickCompanyScreenState();
}

class _PickCompanyScreenState extends State<_PickCompanyScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final cs = context.read<CompanySelectionService>();
    await cs.ensureRestored();
    await cs.loadCompanies();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();
    final cs = context.watch<CompanySelectionService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.noCompanySelected),
          actions: [
            if (auth.viewAsRole != null)
              TextButton(
                onPressed: () => auth.setViewAsRole(null),
                child: Text(l10n.backToAdmin),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.pleaseSelectCompany,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: cs.selectedCompanyId,
                          decoration: InputDecoration(
                            labelText: l10n.companyId,
                            border: const OutlineInputBorder(),
                          ),
                          items: cs.availableCompanies
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            cs.selectCompany(id);
                            auth.setVirtualCompanyId(id);
                          },
                        ),
                      ],
                    ),
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
                Icon(Icons.error_outline, size: 72, color: AppTheme.danger),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.error ?? 'Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.danger,
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
                      ?.copyWith(color: AppTheme.muted),
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
