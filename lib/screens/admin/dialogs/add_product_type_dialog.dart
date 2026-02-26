import 'package:flutter/material.dart';
import '../../../models/product_type.dart';
import '../../../services/product_type_service.dart';
import '../../../l10n/app_localizations.dart';

class AddProductTypeDialog extends StatefulWidget {
  final String companyId;
  final String createdBy;

  const AddProductTypeDialog({
    super.key,
    required this.companyId,
    required this.createdBy,
  });

  @override
  State<AddProductTypeDialog> createState() => _AddProductTypeDialogState();
}

class _AddProductTypeDialogState extends State<AddProductTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _unitsPerBoxController = TextEditingController(text: '1');
  final _boxesPerPalletController = TextEditingController(text: '1');
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _newCategoryController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  bool _addingNewCategory = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final service = ProductTypeService(companyId: widget.companyId);
    final cats = await service.getCategories();
    setState(() {
      _categories = cats;
      // Выбираем первую существующую категорию или null
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
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
      title: Text(l10n.addNewProduct),
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
              // קטגוריה — דינמית מהחברה + אפשרות להוסיף חדשה
              if (_loadingCategories)
                const LinearProgressIndicator()
              else if (_addingNewCategory)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newCategoryController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'קטגוריה חדשה *',
                          border: const OutlineInputBorder(),
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
                        hint: const Text('בחר קטגוריה'),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        validator: (_) =>
                            (_selectedCategory == null && !_addingNewCategory)
                                ? l10n.requiredField
                                : null,
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
          : (_selectedCategory ?? 'general');

      final product = ProductType(
        id: '',
        companyId: widget.companyId,
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
        createdAt: DateTime.now(),
        createdBy: widget.createdBy,
      );

      Navigator.pop(context, product);
    }
  }
}
