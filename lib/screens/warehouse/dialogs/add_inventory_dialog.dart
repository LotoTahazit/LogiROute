import 'package:flutter/material.dart';
import '../../../services/inventory_service.dart';
import '../../../services/box_type_service.dart';

/// Диалог добавления товара в инвентарь
///
/// Параметры:
/// - [userName] - имя пользователя для записи в историю
/// - [onAddNewType] - callback для открытия диалога добавления нового типа
class AddInventoryDialog extends StatefulWidget {
  final String userName;
  final VoidCallback onAddNewType;

  const AddInventoryDialog({
    super.key,
    required this.userName,
    required this.onAddNewType,
  });

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();

  /// Показать диалог добавления товара
  static Future<void> show({
    required BuildContext context,
    required String userName,
    required VoidCallback onAddNewType,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(
        userName: userName,
        onAddNewType: onAddNewType,
      ),
    );
  }
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final BoxTypeService _boxTypeService = BoxTypeService();
  final InventoryService _inventoryService = InventoryService();

  List<Map<String, dynamic>> _boxTypes = [];
  String? _selectedType;
  String? _selectedNumber;

  // Поля из справочника
  int? _volumeMl;
  int? _quantityPerPallet;
  String? _diameter;
  int? _piecesPerBox;
  String? _additionalInfo;

  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBoxTypes();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadBoxTypes() async {
    final boxTypes = await _boxTypeService.getAllBoxTypes();
    if (mounted) {
      setState(() {
        _boxTypes = boxTypes;
      });
    }
  }

  bool get _canSave {
    return _selectedType != null &&
        _selectedNumber != null &&
        _quantityController.text.isNotEmpty &&
        int.tryParse(_quantityController.text) != null &&
        int.parse(_quantityController.text) > 0;
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    try {
      await _inventoryService.addInventory(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('מלאי עודכן בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הוסף מלאי'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Выбор типа
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'סוג',
                border: OutlineInputBorder(),
              ),
              items:
                  (_boxTypes.map((bt) => bt['type'] as String).toSet().toList()
                        ..sort())
                      .map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _selectedNumber = null;
                  _volumeMl = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Выбор номера
            if (_selectedType != null)
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedType),
                initialValue: _selectedNumber,
                decoration: const InputDecoration(
                  labelText: 'מספר',
                  border: OutlineInputBorder(),
                ),
                items: (_boxTypes
                        .where((bt) => bt['type'] == _selectedType)
                        .toList()
                      ..sort((a, b) {
                        final numA = int.tryParse(a['number'] as String);
                        final numB = int.tryParse(b['number'] as String);
                        if (numA != null && numB != null) {
                          return numA.compareTo(numB);
                        }
                        return (a['number'] as String)
                            .compareTo(b['number'] as String);
                      }))
                    .map((bt) {
                  final number = bt['number'] as String;
                  final ml = bt['volumeMl'] as int?;
                  return DropdownMenuItem(
                    value: number,
                    child: Text(ml != null ? '$number ($mlמל)' : number),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedNumber = value;
                    final item = _boxTypes.firstWhere(
                      (bt) =>
                          bt['type'] == _selectedType && bt['number'] == value,
                    );

                    // Заполняем ВСЕ поля из справочника
                    _volumeMl = item['volumeMl'] as int?;
                    _quantityPerPallet = item['quantityPerPallet'] as int?;
                    _diameter = item['diameter'] as String?;
                    _piecesPerBox = item['piecesPerBox'] as int?;
                    _additionalInfo = item['additionalInfo'] as String?;
                  });
                },
              ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

            // Кнопка добавления нового типа
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onAddNewType();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('הוסף סוג חדש למאגר'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _canSave ? _save : null,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
