import 'package:flutter/material.dart';
import '../models/box_type.dart';
import '../models/product_type.dart';
import '../services/box_type_service.dart';
import '../services/product_type_service.dart';
import '../services/company_context.dart';
import '../l10n/app_localizations.dart';

/// Гибридный селектор: использует ProductType если есть, иначе старый BoxTypeService
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

  // Старая система
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

    // Проверяем есть ли ProductType
    final productService = ProductTypeService(companyId: companyId);
    final products =
        await productService.getProductTypes(activeOnly: true).first;

    if (products.isNotEmpty) {
      // Используем новую систему
      setState(() {
        _useNewSystem = true;
        _productTypes = products;
        _isLoading = false;
      });
    } else {
      // Используем старую систему
      await _loadOldBoxTypes();
    }
  }

  Future<void> _loadOldBoxTypes() async {
    setState(() => _isLoading = true);

    try {
      await _boxTypeService.initializeDefaultBoxTypes();
      final types = await _boxTypeService.getUniqueTypes();
      final numbersByType = <String, List<Map<String, dynamic>>>{};

      for (final type in types) {
        final numbers = await _boxTypeService.getNumbersForType(type);
        numbersByType[type] = numbers;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_useNewSystem) {
      return _buildNewSystemUI();
    } else {
      return _buildOldSystemUI();
    }
  }

  // Новая система UI
  Widget _buildNewSystemUI() {
    final l10n = AppLocalizations.of(context)!;
    final selectedProducts = _productTypes.where((p) {
      return widget.selectedBoxTypes
          .any((bt) => bt.productCode == p.productCode);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedProducts.isNotEmpty) ...[
          ...selectedProducts.map((product) {
            final boxType = widget.selectedBoxTypes.firstWhere(
              (bt) => bt.productCode == product.productCode,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(product.name.substring(0, 1)),
                ),
                title: Text(product.name),
                subtitle: Text('${l10n.productCode}: ${product.productCode}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () =>
                          _updateNewQuantity(product, boxType.quantity - 1),
                    ),
                    Text('${boxType.quantity}',
                        style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _updateNewQuantity(product, boxType.quantity + 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeNewProduct(product),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        ElevatedButton.icon(
          onPressed: _showNewProductPicker,
          icon: const Icon(Icons.add),
          label: Text(l10n.addProduct),
        ),
      ],
    );
  }

  void _updateNewQuantity(ProductType product, int newQuantity) {
    if (newQuantity <= 0) {
      _removeNewProduct(product);
      return;
    }

    final updated = widget.selectedBoxTypes.map((bt) {
      if (bt.productCode == product.productCode) {
        return BoxType(
          type: bt.type,
          number: bt.number,
          quantity: newQuantity,
          productCode: bt.productCode,
          volumeMl: bt.volumeMl,
          companyId: bt.companyId,
        );
      }
      return bt;
    }).toList();

    widget.onChanged(updated);
  }

  void _removeNewProduct(ProductType product) {
    final updated = widget.selectedBoxTypes
        .where((bt) => bt.productCode != product.productCode)
        .toList();
    widget.onChanged(updated);
  }

  void _showNewProductPicker() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProduct),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _productTypes.length,
            itemBuilder: (context, index) {
              final product = _productTypes[index];
              final isSelected = widget.selectedBoxTypes.any(
                (bt) => bt.productCode == product.productCode,
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.green : Colors.grey,
                  child: Text(product.name.substring(0, 1)),
                ),
                title: Text(product.name),
                subtitle: Text('${l10n.productCode}: ${product.productCode}'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
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
                labelText: l10n.quantity,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              if (quantity > 0) {
                final companyCtx = CompanyContext.of(context);
                final companyId = companyCtx.effectiveCompanyId ?? '';

                final newBoxType = BoxType(
                  type: product.category,
                  number: product.name,
                  quantity: quantity,
                  productCode: product.productCode,
                  volumeMl: 0,
                  companyId: companyId,
                );

                widget.onChanged([...widget.selectedBoxTypes, newBoxType]);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  // Старая система UI (оставляем как есть для Y.C. Plast)
  Widget _buildOldSystemUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedBoxTypes.isNotEmpty) ...[
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
                          _updateOldQuantity(boxType, boxType.quantity - 1),
                    ),
                    Text('${boxType.quantity}',
                        style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _updateOldQuantity(boxType, boxType.quantity + 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeOldBoxType(boxType),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        ElevatedButton.icon(
          onPressed: _showOldBoxTypePicker,
          icon: const Icon(Icons.add),
          label: const Text('הוסף סוג קופסה'),
        ),
      ],
    );
  }

  void _updateOldQuantity(BoxType boxType, int newQuantity) {
    if (newQuantity <= 0) {
      _removeOldBoxType(boxType);
      return;
    }

    final updated = widget.selectedBoxTypes.map((bt) {
      if (bt.type == boxType.type && bt.number == boxType.number) {
        return BoxType(
          type: bt.type,
          number: bt.number,
          quantity: newQuantity,
          productCode: bt.productCode,
          volumeMl: bt.volumeMl,
          companyId: bt.companyId,
        );
      }
      return bt;
    }).toList();

    widget.onChanged(updated);
  }

  void _removeOldBoxType(BoxType boxType) {
    final updated = widget.selectedBoxTypes
        .where(
            (bt) => !(bt.type == boxType.type && bt.number == boxType.number))
        .toList();
    widget.onChanged(updated);
  }

  void _showOldBoxTypePicker() {
    // Показываем старый диалог выбора
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר סוג קופסה'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableTypes.length,
            itemBuilder: (context, index) {
              final type = _availableTypes[index];
              return ExpansionTile(
                title: Text(type),
                children: (_numbersByType[type] ?? []).map((item) {
                  final number = item['number'] as String;
                  final productCode = item['productCode'] as String? ?? '';

                  return ListTile(
                    title: Text(number),
                    subtitle: Text('מק"ט: $productCode'),
                    onTap: () {
                      Navigator.pop(context);
                      _addOldBoxType(type, number, productCode);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
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
                labelText: 'כמות',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              if (quantity > 0) {
                final companyCtx = CompanyContext.of(context);
                final companyId = companyCtx.effectiveCompanyId ?? '';

                final newBoxType = BoxType(
                  type: type,
                  number: number,
                  quantity: quantity,
                  productCode: productCode,
                  volumeMl: 0,
                  companyId: companyId,
                );

                widget.onChanged([...widget.selectedBoxTypes, newBoxType]);
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
