import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/inventory_service.dart';
import '../../../services/box_type_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_context.dart';
import '../../../l10n/app_localizations.dart';

/// Диалог добавления товара в инвентарь
///
/// Параметры:
/// - [userName] - имя пользователя для записи в историю
class AddInventoryDialog extends StatefulWidget {
  final String userName;

  const AddInventoryDialog({
    super.key,
    required this.userName,
  });

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();

  /// Показать диалог добавления товара
  static Future<void> show({
    required BuildContext context,
    required String userName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(
        userName: userName,
      ),
    );
  }
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  late final BoxTypeService _boxTypeService;
  late final InventoryService _inventoryService;

  List<Map<String, dynamic>> _boxTypes = [];
  String? _selectedProductCode; // Выбранный מק"ט из справочника
  String? _selectedType;
  String? _selectedNumber;

  // Поля из справочника
  int? _volumeMl;
  int? _quantityPerPallet;
  String? _diameter;
  int? _piecesPerBox;
  String? _additionalInfo;

  final _productCodeController = TextEditingController(); // Поле ввода מק"ט
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
    _inventoryService = InventoryService(companyId: companyId);

    _loadBoxTypes();
    // Слушаем изменения в поле מק"ט для поиска
    _productCodeController.addListener(() {
      _searchByProductCode(_productCodeController.text);
    });
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadBoxTypes() async {
    final boxTypes = await _boxTypeService.getAllBoxTypes();
    if (mounted) {
      setState(() {
        _boxTypes = boxTypes;
        // Если справочник пустой, предупреждаем пользователя
        if (_boxTypes.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.catalogEmpty),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  // Поиск товара по מק"ט, типу или номеру
  void _searchByProductCode(String searchText) {
    if (searchText.trim().isEmpty) {
      setState(() {
        _selectedProductCode = null;
        _selectedType = null;
        _selectedNumber = null;
        _volumeMl = null;
        _quantityPerPallet = null;
        _diameter = null;
        _piecesPerBox = null;
        _additionalInfo = null;
      });
      return;
    }

    final search = searchText.toLowerCase();

    try {
      // Сначала ищем по ТОЧНОМУ совпадению מק"ט
      Map<String, dynamic>? item;

      try {
        item = _boxTypes.firstWhere(
          (bt) => (bt['productCode'] as String).toLowerCase() == search,
        );
      } catch (e) {
        // Если точного совпадения нет, ищем по частичному совпадению
        item = _boxTypes.firstWhere(
          (bt) {
            final productCode = (bt['productCode'] as String).toLowerCase();
            final type = (bt['type'] as String).toLowerCase();
            final number = (bt['number'] as String).toLowerCase();

            return productCode.contains(search) ||
                type.contains(search) ||
                number.contains(search);
          },
        );
      }

      setState(() {
        _selectedProductCode = item!['productCode'] as String;
        _selectedType = item['type'] as String;
        _selectedNumber = item['number'] as String;
        _volumeMl = item['volumeMl'] as int?;
        _quantityPerPallet = item['quantityPerPallet'] as int?;
        _diameter = item['diameter'] as String?;
        _piecesPerBox = item['piecesPerBox'] as int?;
        _additionalInfo = item['additionalInfo'] as String?;
      });
    } catch (e) {
      // Если товар не найден, сбрасываем выбор
      setState(() {
        _selectedProductCode = null;
        _selectedType = null;
        _selectedNumber = null;
        _volumeMl = null;
        _quantityPerPallet = null;
        _diameter = null;
        _piecesPerBox = null;
        _additionalInfo = null;
      });
    }
  }

  bool get _canSave {
    return _selectedProductCode != null && // מק"ט найден в справочнике
        _quantityController.text.isNotEmpty &&
        int.tryParse(_quantityController.text) != null &&
        int.parse(_quantityController.text) > 0;
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    try {
      await _inventoryService.addInventory(
        productCode: _selectedProductCode!, // מק"ט из справочника
        type: _selectedType!,
        number: _selectedNumber!,
        volumeMl: _volumeMl,
        quantity: quantity,
        quantityPerPallet: _quantityPerPallet ?? 1,
        userName: widget.userName,
        diameter: _diameter,
        piecesPerBox: _piecesPerBox,
        additionalInfo: _additionalInfo,
      );

      // Небольшая задержка для синхронизации с Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventoryUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addInventory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Поиск по מק"ט - ПЕРВОЕ ПОЛЕ
            TextField(
              controller: _productCodeController,
              decoration: InputDecoration(
                labelText: l10n.productCodeLabel,
                border: const OutlineInputBorder(),
                helperText: l10n.productCodeSearchHelper,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Показываем статус поиска מק"ט
            if (_productCodeController.text.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedProductCode != null
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedProductCode != null
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedProductCode != null
                          ? Icons.check_circle
                          : Icons.error,
                      color: _selectedProductCode != null
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedProductCode != null
                            ? l10n.productCodeFoundInCatalog
                            : l10n.productCodeNotFoundInCatalog,
                        style: TextStyle(
                          color: _selectedProductCode != null
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Альтернативный выбор מק"ט из выпадающего списка - МЕТКИ ЛОКАЛИЗОВАННЫЕ
            DropdownButtonFormField<String>(
              initialValue: _selectedProductCode,
              decoration: InputDecoration(
                labelText: l10n.orSelectFromList,
                border: const OutlineInputBorder(),
                helperText: l10n.selectFromFullList,
              ),
              items: _boxTypes.where((bt) {
                // Фильтруем список по поисковому запросу
                if (_productCodeController.text.trim().isEmpty) {
                  return true; // Показываем все, если поиск пустой
                }
                final search = _productCodeController.text.toLowerCase();
                final productCode = (bt['productCode'] as String).toLowerCase();
                final type = (bt['type'] as String).toLowerCase();
                final number = (bt['number'] as String).toLowerCase();

                return productCode.contains(search) ||
                    type.contains(search) ||
                    number.contains(search);
              }).map((bt) {
                final productCode = bt['productCode'] as String;
                final type = bt['type'] as String;
                final number = bt['number'] as String;
                return DropdownMenuItem(
                  value: productCode,
                  child: Text('$productCode ($type $number)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductCode = value;
                  if (value != null) {
                    _productCodeController.text =
                        value; // Синхронизируем с полем поиска
                    final item = _boxTypes.firstWhere(
                      (bt) => bt['productCode'] == value,
                    );
                    _selectedType = item['type'] as String;
                    _selectedNumber = item['number'] as String;
                    _volumeMl = item['volumeMl'] as int?;
                    _quantityPerPallet = item['quantityPerPallet'] as int?;
                    _diameter = item['diameter'] as String?;
                    _piecesPerBox = item['piecesPerBox'] as int?;
                    _additionalInfo = item['additionalInfo'] as String?;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Показываем выбранный тип и номер (только для информации)
            if (_selectedProductCode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('סוג: $_selectedType',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('מספר: $_selectedNumber'),
                    if (_volumeMl != null) Text('נפח: $_volumeMl מל'),
                    if (_quantityPerPallet != null)
                      Text('כמות במשטח: $_quantityPerPallet'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Выбор типа - УБИРАЕМ, теперь автоматически из מק"ט
            // DropdownButtonFormField<String>(
            // Количество (штук)
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'כמות (יחידות)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _canSave ? _save : null,
          child: Text(AppLocalizations.of(context)!.save),
        ),
        if (!_canSave &&
            _productCodeController.text.trim().isNotEmpty &&
            _selectedProductCode == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.productCodeNotFoundAddFirst,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
