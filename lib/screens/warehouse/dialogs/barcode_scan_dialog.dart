import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/inventory_item.dart';
import '../../../services/inventory_service.dart';

/// Сканирование ברקוד (USB-сканер = клавиатура + Enter).
class BarcodeScanDialog extends StatefulWidget {
  final String companyId;
  final String userName;

  const BarcodeScanDialog({
    super.key,
    required this.companyId,
    required this.userName,
  });

  static Future<void> show(
    BuildContext context, {
    required String companyId,
    required String userName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BarcodeScanDialog(
        companyId: companyId,
        userName: userName,
      ),
    );
  }

  @override
  State<BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<BarcodeScanDialog> {
  final _codeCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _codeFocus = FocusNode();
  bool _incoming = true;
  bool _busy = false;
  InventoryItem? _preview;

  late final InventoryService _service;

  @override
  void initState() {
    super.initState();
    _service = InventoryService(companyId: widget.companyId);
    _requestCodeFocus();
  }

  /// Курсор в поле штрихкода (сканер = клавиатура).
  void _requestCodeFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _codeFocus.requestFocus();
      // После анимации диалога (особенно web) фокус иногда уходит.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _codeFocus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _qtyCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    final item = await _service.findByScanCode(code);
    if (mounted) setState(() => _preview = item);
  }

  int get _parsedQty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  bool get _canSubmit =>
      !_busy && _codeCtrl.text.trim().isNotEmpty && _parsedQty > 0;

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    final qty = _parsedQty;
    if (code.isEmpty || qty <= 0) return;

    setState(() => _busy = true);
    try {
      final delta = _incoming ? qty : -qty;
      final item = await _service.applyBarcodeScan(
        scanCode: code,
        quantityDelta: delta,
        userName: widget.userName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.barcodeScanSuccess(
            item.productCode,
            item.quantity,
          )),
          backgroundColor: Colors.green,
        ),
      );
      _codeCtrl.clear();
      setState(() => _preview = null);
      _requestCodeFocus();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('BARCODE_NOT_FOUND')
          ? l10n.barcodeNotFound
          : e.toString().contains('INSUFFICIENT_STOCK')
              ? l10n.barcodeInsufficientStock
              : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      _requestCodeFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.barcodeScanTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.barcodeScanHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.barcodeScanFieldLabel,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _lookup,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() => _preview = null),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Text(
                _preview!.toShortString(),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.barcodeScanIn)),
                ButtonSegment(value: false, label: Text(l10n.barcodeScanOut)),
              ],
              selected: {_incoming},
              onSelectionChanged: (s) => setState(() => _incoming = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: l10n.quantity,
                border: const OutlineInputBorder(),
                helperText: _parsedQty <= 0 ? l10n.quantityMustBePositive : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.barcodeScanApply),
        ),
      ],
    );
  }
}
