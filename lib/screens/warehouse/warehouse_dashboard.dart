import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../shared/inventory_report_screen.dart';
import 'widgets/inventory_list_view.dart';
import 'dialogs/add_inventory_dialog.dart';
import 'dialogs/add_box_type_dialog.dart';
import 'dialogs/box_types_manager_dialog.dart';
import 'inventory_count_screen.dart';
import 'dialogs/barcode_scan_dialog.dart';

// Условный импорт только для веба
import '../../services/export_service.dart'
    if (dart.library.io) '../../services/export_service_stub.dart';
import '../../services/inventory_import_service.dart';
import '../../services/inventory_service.dart';
import '../../services/company_settings_service.dart';
import '../../services/warehouse_access.dart';
import '../../services/import/import_mapping_wizard_launcher.dart';
import '../../models/import_wizard_type.dart';
import '../../widgets/import_preview_dialog.dart';
import '../../widgets/column_mapping_dialog.dart';
import '../../widgets/notification_bell.dart';

class WarehouseDashboard extends StatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  final AuthService _authService = AuthService();

  String _userName = '';
  bool _showLowStockOnly = false;
  String _searchQuery = '';
  bool _barcodeWarehouseEnabled = false;
  StreamSubscription<bool>? _companySub;
  String? _watchedCompanyId;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isNotEmpty && companyId != _watchedCompanyId) {
      _watchedCompanyId = companyId;
      _watchCompanySettings(companyId);
    }
  }

  void _watchCompanySettings(String companyId) {
    _companySub?.cancel();
    final service = CompanySettingsService(companyId: companyId);
    service.readComputerizedWarehouseEnabled().then((enabled) {
      if (mounted) setState(() => _barcodeWarehouseEnabled = enabled);
    });
    _companySub = service.watchComputerizedWarehouseEnabled().listen(
      (enabled) {
        if (!mounted) return;
        if (enabled != _barcodeWarehouseEnabled) {
          setState(() => _barcodeWarehouseEnabled = enabled);
        }
      },
      onError: (e) => debugPrint('❌ [Warehouse] settings stream: $e'),
    );
  }

  @override
  void dispose() {
    _companySub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = _authService.userModel;
    if (user != null && mounted) {
      setState(() {
        _userName = user.name;
      });
    }
  }

  void _showAddNewBoxTypeDialog() {
    AddBoxTypeDialog.show(context: context, userName: _userName);
  }

  void _showInventoryHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InventoryReportScreen()),
    );
  }

  Future<void> _exportReport() async {
    final l10n = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportToExcelMenu),
        content: Text(l10n.exportLargeDatasetWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId ?? '';
      final inventoryService = InventoryService(companyId: companyId);
      final items = await inventoryService.fetchAllInventoryForExport();

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noItemsToExport)),
          );
        }
        return;
      }

      if (items.length > 2000 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportLargeDatasetNotice(items.length))),
        );
      }

      ExportService.exportInventoryToCSV(items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportExportedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error exporting inventory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.exportError}: $e')),
        );
      }
    }
  }

  void _showBoxTypesManager() {
    BoxTypesManagerDialog.show(context: context);
  }

  Future<void> _importInventory() async {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final result = await InventoryImportService.pickAndParse(context);
    final rows = result.rows;
    if (rows == null || !mounted) return;

    final previewRows = rows
        .map((r) => ImportPreviewRow(
              rowIndex: r.rowIndex,
              values: [
                r.productCode,
                r.type,
                r.number,
                '${r.quantity}',
                '${r.quantityPerPallet}'
              ],
              errors: r.errors,
            ))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ImportPreviewDialog(
        title: l10n.importInventoryTitle,
        columns: [
          l10n.colProductCode,
          l10n.colType,
          l10n.colNumber,
          l10n.colQuantity,
          l10n.colQuantityPerPallet
        ],
        rows: previewRows,
      ),
    );
    if (confirmed != true || !mounted) return;

    int added = 0;
    int updated = 0;
    final errors = <String>[];
    final inventoryService = InventoryService(companyId: companyId);
    final duplicateMode = result.duplicateMode;

    for (final row in rows.where((r) => r.isValid)) {
      try {
        if (duplicateMode == DuplicateMode.update) {
          await inventoryService.updateInventory(
            productCode: row.productCode,
            type: row.type,
            number: row.number,
            quantity: row.quantity,
            quantityPerPallet: row.quantityPerPallet,
            userName: _userName,
            diameter: row.diameter,
            volume: row.volume,
            piecesPerBox: row.piecesPerBox,
            additionalInfo: row.additionalInfo,
          );
          updated++;
        } else {
          await inventoryService.addInventory(
            productCode: row.productCode,
            type: row.type,
            number: row.number,
            quantity: row.quantity,
            quantityPerPallet: row.quantityPerPallet,
            userName: _userName,
            diameter: row.diameter,
            volume: row.volume,
            piecesPerBox: row.piecesPerBox,
            additionalInfo: row.additionalInfo,
          );
          added++;
        }
      } catch (e) {
        errors.add('${row.productCode}: $e');
      }
    }

    if (mounted) {
      final msg = duplicateMode == DuplicateMode.update
          ? l10n.importResultUpdated(updated, errors.length)
          : l10n.importResultMessage(added, errors.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: errors.isEmpty ? Colors.green : Colors.orange,
        ),
      );
      setState(() {}); // refresh
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await _authService.signOut();
    if (mounted) navigator.pushReplacementNamed('/login');
  }

  void _handleWarehouseMenuAction(String value) {
    switch (value) {
      case 'inventory_count':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryCountScreen(userName: _userName),
          ),
        );
      case 'manage_types':
        _showBoxTypesManager();
      case 'add_type':
        _showAddNewBoxTypeDialog();
      case 'filter':
        setState(() => _showLowStockOnly = !_showLowStockOnly);
      case 'history':
        _showInventoryHistory();
      case 'export':
        _exportReport();
      case 'import':
        _importInventory();
      case 'import_wizard':
        ImportMappingWizardLauncher.open(
          context,
          initialType: ImportWizardType.products,
        );
      case 'barcode_scan':
        final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
        if (companyId.isNotEmpty) {
          BarcodeScanDialog.show(
            context,
            companyId: companyId,
            userName: _userName,
          );
        }
      case 'logout':
        _signOut();
    }
  }

  PopupMenuItem<String> _whMenuItem(String value, IconData icon, String label) {
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

  PopupMenuItem<String> _whSectionHeader(String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 36,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  List<PopupMenuEntry<String>> _warehouseOperationsItems(
      AppLocalizations l10n, bool canWrite) {
    if (!canWrite) return [];
    return [
      if (_barcodeWarehouseEnabled)
        _whMenuItem('barcode_scan', Icons.qr_code_2, l10n.barcodeScanTitle),
      _whMenuItem('inventory_count', Icons.fact_check, l10n.inventoryCount),
      _whMenuItem('manage_types', Icons.library_books, l10n.manageBoxTypes),
      _whMenuItem(
          'add_type', Icons.add_circle_outline, l10n.addNewBoxTypeToCatalog),
    ];
  }

  List<PopupMenuEntry<String>> _warehouseReportItems(AppLocalizations l10n) => [
        _whMenuItem('history', Icons.history, l10n.changeHistory),
      ];

  List<PopupMenuEntry<String>> _warehouseImportExportItems(
      AppLocalizations l10n, bool canWrite) {
    return [
      if (kIsWeb) _whMenuItem('export', Icons.download, l10n.exportReport),
      if (canWrite) _whMenuItem('import', Icons.upload_file, l10n.importFromExcel),
      if (canWrite) _whMenuItem('import_wizard', Icons.auto_fix_high, l10n.importWizardMenu),
    ];
  }

  Widget _whGroupMenu({
    required IconData icon,
    required String tooltip,
    required List<PopupMenuEntry<String>> items,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: _handleWarehouseMenuAction,
      itemBuilder: (_) => items,
    );
  }

  List<PopupMenuEntry<String>> _warehouseMobileMenuItems(
      AppLocalizations l10n, bool canWrite) {
    final ops = _warehouseOperationsItems(l10n, canWrite);
    final io = _warehouseImportExportItems(l10n, canWrite);
    return [
      if (ops.isNotEmpty) ...[
        _whSectionHeader(l10n.appBarGroupOperations),
        ...ops,
      ],
      _whMenuItem(
        'filter',
        _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
        l10n.showLowStockOnly,
      ),
      const PopupMenuDivider(),
      _whSectionHeader(l10n.appBarGroupReports),
      ..._warehouseReportItems(l10n),
      if (io.isNotEmpty) ...[
        const PopupMenuDivider(),
        _whSectionHeader(l10n.appBarGroupImportExport),
        ...io,
      ],
      const PopupMenuDivider(),
      _whMenuItem('logout', Icons.logout, l10n.logout),
    ];
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, AppLocalizations l10n, bool canWrite) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';

    if (isNarrow) {
      return [
        NotificationBell(companyId: companyId),
        if (canWrite && _barcodeWarehouseEnabled)
          IconButton(
            icon: const _BarcodeFabIcon(color: Colors.green, size: 22),
            tooltip: l10n.barcodeScanTitle,
            onPressed: () => _handleWarehouseMenuAction('barcode_scan'),
          ),
        IconButton(
          icon: Icon(
            _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: _showLowStockOnly ? Colors.orange : null,
          ),
          tooltip: l10n.showLowStockOnly,
          onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.settings,
          onSelected: _handleWarehouseMenuAction,
          itemBuilder: (_) => _warehouseMobileMenuItems(l10n, canWrite),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: l10n.logout,
          onPressed: _signOut,
        ),
      ];
    }

    final ops = _warehouseOperationsItems(l10n, canWrite);
    final io = _warehouseImportExportItems(l10n, canWrite);

    return [
      NotificationBell(companyId: companyId),
      if (canWrite && _barcodeWarehouseEnabled)
        IconButton(
          icon: const _BarcodeFabIcon(color: Colors.green, size: 22),
          tooltip: l10n.barcodeScanTitle,
          onPressed: () => _handleWarehouseMenuAction('barcode_scan'),
        ),
      IconButton(
        icon: Icon(
          _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: _showLowStockOnly ? Colors.orange : null,
        ),
        tooltip: l10n.showLowStockOnly,
        onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
      ),
      if (ops.isNotEmpty)
        _whGroupMenu(
          icon: Icons.tune_outlined,
          tooltip: l10n.appBarGroupOperations,
          items: ops,
        ),
      _whGroupMenu(
        icon: Icons.bar_chart,
        tooltip: l10n.appBarGroupReports,
        items: _warehouseReportItems(l10n),
      ),
      if (io.isNotEmpty)
        _whGroupMenu(
          icon: Icons.import_export,
          tooltip: l10n.appBarGroupImportExport,
          items: io,
        ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: l10n.logout,
        onPressed: _signOut,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final l10n = AppLocalizations.of(context)!;

    final userRole = authService.viewAsRole ?? authService.userRole;
    final canWrite = WarehouseAccess.canWriteWarehouse(userRole);
    final showReferenceFields = userRole == 'dispatcher' ||
        userRole == 'admin' ||
        userRole == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.warehouseInventoryManagement),
        actions: _buildAppBarActions(context, l10n, canWrite),
      ),
      body: Column(
        children: [
          if (WarehouseAccess.isReadOnlyWarehouse(userRole))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.settingsReadOnly} — ${l10n.warehouseInventory}',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Индикатор режима просмотра для админа
          if (authService.userModel?.isAdmin == true &&
              authService.viewAsRole == 'warehouse_keeper')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade100,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.blue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '👁️ ${l10n.viewModeWarehouse}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      authService.setViewAsRole(null);
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(l10n.returnToAdmin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchByTypeOrNumber,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Основной контент
          Expanded(
            child: InventoryListView(
              showAllFields: showReferenceFields,
              showLowStockOnly: _showLowStockOnly,
              searchQuery: _searchQuery,
              emptyMessage: l10n.noItemsInInventory,
              barcodeWarehouseEnabled:
                  canWrite && _barcodeWarehouseEnabled,
              userName: _userName,
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? (_barcodeWarehouseEnabled
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'warehouse_barcode_scan',
                      onPressed: () =>
                          _handleWarehouseMenuAction('barcode_scan'),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      tooltip: l10n.barcodeScanTitle,
                      icon: const _BarcodeFabIcon(),
                      label: const Text('QR'),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'warehouse_add_inventory',
                      onPressed: () {
                        AddInventoryDialog.show(
                          context: context,
                          userName: _userName,
                        );
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.add),
                    ),
                  ],
                )
              : FloatingActionButton(
                  onPressed: () {
                    AddInventoryDialog.show(
                      context: context,
                      userName: _userName,
                    );
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                ))
          : null,
    );
  }
}

/// Иконка штрихкода без Material Icons (web tree-shake).
class _BarcodeFabIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _BarcodeFabIcon({this.color = Colors.white, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BarcodeIconPainter(color),
    );
  }
}

class _BarcodeIconPainter extends CustomPainter {
  final Color color;

  _BarcodeIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final bars = [0.06, 0.18, 0.30, 0.42, 0.54, 0.66, 0.78, 0.90];
    for (final x in bars) {
      final barW = w * (x == 0.06 || x == 0.90 ? 0.10 : 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * 0.12, barW, h * 0.76),
          const Radius.circular(1),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
