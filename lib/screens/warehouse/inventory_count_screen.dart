import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_count.dart';
import '../../models/count_item.dart';
import '../../services/inventory_count_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import 'widgets/count_item_card.dart';

/// Экран инвентаризации для кладовщика (Android-ориентированный)
class InventoryCountScreen extends StatefulWidget {
  final String userName;

  const InventoryCountScreen({
    super.key,
    required this.userName,
  });

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  late final InventoryCountService _countService;
  late final InventoryService _inventoryService;
  final ScrollController _scrollController = ScrollController();

  InventoryCount? _activeCount;
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyDifferences = false;

  // ✅ НОВОЕ: Храним введенные количества локально
  final Map<String, int> _enteredQuantities = {};
  final Map<String, String> _enteredNotes = {};

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _countService = InventoryCountService(companyId: companyId);
    _inventoryService = InventoryService(companyId: companyId);
    _loadActiveCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveCount() async {
    setState(() => _isLoading = true);

    try {
      final activeCount = await _countService.getActiveCount();

      if (mounted) {
        setState(() {
          _activeCount = activeCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת ספירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startNewCount() async {
    // Подтверждение
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('התחל ספירת מלאי חדשה'),
        content: const Text(
            'האם להתחיל ספירת מלאי חדשה?\nזה ייצור רשימה של כל הפריטים במלאי.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('התחל'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Получаем текущий инвентарь
      final inventory = await _inventoryService.getInventory();

      // Начинаем новый подсчет
      final countId = await _countService.startNewCount(
        userName: widget.userName,
        currentInventory: inventory,
      );

      // Загружаем созданный подсчет
      final newCount = await _countService.getCountById(countId);

      if (mounted) {
        setState(() {
          _activeCount = newCount;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ספירת מלאי חדשה התחילה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהתחלת ספירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateItemCount(
      CountItem item, int actualQuantity, String? notes) async {
    // ✅ ИЗМЕНЕНО: Просто сохраняем локально, без отправки на сервер
    setState(() {
      _enteredQuantities[item.productCode] = actualQuantity;
      if (notes != null && notes.isNotEmpty) {
        _enteredNotes[item.productCode] = notes;
      }
    });
  }

  Future<void> _completeCount() async {
    // ✅ ИЗМЕНЕНО: Сначала сохраняем все введенные данные
    setState(() => _isLoading = true);

    try {
      // Сохраняем все введенные количества
      for (final entry in _enteredQuantities.entries) {
        final productCode = entry.key;
        final quantity = entry.value;
        final notes = _enteredNotes[productCode];

        await _countService.updateItemCount(
          countId: _activeCount!.id,
          productCode: productCode,
          actualQuantity: quantity,
          notes: notes,
        );
      }

      // Перезагружаем подсчет после сохранения всех данных
      final updatedCount = await _countService.getCountById(_activeCount!.id);

      if (updatedCount == null) {
        throw Exception('Не удалось загрузить обновленный подсчет');
      }

      // Проверяем, все ли товары проверены
      final uncheckedCount =
          updatedCount.items.where((item) => !item.isChecked).length;

      if (uncheckedCount > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('סיים ספירה'),
            content: Text(
                'יש עדיין $uncheckedCount פריטים שלא נספרו.\nהאם לסיים בכל זאת?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('סיים'),
              ),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Завершаем подсчет
      await _countService.completeCount(_activeCount!.id);

      if (mounted) {
        setState(() {
          _activeCount = null;
          _isLoading = false;
          _enteredQuantities.clear();
          _enteredNotes.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ספירת מלאי הושלמה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בסיום ספירה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CountItem> _getFilteredItems() {
    if (_activeCount == null) return [];

    var items = _activeCount!.items;

    // Фильтр по поиску
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final search = _searchQuery.toLowerCase();
        return item.productCode.toLowerCase().contains(search) ||
            item.type.toLowerCase().contains(search) ||
            item.number.toLowerCase().contains(search);
      }).toList();
    }

    // Фильтр только расхождения
    if (_showOnlyDifferences) {
      items = items.where((item) => item.hasDifference).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ספירת מלאי'),
        actions: [
          if (_activeCount != null) ...[
            // Фильтр "только расхождения"
            IconButton(
              icon: Icon(
                _showOnlyDifferences
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _showOnlyDifferences ? Colors.orange : null,
              ),
              tooltip: 'הצג רק הפרשים',
              onPressed: () {
                setState(() => _showOnlyDifferences = !_showOnlyDifferences);
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeCount == null
              ? _buildNoActiveCount()
              : _buildCountInProgress(),
      floatingActionButton: _activeCount != null
          ? FloatingActionButton.extended(
              onPressed: _completeCount,
              icon: const Icon(Icons.check),
              label: const Text('סיים ספירה'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildNoActiveCount() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'אין ספירת מלאי פעילה',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startNewCount,
            icon: const Icon(Icons.add),
            label: const Text('התחל ספירת מלאי חדשה'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountInProgress() {
    final summary = _activeCount!.summary;
    final filteredItems = _getFilteredItems();
    final progress = summary.totalItems > 0
        ? summary.checkedItems / summary.totalItems
        : 0.0;

    return Column(
      children: [
        // Прогресс и статистика
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              // Прогресс-бар
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${summary.checkedItems}/${summary.totalItems}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'נספרו',
                    value: '${summary.checkedItems}',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.warning,
                    label: 'הפרשים',
                    value: '${summary.itemsWithDifference}',
                    color: Colors.orange,
                  ),
                  _buildStatItem(
                    icon: Icons.arrow_downward,
                    label: 'חסר',
                    value: '${summary.totalShortage}',
                    color: Colors.red,
                  ),
                  _buildStatItem(
                    icon: Icons.arrow_upward,
                    label: 'עודף',
                    value: '${summary.totalSurplus}',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Поиск
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'חיפוש לפי מק"ט / סוג / מספר',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Список товаров
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'לא נמצאו תוצאות'
                        : _showOnlyDifferences
                            ? 'אין הפרשים'
                            : 'אין פריטים',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    // Получаем введенное количество из локального хранилища
                    final enteredQty = _enteredQuantities[item.productCode];
                    final enteredNote = _enteredNotes[item.productCode];

                    return CountItemCard(
                      item: item,
                      initialQuantity: enteredQty,
                      initialNotes: enteredNote,
                      onUpdate: (actualQuantity, notes) {
                        _updateItemCount(item, actualQuantity, notes);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
