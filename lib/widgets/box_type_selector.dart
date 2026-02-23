import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/box_type.dart';
import '../services/box_type_service.dart';
import '../services/auth_service.dart';

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
  late final BoxTypeService _boxTypeService;
  List<String> _availableTypes = [];
  Map<String, List<Map<String, dynamic>>> _numbersByType = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    _boxTypeService = BoxTypeService(companyId: companyId);
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

    String? selectedProductCode;
    String? selectedType;
    String? selectedNumber;
    int? volumeMl;
    final quantityController = TextEditingController(text: '1');

    // Получаем все productCode и типы для автокомплита
    final allProductCodes = <String>[];
    final allSearchOptions = <String>[]; // Комбинированный список для поиска
    final productCodeMap = <String, Map<String, dynamic>>{};
    final typeToItemsMap =
        <String, List<Map<String, dynamic>>>{}; // סוג -> список товаров

    for (final type in _availableTypes) {
      // Добавляем сам тип в поиск
      if (!allSearchOptions.contains(type)) {
        allSearchOptions.add(type);
      }

      typeToItemsMap[type] = [];

      for (final item in _numbersByType[type] ?? []) {
        final code = item['productCode'] as String? ?? '';
        if (code.isNotEmpty) {
          allProductCodes.add(code);
          allSearchOptions.add(code); // Добавляем מק"ט в общий поиск
          productCodeMap[code] = item;
          typeToItemsMap[type]!.add(item);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('הוסף סוג קופסה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Поиск по מק"ט или סוג
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return allSearchOptions.where((option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selected) {
                    setState(() {
                      // Проверяем, это מק"ט или סוג
                      if (productCodeMap.containsKey(selected)) {
                        // Это מק"ט - заполняем все поля
                        final item = productCodeMap[selected];
                        selectedProductCode = selected;
                        selectedType = item?['type'] as String?;
                        selectedNumber = item?['number'] as String?;
                        volumeMl = item?['volumeMl'] as int? ?? 0;
                      } else if (_availableTypes.contains(selected)) {
                        // Это סוג - показываем только тип, ждем выбора מספר
                        selectedType = selected;
                        selectedProductCode = null;
                        selectedNumber = null;
                        volumeMl = null;
                      }
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'חפש לפי מק"ט או סוג',
                        border: OutlineInputBorder(),
                        hintText: 'הקלד מק"ט או סוג (בביע, מכסה, כוס)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Проверяем, что введено
                          if (productCodeMap.containsKey(value)) {
                            // Это מק"ט
                            final item = productCodeMap[value];
                            selectedProductCode = value;
                            selectedType = item?['type'] as String?;
                            selectedNumber = item?['number'] as String?;
                            volumeMl = item?['volumeMl'] as int? ?? 0;
                          } else if (_availableTypes.contains(value)) {
                            // Это סוג
                            selectedType = value;
                            selectedProductCode = null;
                            selectedNumber = null;
                            volumeMl = null;
                          } else {
                            // Ручной ввод - сбрасываем
                            selectedProductCode =
                                value.isNotEmpty ? value : null;
                            selectedType = null;
                            selectedNumber = null;
                            volumeMl = null;
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // סוג - показывается после выбора
                TextField(
                  controller: TextEditingController(text: selectedType ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'סוג',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // מספר - выбор из списка если выбран только סוג
                if (selectedType != null && selectedProductCode == null)
                  DropdownButtonFormField<String>(
                    value: selectedNumber,
                    decoration: const InputDecoration(
                      labelText: 'מספר',
                      border: OutlineInputBorder(),
                    ),
                    items: (typeToItemsMap[selectedType] ?? []).map((item) {
                      final number = item['number'] as String;
                      final code = item['productCode'] as String? ?? '';
                      final ml = item['volumeMl'] as int?;
                      return DropdownMenuItem(
                        value: number,
                        child: Text(
                          ml != null
                              ? '$number ($mlמל) - $code'
                              : '$number - $code',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedNumber = value;
                        // Находим полную информацию
                        final item = typeToItemsMap[selectedType]!.firstWhere(
                          (item) => item['number'] == value,
                        );
                        selectedProductCode = item['productCode'] as String?;
                        volumeMl = item['volumeMl'] as int? ?? 0;
                      });
                    },
                  )
                else
                  // מספר - только для отображения если выбран מק"ט
                  TextField(
                    controller:
                        TextEditingController(text: selectedNumber ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'מספר',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                const SizedBox(height: 16),

                // כמות
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'כמות',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
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
              onPressed: selectedProductCode != null &&
                      selectedProductCode!.isNotEmpty &&
                      selectedType != null &&
                      selectedNumber != null &&
                      quantityController.text.isNotEmpty &&
                      int.tryParse(quantityController.text) != null &&
                      int.parse(quantityController.text) > 0
                  ? () {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 1;

                      final authService = context.read<AuthService>();
                      final companyId = authService.userModel?.companyId ?? '';

                      final newBoxType = BoxType(
                        productCode: selectedProductCode!,
                        type: selectedType!,
                        number: selectedNumber!,
                        volumeMl: volumeMl ?? 0,
                        quantity: quantity,
                        companyId: companyId,
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
    final productCodeController = TextEditingController();
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
            // מק"ט - ПЕРВОЕ ПОЛЕ
            TextField(
              controller: productCodeController,
              decoration: const InputDecoration(
                labelText: 'מק"ט',
                border: OutlineInputBorder(),
                hintText: 'לדוגמה: BB100, CUP250',
              ),
            ),
            const SizedBox(height: 16),
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
              if (productCodeController.text.isNotEmpty &&
                  typeController.text.isNotEmpty &&
                  numberController.text.isNotEmpty &&
                  volumeController.text.isNotEmpty) {
                try {
                  await _boxTypeService.addBoxType(
                    productCode: productCodeController.text.trim(),
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
