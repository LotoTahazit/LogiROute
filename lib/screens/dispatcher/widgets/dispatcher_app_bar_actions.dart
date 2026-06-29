import 'package:flutter/material.dart';
import '../../shared/inventory_report_screen.dart';
import '../../shared/client_management_screen.dart';
import '../../admin/archive_management_screen.dart';
import '../../shared/route_archive_screen.dart';
import '../../admin/data_retention_screen.dart';
import '../../admin/inventory_counts_list_screen.dart';
import '../price_management_screen.dart';
import '../../warehouse/warehouse_dashboard.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_context.dart';
import '../../../services/import/import_mapping_wizard_launcher.dart';
import '../../../services/delivery_point_import_service.dart';
import '../../../services/warehouse_access.dart';
import '../../shift_settings_screen.dart';

/// AppBar actions диспетчера — сгруппированные меню (вариант A).
class DispatcherAppBarActions extends StatelessWidget {
  final VoidCallback onSetWarehouseLocation;
  final AuthService authService;

  const DispatcherAppBarActions({
    super.key,
    required this.onSetWarehouseLocation,
    required this.authService,
  });

  void _handleAction(BuildContext context, String value) {
    switch (value) {
      case 'clients':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientManagementScreen()),
        );
      case 'import_delivery_points':
        DeliveryPointImportService.runImport(context);
      case 'import_wizard':
        ImportMappingWizardLauncher.open(context);
      case 'prices':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PriceManagementScreen()),
        );
      case 'warehouse_location':
        onSetWarehouseLocation();
      case 'shift_settings':
        final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ShiftSettingsScreen(companyId: companyId),
          ),
        );
      case 'warehouse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WarehouseDashboard()),
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
      case 'data_retention':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DataRetentionScreen(infoOnly: true),
          ),
        );
      case 'logout':
        authService.signOut();
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

  List<PopupMenuEntry<String>> _logisticsItems(AppLocalizations l10n) => [
        _item('clients', Icons.people, l10n.clientManagement),
        _item('import_delivery_points', Icons.upload_file, l10n.importDeliveryPointsMenu),
        _item('import_wizard', Icons.auto_fix_high, l10n.importWizardMenu),
        _item('prices', Icons.attach_money, l10n.priceManagement),
        _item('warehouse_location', Icons.location_on, l10n.setWarehouseLocation),
        _item('shift_settings', Icons.schedule, l10n.shiftScheduleTitle),
      ];

  List<PopupMenuEntry<String>> _warehouseItems(AppLocalizations l10n) {
    final role = authService.viewAsRole ?? authService.userRole;
    if (!WarehouseAccess.canReadWarehouse(role)) return [];
    return [
      _item('warehouse', Icons.inventory_2, l10n.warehouseInventory),
      _item('inventory_report', Icons.swap_horiz, l10n.inventoryChangesReport),
      if (WarehouseAccess.canWriteWarehouse(role))
        _item('inventory_counts', Icons.fact_check,
            l10n.inventoryCountReportsTooltip),
    ];
  }

  List<PopupMenuEntry<String>> _archiveItems(AppLocalizations l10n) => [
        _item('route_archive', Icons.history, l10n.routeArchiveTitle),
        _item('archive', Icons.archive, l10n.archiveManagement),
        _item('data_retention', Icons.policy, l10n.dataRetention),
      ];

  Widget _groupMenu({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required List<PopupMenuEntry<String>> items,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: (v) => _handleAction(context, v),
      itemBuilder: (_) => items,
    );
  }

  List<PopupMenuEntry<String>> _mobileMenuItems(AppLocalizations l10n) {
    final warehouseItems = _warehouseItems(l10n);
    return [
      _sectionHeader(l10n.appBarGroupLogistics),
      ..._logisticsItems(l10n),
      if (warehouseItems.isNotEmpty) ...[
        const PopupMenuDivider(),
        _sectionHeader(l10n.appBarGroupWarehouse),
        ...warehouseItems,
      ],
      const PopupMenuDivider(),
      _sectionHeader(l10n.appBarGroupArchive),
      ..._archiveItems(l10n),
      const PopupMenuDivider(),
      _item('logout', Icons.logout, l10n.logout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final warehouseItems = _warehouseItems(l10n);

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
        _groupMenu(
          context: context,
          icon: Icons.local_shipping_outlined,
          tooltip: l10n.appBarGroupLogistics,
          items: _logisticsItems(l10n),
        ),
        if (warehouseItems.isNotEmpty)
          _groupMenu(
            context: context,
            icon: Icons.inventory_2_outlined,
            tooltip: l10n.appBarGroupWarehouse,
            items: warehouseItems,
          ),
        _groupMenu(
          context: context,
          icon: Icons.archive_outlined,
          tooltip: l10n.appBarGroupArchive,
          items: _archiveItems(l10n),
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
