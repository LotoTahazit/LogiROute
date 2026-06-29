import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../services/inventory_service.dart';
import '../../../services/company_context.dart';
import '../../../l10n/app_localizations.dart';
import 'inventory_item_card.dart';
import '../dialogs/edit_barcode_dialog.dart';

/// Виджет списка товаров с фильтрацией и сортировкой
///
/// Параметры:
/// - [showAllFields] - показывать все поля товара или только основные
/// - [showLowStockOnly] - фильтр: показывать только товары с низким остатком
/// - [searchQuery] - поисковый запрос для фильтрации
/// - [emptyMessage] - сообщение при пустом списке
///
/// ⚡ OPTIMIZED: Converted to StatefulWidget to prevent stream recreation on every build
class InventoryListView extends StatefulWidget {
  final bool showAllFields;
  final bool showLowStockOnly;
  final String searchQuery;
  final String emptyMessage;
  final bool barcodeWarehouseEnabled;
  final String userName;

  const InventoryListView({
    super.key,
    this.showAllFields = true,
    this.showLowStockOnly = false,
    this.searchQuery = '',
    this.emptyMessage = 'אין פריטים במלאי',
    this.barcodeWarehouseEnabled = false,
    this.userName = '',
  });

  @override
  State<InventoryListView> createState() => _InventoryListViewState();
}

class _InventoryListViewState extends State<InventoryListView> {
  late final InventoryService _inventoryService;
  late Stream<List<InventoryItem>> _inventoryStream;
  late final String _companyId;
  int _streamLimit = InventoryService.defaultListLimit;
  bool _truncated = false;

  void _initStream() {
    _inventoryStream =
        _inventoryService.getInventoryStream(limit: _streamLimit);
  }

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _companyId = companyId;
    _inventoryService = InventoryService(companyId: companyId);
    _initStream();
  }

  void _loadMore() {
    setState(() {
      _streamLimit += InventoryService.defaultListLimit;
      _initStream();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      key: ValueKey(_streamLimit),
      stream: _inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
                '${AppLocalizations.of(context)!.error}: ${snapshot.error}'),
          );
        }

        final items = snapshot.data ?? [];
        _truncated = items.length >= _streamLimit;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.emptyMessage,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Фильтруем по поиску и низким остаткам
        var filteredItems = items;

        if (widget.searchQuery.isNotEmpty) {
          filteredItems = filteredItems.where((item) {
            final productCode = item.productCode;
            final type = item.type;
            final number = item.number;

            return productCode
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase()) ||
                type.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
                number.toLowerCase().contains(widget.searchQuery.toLowerCase());
          }).toList();
        }

        if (widget.showLowStockOnly) {
          filteredItems =
              filteredItems.where((item) => item.quantity < 60).toList();
        }

        // Сортируем по מק"ט (productCode)
        filteredItems.sort((a, b) {
          final codeA = a.productCode;
          final codeB = b.productCode;
          return codeA.compareTo(codeB);
        });

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noItemsFound,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Показываем список товаров
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];

                  return InventoryItemCard(
                    item: item,
                    showAllFields: widget.showAllFields,
                    formatDate: _formatDate,
                    showBarcodeEdit: widget.barcodeWarehouseEnabled,
                    onEditBarcode: widget.barcodeWarehouseEnabled
                        ? () => EditBarcodeDialog.show(
                              context,
                              item: item,
                              companyId: _companyId,
                              userName: widget.userName,
                            )
                        : null,
                  );
                },
              ),
            ),
            if (_truncated)
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(AppLocalizations.of(context)!.reportsLoadMore),
                ),
              ),
          ],
        );
      },
    );
  }
}
