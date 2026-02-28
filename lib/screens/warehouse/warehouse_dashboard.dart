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
        actions: [
          NotificationBell(
            companyId: CompanyContext.of(context).effectiveCompanyId ?? '',
          ),
          // Инвентаризация (ספירת מלאי)
          IconButton(
            icon: const Icon(Icons.fact_check),
            tooltip: l10n.inventoryCount,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InventoryCountScreen(userName: _userName),
                ),
              );
            },
          ),
          // Управление справочником
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: l10n.manageBoxTypes,
            onPressed: _showBoxTypesManager,
          ),
          // Добавить новый тип в справочник
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addNewBoxTypeToCatalog,
            onPressed: _showAddNewBoxTypeDialog,
          ),
          // Фильтр низких остатков
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
          // История
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.changeHistory,
            onPressed: _showInventoryHistory,
          ),
          // Экспорт (только для веба)
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: l10n.exportReport,
              onPressed: _exportReport,
            ),
          // Выход
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
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
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '👁️ ${l10n.viewModeWarehouse}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
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
