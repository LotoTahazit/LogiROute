import 'package:flutter/material.dart';
import '../../shared/inventory_report_screen.dart';
import '../../shared/client_management_screen.dart';
import '../../admin/archive_management_screen.dart';
import '../../admin/inventory_counts_list_screen.dart';
import '../price_management_screen.dart';
import '../../warehouse/warehouse_dashboard.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';

/// AppBar actions для диспетчера
class DispatcherAppBarActions extends StatelessWidget {
  final VoidCallback onSetWarehouseLocation;
  final AuthService authService;

  const DispatcherAppBarActions({
    super.key,
    required this.onSetWarehouseLocation,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.people),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClientManagementScreen(),
              ),
            );
          },
          tooltip: l10n.clientManagement,
        ),
        IconButton(
          icon: const Icon(Icons.attach_money),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PriceManagementScreen(),
              ),
            );
          },
          tooltip: 'ניהול מחירים',
        ),
        IconButton(
          icon: const Icon(Icons.inventory_2),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WarehouseDashboard(),
              ),
            );
          },
          tooltip: l10n.warehouseInventory,
        ),
        IconButton(
          icon: const Icon(Icons.assessment),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryReportScreen(),
              ),
            );
          },
          tooltip: l10n.inventoryChangesReport,
        ),
        IconButton(
          icon: const Icon(Icons.fact_check),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryCountsListScreen(),
              ),
            );
          },
          tooltip: l10n.inventoryCountReportsTooltip,
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArchiveManagementScreen(),
              ),
            );
          },
          tooltip: l10n.archiveManagement,
        ),
        IconButton(
          icon: const Icon(Icons.location_on),
          onPressed: onSetWarehouseLocation,
          tooltip: l10n.setWarehouseLocation,
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
