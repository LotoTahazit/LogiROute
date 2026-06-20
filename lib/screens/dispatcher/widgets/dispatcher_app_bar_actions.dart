import 'package:flutter/material.dart';
import '../../shared/inventory_report_screen.dart';
import '../../shared/client_management_screen.dart';
import '../../admin/archive_management_screen.dart';
import '../../admin/data_retention_screen.dart';
import '../../admin/inventory_counts_list_screen.dart';
import '../price_management_screen.dart';
import '../../warehouse/warehouse_dashboard.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_context.dart';
import '../../../services/delivery_point_import_service.dart';
import '../../shift_settings_screen.dart';
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
        PopupMenuButton<String>(
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
          value: 'import_delivery_points',
          child: Row(
            children: [
              const Icon(Icons.upload_file, size: 20),
              const SizedBox(width: 12),
              Text(l10n.importDeliveryPointsMenu),
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
        PopupMenuItem(
          value: 'shift_settings',
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 12),
              Text(l10n.shiftScheduleTitle),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'data_retention',
          child: Row(
            children: [
              const Icon(Icons.policy, size: 20),
              const SizedBox(width: 12),
              Text(l10n.dataRetention),
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
          case 'import_delivery_points':
            DeliveryPointImportService.runImport(context);
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
          case 'shift_settings':
            final companyId =
                CompanyContext.of(context).effectiveCompanyId ?? '';
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ShiftSettingsScreen(companyId: companyId),
              ),
            );
            break;
          case 'data_retention':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DataRetentionScreen(infoOnly: true),
              ),
            );
            break;
          case 'logout':
            authService.signOut();
            break;
        }
      },
        ),
      ],
    );
  }
}
