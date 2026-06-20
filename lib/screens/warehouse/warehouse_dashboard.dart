import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/inventory_item.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../shared/inventory_report_screen.dart';
import 'widgets/inventory_list_view.dart';
import 'dialogs/add_inventory_dialog.dart';
import 'dialogs/add_box_type_dialog.dart';
import 'dialogs/box_types_manager_dialog.dart';
import 'inventory_count_screen.dart';

// Условный импорт только для веба
import '../../services/export_service.dart'
    if (dart.library.io) '../../services/export_service_stub.dart';
import '../../services/inventory_import_service.dart';
import '../../services/inventory_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserName();
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

    try {
      // Получаем текущий инвентарь
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('warehouse')
          .doc('_root')
          .collection('inventory')
          .orderBy('productCode')
          .get();

      final items = snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noItemsToExport)),
          );
        }
        return;
      }

      // Экспортируем
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

  List<Widget> _buildAppBarActions(
      BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    if (isNarrow) {
      // Мобильный — notification bell + меню
      return [
        NotificationBell(
          companyId: CompanyContext.of(context).effectiveCompanyId ?? '',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'inventory_count':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        InventoryCountScreen(userName: _userName),
                  ),
                );
                break;
              case 'manage_types':
                _showBoxTypesManager();
                break;
              case 'add_type':
                _showAddNewBoxTypeDialog();
                break;
              case 'filter':
                setState(() => _showLowStockOnly = !_showLowStockOnly);
                break;
              case 'history':
                _showInventoryHistory();
                break;
              case 'export':
                _exportReport();
                break;
              case 'import':
                _importInventory();
                break;
              case 'logout':
                final navigator = Navigator.of(context);
                await _authService.signOut();
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'inventory_count',
              child: ListTile(
                leading: const Icon(Icons.fact_check),
                title: Text(l10n.inventoryCount),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'manage_types',
              child: ListTile(
                leading: const Icon(Icons.library_books),
                title: Text(l10n.manageBoxTypes),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'add_type',
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l10n.addNewBoxTypeToCatalog),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'filter',
              child: ListTile(
                leading: Icon(
                  _showLowStockOnly
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: _showLowStockOnly ? Colors.orange : null,
                ),
                title: Text(l10n.showLowStockOnly),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.changeHistory),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (kIsWeb)
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.exportReport),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(l10n.importFromExcel),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(l10n.logout,
                    style: const TextStyle(color: Colors.red)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }

    // Десктоп — все иконки как раньше
    return [
      NotificationBell(
        companyId: CompanyContext.of(context).effectiveCompanyId ?? '',
      ),
      IconButton(
        icon: const Icon(Icons.fact_check),
        tooltip: l10n.inventoryCount,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryCountScreen(userName: _userName),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.library_books),
        tooltip: l10n.manageBoxTypes,
        onPressed: _showBoxTypesManager,
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: l10n.addNewBoxTypeToCatalog,
        onPressed: _showAddNewBoxTypeDialog,
      ),
      IconButton(
        icon: Icon(
          _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
          color: _showLowStockOnly ? Colors.orange : null,
        ),
        tooltip: l10n.showLowStockOnly,
        onPressed: () {
          setState(() {
            _showLowStockOnly = !_showLowStockOnly;
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.history),
        tooltip: l10n.changeHistory,
        onPressed: _showInventoryHistory,
      ),
      if (kIsWeb)
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: l10n.exportReport,
          onPressed: _exportReport,
        ),
      IconButton(
        icon: const Icon(Icons.upload_file),
        tooltip: l10n.importFromExcel,
        onPressed: _importInventory,
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: l10n.logout,
        onPressed: () async {
          final navigator = Navigator.of(context);
          await _authService.signOut();
          if (mounted) {
            navigator.pushReplacementNamed('/login');
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final l10n = AppLocalizations.of(context)!;

    // Определяем роль пользователя
    final userRole = authService.viewAsRole ?? authService.userRole;
    final isDispatcher = userRole == 'dispatcher' ||
        userRole == 'admin' ||
        userRole == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.warehouseInventoryManagement),
        actions: _buildAppBarActions(context, l10n),
      ),
      body: Column(
        children: [
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
              showAllFields: isDispatcher,
              showLowStockOnly: _showLowStockOnly,
              searchQuery: _searchQuery,
              emptyMessage: l10n.noItemsInInventory,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddInventoryDialog.show(
            context: context,
            userName: _userName,
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
