import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/box_type_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_context.dart';
import '../../../l10n/app_localizations.dart';

/// Диалог добавления нового типа в справочник и в инвентарь
///
/// Параметры:
/// - [userName] - имя пользователя для записи в историю
class AddBoxTypeDialog extends StatefulWidget {
  final String userName;

  const AddBoxTypeDialog({
    super.key,
    required this.userName,
  });

  @override
  State<AddBoxTypeDialog> createState() => _AddBoxTypeDialogState();

  /// Показать диалог добавления нового типа
  static Future<void> show({
    required BuildContext context,
    required String userName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddBoxTypeDialog(
        userName: userName,
      ),
    );
  }
}

class _AddBoxTypeDialogState extends State<AddBoxTypeDialog> {
  late final BoxTypeService _boxTypeService;

  final _productCodeController = TextEditingController(); // מק"ט - НОВОЕ ПОЛЕ
  final _typeController = TextEditingController();
  final _numberController = TextEditingController();
  final _volumeController = TextEditingController();
  final _quantityPerPalletController = TextEditingController(text: '1');
  final _diameterController = TextEditingController();
  final _piecesPerBoxController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
  }

  @override
  void dispose() {
    _productCodeController.dispose(); // מק"ט
    _typeController.dispose();
    _numberController.dispose();
    _volumeController.dispose();
    _quantityPerPalletController.dispose();
    _diameterController.dispose();
    _piecesPerBoxController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _productCodeController.text.trim().isNotEmpty && // מק"ט обязательное
        _typeController.text.trim().isNotEmpty &&
        _numberController.text.trim().isNotEmpty &&
        _quantityPerPalletController.text.trim().isNotEmpty &&
        int.tryParse(_quantityPerPalletController.text) != null &&
        int.parse(_quantityPerPalletController.text) > 0;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final volumeMl = _volumeController.text.trim().isEmpty
        ? null
        : int.tryParse(_volumeController.text);
    final quantityPerPallet =
        int.tryParse(_quantityPerPalletController.text) ?? 1;
    final piecesPerBox = int.tryParse(_piecesPerBoxController.text);

    try {
      // Добавляем в справочник box_types
      await _boxTypeService.addBoxType(
        productCode:
            _productCodeController.text.trim(), // מק"ט - ПЕРВЫЙ ПАРАМЕТР
        type: _typeController.text.trim(),
        number: _numberController.text.trim(),
        volumeMl: volumeMl,
        quantityPerPallet: quantityPerPallet,
        diameter: _diameterController.text.trim().isEmpty
            ? null
            : _diameterController.text.trim(),
        piecesPerBox: piecesPerBox,
        additionalInfo: _additionalInfoController.text.trim().isEmpty
            ? null
            : _additionalInfoController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newBoxTypeAdded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
      title: Text(l10n.addNewBoxType),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // מק"ט - ПЕРВОЕ ПОЛЕ
            TextField(
              controller: _productCodeController,
              decoration: InputDecoration(
                labelText: l10n.productCodeLabel,
                border: const OutlineInputBorder(),
                helperText: l10n.productCodeHelper,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Тип
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: l10n.typeLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Номер
            TextField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: l10n.numberLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Объем в мл (необязательное)
            TextField(
              controller: _volumeController,
              decoration: InputDecoration(
                labelText: l10n.volumeMlLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Количество на миштахе - обязательное
            TextField(
              controller: _quantityPerPalletController,
              decoration: InputDecoration(
                labelText: l10n.quantityPerPalletLabel,
                hintText: l10n.requiredField,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Диаметр (необязательное)
            TextField(
              controller: _diameterController,
              decoration: InputDecoration(
                labelText: l10n.diameterLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Количество в коробке (необязательное)
            TextField(
              controller: _piecesPerBoxController,
              decoration: InputDecoration(
                labelText: l10n.piecesPerBoxLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Дополнительные данные (необязательное)
            TextField(
              controller: _additionalInfoController,
              decoration: InputDecoration(
                labelText: l10n.additionalInfoLabel,
                border: const OutlineInputBorder(),
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
          onPressed: _canSave ? _save : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
