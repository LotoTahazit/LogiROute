import 'package:flutter/material.dart';
import '../../../models/product_type.dart';
import '../../../services/product_type_service.dart';
import '../../../l10n/app_localizations.dart';

class EditProductTypeDialog extends StatefulWidget {
  final ProductType product;

  const EditProductTypeDialog({
    super.key,
    required this.product,
  });

  @override
  State<EditProductTypeDialog> createState() => _EditProductTypeDialogState();
}

class _EditProductTypeDialogState extends State<EditProductTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _productCodeController;
  late TextEditingController _unitsPerBoxController;
  late TextEditingController _boxesPerPalletController;
  late TextEditingController _weightController;
  late TextEditingController _volumeController;
  final _newCategoryController = TextEditingController();

  late String _selectedCategory;
  List<String> _categories = [];
  bool _addingNewCategory = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _productCodeController =
        TextEditingController(text: widget.product.productCode);
    _unitsPerBoxController =
        TextEditingController(text: widget.product.unitsPerBox.toString());
    _boxesPerPalletController =
        TextEditingController(text: widget.product.boxesPerPallet.toString());
    _weightController =
        TextEditingController(text: widget.product.weight?.toString() ?? '');
    _volumeController =
        TextEditingController(text: widget.product.volume?.toString() ?? '');
    _selectedCategory = widget.product.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final service = ProductTypeService(companyId: widget.product.companyId);
    final cats = await service.getCategories();
    setState(() {
      // Убеждаемся что текущая категория товара есть в списке
      _categories = cats.contains(_selectedCategory)
          ? cats
          : [_selectedCategory, ...cats];
      _loadingCategories = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productCodeController.dispose();
    _unitsPerBoxController.dispose();
    _boxesPerPalletController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editProduct),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.productName} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productCodeController,
                decoration: InputDecoration(
                  labelText: '${l10n.productCode} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 16),
              if (_loadingCategories)
                const LinearProgressIndicator()
              else if (_addingNewCategory)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newCategoryController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'קטגוריה חדשה *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? l10n.requiredField
                            : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'ביטול',
                      onPressed: () => setState(() {
                        _addingNewCategory = false;
                        _newCategoryController.clear();
                      }),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: l10n.category,
                          border: const OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() =>
                            _selectedCategory = value ?? _selectedCategory),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'קטגוריה חדשה',
                      onPressed: () =>
                          setState(() => _addingNewCategory = true),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitsPerBoxController,
                      decoration: InputDecoration(
                        labelText: '${l10n.unitsPerBox} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return l10n.requiredField;
                        if (int.tryParse(value) == null)
                          return l10n.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _boxesPerPalletController,
                      decoration: InputDecoration(
                        labelText: '${l10n.boxesPerPallet} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return l10n.requiredField;
                        if (int.tryParse(value) == null)
                          return l10n.invalidNumber;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: l10n.weight,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _volumeController,
                      decoration: InputDecoration(
                        labelText: l10n.volume,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final category = _addingNewCategory
          ? _newCategoryController.text.trim()
          : _selectedCategory;

      final product = widget.product.copyWith(
        name: _nameController.text.trim(),
        productCode: _productCodeController.text.trim(),
        category: category,
        unitsPerBox: int.parse(_unitsPerBoxController.text),
        boxesPerPallet: int.parse(_boxesPerPalletController.text),
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        volume: _volumeController.text.isNotEmpty
            ? double.tryParse(_volumeController.text)
            : null,
      );

      Navigator.pop(context, product);
    }
  }
}
