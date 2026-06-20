import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/inventory_item.dart';
import '../../../services/inventory_service.dart';
import '../../../services/company_context.dart';

/// Диалог редактирования товара
///
/// Параметры:
/// - [item] - товар для редактирования
/// - [userName] - имя пользователя для записи в историю
class EditInventoryDialog extends StatefulWidget {
  final InventoryItem item;
  final String userName;

  const EditInventoryDialog({
    super.key,
    required this.item,
    required this.userName,
  });

  @override
  State<EditInventoryDialog> createState() => _EditInventoryDialogState();

  /// Показать диалог редактирования товара
  static Future<void> show({
    required BuildContext context,
    required InventoryItem item,
    required String userName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditInventoryDialog(
        item: item,
        userName: userName,
      ),
    );
  }
}

class _EditInventoryDialogState extends State<EditInventoryDialog> {
  late final InventoryService _inventoryService;

  late final TextEditingController _productCodeController; // מק"ט - ПЕРВОЕ ПОЛЕ
  late final TextEditingController _typeController;
  late final TextEditingController _numberController;
  late final TextEditingController _volumeMlController;
  late final TextEditingController _quantityController;
  late final TextEditingController _quantityPerPalletController;
  late final TextEditingController _diameterController;
  late final TextEditingController _piecesPerBoxController;
  late final TextEditingController _additionalInfoController;

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _inventoryService = InventoryService(companyId: companyId);

    _productCodeController =
        TextEditingController(text: widget.item.productCode); // מק"ט
    _typeController = TextEditingController(text: widget.item.type);
    _numberController = TextEditingController(text: widget.item.number);
    _volumeMlController = TextEditingController(
        text: widget.item.volumeMl != null
            ? widget.item.volumeMl.toString()
            : '');
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _quantityPerPalletController =
        TextEditingController(text: widget.item.quantityPerPallet.toString());
    _diameterController =
        TextEditingController(text: widget.item.diameter ?? '');
    _piecesPerBoxController = TextEditingController(
        text: widget.item.piecesPerBox != null
            ? widget.item.piecesPerBox.toString()
            : '');
    _additionalInfoController =
        TextEditingController(text: widget.item.additionalInfo ?? '');
  }

  @override
  void dispose() {
    _productCodeController.dispose(); // מק"ט
    _typeController.dispose();
    _numberController.dispose();
    _volumeMlController.dispose();
    _quantityController.dispose();
    _quantityPerPalletController.dispose();
    _diameterController.dispose();
    _piecesPerBoxController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_productCodeController.text.trim().isEmpty || // מק"ט обязательное
        _typeController.text.trim().isEmpty ||
        _numberController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _quantityPerPalletController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllRequiredFieldsIncludingProductCode),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newProductCode = _productCodeController.text.trim(); // מק"ט
    final newType = _typeController.text.trim();
    final newNumber = _numberController.text.trim();
    final newVolumeMl = _volumeMlController.text.trim().isEmpty
        ? null
        : int.tryParse(_volumeMlController.text);
    final newQuantity = int.tryParse(_quantityController.text) ?? 0;
    final newQuantityPerPallet =
        int.tryParse(_quantityPerPalletController.text) ?? 1;
    final newPiecesPerBox = _piecesPerBoxController.text.trim().isEmpty
        ? null
        : int.tryParse(_piecesPerBoxController.text);
    final newDiameter = _diameterController.text.trim().isEmpty
        ? null
        : _diameterController.text.trim();
    final newAdditionalInfo = _additionalInfoController.text.trim().isEmpty
        ? null
        : _additionalInfoController.text.trim();

    try {
      // Обновляем товар с новым מק"ט
      await _inventoryService.updateInventory(
        productCode: newProductCode, // מק"ט - ПЕРВЫЙ ПАРАМЕТР
        type: newType,
        number: newNumber,
        volumeMl: newVolumeMl,
        volume: widget.item.volume, // Сохраняем старое значение
        quantity: newQuantity,
        quantityPerPallet: newQuantityPerPallet,
        userName: widget.userName,
        diameter: newDiameter,
        piecesPerBox: newPiecesPerBox,
        additionalInfo: newAdditionalInfo,
      );

      // Если מק"ט изменился, удаляем старый товар
      if (newProductCode != widget.item.productCode) {
        await _inventoryService.deleteInventoryItem(widget.item.productCode);
      }

      // Небольшая задержка для синхронизации с Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.itemUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithDetail(e.toString())),
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
      title: Text(l10n.editItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // מק"ט - ПЕРВОЕ ПОЛЕ
            TextField(
              controller: _productCodeController,
              decoration: InputDecoration(
                labelText: l10n.productCodeRequired,
                border: const OutlineInputBorder(),
                helperText: l10n.productCode,
              ),
            ),
            const SizedBox(height: 16),

            // Тип
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: l10n.typeRequired,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Номер
            TextField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: l10n.numberRequired,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Объем в мл (необязательное)
            TextField(
              controller: _volumeMlController,
              decoration: InputDecoration(
                labelText: l10n.volumeMlOptional,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Количество
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: '${l10n.quantityLabel} *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Количество на миштахе
            TextField(
              controller: _quantityPerPalletController,
              decoration: InputDecoration(
                labelText: l10n.quantityOnPalletRequired,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Диаметр (необязательное)
            TextField(
              controller: _diameterController,
              decoration: InputDecoration(
                labelText: l10n.diameterOptional,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Количество в коробке (необязательное)
            TextField(
              controller: _piecesPerBoxController,
              decoration: InputDecoration(
                labelText: l10n.packedCartonOptional,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Дополнительная информация (необязательное)
            TextField(
              controller: _additionalInfoController,
              decoration: InputDecoration(
                labelText: l10n.additionalInfoOptional,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
}
