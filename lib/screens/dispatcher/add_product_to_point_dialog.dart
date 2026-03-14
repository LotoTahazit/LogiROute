import 'package:flutter/material.dart';
import '../../models/delivery_point.dart';
import '../../models/box_type.dart';
import '../../widgets/box_type_selector.dart';
import '../../l10n/app_localizations.dart';

/// Диалог добавления/редактирования товаров в существующий заказ
class AddProductToPointDialog extends StatefulWidget {
  final DeliveryPoint point;

  const AddProductToPointDialog({super.key, required this.point});

  @override
  State<AddProductToPointDialog> createState() =>
      _AddProductToPointDialogState();
}

class _AddProductToPointDialogState extends State<AddProductToPointDialog> {
  late List<BoxType> _boxTypes;

  @override
  void initState() {
    super.initState();
    _boxTypes = List<BoxType>.from(widget.point.boxTypes ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        '${l10n.addProduct} — ${widget.point.clientName}',
        style: const TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущие товары
              if (_boxTypes.isNotEmpty) ...[
                Text(
                  '${l10n.addProduct} (${_boxTypes.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              BoxTypeSelector(
                selectedBoxTypes: _boxTypes,
                onChanged: (updated) {
                  setState(() => _boxTypes = updated);
                },
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
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, _boxTypes),
          icon: const Icon(Icons.save, size: 18),
          label: Text(l10n.save),
        ),
      ],
    );
  }
}
