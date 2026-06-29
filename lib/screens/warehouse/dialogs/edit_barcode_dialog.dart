import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/inventory_item.dart';
import '../../../services/inventory_service.dart';

class EditBarcodeDialog extends StatefulWidget {
  final InventoryItem item;
  final String companyId;
  final String userName;

  const EditBarcodeDialog({
    super.key,
    required this.item,
    required this.companyId,
    required this.userName,
  });

  static Future<void> show(
    BuildContext context, {
    required InventoryItem item,
    required String companyId,
    required String userName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => EditBarcodeDialog(
        item: item,
        companyId: companyId,
        userName: userName,
      ),
    );
  }

  @override
  State<EditBarcodeDialog> createState() => _EditBarcodeDialogState();
}

class _EditBarcodeDialogState extends State<EditBarcodeDialog> {
  late final TextEditingController _barcodeCtrl;
  late final InventoryService _service;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.item.barcode ?? '');
    _service = InventoryService(companyId: widget.companyId);
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.updateItemBarcode(
        productCode: widget.item.productCode,
        barcode: _barcodeCtrl.text,
        userName: widget.userName,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.barcodeUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('BARCODE_DUPLICATE')
                ? l10n.barcodeDuplicateError
                : '${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.barcodeEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.productCode}: ${widget.item.productCode}'),
          const SizedBox(height: 12),
          TextField(
            controller: _barcodeCtrl,
            decoration: InputDecoration(
              labelText: l10n.barcodeScanFieldLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.qr_code),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
