import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiroute/services/box_type_service.dart';
import 'package:logiroute/services/auth_service.dart';
import 'package:logiroute/services/company_context.dart';
import 'package:logiroute/l10n/app_localizations.dart';

class EditBoxTypeDialog extends StatefulWidget {
  final String id;
  final String oldProductCode;
  final String oldType;
  final String oldNumber;
  final int oldVolumeMl;
  final int oldQuantityPerPallet;
  final String? oldDiameter;
  final int? oldPiecesPerBox;
  final String? oldAdditionalInfo;

  const EditBoxTypeDialog({
    super.key,
    required this.id,
    required this.oldProductCode,
    required this.oldType,
    required this.oldNumber,
    required this.oldVolumeMl,
    required this.oldQuantityPerPallet,
    this.oldDiameter,
    this.oldPiecesPerBox,
    this.oldAdditionalInfo,
  });

  @override
  State<EditBoxTypeDialog> createState() => _EditBoxTypeDialogState();

  static Future<void> show({
    required BuildContext context,
    required String id,
    required String oldProductCode,
    required String oldType,
    required String oldNumber,
    required int oldVolumeMl,
    required int oldQuantityPerPallet,
    String? oldDiameter,
    int? oldPiecesPerBox,
    String? oldAdditionalInfo,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditBoxTypeDialog(
        id: id,
        oldProductCode: oldProductCode,
        oldType: oldType,
        oldNumber: oldNumber,
        oldVolumeMl: oldVolumeMl,
        oldQuantityPerPallet: oldQuantityPerPallet,
        oldDiameter: oldDiameter,
        oldPiecesPerBox: oldPiecesPerBox,
        oldAdditionalInfo: oldAdditionalInfo,
      ),
    );
  }
}

class _EditBoxTypeDialogState extends State<EditBoxTypeDialog> {
  late final BoxTypeService _boxTypeService;
  late final TextEditingController _productCodeController;
  late final TextEditingController _typeController;
  late final TextEditingController _numberController;
  late final TextEditingController _volumeController;
  late final TextEditingController _quantityPerPalletController;
  late final TextEditingController _diameterController;
  late final TextEditingController _piecesPerBoxController;
  late final TextEditingController _additionalInfoController;

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);

    _productCodeController = TextEditingController(text: widget.oldProductCode);
    _typeController = TextEditingController(text: widget.oldType);
    _numberController = TextEditingController(text: widget.oldNumber);
    _volumeController = TextEditingController(
        text: widget.oldVolumeMl > 0 ? widget.oldVolumeMl.toString() : '');
    _quantityPerPalletController =
        TextEditingController(text: widget.oldQuantityPerPallet.toString());
    _diameterController = TextEditingController(text: widget.oldDiameter ?? '');
    _piecesPerBoxController =
        TextEditingController(text: widget.oldPiecesPerBox?.toString() ?? '');
    _additionalInfoController =
        TextEditingController(text: widget.oldAdditionalInfo ?? '');
  }

  @override
  void dispose() {
    _productCodeController.dispose();
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
    return _productCodeController.text.trim().isNotEmpty &&
        _typeController.text.trim().isNotEmpty &&
        _numberController.text.trim().isNotEmpty &&
        _quantityPerPalletController.text.trim().isNotEmpty &&
        int.tryParse(_quantityPerPalletController.text) != null &&
        int.parse(_quantityPerPalletController.text) > 0;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.fillAllRequiredFields),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final volumeMl = _volumeController.text.trim().isEmpty
        ? null
        : int.tryParse(_volumeController.text);
    final quantityPerPallet =
        int.tryParse(_quantityPerPalletController.text) ?? 1;
    final piecesPerBox = int.tryParse(_piecesPerBoxController.text);

    try {
      await _boxTypeService.deleteBoxType(widget.id);
      await _boxTypeService.addBoxType(
        productCode: _productCodeController.text.trim(),
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
              content: Text(l10n.typeUpdatedSuccessfully),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editBoxType),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _productCodeController,
                decoration: InputDecoration(
                    labelText: l10n.productCodeLabel,
                    border: const OutlineInputBorder(),
                    helperText: l10n.productCodeHelper),
                onChanged: (value) => setState(() {})),
            const SizedBox(height: 16),
            TextField(
                controller: _typeController,
                decoration: InputDecoration(
                    labelText: l10n.typeLabel,
                    border: const OutlineInputBorder()),
                onChanged: (value) => setState(() {})),
            const SizedBox(height: 16),
            TextField(
                controller: _numberController,
                decoration: InputDecoration(
                    labelText: l10n.numberLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {})),
            const SizedBox(height: 16),
            TextField(
                controller: _volumeController,
                decoration: InputDecoration(
                    labelText: l10n.volumeMlLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {})),
            const SizedBox(height: 16),
            TextField(
                controller: _quantityPerPalletController,
                decoration: InputDecoration(
                    labelText: l10n.quantityPerPalletLabel,
                    hintText: l10n.requiredField,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {})),
            const SizedBox(height: 16),
            TextField(
                controller: _diameterController,
                decoration: InputDecoration(
                    labelText: l10n.diameterLabel,
                    border: const OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
                controller: _piecesPerBoxController,
                decoration: InputDecoration(
                    labelText: l10n.piecesPerBoxLabel,
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(
                controller: _additionalInfoController,
                decoration: InputDecoration(
                    labelText: l10n.additionalInfoLabel,
                    border: const OutlineInputBorder()),
                maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
            onPressed: _canSave ? _save : null, child: Text(l10n.save)),
      ],
    );
  }
}
