import 'package:flutter/material.dart';
import '../../models/price.dart';
import '../../services/price_service.dart';
import '../../services/box_type_service.dart';
import '../../services/company_context.dart';

/// ЭТАЛОННЫЙ ЭКРАН для работы с company-scoped данными
///
/// Паттерн который нужно копировать на все экраны:
/// 1. Используем CompanyContext.watch() для автообновления при смене компании
/// 2. Получаем effectiveCompanyId из контекста (НЕ из userModel!)
/// 3. Все сервисы создаём с effectiveCompanyId
/// 4. При смене компании экран автоматически перестраивается
class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  List<Map<String, dynamic>> _allBoxTypes = [];
  List<Map<String, dynamic>> _filteredBoxTypes = [];
  Map<String, Price> _prices = {}; // key: companyId_type_number
  bool _isLoading = true;
  final _searchController = TextEditingController();

  String? _currentCompanyId; // Для отслеживания смены компании

  @override
  void initState() {
    super.initState();
    // Первоначальная загрузка данных произойдёт в build() через CompanyContext
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBoxTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBoxTypes = _allBoxTypes;
      } else {
        _filteredBoxTypes = _allBoxTypes.where((boxType) {
          final productCode =
              (boxType['productCode'] as String? ?? '').toLowerCase();
          final type = (boxType['type'] as String? ?? '').toLowerCase();
          final number = (boxType['number'] as String? ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return productCode.contains(searchLower) ||
              type.contains(searchLower) ||
              number.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadData(String companyId) async {
    if (companyId.isEmpty) {
      print('⚠️ [PriceManagement] CompanyId is empty, skipping load');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📊 [PriceManagement] Loading data for company: $companyId');

      // Создаём сервисы с текущим companyId
      final priceService = PriceService(companyId: companyId);
      final boxTypeService = BoxTypeService(companyId: companyId);

      // Загружаем все типы товаров из справочника
      final boxTypes = await boxTypeService.getAllBoxTypes();

      // Загружаем все цены
      final prices = await priceService.getAllPrices();
      final pricesMap = <String, Price>{};
      for (final price in prices) {
        pricesMap[price.id] = price;
      }

      if (mounted) {
        setState(() {
          _allBoxTypes = boxTypes;
          _filteredBoxTypes = boxTypes;
          _prices = pricesMap;
          _isLoading = false;
          _currentCompanyId = companyId;
        });
      }

      print(
          '✅ [PriceManagement] Loaded ${boxTypes.length} box types and ${prices.length} prices');
    } catch (e) {
      print('❌ [PriceManagement] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditPriceDialog(BuildContext context, String companyId, String type,
      String number, double? currentPrice) {
    final priceController = TextEditingController(
      text: currentPrice?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('עדכן מחיר - $type $number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'מחיר לפני מע"מ (₪)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'המחיר הוא לפני מע"מ (18%)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              final priceText = priceController.text.trim();
              final price = double.tryParse(priceText);

              if (price == null || price < 0) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('נא להזין מחיר תקין'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              try {
                // Получаем userName из контекста
                final companyCtx = CompanyContext.of(context);
                final userName = companyCtx.currentUser?.name ?? 'Unknown';

                // Создаём сервис с правильным companyId
                final priceService = PriceService(companyId: companyId);

                await priceService.setPrice(
                  type: type,
                  number: number,
                  priceBeforeVAT: price,
                  userName: userName,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ המחיר עודכן בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData(companyId); // Перезагружаем данные
                }
              } catch (e) {
                print('❌ [PriceManagement] Error updating price: $e');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ שגיאה בעדכון מחיר: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Используем CompanyContext.watch() для автообновления
    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Отслеживаем смену компании
    if (_currentCompanyId != effectiveCompanyId) {
      // Компания изменилась - перезагружаем данные
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              '🔄 [PriceManagement] Company changed: $_currentCompanyId -> $effectiveCompanyId');
          _loadData(effectiveCompanyId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול מחירים'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Поле поиска
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'חיפוש',
                      hintText: 'חיפוש לפי מק"ט, סוג או מספר',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterBoxTypes('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterBoxTypes,
                  ),
                ),
                // Список товаров
                Expanded(
                  child: _filteredBoxTypes.isEmpty
                      ? const Center(
                          child: Text(
                            'לא נמצאו תוצאות',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredBoxTypes.length,
                          itemBuilder: (context, index) {
                            final boxType = _filteredBoxTypes[index];
                            final productCode =
                                boxType['productCode'] as String? ?? '';
                            final type = boxType['type'] as String;
                            final number = boxType['number'] as String;
                            final volumeMl = boxType['volumeMl'] as int?;
                            final id = Price.generateId(
                                effectiveCompanyId, type, number);
                            final price = _prices[id];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                                title: Text(
                                  '$type $number${volumeMl != null ? " ($volumeMl מל)" : ""}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (productCode.isNotEmpty)
                                      Text(
                                        'מק"ט: $productCode',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    price != null
                                        ? Text(
                                            'מחיר: ₪${price.priceBeforeVAT.toStringAsFixed(2)} (לפני מע"מ)',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : const Text(
                                            'לא הוגדר מחיר',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    price != null
                                        ? Icons.edit
                                        : Icons.add_circle,
                                    color: price != null
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                  onPressed: () => _showEditPriceDialog(
                                    context,
                                    effectiveCompanyId,
                                    type,
                                    number,
                                    price?.priceBeforeVAT,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
