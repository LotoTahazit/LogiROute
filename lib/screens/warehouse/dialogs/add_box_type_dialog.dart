import 'package:flutter/material.dart';
import '../../../services/box_type_service.dart';

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
  final BoxTypeService _boxTypeService = BoxTypeService();

  final _typeController = TextEditingController();
  final _numberController = TextEditingController();
  final _volumeController = TextEditingController();
  final _quantityPerPalletController = TextEditingController(text: '1');
  final _diameterController = TextEditingController();
  final _piecesPerBoxController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  void dispose() {
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
    return _typeController.text.trim().isNotEmpty &&
        _numberController.text.trim().isNotEmpty &&
        _quantityPerPalletController.text.trim().isNotEmpty &&
        int.tryParse(_quantityPerPalletController.text) != null &&
        int.parse(_quantityPerPalletController.text) > 0;
  }

  Future<void> _save() async {
    final volumeMl = _volumeController.text.trim().isEmpty
        ? null
        : int.tryParse(_volumeController.text);
    final quantityPerPallet =
        int.tryParse(_quantityPerPalletController.text) ?? 1;
    final piecesPerBox = int.tryParse(_piecesPerBoxController.text);

    try {
      // Добавляем в box_types только если указан volumeMl
      if (volumeMl != null) {
        await _boxTypeService.addBoxType(
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
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('סוג חדש נוסף למאגר בהצלחה!'),
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
      title: const Text('הוסף סוג חדש למאגר'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Тип
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'סוג (בביע, מכסה, כוס) *',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Номер
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'מספר (100, 200, וכו\') *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Объем в мл (необязательное)
            TextField(
              controller: _volumeController,
              decoration: const InputDecoration(
                labelText: 'נפח במ"ל (אופציונלי)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Количество на миштахе - обязательное
            TextField(
              controller: _quantityPerPalletController,
              decoration: const InputDecoration(
                labelText: 'כמות במשטח *',
                hintText: 'חובה',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Диаметр (необязательное)
            TextField(
              controller: _diameterController,
              decoration: const InputDecoration(
                labelText: 'קוטר (אופציונלי)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Количество в коробке (необязательное)
            TextField(
              controller: _piecesPerBoxController,
              decoration: const InputDecoration(
                labelText: 'ארוז - כמות בקרטון (אופציונלי)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Дополнительные данные (необязательное)
            TextField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'מידע נוסף (אופציונלי)',
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
