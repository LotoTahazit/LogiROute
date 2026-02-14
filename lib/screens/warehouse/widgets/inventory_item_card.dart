import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';

/// Виджет для отображения одного товара в списке инвентаря
///
/// Параметры:
/// - [item] - товар для отображения
/// - [showAllFields] - показывать все поля (true) или только основные (false)
/// - [onEdit] - callback при нажатии на кнопку редактирования
/// - [onDelete] - callback при нажатии на кнопку удаления
/// - [formatDate] - функция для форматирования даты
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final bool showAllFields;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String Function(DateTime) formatDate;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.showAllFields = true,
    this.onEdit,
    this.onDelete,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.quantity < 10;
    final isWarningStock = item.quantity <= 30 && item.quantity >= 10;

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
            isLowStock || isWarningStock ? Icons.warning : Icons.inventory_2,
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

            // Показываем дополнительные поля только если showAllFields = true
            if (showAllFields) ...[
              // Объем в мл (если заполнен)
              if (item.volumeMl != null)
                Text(
                  'נפח: ${item.volumeMl} מל',
                  style: const TextStyle(fontSize: 14),
                ),
              // Диаметр (если заполнен)
              if (item.diameter != null && item.diameter!.isNotEmpty)
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
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],

            const SizedBox(height: 4),

            // Количество - показываем всегда
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

            // Информация об обновлении - показываем только если showAllFields = true
            if (showAllFields)
              Text(
                'עודכן: ${formatDate(item.lastUpdated)} ע"י ${item.updatedBy}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: (onEdit != null || onDelete != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'ערוך',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'מחק',
                    ),
                ],
              )
            : null,
      ),
    );
  }
}
