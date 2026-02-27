import 'package:flutter/material.dart';
import '../models/box_type.dart';
import '../models/inventory_item.dart';
import '../models/product_type.dart';
import '../services/box_type_service.dart';
import '../services/product_type_service.dart';
import '../services/inventory_service.dart';
import '../services/company_context.dart';
import '../l10n/app_localizations.dart';

/// Гибридный селектор: использует BoxType (box_types) если есть, иначе ProductType
class BoxTypeSelector extends StatefulWidget {
  final List<BoxType> selectedBoxTypes;
  final Function(List<BoxType>) onChanged;

  const BoxTypeSelector({
    super.key,
    required this.selectedBoxTypes,
    required this.onChanged,
  });

  @override
  State<BoxTypeSelector> createState() => _BoxTypeSelectorState();
}

class _BoxTypeSelectorState extends State<BoxTypeSelector> {
  bool _useNewSystem = false;
  bool _isLoading = true;
  List<ProductType> _productTypes = [];

  late final BoxTypeService _boxTypeService;
  List<String> _availableTypes = [];
  Map<String, List<Map<String, dynamic>>> _numbersByType = {};

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
    _checkSystemAndLoad();
  }

  Future<void> _checkSystemAndLoad() async {
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    if (companyId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Приоритет: box_types (реальные данные), потом product_types
    await _loadOldBoxTypes();
    if (_availableTypes.isNotEmpty) return;

    final productService = ProductTypeService(companyId: companyId);
    final products =
        await productService.getProductTypes(activeOnly: true).first;
    if (products.isNotEmpty) {
      setState(() {
        _useNewSystem = true;
        _productTypes = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOldBoxTypes() async {
    setState(() => _isLoading = true);
    try {
      await _boxTypeService.initializeDefaultBoxTypes();
      final types = await _boxTypeService.getUniqueTypes();
      final numbersByType = <String, List<Map<String, dynamic>>>{};
      for (final type in types) {
        numbersByType[type] = await _boxTypeService.getNumbersForType(type);
      }
      setState(() {
        _availableTypes = types;
        _numbersByType = numbersByType;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading box types: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return _useNewSystem ? _buildNewSystemUI() : _buildOldSystemUI();
  }

  // ─── Новая система (ProductType) ───

  Widget _buildNewSystemUI() {
    final l10n = AppLocalizations.of(context)!;
    final selectedProducts = _productTypes
        .where((p) => widget.selectedBoxTypes
            .any((bt) => bt.productCode == p.productCode))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...selectedProducts.map((product) {
          final boxType = widget.selectedBoxTypes
              .firstWhere((bt) => bt.productCode == product.productCode);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(product.name.substring(0, 1))),
              title: Text(product.name),
              subtitle: Text('${l10n.productCode}: ${product.productCode}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () =>
                          _updateNewQuantity(product, boxType.quantity - 1)),
                  Text('${boxType.quantity}',
                      style: const TextStyle(fontSize: 16)),
                  IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _updateNewQuantity(product, boxType.quantity + 1)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeNewProduct(product)),
                ],
              ),
            ),
          );
        }),
        ElevatedButton.icon(
          onPressed: _showNewProductPicker,
          icon: const Icon(Icons.add),
          label: Text(l10n.addProduct),
        ),
      ],
    );
  }

  void _updateNewQuantity(ProductType product, int qty) {
    if (qty <= 0) return _removeNewProduct(product);
    widget.onChanged(widget.selectedBoxTypes.map((bt) {
      if (bt.productCode == product.productCode) {
        return BoxType(
            type: bt.type,
            number: bt.number,
            quantity: qty,
            productCode: bt.productCode,
            volumeMl: bt.volumeMl,
            companyId: bt.companyId);
      }
      return bt;
    }).toList());
  }

  void _removeNewProduct(ProductType product) {
    widget.onChanged(widget.selectedBoxTypes
        .where((bt) => bt.productCode != product.productCode)
        .toList());
  }

  void _showNewProductPicker() {
    final l10n = AppLocalizations.of(context)!;
    final searchController = TextEditingController();
    var filtered = List<ProductType>.from(_productTypes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.addProduct),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'חיפוש לפי מק"ט, סוג, מספר...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (query) {
                      final q = query.toLowerCase();
                      setDialogState(() {
                        filtered = _productTypes.where((p) {
                          return p.name.toLowerCase().contains(q) ||
                              p.productCode.toLowerCase().contains(q) ||
                              p.category.toLowerCase().contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final isSelected = widget.selectedBoxTypes
                            .any((bt) => bt.productCode == product.productCode);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isSelected ? Colors.green : Colors.grey,
                            child: Text(product.name.substring(0, 1)),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                              '${l10n.productCode}: ${product.productCode}'),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            _addNewProduct(product);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel)),
            ],
          );
        },
      ),
    );
  }

  void _addNewProduct(ProductType product) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.productCode}: ${product.productCode}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                  labelText: l10n.quantity, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              if (quantity > 0) {
                final companyId =
                    CompanyContext.of(context).effectiveCompanyId ?? '';
                widget.onChanged([
                  ...widget.selectedBoxTypes,
                  BoxType(
                      type: product.category,
                      number: product.name,
                      quantity: quantity,
                      productCode: product.productCode,
                      volumeMl: 0,
                      companyId: companyId),
                ]);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  // ─── Старая система (BoxType / box_types) ───

  Widget _buildOldSystemUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.selectedBoxTypes.map((boxType) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${boxType.type} ${boxType.number}'),
              subtitle: Text('מק"ט: ${boxType.productCode}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () =>
                          _updateOldQuantity(boxType, boxType.quantity - 1)),
                  Text('${boxType.quantity}',
                      style: const TextStyle(fontSize: 16)),
                  IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _updateOldQuantity(boxType, boxType.quantity + 1)),
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeOldBoxType(boxType)),
                ],
              ),
            ),
          );
        }),
        ElevatedButton.icon(
          onPressed: _showOldBoxTypePicker,
          icon: const Icon(Icons.add),
          label: const Text('הוסף סוג קופסה'),
        ),
      ],
    );
  }

  void _updateOldQuantity(BoxType boxType, int qty) {
    if (qty <= 0) return _removeOldBoxType(boxType);
    widget.onChanged(widget.selectedBoxTypes.map((bt) {
      if (bt.type == boxType.type && bt.number == boxType.number) {
        return BoxType(
            type: bt.type,
            number: bt.number,
            quantity: qty,
            productCode: bt.productCode,
            volumeMl: bt.volumeMl,
            companyId: bt.companyId);
      }
      return bt;
    }).toList());
  }

  void _removeOldBoxType(BoxType boxType) {
    widget.onChanged(widget.selectedBoxTypes
        .where(
            (bt) => !(bt.type == boxType.type && bt.number == boxType.number))
        .toList());
  }

  void _showOldBoxTypePicker() async {
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    // Загружаем остатки со склада ДО открытия диалога
    final inventoryService = InventoryService(companyId: companyId);
    final inventoryItems = await inventoryService.getInventory();
    final stockMap = <String, InventoryItem>{};
    for (final inv in inventoryItems) {
      stockMap[inv.productCode] = inv;
    }

    // Собираем плоский список, обогащённый данными со склада
    final allItems = <Map<String, dynamic>>[];
    for (final type in _availableTypes) {
      for (final item in (_numbersByType[type] ?? [])) {
        final code = item['productCode'] as String? ?? '';
        final inv = stockMap[code];
        allItems.add({
          'type': type,
          'number': item['number'] as String,
          'productCode': code,
          'stock': inv?.quantity,
          'quantityPerPallet':
              inv?.quantityPerPallet ?? item['quantityPerPallet'],
          'piecesPerBox': inv?.piecesPerBox ?? item['piecesPerBox'],
          'diameter': inv?.diameter ?? item['diameter'],
          'volumeMl': inv?.volumeMl ?? item['volumeMl'],
          'volume': inv?.volume,
          'additionalInfo': inv?.additionalInfo ?? item['additionalInfo'],
        });
      }
    }

    // Сортировка по מק"ט (числовой)
    allItems.sort((a, b) {
      final codeA = int.tryParse(a['productCode'] as String) ?? 999999;
      final codeB = int.tryParse(b['productCode'] as String) ?? 999999;
      return codeA.compareTo(codeB);
    });

    if (!mounted) return;

    final searchController = TextEditingController();
    var filtered = List<Map<String, dynamic>>.from(allItems);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('הוסף מוצר'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'חיפוש לפי מק"ט, סוג, מספר...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (query) {
                      final q = query.toLowerCase();
                      setDialogState(() {
                        filtered = allItems.where((item) {
                          final t = (item['type'] as String).toLowerCase();
                          final n = (item['number'] as String).toLowerCase();
                          final c =
                              (item['productCode'] as String).toLowerCase();
                          return t.contains(q) ||
                              n.contains(q) ||
                              c.contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildPickerTile(filtered[index]),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPickerTile(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final number = item['number'] as String;
    final productCode = item['productCode'] as String;
    final stock = item['stock'] as int?;
    final piecesPerBox = item['piecesPerBox'];
    final quantityPerPallet = item['quantityPerPallet'];
    final diameter = item['diameter'];
    final volumeMl = item['volumeMl'];
    final volume = item['volume'];
    final additionalInfo = item['additionalInfo'];

    final details = <String>[];
    if (stock != null) details.add('במלאי: $stock יח\'');
    if (piecesPerBox != null) details.add('ארוז: $piecesPerBox');
    if (quantityPerPallet != null) details.add('במשטח: $quantityPerPallet');
    if (diameter != null && '$diameter'.isNotEmpty) {
      details.add('קוטר: $diameter');
    }
    if (volumeMl != null) details.add('נפח: $volumeMl מ"ל');
    if (volume != null && '$volume'.isNotEmpty) details.add('נפח: $volume');
    if (additionalInfo != null && '$additionalInfo'.isNotEmpty) {
      details.add('$additionalInfo');
    }

    final stockColor = stock == null
        ? Colors.grey
        : stock > 0
            ? Colors.green
            : Colors.red;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: stockColor,
        foregroundColor: Colors.white,
        child: Text(type.substring(0, 1)),
      ),
      title: Text('$type $number'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('מק"ט: $productCode', style: const TextStyle(fontSize: 12)),
          if (details.isNotEmpty)
            Text(
              details.join(' | '),
              style: TextStyle(
                fontSize: 11,
                color: stock == 0 ? Colors.red : Colors.grey[600],
              ),
            ),
        ],
      ),
      isThreeLine: details.isNotEmpty,
      onTap: () {
        Navigator.pop(context);
        _addOldBoxType(type, number, productCode);
      },
    );
  }

  void _addOldBoxType(String type, String number, String productCode) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type $number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('מק"ט: $productCode'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                  labelText: 'כמות', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              if (quantity > 0) {
                final companyId =
                    CompanyContext.of(context).effectiveCompanyId ?? '';
                widget.onChanged([
                  ...widget.selectedBoxTypes,
                  BoxType(
                      type: type,
                      number: number,
                      quantity: quantity,
                      productCode: productCode,
                      volumeMl: 0,
                      companyId: companyId),
                ]);
                Navigator.pop(context);
              }
            },
            child: const Text('הוסף'),
          ),
        ],
      ),
    );
  }
}
