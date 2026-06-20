import 'package:flutter/material.dart';
import '../../models/inventory_count.dart';
import '../../models/count_item.dart';
import '../../services/inventory_count_service.dart';
import '../../services/inventory_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
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
  final bool _showOnlyDifferences = false;

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
            content:
                Text(AppLocalizations.of(context)!.errorLoadingCountMessage(e)),
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.startNewCount),
          content: Text(l10n.startNewCountConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.start),
            ),
          ],
        );
      },
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.countStarted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorStartingCountMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateItemCount(
      CountItem item, int actualQuantity, String? notes) async {
    // Validate: negative quantities not allowed
    if (actualQuantity < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.quantityCannotBeNegative),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
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
    final l10n = AppLocalizations.of(context)!;
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
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.completeCount),
              content: Text(l10n.uncheckedItemsWarning(uncheckedCount)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text(l10n.finish),
                ),
              ],
            );
          },
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.countCompleted),
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
            content: Text(
                AppLocalizations.of(context)!.errorCompletingCountMessage(e)),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryCount),
        actions: const [],
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
              label: Text(l10n.finishCountButton),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildNoActiveCount() {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.noActiveCount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startNewCount,
            icon: const Icon(Icons.add),
            label: Text(l10n.startNewCount),
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
        // Компактный прогресс (без статистики — кладовщик не видит результаты)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.checkedItems}/${summary.totalItems}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
              labelText:
                  AppLocalizations.of(context)!.searchByCodeTypeNumberHint,
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
                        ? AppLocalizations.of(context)!.noResultsFoundLabel
                        : _showOnlyDifferences
                            ? AppLocalizations.of(context)!.noDifferencesLabel
                            : AppLocalizations.of(context)!.noItemsLabel,
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
}
