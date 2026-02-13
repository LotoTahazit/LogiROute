import 'package:flutter/material.dart';
import '../models/box_type.dart';
import '../services/box_type_service.dart';

class BoxTypeSelector extends StatefulWidget {
  final List<BoxType> selectedBoxTypes;
  final Function(List<BoxType>) onChanged;

  const BoxTypeSelector({
    super.key,
    required this.selectedBoxTypes,
    required this.onChanged,
  });

  @override
  State<BoxTypeSelector> createState() => _BoxTypeSelectorState();
}

class _BoxTypeSelectorState extends State<BoxTypeSelector> {
  final BoxTypeService _boxTypeService = BoxTypeService();
  List<String> _availableTypes = [];
  Map<String, List<Map<String, dynamic>>> _numbersByType = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxTypes();
  }

  Future<void> _loadBoxTypes() async {
    setState(() => _isLoading = true);

    try {
      // Инициализируем справочник если пустой
      await _boxTypeService.initializeDefaultBoxTypes();

      // Загружаем уникальные типы
      final types = await _boxTypeService.getUniqueTypes();

      // Загружаем номера для каждого типа
      final numbersByType = <String, List<Map<String, dynamic>>>{};
      for (final type in types) {
        final numbers = await _boxTypeService.getNumbersForType(type);
        numbersByType[type] = numbers;
      }

      setState(() {
        _availableTypes = types;
        _numbersByType = numbersByType;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading box types: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddBoxTypeDialog() {
    // Если справочник пустой, сразу показываем форму добавления нового типа
    if (_availableTypes.isEmpty) {
      _showAddNewBoxTypeToDatabase(isFirstTime: true);
      return;
    }

    String? selectedType;
    String? selectedNumber;
    int? volumeMl;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('הוסף סוג קופסה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Выбор типа
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'סוג',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                      selectedNumber = null; // Сбрасываем номер
                      volumeMl = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Выбор номера (зависит от типа)
                if (selectedType != null)
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        selectedType), // Добавляем key для пересоздания виджета
                    initialValue: selectedNumber,
                    decoration: const InputDecoration(
                      labelText: 'מספר',
                      border: OutlineInputBorder(),
                    ),
                    items: (_numbersByType[selectedType] ?? []).map((item) {
                      final number = item['number'] as String;
                      final ml = item['volumeMl'] as int;
                      return DropdownMenuItem(
                        value: number,
                        child: Text('$number ($mlמל)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedNumber = value;
                        // Находим volumeMl для выбранного номера
                        final item = _numbersByType[selectedType]!
                            .firstWhere((item) => item['number'] == value);
                        volumeMl = item['volumeMl'] as int;
                      });
                    },
                  ),
                const SizedBox(height: 16),

                // Количество
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'כמות',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Обновляем состояние при изменении количества
                    setState(() {});
                  },
                ),

                const SizedBox(height: 16),

                // Кнопка добавления нового типа в справочник
                TextButton.icon(
                  onPressed: () => _showAddNewBoxTypeToDatabase(),
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
              onPressed: selectedType != null &&
                      selectedNumber != null &&
                      volumeMl != null &&
                      quantityController.text.isNotEmpty &&
                      int.tryParse(quantityController.text) != null &&
                      int.parse(quantityController.text) > 0
                  ? () {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 1;
                      final newBoxType = BoxType(
                        type: selectedType!,
                        number: selectedNumber!,
                        volumeMl: volumeMl!,
                        quantity: quantity,
                      );

                      final updatedList =
                          List<BoxType>.from(widget.selectedBoxTypes)
                            ..add(newBoxType);
                      widget.onChanged(updatedList);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('הוסף'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewBoxTypeToDatabase({bool isFirstTime = false}) {
    final typeController = TextEditingController();
    final numberController = TextEditingController();
    final volumeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !isFirstTime, // Нельзя закрыть если первый раз
      builder: (context) => AlertDialog(
        title:
            Text(isFirstTime ? 'הוסף סוג קופסה ראשון' : 'הוסף סוג חדש למאגר'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFirstTime)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'המאגר ריק. הוסף את הסוג הראשון.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'סוג (בביע, מכסה, כוס)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'מספר (100, 200, וכו\')',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: volumeController,
              decoration: const InputDecoration(
                labelText: 'נפח (מל)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          if (!isFirstTime)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty &&
                  numberController.text.isNotEmpty &&
                  volumeController.text.isNotEmpty) {
                try {
                  await _boxTypeService.addBoxType(
                    type: typeController.text.trim(),
                    number: numberController.text.trim(),
                    volumeMl: int.parse(volumeController.text),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('סוג קופסה נוסף בהצלחה!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadBoxTypes(); // Перезагружаем список
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
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _removeBoxType(int index) {
    final updatedList = List<BoxType>.from(widget.selectedBoxTypes)
      ..removeAt(index);
    widget.onChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'קופסאות:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddBoxTypeDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('הוסף קופסה'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.selectedBoxTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'לא נבחרו קופסאות',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.selectedBoxTypes.length,
            itemBuilder: (context, index) {
              final boxType = widget.selectedBoxTypes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.blue),
                  title: Text(
                    boxType.toDisplayString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeBoxType(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
