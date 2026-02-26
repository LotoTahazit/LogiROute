import 'package:flutter/material.dart';
import '../models/product_type.dart';
import '../models/box_type.dart';
import '../services/product_type_service.dart';
import '../services/product_type_adapter.dart';
import '../services/company_context.dart';
import '../l10n/app_localizations.dart';

/// Новый селектор товаров на основе ProductType
class ProductTypeSelector extends StatefulWidget {
  final List<BoxType> selectedBoxTypes;
  final Function(List<BoxType>) onChanged;

  const ProductTypeSelector({
    super.key,
    required this.selectedBoxTypes,
    required this.onChanged,
  });

  @override
  State<ProductTypeSelector> createState() => _ProductTypeSelectorState();
}

class _ProductTypeSelectorState extends State<ProductTypeSelector> {
  List<ProductType> _availableProducts = [];
  Map<String, int> _selectedQuantities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeFromBoxTypes();
  }

  void _initializeFromBoxTypes() {
    // Конвертируем существующие BoxType в количества
    for (final boxType in widget.selectedBoxTypes) {
      final key = '${boxType.type}_${boxType.number}';
      _selectedQuantities[key] = boxType.quantity;
    }
  }

  Future<void> _loadProducts() async {
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    if (companyId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final productService = ProductTypeService(companyId: companyId);

    // Слушаем изменения в реальном времени
    productService.getProductTypes(activeOnly: true).listen((products) {
      if (mounted) {
        setState(() {
          _availableProducts = products;
          _isLoading = false;
        });
      }
    });
  }

  void _addProduct(ProductType product) {
    showDialog(
      context: context,
      builder: (context) => _QuantityDialog(
        product: product,
        onConfirm: (quantity) {
          setState(() {
            _selectedQuantities[product.id] = quantity;
          });
          _notifyChanges();
        },
      ),
    );
  }

  void _updateQuantity(ProductType product, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedQuantities[product.id] = quantity;
      } else {
        _selectedQuantities.remove(product.id);
      }
    });
    _notifyChanges();
  }

  void _removeProduct(String productId) {
    setState(() {
      _selectedQuantities.remove(productId);
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    // Конвертируем выбранные товары в BoxType для обратной совместимости
    final selectedProducts = _availableProducts
        .where((p) => _selectedQuantities.containsKey(p.id))
        .toList();

    final boxTypes = selectedProducts.map((product) {
      final quantity = _selectedQuantities[product.id] ?? 1;
      return ProductTypeAdapter.toBoxType(product, quantity);
    }).toList();

    widget.onChanged(boxTypes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(l10n.noProducts),
              const SizedBox(height: 8),
              Text(l10n.addFirstProduct, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final selectedProducts = _availableProducts
        .where((p) => _selectedQuantities.containsKey(p.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Выбранные товары
        if (selectedProducts.isNotEmpty) ...[
          ...selectedProducts.map((product) {
            final quantity = _selectedQuantities[product.id] ?? 1;
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
                      onPressed: () => _updateQuantity(product, quantity - 1),
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateQuantity(product, quantity + 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeProduct(product.id),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Кнопка добавления товара
        ElevatedButton.icon(
          onPressed: () => _showProductPicker(),
          icon: const Icon(Icons.add),
          label: Text(l10n.addProduct),
        ),
      ],
    );
  }

  void _showProductPicker() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProduct),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableProducts.length,
            itemBuilder: (context, index) {
              final product = _availableProducts[index];
              final isSelected = _selectedQuantities.containsKey(product.id);

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
                  _addProduct(product);
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
}

/// Диалог ввода количества
class _QuantityDialog extends StatefulWidget {
  final ProductType product;
  final Function(int) onConfirm;

  const _QuantityDialog({
    required this.product,
    required this.onConfirm,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${l10n.productCode}: ${widget.product.productCode}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
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
            final quantity = int.tryParse(_controller.text) ?? 1;
            if (quantity > 0) {
              widget.onConfirm(quantity);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
