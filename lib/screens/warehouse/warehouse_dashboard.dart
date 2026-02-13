import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
import '../../services/box_type_service.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class WarehouseDashboard extends StatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  final InventoryService _inventoryService = InventoryService();
  final BoxTypeService _boxTypeService = BoxTypeService();
  final AuthService _authService = AuthService();

  String _userName = '';
  bool _showLowStockOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _authService.userModel;
    if (user != null && mounted) {
      setState(() {
        _userName = user.name;
      });
    }
  }

  void _showAddInventoryDialog() async {
    // Загружаем доступные типы коробок
    final boxTypes = await _boxTypeService.getAllBoxTypes();

    if (!mounted) return;

    String? selectedType;
    String? selectedNumber;
    int? volumeMl;
    final quantityController = TextEditingController();
    final quantityPerPalletController = TextEditingController(text: '1');
    final diameterController = TextEditingController();
    final piecesPerBoxController = TextEditingController();
    final additionalInfoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('הוסף מלאי'),
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
                  items: (boxTypes
                          .map((bt) => bt['type'] as String)
                          .toSet()
                          .toList()
                        ..sort())
                      .map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                      selectedNumber = null;
                      volumeMl = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Выбор номера
                if (selectedType != null)
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedType),
                    initialValue: selectedNumber,
                    decoration: const InputDecoration(
                      labelText: 'מספר',
                      border: OutlineInputBorder(),
                    ),
                    items: (boxTypes
                            .where((bt) => bt['type'] == selectedType)
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
                      setDialogState(() {
                        selectedNumber = value;
                        final item = boxTypes.firstWhere(
                          (bt) =>
                              bt['type'] == selectedType &&
                              bt['number'] == value,
                        );
                        volumeMl = item['volumeMl'] as int?;

                        // Заполняем поля из справочника
                        if (item['quantityPerPallet'] != null) {
                          quantityPerPalletController.text =
                              item['quantityPerPallet'].toString();
                        }
                        if (item['diameter'] != null) {
                          diameterController.text = item['diameter'] as String;
                        }
                        if (item['piecesPerBox'] != null) {
                          piecesPerBoxController.text =
                              item['piecesPerBox'].toString();
                        }
                        if (item['additionalInfo'] != null) {
                          additionalInfoController.text =
                              item['additionalInfo'] as String;
                        }
                      });
                    },
                  ),
                const SizedBox(height: 16),

                // Количество (штук)
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'כמות (יחידות)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Количество на миштахе (ОБЯЗАТЕЛЬНОЕ)
                TextField(
                  controller: quantityPerPalletController,
                  decoration: const InputDecoration(
                    labelText: 'כמות במשטח *',
                    hintText: 'חובה',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Диаметр (необязательное)
                TextField(
                  controller: diameterController,
                  decoration: const InputDecoration(
                    labelText: 'קוטר (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Количество в коробке (необязательное)
                TextField(
                  controller: piecesPerBoxController,
                  decoration: const InputDecoration(
                    labelText: 'ארוז - כמות בקרטון (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Дополнительные данные (необязательное)
                TextField(
                  controller: additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'מידע נוסף (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Кнопка добавления нового типа
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddNewBoxTypeDialog();
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
              onPressed: selectedType != null &&
                      selectedNumber != null &&
                      quantityController.text.isNotEmpty &&
                      quantityPerPalletController.text.isNotEmpty &&
                      int.tryParse(quantityController.text) != null &&
                      int.parse(quantityController.text) > 0 &&
                      int.tryParse(quantityPerPalletController.text) != null &&
                      int.parse(quantityPerPalletController.text) > 0
                  ? () async {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      final quantityPerPallet =
                          int.tryParse(quantityPerPalletController.text) ?? 1;
                      final piecesPerBox =
                          int.tryParse(piecesPerBoxController.text);

                      try {
                        await _inventoryService.addInventory(
                          type: selectedType!,
                          number: selectedNumber!,
                          volumeMl: volumeMl,
                          quantity: quantity,
                          quantityPerPallet: quantityPerPallet,
                          userName: _userName,
                          diameter: diameterController.text.trim().isEmpty
                              ? null
                              : diameterController.text.trim(),
                          piecesPerBox: piecesPerBox,
                          additionalInfo:
                              additionalInfoController.text.trim().isEmpty
                                  ? null
                                  : additionalInfoController.text.trim(),
                        );

                        // Небольшая задержка для синхронизации с Firestore
                        await Future.delayed(const Duration(milliseconds: 300));

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('מלאי עודכן בהצלחה!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('שגיאה: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewBoxTypeDialog() {
    final typeController = TextEditingController();
    final numberController = TextEditingController();
    final volumeController = TextEditingController();
    final quantityController = TextEditingController();
    final quantityPerPalletController = TextEditingController(text: '1');
    final diameterController = TextEditingController();
    final piecesPerBoxController = TextEditingController();
    final additionalInfoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('הוסף סוג חדש למאגר'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Тип
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'סוג (בביע, מכסה, כוס) *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // Номер
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'מספר (100, 200, וכו\') *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // Объем в мл (необязательное)
                TextField(
                  controller: volumeController,
                  decoration: const InputDecoration(
                    labelText: 'נפח במ"ל (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // Количество (штук) - обязательное
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'כמות (יחידות) *',
                    hintText: 'חובה',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // Количество на миштахе - обязательное
                TextField(
                  controller: quantityPerPalletController,
                  decoration: const InputDecoration(
                    labelText: 'כמות במשטח *',
                    hintText: 'חובה',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // Диаметр (необязательное)
                TextField(
                  controller: diameterController,
                  decoration: const InputDecoration(
                    labelText: 'קוטר (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Количество в коробке (необязательное)
                TextField(
                  controller: piecesPerBoxController,
                  decoration: const InputDecoration(
                    labelText: 'ארוז - כמות בקרטון (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Дополнительные данные (необязательное)
                TextField(
                  controller: additionalInfoController,
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
              onPressed: typeController.text.trim().isNotEmpty &&
                      numberController.text.trim().isNotEmpty &&
                      quantityController.text.trim().isNotEmpty &&
                      quantityPerPalletController.text.trim().isNotEmpty &&
                      int.tryParse(quantityController.text) != null &&
                      int.parse(quantityController.text) > 0 &&
                      int.tryParse(quantityPerPalletController.text) != null &&
                      int.parse(quantityPerPalletController.text) > 0
                  ? () async {
                      final volumeMl = volumeController.text.trim().isEmpty
                          ? null
                          : int.tryParse(volumeController.text);
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      final quantityPerPallet =
                          int.tryParse(quantityPerPalletController.text) ?? 1;
                      final piecesPerBox =
                          int.tryParse(piecesPerBoxController.text);

                      try {
                        // Добавляем в box_types только если указан volumeMl
                        if (volumeMl != null) {
                          await _boxTypeService.addBoxType(
                            type: typeController.text.trim(),
                            number: numberController.text.trim(),
                            volumeMl: volumeMl,
                          );
                        }

                        // Добавляем в inventory со всеми полями
                        await _inventoryService.addInventory(
                          type: typeController.text.trim(),
                          number: numberController.text.trim(),
                          volumeMl: volumeMl,
                          quantity: quantity,
                          quantityPerPallet: quantityPerPallet,
                          userName: _userName,
                          diameter: diameterController.text.trim().isEmpty
                              ? null
                              : diameterController.text.trim(),
                          piecesPerBox: piecesPerBox,
                          additionalInfo:
                              additionalInfoController.text.trim().isEmpty
                                  ? null
                                  : additionalInfoController.text.trim(),
                        );

                        // Небольшая задержка для синхронизации с Firestore
                        await Future.delayed(const Duration(milliseconds: 300));

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('סוג חדש נוסף למלאי בהצלחה!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('שגיאה: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditInventoryDialog(InventoryItem item) {
    final typeController = TextEditingController(text: item.type);
    final numberController = TextEditingController(text: item.number);
    final volumeMlController = TextEditingController(
        text: item.volumeMl != null ? item.volumeMl.toString() : '');
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final quantityPerPalletController =
        TextEditingController(text: item.quantityPerPallet.toString());
    final diameterController = TextEditingController(text: item.diameter ?? '');
    final volumeController = TextEditingController(text: item.volume ?? '');
    final piecesPerBoxController = TextEditingController(
        text: item.piecesPerBox != null ? item.piecesPerBox.toString() : '');
    final additionalInfoController =
        TextEditingController(text: item.additionalInfo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ערוך פריט'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'סוג *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Номер
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'מספר *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Объем в мл (необязательное)
              TextField(
                controller: volumeMlController,
                decoration: const InputDecoration(
                  labelText: 'נפח במ"ל (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Количество
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'כמות (יחידות) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Количество на миштахе
              TextField(
                controller: quantityPerPalletController,
                decoration: const InputDecoration(
                  labelText: 'כמות במשטח *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Диаметр (необязательное)
              TextField(
                controller: diameterController,
                decoration: const InputDecoration(
                  labelText: 'קוטר (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Объем текстовый (необязательное)
              TextField(
                controller: volumeController,
                decoration: const InputDecoration(
                  labelText: 'נפח (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Количество в коробке (необязательное)
              TextField(
                controller: piecesPerBoxController,
                decoration: const InputDecoration(
                  labelText: 'ארוז - כמות בקרטון (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Дополнительная информация (необязательное)
              TextField(
                controller: additionalInfoController,
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
            onPressed: () async {
              if (typeController.text.trim().isEmpty ||
                  numberController.text.trim().isEmpty ||
                  quantityController.text.trim().isEmpty ||
                  quantityPerPalletController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('נא למלא את כל השדות החובה'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final newType = typeController.text.trim();
              final newNumber = numberController.text.trim();
              final newQuantity = int.tryParse(quantityController.text) ?? 0;
              final newQuantityPerPallet =
                  int.tryParse(quantityPerPalletController.text) ?? 1;
              final newVolumeMl = volumeMlController.text.trim().isEmpty
                  ? null
                  : int.tryParse(volumeMlController.text);
              final newPiecesPerBox = piecesPerBoxController.text.trim().isEmpty
                  ? null
                  : int.tryParse(piecesPerBoxController.text);
              final newDiameter = diameterController.text.trim().isEmpty
                  ? null
                  : diameterController.text.trim();
              final newVolume = volumeController.text.trim().isEmpty
                  ? null
                  : volumeController.text.trim();
              final newAdditionalInfo =
                  additionalInfoController.text.trim().isEmpty
                      ? null
                      : additionalInfoController.text.trim();

              try {
                // Вычисляем новый ID
                final newId = InventoryItem.generateId(newType, newNumber);

                // Обновляем товар (с новым ID если изменился)
                await _inventoryService.updateInventory(
                  type: newType,
                  number: newNumber,
                  volumeMl: newVolumeMl,
                  quantity: newQuantity,
                  quantityPerPallet: newQuantityPerPallet,
                  userName: _userName,
                  diameter: newDiameter,
                  volume: newVolume,
                  piecesPerBox: newPiecesPerBox,
                  additionalInfo: newAdditionalInfo,
                );

                // Если ID изменился (изменили тип или номер), удаляем старый
                if (newId != item.id) {
                  await _inventoryService.deleteInventoryItem(item.id);
                }

                // Небольшая задержка для синхронизации с Firestore
                await Future.delayed(const Duration(milliseconds: 300));

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('פריט עודכן בהצלחה!'),
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
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק פריט'),
        content: Text('האם למחוק ${item.toDisplayString()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _inventoryService.deleteInventoryItem(item.id);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('פריט נמחק בהצלחה!'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  void _showInventoryHistory() {
    // История изменений инвентаря
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('היסטוריה - בפיתוח'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportReport() {
    // Экспорт отчета инвентаря
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ייצוא דוח - בפיתוח'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showBoxTypesManager() async {
    final boxTypes = await _boxTypeService.getAllBoxTypes();

    if (!mounted) return;

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ניהול מאגר סוגים'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: boxTypes.isEmpty
              ? const Center(
                  child: Text('אין סוגים במאגר'),
                )
              : ListView.builder(
                  itemCount: boxTypes.length,
                  itemBuilder: (context, index) {
                    final boxType = boxTypes[index];
                    final type = boxType['type'] as String;
                    final number = boxType['number'] as String;
                    final volumeMl = boxType['volumeMl'] as int;
                    final id = boxType['id'] as String;

                    return Card(
                      child: ListTile(
                        title: Text('$type $number'),
                        subtitle: Text('$volumeMl מל'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditBoxTypeDialog(
                                    id, type, number, volumeMl);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteBoxTypeConfirmation(
                                    id, type, number);
                              },
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
      ),
    );
  }

  void _showEditBoxTypeDialog(
      String id, String oldType, String oldNumber, int oldVolumeMl) {
    final typeController = TextEditingController(text: oldType);
    final numberController = TextEditingController(text: oldNumber);
    final volumeController =
        TextEditingController(text: oldVolumeMl.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ערוך סוג'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.trim().isEmpty ||
                  numberController.text.trim().isEmpty ||
                  volumeController.text.trim().isEmpty) {
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
                await _boxTypeService.deleteBoxType(id);

                // Добавляем новый
                await _boxTypeService.addBoxType(
                  type: typeController.text.trim(),
                  number: numberController.text.trim(),
                  volumeMl: int.parse(volumeController.text),
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
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBoxTypeConfirmation(String id, String type, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק סוג'),
        content: Text('האם למחוק $type $number מהמאגר?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _boxTypeService.deleteBoxType(id);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('סוג נמחק בהצלחה!'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('מחסן - ניהול מלאי'),
        actions: [
          // Управление справочником
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'ניהול מאגר סוגים',
            onPressed: _showBoxTypesManager,
          ),
          // Фильтр низких остатков
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showLowStockOnly ? Colors.orange : null,
            ),
            tooltip: 'הצג רק מלאי נמוך',
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
              });
            },
          ),
          // История
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'היסטוריית שינויים',
            onPressed: _showInventoryHistory,
          ),
          // Экспорт
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'ייצוא דוח',
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Индикатор режима просмотра для админа
          if (authService.userModel?.isAdmin == true &&
              authService.viewAsRole == 'warehouse_keeper')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade100,
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '👁️ ${l10n.viewModeWarehouse}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      authService.setViewAsRole(null);
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(l10n.returnToAdmin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'חיפוש לפי סוג או מספר...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Основной контент
          Expanded(
            child: StreamBuilder<List<InventoryItem>>(
              stream: _inventoryService.getInventoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('שגיאה: ${snapshot.error}'),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'אין פריטים במלאי',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'לחץ על + למטה להוספת פריט',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Фильтруем по поиску и низким остаткам
                var filteredItems = items;

                if (_searchQuery.isNotEmpty) {
                  filteredItems = filteredItems.where((item) {
                    return item.type.toLowerCase().contains(_searchQuery) ||
                        item.number.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_showLowStockOnly) {
                  filteredItems = filteredItems
                      .where((item) => item.quantity < 10)
                      .toList();
                }

                // Сортируем по алфавиту: сначала по типу, потом по номеру
                filteredItems.sort((a, b) {
                  final typeCompare = a.type.compareTo(b.type);
                  if (typeCompare != 0) return typeCompare;
                  // Пробуем сортировать номера как числа
                  final numA = int.tryParse(a.number);
                  final numB = int.tryParse(b.number);
                  if (numA != null && numB != null) {
                    return numA.compareTo(numB);
                  }
                  return a.number.compareTo(b.number);
                });

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'לא נמצאו פריטים',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Показываем список без группировки - каждый товар отдельно
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isLowStock = item.quantity < 10;
                    final isWarningStock =
                        item.quantity <= 30 && item.quantity >= 10;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      color: isLowStock
                          ? Colors.red.shade50
                          : isWarningStock
                              ? Colors.orange.shade50
                              : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isLowStock
                              ? Colors.red
                              : isWarningStock
                                  ? Colors.orange
                                  : Colors.green,
                          child: Icon(
                            isLowStock || isWarningStock
                                ? Icons.warning
                                : Icons.inventory_2,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.type} ${item.number}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'מלאי נמוך!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isWarningStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'מלאי מועט',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Объем в мл (если заполнен)
                            if (item.volumeMl != null)
                              Text(
                                'נפח: ${item.volumeMl} מל',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Диаметр (если заполнен)
                            if (item.diameter != null &&
                                item.diameter!.isNotEmpty)
                              Text(
                                'קוטר: ${item.diameter}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Объем текстовый (если заполнен)
                            if (item.volume != null && item.volume!.isNotEmpty)
                              Text(
                                'נפח: ${item.volume}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Количество в коробке (если заполнен)
                            if (item.piecesPerBox != null)
                              Text(
                                'ארוז: ${item.piecesPerBox} יח\' בקרטון',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Количество на миштахе
                            Text(
                              'כמות במשטח: ${item.quantityPerPallet} יח\'',
                              style: const TextStyle(fontSize: 14),
                            ),
                            // Дополнительная информация (если заполнена)
                            if (item.additionalInfo != null &&
                                item.additionalInfo!.isNotEmpty)
                              Text(
                                'מידע נוסף: ${item.additionalInfo}',
                                style: const TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'כמות: ${item.quantity} יח\'',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLowStock
                                    ? Colors.red
                                    : isWarningStock
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                              ),
                            ),
                            if (isWarningStock)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '⚠️ נותרו ${item.quantity} יחידות בלבד',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            if (isLowStock)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '🚨 דחוף! יש להזמין מלאי',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'עודכן: ${_formatDate(item.lastUpdated)} ע"י ${item.updatedBy}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditInventoryDialog(item),
                              tooltip: 'ערוך',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(item),
                              tooltip: 'מחק',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInventoryDialog,
        backgroundColor: Colors.green,
        tooltip: 'הוסף מלאי',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
