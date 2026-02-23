import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/price.dart';
import '../../services/price_service.dart';
import '../../services/box_type_service.dart';
import '../../services/auth_service.dart';

class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  final PriceService _priceService = PriceService();
  late final BoxTypeService _boxTypeService;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _allBoxTypes = [];
  List<Map<String, dynamic>> _filteredBoxTypes = [];
  Map<String, Price> _prices = {}; // key: type_number
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Загружаем все типы товаров из справочника
      final boxTypes = await _boxTypeService.getAllBoxTypes();

      // Загружаем все цены
      final prices = await _priceService.getAllPrices();
      final pricesMap = <String, Price>{};
      for (final price in prices) {
        pricesMap[price.id] = price;
      }

      setState(() {
        _allBoxTypes = boxTypes;
        _filteredBoxTypes = boxTypes;
        _prices = pricesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEditPriceDialog(String type, String number, double? currentPrice) {
    final priceController = TextEditingController(
      text: currentPrice?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              final priceText = priceController.text.trim();
              final price = double.tryParse(priceText);

              if (price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('נא להזין מחיר תקין'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = _authService.userModel;
                await _priceService.setPrice(
                  type: type,
                  number: number,
                  priceBeforeVAT: price,
                  userName: user?.name ?? 'Unknown',
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ המחיר עודכן בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData(); // Перезагружаем данные
                }
              } catch (e) {
                print('❌ [PriceManagement] Error updating price: $e');
                if (mounted) {
                  Navigator.pop(context); // Close dialog first
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
                            final id = Price.generateId(type, number);
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
