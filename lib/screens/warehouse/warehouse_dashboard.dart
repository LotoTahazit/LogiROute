import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/inventory_list_view.dart';
import 'dialogs/add_inventory_dialog.dart';
import 'dialogs/add_box_type_dialog.dart';
import 'dialogs/edit_inventory_dialog.dart';
import 'dialogs/box_types_manager_dialog.dart';
import 'dialogs/delete_confirmation_dialog.dart';

class WarehouseDashboard extends StatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  final InventoryService _inventoryService = InventoryService();
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

  void _showAddInventoryDialog() {
    AddInventoryDialog.show(
      context: context,
      userName: _userName,
      onAddNewType: _showAddNewBoxTypeDialog,
    );
  }

  void _showAddNewBoxTypeDialog() {
    AddBoxTypeDialog.show(
      context: context,
      userName: _userName,
    );
  }

  void _showEditInventoryDialog(InventoryItem item) {
    EditInventoryDialog.show(
      context: context,
      item: item,
      userName: _userName,
    );
  }

  void _showDeleteConfirmation(InventoryItem item) {
    DeleteConfirmationDialog.show(
      context: context,
      title: 'מחק פריט',
      content: 'האם למחוק ${item.toDisplayString()}?',
      onConfirm: () async {
        await _inventoryService.deleteInventoryItem(item.id);
      },
    );
  }

  void _showInventoryHistory() {
    // История изменений инвентаря
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('היסטוריה - בפיתוח'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportReport() {
    // Экспорт отчета инвентаря
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ייצוא דוח - בפיתוח'),
        duration: Duration(seconds: 2),
      ),
    );
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
        title: const Text('מחסן - ניהול מלאי'),
        actions: [
          // Управление справочником
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'ניהול מאגר סוגים',
            onPressed: _showBoxTypesManager,
          ),
          // Фильтр низких остатков
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showLowStockOnly ? Colors.orange : null,
            ),
            tooltip: 'הצג רק מלאי נמוך',
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
              });
            },
          ),
          // История
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'היסטוריית שינויים',
            onPressed: _showInventoryHistory,
          ),
          // Экспорт
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'ייצוא דוח',
            onPressed: _exportReport,
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
                hintText: 'חיפוש לפי סוג או מספר...',
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
              onEdit: _showEditInventoryDialog,
              onDelete: _showDeleteConfirmation,
              emptyMessage: 'אין פריטים במלאי',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInventoryDialog,
        backgroundColor: Colors.green,
        tooltip: 'הוסף מלאי',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
