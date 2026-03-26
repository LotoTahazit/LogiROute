import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' as xl;
import '../../models/inventory_count.dart';
import '../../models/count_item.dart';
import '../../services/inventory_count_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../utils/file_download_stub.dart'
    if (dart.library.html) '../../utils/file_download_web.dart';

/// Детальный экран отчета по инвентаризации (Web-ориентированный)
class InventoryCountDetailScreen extends StatefulWidget {
  final String countId;

  const InventoryCountDetailScreen({
    super.key,
    required this.countId,
  });

  @override
  State<InventoryCountDetailScreen> createState() =>
      _InventoryCountDetailScreenState();
}

class _InventoryCountDetailScreenState
    extends State<InventoryCountDetailScreen> {
  late final InventoryCountService _countService;
  InventoryCount? _count;
  bool _isLoading = true;
  bool _showOnlyDifferences = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // ✅ Используем CompanyContext для получения effectiveCompanyId
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _countService = InventoryCountService(companyId: companyId);
    _loadCount();
  }

  Future<void> _loadCount() async {
    setState(() => _isLoading = true);

    try {
      final count = await _countService.getCountById(widget.countId);

      if (mounted) {
        setState(() {
          _count = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingReport}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportToExcel(InventoryCount count) {
    try {
      final l10n = AppLocalizations.of(context)!;
      final excel = xl.Excel.createExcel();
      final sheet = excel['Inventory'];

      // Headers
      sheet.appendRow([
        xl.TextCellValue(l10n.productCode),
        xl.TextCellValue('Type'),
        xl.TextCellValue('Number'),
        xl.TextCellValue(l10n.expected),
        xl.TextCellValue(l10n.actualCounted),
        xl.TextCellValue(l10n.difference),
        xl.TextCellValue(l10n.notes),
      ]);

      // Data rows
      for (final item in count.items) {
        sheet.appendRow([
          xl.TextCellValue(item.productCode),
          xl.TextCellValue(item.type),
          xl.TextCellValue(item.number),
          xl.IntCellValue(item.expectedQuantity),
          item.actualQuantity != null
              ? xl.IntCellValue(item.actualQuantity!)
              : xl.TextCellValue('—'),
          item.difference != null
              ? xl.IntCellValue(item.difference!)
              : xl.TextCellValue('—'),
          xl.TextCellValue(item.notes ?? ''),
        ]);
      }

      // Remove default Sheet1
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final fileName =
          'inventory_${count.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        downloadFile(bytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.exportToExcel}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel export available on web only')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveCount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.approveCount),
        content: Text(l10n.approveCountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.approveAndUpdate),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _countService.approveAndUpdateInventory(widget.countId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.countApproved),
            backgroundColor: Colors.green,
          ),
        );

        // Перезагружаем данные
        await _loadCount();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorApprovingCount}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CountItem> _getFilteredItems() {
    if (_count == null) return [];

    var items = _count!.items;

    // Фильтр только расхождения
    if (_showOnlyDifferences) {
      items = items.where((item) => item.hasDifference).toList();
    }

    // Фильтр по поиску
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final search = _searchQuery.toLowerCase();
        return item.productCode.toLowerCase().contains(search) ||
            item.type.toLowerCase().contains(search) ||
            item.number.toLowerCase().contains(search);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.countReport)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_count == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.countReport)),
        body: Center(child: Text(l10n.countNotFound)),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isCompleted =
        _count!.status == 'completed' || _count!.status == 'approved';
    final isApproved = _count!.status == 'approved';
    final filteredItems = _getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.countReport} #${widget.countId.substring(0, 8)}'),
        actions: [
          // Фильтр
          IconButton(
            icon: Icon(
              _showOnlyDifferences
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _showOnlyDifferences ? Colors.orange : null,
            ),
            tooltip: l10n.showOnlyDifferences,
            onPressed: () {
              setState(() => _showOnlyDifferences = !_showOnlyDifferences);
            },
          ),
          // Экспорт в Excel
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.exportToExcel,
            onPressed: _count == null ? null : () => _exportToExcel(_count!),
          ),
        ],
      ),
      body: Column(
        children: [
          // Шапка с информацией
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      isApproved
                          ? Icons.check_circle
                          : isCompleted
                              ? Icons.done
                              : Icons.pending,
                      color: isApproved
                          ? Colors.green
                          : isCompleted
                              ? Colors.blue
                              : Colors.orange,
                      size: 40,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: narrow ? 260 : 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.inventoryCount} — ${DateFormat('dd/MM/yyyy HH:mm').format(_count!.startedAt)}',
                            style: TextStyle(
                              fontSize: narrow ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${l10n.performedBy}: ${_count!.userName}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(_count!.status, l10n),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.countStartedLabel}: ${dateFormat.format(_count!.startedAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_count!.completedAt != null)
                            Text(
                              '${l10n.countFinishedLabel}: ${dateFormat.format(_count!.completedAt!)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Статистика
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      icon: Icons.inventory,
                      label: l10n.totalItemsLabel,
                      value: '${_count!.summary.totalItems}',
                      color: Colors.blue,
                    ),
                    _buildStatBox(
                      icon: Icons.check_circle,
                      label: l10n.countedLabel,
                      value: '${_count!.summary.checkedItems}',
                      color: Colors.green,
                    ),
                    _buildStatBox(
                      icon: Icons.warning,
                      label: l10n.differencesLabel,
                      value: '${_count!.summary.itemsWithDifference}',
                      color: Colors.orange,
                    ),
                    _buildStatBox(
                      icon: Icons.arrow_downward,
                      label: l10n.shortageLabel,
                      value: '${_count!.summary.totalShortage}',
                      color: Colors.red,
                    ),
                    _buildStatBox(
                      icon: Icons.arrow_upward,
                      label: l10n.surplusLabel,
                      value: '${_count!.summary.totalSurplus}',
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
                labelText: l10n.searchByProductCodeTypeNumber,
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

          // Таблица товаров
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      _showOnlyDifferences ? l10n.noDifferences : l10n.noItems,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(item, l10n);
                    },
                  ),
          ),

          // Кнопка подтверждения
          if (isCompleted && !isApproved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _approveCount,
                icon: const Icon(Icons.check_circle),
                label: Text('${l10n.approveCount} ${l10n.inventoryChangesReport.toLowerCase()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color color;
    String text;

    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        text = l10n.inProgress;
        break;
      case 'completed':
        color = Colors.blue;
        text = l10n.completed;
        break;
      case 'approved':
        color = Colors.green;
        text = l10n.approved;
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CountItem item, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: item.isShortage
          ? Colors.red.shade50
          : item.isSurplus
              ? Colors.green.shade50
              : Colors.white,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.productCode,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          '${item.type} ${item.number}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text('${l10n.expected}: ${item.expectedQuantity}'),
            Text('${l10n.actualCounted}: ${item.actualQuantity ?? "-"}'),
            if (item.hasDifference)
              Text(
                '${l10n.difference}: ${item.difference! > 0 ? "+" : ""}${item.difference}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item.isShortage ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
        children: [
          if (item.relatedOrders.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.suspiciousOrders}:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.relatedOrders.map((order) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                order.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                '${l10n.order} #${order.orderNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getStatusText(order.status, l10n),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${l10n.clientName}: ${order.clientName}'),
                          Text(
                              '${l10n.quantity}: ${order.quantity} ${l10n.units}'),
                          const SizedBox(height: 4),
                          Text(
                            order.reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return '${l10n.delivered} ✓';
      case 'in_transit':
      case 'in_progress':
      case 'assigned':
        return '${l10n.inProgress} 🚚';
      case 'cancelled':
        return '${l10n.cancelled} ❌';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'in_transit':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
