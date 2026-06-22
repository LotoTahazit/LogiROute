import 'package:flutter/material.dart';
import '../../warehouse/warehouse_dashboard.dart';
import '../../shared/inventory_report_screen.dart';
import '../analytics_screen.dart';
import '../../../screens/shared/reports_screen.dart';
import '../inventory_counts_list_screen.dart';
import '../company_settings_screen.dart';
import '../archive_management_screen.dart';
import '../../shared/route_archive_screen.dart';
import '../billing_locks_screen.dart';
import '../module_toggle_screen.dart';
import '../subscription_screen.dart';
import '../billing/billing_portal_screen.dart';
import '../backup_management_screen.dart';
import '../data_retention_screen.dart';
import '../support_console_screen.dart';
import '../admin_activity_screen.dart';
import '../../../screens/shared/client_management_screen.dart';
import '../integrity_check_screen.dart';
import '../create_company_screen.dart';
import '../product_management_screen.dart';
import '../terminology_settings_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/locale_service.dart';

/// AppBar actions для админа — сгруппированные меню (вариант A).
class AdminAppBarActions extends StatelessWidget {
  final VoidCallback onAddUser;
  final VoidCallback onRefresh;
  final bool isLoading;
  final AuthService authService;
  final LocaleService localeService;

  const AdminAppBarActions({
    super.key,
    required this.onAddUser,
    required this.onRefresh,
    required this.isLoading,
    required this.authService,
    required this.localeService,
  });

  bool get _isSuperAdmin => authService.userModel?.isSuperAdmin == true;

  void _handleAction(BuildContext context, String value) {
    switch (value) {
      case 'add_user':
        onAddUser();
      case 'refresh':
        onRefresh();
      case 'activity_log':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminActivityScreen()),
        );
      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        );
      case 'reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
      case 'warehouse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WarehouseDashboard()),
        );
      case 'products':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
        );
      case 'inventory_report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryReportScreen()),
        );
      case 'inventory_counts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryCountsListScreen()),
        );
      case 'company_settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompanySettingsScreen()),
        );
      case 'terminology':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TerminologySettingsScreen()),
        );
      case 'route_archive':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RouteArchiveScreen()),
        );
      case 'archive':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArchiveManagementScreen()),
        );
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      case 'billing_portal':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BillingPortalScreen()),
        );
      case 'client_management':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientManagementScreen()),
        );
      case 'billing_locks':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BillingLocksScreen()),
        );
      case 'module_toggle':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ModuleToggleScreen()),
        );
      case 'backup':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupManagementScreen()),
        );
      case 'data_retention':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataRetentionScreen()),
        );
      case 'integrity_check':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IntegrityCheckScreen()),
        );
      case 'create_company':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
        );
      case 'support_console':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupportConsoleScreen()),
        );
      case 'logout':
        authService.signOut();
      case 'he':
      case 'ru':
      case 'en':
        localeService.setLocale(value);
    }
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sectionHeader(String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 36,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  List<PopupMenuEntry<String>> _reportItems(AppLocalizations l10n) => [
        _item('analytics', Icons.analytics, l10n.analytics),
        _item('reports', Icons.assessment, l10n.reports),
        _item('inventory_report', Icons.swap_horiz, l10n.inventoryChangesReport),
        _item('inventory_counts', Icons.fact_check, l10n.inventoryCountReportsTooltip),
        _item('activity_log', Icons.history, l10n.adminActivityLog),
      ];

  List<PopupMenuEntry<String>> _warehouseItems(AppLocalizations l10n) => [
        _item('warehouse', Icons.inventory_2, l10n.warehouseInventory),
        _item('products', Icons.category, l10n.productManagement),
      ];

  List<PopupMenuEntry<String>> _companyItems(AppLocalizations l10n) => [
        _item('company_settings', Icons.business, l10n.companySettings),
        _item('terminology', Icons.translate, l10n.terminologySettings),
        _item('route_archive', Icons.history, l10n.routeArchiveTitle),
        _item('archive', Icons.archive, l10n.archiveManagement),
        _item('client_management', Icons.people, l10n.clientManagement),
      ];

  List<PopupMenuEntry<String>> _billingItems(AppLocalizations l10n) => [
        _item('billing_portal', Icons.receipt_long, l10n.billingPortal),
        _item('subscription', Icons.card_membership, l10n.subscriptionManagement),
      ];

  List<PopupMenuEntry<String>> _platformItems(AppLocalizations l10n) => [
        _item('billing_locks', Icons.payments, l10n.billingAndLocks),
        _item('module_toggle', Icons.toggle_on, l10n.moduleManagement),
        _item('backup', Icons.backup, l10n.backupManagement),
        _item('data_retention', Icons.policy, l10n.dataRetention),
        _item('integrity_check', Icons.verified_user, l10n.integrityCheck),
        _item('create_company', Icons.add_business, l10n.createCompany),
        _item('support_console', Icons.support_agent, l10n.supportConsoleTitle),
      ];

  Widget _groupMenu({
    required IconData icon,
    required String tooltip,
    required List<PopupMenuEntry<String>> items,
    required BuildContext context,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: (v) => _handleAction(context, v),
      itemBuilder: (_) => items,
    );
  }

  List<PopupMenuEntry<String>> _mobileMenuItems(AppLocalizations l10n) {
    return [
      _item('add_user', Icons.add, l10n.addUser),
      PopupMenuItem(
        value: 'refresh',
        enabled: !isLoading,
        child: Row(
          children: [
            const Icon(Icons.refresh, size: 20),
            const SizedBox(width: 8),
            Text(l10n.refresh),
          ],
        ),
      ),
      const PopupMenuDivider(),
      _sectionHeader(l10n.appBarGroupReports),
      ..._reportItems(l10n),
      const PopupMenuDivider(),
      _sectionHeader(l10n.appBarGroupWarehouse),
      ..._warehouseItems(l10n),
      const PopupMenuDivider(),
      _sectionHeader(l10n.appBarGroupCompany),
      ..._companyItems(l10n),
      const PopupMenuDivider(),
      _sectionHeader(l10n.appBarGroupBilling),
      ..._billingItems(l10n),
      if (_isSuperAdmin) ...[
        const PopupMenuDivider(),
        _sectionHeader(l10n.appBarGroupPlatform),
        ..._platformItems(l10n),
      ],
      const PopupMenuDivider(),
      _sectionHeader(l10n.settings),
      PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
      PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
      PopupMenuItem(value: 'en', child: Text(l10n.english)),
      const PopupMenuDivider(),
      _item('logout', Icons.logout, l10n.logout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () => authService.signOut(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.settings,
            onSelected: (v) => _handleAction(context, v),
            itemBuilder: (_) => _mobileMenuItems(l10n),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: l10n.addUser,
          onPressed: onAddUser,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.refresh,
          onPressed: isLoading ? null : onRefresh,
        ),
        _groupMenu(
          context: context,
          icon: Icons.bar_chart,
          tooltip: l10n.appBarGroupReports,
          items: _reportItems(l10n),
        ),
        _groupMenu(
          context: context,
          icon: Icons.inventory_2_outlined,
          tooltip: l10n.appBarGroupWarehouse,
          items: _warehouseItems(l10n),
        ),
        _groupMenu(
          context: context,
          icon: Icons.business_outlined,
          tooltip: l10n.appBarGroupCompany,
          items: _companyItems(l10n),
        ),
        _groupMenu(
          context: context,
          icon: Icons.receipt_long_outlined,
          tooltip: l10n.appBarGroupBilling,
          items: _billingItems(l10n),
        ),
        if (_isSuperAdmin)
          _groupMenu(
            context: context,
            icon: Icons.admin_panel_settings_outlined,
            tooltip: l10n.appBarGroupPlatform,
            items: _platformItems(l10n),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: l10n.settings,
          onSelected: (v) => _handleAction(context, v),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
            PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
            PopupMenuItem(value: 'en', child: Text(l10n.english)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: l10n.logout,
          onPressed: () => authService.signOut(),
        ),
      ],
    );
  }
}
