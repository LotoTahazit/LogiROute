import 'package:flutter/material.dart';
import '../../../services/box_type_service.dart';

/// Диалог редактирования типа в справочнике
///
/// Параметры:
/// - [id] - ID типа в справочнике
/// - [oldType] - текущий тип
/// - [oldNumber] - текущий номер
/// - [oldVolumeMl] - текущий объем в мл
class EditBoxTypeDialog extends StatefulWidget {
  final String id;
  final String oldType;
  final String oldNumber;
  final int oldVolumeMl;

  const EditBoxTypeDialog({
    super.key,
    required this.id,
    required this.oldType,
    required this.oldNumber,
    required this.oldVolumeMl,
  });

  @override
  State<EditBoxTypeDialog> createState() => _EditBoxTypeDialogState();

  /// Показать диалог редактирования типа
  static Future<void> show({
    required BuildContext context,
    required String id,
    required String oldType,
    required String oldNumber,
    required int oldVolumeMl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditBoxTypeDialog(
        id: id,
        oldType: oldType,
        oldNumber: oldNumber,
        oldVolumeMl: oldVolumeMl,
      ),
    );
  }
}

class _EditBoxTypeDialogState extends State<EditBoxTypeDialog> {
  final BoxTypeService _boxTypeService = BoxTypeService();

  late final TextEditingController _typeController;
  late final TextEditingController _numberController;
  late final TextEditingController _volumeController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.oldType);
    _numberController = TextEditingController(text: widget.oldNumber);
    _volumeController =
        TextEditingController(text: widget.oldVolumeMl.toString());
  }

  @override
  void dispose() {
    _typeController.dispose();
    _numberController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_typeController.text.trim().isEmpty ||
        _numberController.text.trim().isEmpty ||
        _volumeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא למלא את כל השדות'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Удаляем старый
      await _boxTypeService.deleteBoxType(widget.id);

      // Добавляем новый
      await _boxTypeService.addBoxType(
        type: _typeController.text.trim(),
        number: _numberController.text.trim(),
        volumeMl: int.parse(_volumeController.text),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('סוג עודכן בהצלחה!'),
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
      title: const Text('ערוך סוג'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _typeController,
            decoration: const InputDecoration(
              labelText: 'סוג (בביע, מכסה, כוס)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(
              labelText: 'מספר (100, 200, וכו\')',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _volumeController,
            decoration: const InputDecoration(
              labelText: 'נפח (מל)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
