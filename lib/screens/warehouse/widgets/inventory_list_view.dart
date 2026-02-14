import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../services/inventory_service.dart';
import 'inventory_item_card.dart';

/// Виджет списка товаров с фильтрацией и сортировкой
///
/// Параметры:
/// - [showAllFields] - показывать все поля товара или только основные
/// - [showLowStockOnly] - фильтр: показывать только товары с низким остатком
/// - [searchQuery] - поисковый запрос для фильтрации
/// - [onEdit] - callback при редактировании товара
/// - [onDelete] - callback при удалении товара
/// - [emptyMessage] - сообщение при пустом списке
///
/// ⚡ OPTIMIZED: Converted to StatefulWidget to prevent stream recreation on every build
class InventoryListView extends StatefulWidget {
  final bool showAllFields;
  final bool showLowStockOnly;
  final String searchQuery;
  final Function(InventoryItem)? onEdit;
  final Function(InventoryItem)? onDelete;
  final String emptyMessage;

  const InventoryListView({
    super.key,
    this.showAllFields = true,
    this.showLowStockOnly = false,
    this.searchQuery = '',
    this.onEdit,
    this.onDelete,
    this.emptyMessage = 'אין פריטים במלאי',
  });

  @override
  State<InventoryListView> createState() => _InventoryListViewState();
}

class _InventoryListViewState extends State<InventoryListView> {
  late final InventoryService _inventoryService;
  late final Stream<List<InventoryItem>> _inventoryStream;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize service and stream ONCE in initState
    _inventoryService = InventoryService();
    _inventoryStream = _inventoryService.getInventoryStream(limit: 200);
    print('✅ [InventoryListView] Stream initialized in initState()');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      stream: _inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('שגיאה: ${snapshot.error}'),
          );
        }

        final items = snapshot.data ?? [];

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
                const SizedBox(height: 8),
                const Text(
                  'לחץ על + למטה להוספת פריט',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Фильтруем по поиску и низким остаткам
        var filteredItems = items;

        if (widget.searchQuery.isNotEmpty) {
          filteredItems = filteredItems.where((item) {
            return item.type
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase()) ||
                item.number
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase());
          }).toList();
        }

        if (widget.showLowStockOnly) {
          filteredItems =
              filteredItems.where((item) => item.quantity < 10).toList();
        }

        // Сортируем по алфавиту: сначала по типу, потом по номеру
        filteredItems.sort((a, b) {
          final typeCompare = a.type.compareTo(b.type);
          if (typeCompare != 0) return typeCompare;
          // Пробуем сортировать номера как числа
          final numA = int.tryParse(a.number);
          final numB = int.tryParse(b.number);
          if (numA != null && numB != null) {
            return numA.compareTo(numB);
          }
          return a.number.compareTo(b.number);
        });

        if (filteredItems.isEmpty) {
          return const Center(
            child: Text(
              'לא נמצאו פריטים',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Показываем список товаров
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];

            return InventoryItemCard(
              item: item,
              showAllFields: widget.showAllFields,
              onEdit: widget.onEdit != null ? () => widget.onEdit!(item) : null,
              onDelete:
                  widget.onDelete != null ? () => widget.onDelete!(item) : null,
              formatDate: _formatDate,
            );
          },
        );
      },
    );
  }
}
