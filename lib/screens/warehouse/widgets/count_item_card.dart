import 'package:flutter/material.dart';
import '../../../models/count_item.dart';

/// Карточка товара в инвентаризации (Android-ориентированная)
class CountItemCard extends StatefulWidget {
  final CountItem item;
  final int? initialQuantity;
  final String? initialNotes;
  final Function(int actualQuantity, String? notes) onUpdate;

  const CountItemCard({
    super.key,
    required this.item,
    this.initialQuantity,
    this.initialNotes,
    required this.onUpdate,
  });

  @override
  State<CountItemCard> createState() => _CountItemCardState();
}

class _CountItemCardState extends State<CountItemCard> {
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Используем initialQuantity если есть, иначе actualQuantity из item
    final initialQty = widget.initialQuantity ?? widget.item.actualQuantity;
    _quantityController = TextEditingController(
      text: initialQty?.toString() ?? '',
    );
    // Используем initialNotes если есть, иначе notes из item
    final initialNote = widget.initialNotes ?? widget.item.notes;
    _notesController = TextEditingController(
      text: initialNote ?? '',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveCount() {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא להזין מספר תקין'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Вызываем callback для сохранения локально
    widget.onUpdate(
        quantity,
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim());
  }

  Color _getCardColor() {
    if (!widget.item.isChecked) {
      return Colors.white;
    }
    if (widget.item.isShortage) {
      return Colors.red.shade50;
    }
    if (widget.item.isSurplus) {
      return Colors.green.shade50;
    }
    return Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _getCardColor(),
      elevation: widget.item.hasDifference ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок товара
            Row(
              children: [
                // מק"ט
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.productCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Название
                Expanded(
                  child: Text(
                    '${widget.item.type} ${widget.item.number}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Статус
                if (widget.item.isChecked)
                  Icon(
                    Icons.check_circle,
                    color: widget.item.hasDifference
                        ? Colors.orange
                        : Colors.green,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ УБРАНО: Ожидаемое количество (кладовщик не должен его видеть)

            // Поле ввода фактического количества (БЕЗ автосохранения на сервер)
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'נספר',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixText: 'יח\'',
                helperText: 'הכמות תישמר בסיום הספירה',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              onChanged: (value) {
                // Сохраняем локально при изменении
                _saveCount();
              },
            ),

            // ✅ УБРАНО: Показ разницы (кладовщик не должен видеть ожидаемое количество)

            // ✅ УБРАНО: Подозрительные заказы (только для админа/диспетчера)

            // Поле для заметок
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות (אופציונלי)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
