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

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'תפריט',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'clients',
          child: Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 12),
              Text(l10n.clientManagement),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'prices',
          child: Row(
            children: [
              const Icon(Icons.attach_money, size: 20),
              const SizedBox(width: 12),
              Text(l10n.priceManagement),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'warehouse',
          child: Row(
            children: [
              const Icon(Icons.inventory_2, size: 20),
              const SizedBox(width: 12),
              Text(l10n.warehouseInventory),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'inventory_report',
          child: Row(
            children: [
              const Icon(Icons.assessment, size: 20),
              const SizedBox(width: 12),
              Text(l10n.inventoryChangesReport),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'inventory_counts',
          child: Row(
            children: [
              const Icon(Icons.fact_check, size: 20),
              const SizedBox(width: 12),
              Text(l10n.inventoryCountReportsTooltip),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              const Icon(Icons.archive, size: 20),
              const SizedBox(width: 12),
              Text(l10n.archiveManagement),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'warehouse_location',
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 12),
              Text(l10n.setWarehouseLocation),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(l10n.logout, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'clients':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClientManagementScreen(),
              ),
            );
            break;
          case 'prices':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PriceManagementScreen(),
              ),
            );
            break;
          case 'warehouse':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WarehouseDashboard(),
              ),
            );
            break;
          case 'inventory_report':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryReportScreen(),
              ),
            );
            break;
          case 'inventory_counts':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryCountsListScreen(),
              ),
            );
            break;
          case 'archive':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArchiveManagementScreen(),
              ),
            );
            break;
          case 'warehouse_location':
            onSetWarehouseLocation();
            break;
          case 'logout':
            authService.signOut();
            break;
        }
      },
    );
  }
}
