import 'package:flutter/material.dart';
import '../../warehouse/warehouse_dashboard.dart';
import '../../shared/inventory_report_screen.dart';
import '../analytics_screen.dart';
import '../../../screens/shared/reports_screen.dart';
import '../inventory_counts_list_screen.dart';
import '../company_settings_screen.dart';
import '../archive_management_screen.dart';
import '../billing_locks_screen.dart';
import '../module_toggle_screen.dart';
import '../subscription_screen.dart';
import '../billing/billing_portal_screen.dart';
import '../backup_management_screen.dart';
import '../data_retention_screen.dart';
import '../support_console_screen.dart';
import '../../../screens/shared/client_management_screen.dart';
import '../integrity_check_screen.dart';
import '../nested_migration_screen.dart';
import '../final_migration_screen.dart';
import '../product_management_screen.dart';
import '../terminology_settings_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/locale_service.dart';

/// AppBar actions для админа
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // На мобилке - всё в меню
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: l10n.settings,
        onSelected: (value) {
          switch (value) {
            case 'add_user':
              onAddUser();
              break;
            case 'refresh':
              onRefresh();
              break;
            case 'analytics':
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
              break;
            case 'reports':
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()));
              break;
            case 'warehouse':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WarehouseDashboard()));
              break;
            case 'products':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductManagementScreen()));
              break;
            case 'inventory_report':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InventoryReportScreen()));
              break;
            case 'inventory_counts':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InventoryCountsListScreen()));
              break;
            case 'company_settings':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompanySettingsScreen()));
              break;
            case 'terminology':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TerminologySettingsScreen()));
              break;
            case 'archive':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArchiveManagementScreen()));
              break;
            case 'billing_locks':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BillingLocksScreen()));
              break;
            case 'module_toggle':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ModuleToggleScreen()));
              break;
            case 'subscription':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen()));
              break;
            case 'billing_portal':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BillingPortalScreen()));
              break;
            case 'client_management':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClientManagementScreen()));
              break;
            case 'backup':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BackupManagementScreen()));
              break;
            case 'data_retention':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DataRetentionScreen()));
              break;
            case 'integrity_check':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IntegrityCheckScreen()));
              break;
            case 'nested_migration':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NestedMigrationScreen()));
              break;
            case 'final_migration':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FinalMigrationScreen()));
              break;
            case 'support_console':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SupportConsoleScreen()));
              break;
            case 'logout':
              authService.signOut();
              break;
            case 'he':
            case 'ru':
            case 'en':
              localeService.setLocale(value);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'add_user',
            child: Row(
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 8),
                Text(l10n.addUser),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'refresh',
            enabled: !isLoading,
            child: Row(
              children: [
                const Icon(Icons.refresh),
                const SizedBox(width: 8),
                Text(l10n.refresh),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'analytics',
            child: Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(l10n.analytics),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reports',
            child: Row(
              children: [
                const Icon(Icons.assessment),
                const SizedBox(width: 8),
                const Text('דוחות'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'warehouse',
            child: Row(
              children: [
                const Icon(Icons.inventory_2),
                const SizedBox(width: 8),
                Text(l10n.warehouseInventory),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'products',
            child: Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text(l10n.productManagement),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'inventory_report',
            child: Row(
              children: [
                const Icon(Icons.assessment),
                const SizedBox(width: 8),
                Text(l10n.inventoryChangesReport),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'inventory_counts',
            child: Row(
              children: [
                const Icon(Icons.fact_check),
                const SizedBox(width: 8),
                Text(l10n.inventoryCountReportsTooltip),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'company_settings',
            child: Row(
              children: [
                const Icon(Icons.business),
                const SizedBox(width: 8),
                Text(l10n.companySettings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'terminology',
            child: Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 8),
                Text(l10n.terminologySettings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive),
                const SizedBox(width: 8),
                Text(l10n.archiveManagement),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'subscription',
            child: Row(
              children: [
                const Icon(Icons.card_membership),
                const SizedBox(width: 8),
                const Text('ניהול מנוי'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'billing_portal',
            child: Row(
              children: [
                const Icon(Icons.receipt_long),
                const SizedBox(width: 8),
                const Text('פורטל חיוב'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'client_management',
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(l10n.clientManagement),
              ],
            ),
          ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  const Icon(Icons.backup),
                  const SizedBox(width: 8),
                  const Text('ניהול גיבויים'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'data_retention',
              child: Row(
                children: [
                  const Icon(Icons.policy),
                  const SizedBox(width: 8),
                  const Text('מדיניות שמירה'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'billing_locks',
              child: Row(
                children: [
                  const Icon(Icons.payments),
                  const SizedBox(width: 8),
                  const Text('Billing & Locks'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'module_toggle',
              child: Row(
                children: [
                  const Icon(Icons.toggle_on),
                  const SizedBox(width: 8),
                  const Text('ניהול מודולים'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'integrity_check',
              child: Row(
                children: [
                  const Icon(Icons.verified_user),
                  const SizedBox(width: 8),
                  const Text('בדיקת שלמות'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'nested_migration',
              child: Row(
                children: [
                  const Icon(Icons.account_tree),
                  const SizedBox(width: 8),
                  const Text('Nested Migration'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'final_migration',
              child: Row(
                children: [
                  const Icon(Icons.move_down),
                  const SizedBox(width: 8),
                  const Text('Final Migration'),
                ],
              ),
            ),
          if (authService.userModel?.isSuperAdmin == true)
            PopupMenuItem(
              value: 'support_console',
              child: Row(
                children: [
                  const Icon(Icons.support_agent),
                  const SizedBox(width: 8),
                  const Text('Support Console'),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
          PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
          PopupMenuItem(value: 'en', child: Text(l10n.english)),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.logout, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    }

    // На десктопе - иконки как раньше
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
        IconButton(
          icon: const Icon(Icons.analytics),
          tooltip: l10n.analytics,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.assessment),
          tooltip: 'דוחות',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.inventory_2),
          tooltip: l10n.warehouseInventory,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WarehouseDashboard()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: l10n.productManagement,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProductManagementScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.assessment),
          tooltip: l10n.inventoryChangesReport,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryReportScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.fact_check),
          tooltip: l10n.inventoryCountReportsTooltip,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryCountsListScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.business),
          tooltip: l10n.companySettings,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompanySettingsScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.translate),
          tooltip: l10n.terminologySettings,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TerminologySettingsScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          tooltip: l10n.archiveManagement,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ArchiveManagementScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long),
          tooltip: 'פורטל חיוב',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillingPortalScreen()),
            );
          },
        ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.payments),
            tooltip: 'Billing & Locks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingLocksScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'ניהול גיבויים',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BackupManagementScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.policy),
            tooltip: 'מדיניות שמירה',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataRetentionScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.toggle_on),
            tooltip: 'ניהול מודולים',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModuleToggleScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'בדיקת שלמות שרשרת',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IntegrityCheckScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Nested Collections Migration',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NestedMigrationScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.move_down),
            tooltip: 'Final Migration (Move to Company)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinalMigrationScreen()),
              );
            },
          ),
        if (authService.userModel?.isSuperAdmin == true)
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'Support Console',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportConsoleScreen()),
              );
            },
          ),
        PopupMenuButton<String>(
          tooltip: l10n.settings,
          onSelected: (value) {
            if (value == 'logout') {
              authService.signOut();
            } else if (value == 'he' || value == 'ru' || value == 'en') {
              localeService.setLocale(value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
            PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
            PopupMenuItem(value: 'en', child: Text(l10n.english)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
          ],
        ),
      ],
    );
  }
}
