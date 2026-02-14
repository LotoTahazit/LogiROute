import 'package:flutter/material.dart';
import '../../../services/box_type_service.dart';
import 'edit_box_type_dialog.dart';
import 'delete_confirmation_dialog.dart';

/// Диалог управления справочником типов коробок
class BoxTypesManagerDialog extends StatefulWidget {
  const BoxTypesManagerDialog({super.key});

  @override
  State<BoxTypesManagerDialog> createState() => _BoxTypesManagerDialogState();

  /// Показать диалог управления справочником
  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog(
      context: context,
      builder: (context) => const BoxTypesManagerDialog(),
    );
  }
}

class _BoxTypesManagerDialogState extends State<BoxTypesManagerDialog> {
  final BoxTypeService _boxTypeService = BoxTypeService();
  List<Map<String, dynamic>> _boxTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxTypes();
  }

  Future<void> _loadBoxTypes() async {
    setState(() => _isLoading = true);

    final boxTypes = await _boxTypeService.getAllBoxTypes();

    // Сортируем по типу, потом по номеру
    boxTypes.sort((a, b) {
      final typeCompare = (a['type'] as String).compareTo(b['type'] as String);
      if (typeCompare != 0) return typeCompare;

      final numA = int.tryParse(a['number'] as String);
      final numB = int.tryParse(b['number'] as String);
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      return (a['number'] as String).compareTo(b['number'] as String);
    });

    if (mounted) {
      setState(() {
        _boxTypes = boxTypes;
        _isLoading = false;
      });
    }
  }

  Future<void> _editBoxType(
      String id, String type, String number, int volumeMl) async {
    await EditBoxTypeDialog.show(
      context: context,
      id: id,
      oldType: type,
      oldNumber: number,
      oldVolumeMl: volumeMl,
    );
    // Перезагружаем список после редактирования
    _loadBoxTypes();
  }

  Future<void> _deleteBoxType(String id, String type, String number) async {
    await DeleteConfirmationDialog.show(
      context: context,
      title: 'מחק סוג',
      content: 'האם למחוק $type $number מהמאגר?',
      onConfirm: () async {
        await _boxTypeService.deleteBoxType(id);
      },
    );
    // Перезагружаем список после удаления
    _loadBoxTypes();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ניהול מאגר סוגים'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _boxTypes.isEmpty
                ? const Center(
                    child: Text('אין סוגים במאגר'),
                  )
                : ListView.builder(
                    itemCount: _boxTypes.length,
                    itemBuilder: (context, index) {
                      final boxType = _boxTypes[index];
                      final type = boxType['type'] as String;
                      final number = boxType['number'] as String;
                      final volumeMl = boxType['volumeMl'] as int?;
                      final id = boxType['id'] as String;

                      return Card(
                        child: ListTile(
                          title: Text('$type $number'),
                          subtitle: volumeMl != null
                              ? Text('$volumeMl מל')
                              : const Text('נפח לא צוין'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editBoxType(
                                    id, type, number, volumeMl ?? 0),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteBoxType(id, type, number),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('סגור'),
        ),
      ],
    );
  }
}
