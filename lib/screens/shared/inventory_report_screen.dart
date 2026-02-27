import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import '../../models/inventory_change.dart';
import '../../l10n/app_localizations.dart';
import '../../services/company_context.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // По умолчанию показываем сегодняшний день
    _setToday();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        0,
        0,
        0,
      );
      _endDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );
    });
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _startDate = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
        0,
        0,
        0,
      );
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setAllTime() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Stream<List<InventoryChange>> _getChangesStream() {
    // Получаем companyId из контекста
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    if (companyId.isEmpty) {
      debugPrint('❌ [InventoryReport] CompanyId is empty!');
      return Stream.value([]);
    }

    // Используем вложенную коллекцию companies/{companyId}/inventory_history
    Query query = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('inventory_history')
        .orderBy('timestamp', descending: true);

    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: _endDate);
    }

    return query.limit(500).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => InventoryChange.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
          0,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Widget _buildQuickFilterButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: Colors.blue),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  List<InventoryChange> _filterChanges(List<InventoryChange> changes) {
    if (_searchQuery.isEmpty) return changes;

    final query = _searchQuery.toLowerCase();
    return changes.where((change) {
      return change.productCode.toLowerCase().contains(query) ||
          change.type.toLowerCase().contains(query) ||
          change.number.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryChangesReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: l10n.selectDates,
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            // Фильтр по датам с кнопками быстрого выбора
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  // Текущий период
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null && _endDate != null
                            ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                            : l10n.allPeriod,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.date_range, size: 20),
                        onPressed: _selectDateRange,
                        tooltip: l10n.selectDates,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Кнопки быстрого выбора
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickFilterButton(l10n.today, _setToday),
                      _buildQuickFilterButton(l10n.yesterday, _setYesterday),
                      _buildQuickFilterButton(l10n.thisWeek, _setThisWeek),
                      _buildQuickFilterButton(l10n.thisMonth, _setThisMonth),
                      _buildQuickFilterButton(l10n.all, _setAllTime),
                    ],
                  ),
                ],
              ),
            ),

            // Поле поиска по товару
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textDirection: ui.TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: l10n.searchByProductCodeTypeNumberHint,
                      hintTextDirection: ui.TextDirection.rtl,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: StreamBuilder<List<InventoryChange>>(
                        stream: _getChangesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final filtered = _filterChanges(snapshot.data!);
                            final totalAdded = filtered
                                .where((c) => c.quantityChange > 0)
                                .fold(0, (sum, c) => sum + c.quantityChange);
                            final totalDeducted = filtered
                                .where((c) => c.quantityChange < 0)
                                .fold(
                                  0,
                                  (sum, c) => sum + c.quantityChange.abs(),
                                );

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    l10n.foundChanges(filtered.length),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${l10n.added}: +$totalAdded',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  Text(
                                    '${l10n.deducted}: -$totalDeducted',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Список изменений в реальном времени
            Expanded(
              child: StreamBuilder<List<InventoryChange>>(
                stream: _getChangesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('${l10n.error}: ${snapshot.error}'));
                  }

                  final allChanges = snapshot.data ?? [];
                  final changes = _filterChanges(allChanges);

                  if (changes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? l10n.noResultsFor(_searchQuery)
                                : l10n.noChangesInPeriod,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Группируем по дате
                  final Map<String, List<InventoryChange>> groupedByDate = {};
                  for (final change in changes) {
                    final dateKey = _formatDate(change.timestamp);
                    groupedByDate.putIfAbsent(dateKey, () => []);
                    groupedByDate[dateKey]!.add(change);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedByDate.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedByDate.keys.elementAt(index);
                      final dayChanges = groupedByDate[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок даты
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                          // Изменения за день
                          ...dayChanges.map((change) {
                            final isAddition = change.quantityChange > 0;
                            final color =
                                isAddition ? Colors.green : Colors.red;
                            final icon = isAddition
                                ? Icons.add_circle
                                : Icons.remove_circle;

                            final isHighlighted = _searchQuery.isNotEmpty &&
                                (change.productCode.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                    change.type.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                    change.number.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ));

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color:
                                  isHighlighted ? Colors.yellow.shade100 : null,
                              elevation: isHighlighted ? 4 : 1,
                              child: ListTile(
                                leading: Icon(icon, color: color, size: 32),
                                title: Text(
                                  '${l10n.productCode}: ${change.productCode} | ${change.type} ${change.number}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: isHighlighted
                                        ? Colors.yellow.shade300
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${change.actionInHebrew}: ${isAddition ? '+' : ''}${change.quantityChange} יח\'',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${l10n.before}: ${change.quantityBefore} → ${l10n.after}: ${change.quantityAfter}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '${_formatDateTime(change.timestamp)} | ${change.userName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (change.reason != null)
                                      Text(
                                        '${l10n.reason}: ${change.reason}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
