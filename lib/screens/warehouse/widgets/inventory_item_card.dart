import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// Виджет для отображения одного товара в списке инвентаря
///
/// Параметры:
/// - [item] - товар для отображения
/// - [showAllFields] - показывать все поля (true) или только основные (false)
/// - [formatDate] - функция для форматирования даты
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final bool showAllFields;
  final String Function(DateTime) formatDate;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.showAllFields = true,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // מק"ט - ПЕРВОЕ ПОЛЕ (показываем всегда) - ВСЕГДА НА ИВРИТЕ
            Text(
              'מק"ט: ${item.productCode}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 2),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final stockBadge = isLowStock
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.lowStock,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : isWarningStock
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.limitedStock,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.type} ${item.number}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stockBadge != null) ...[
                        const SizedBox(height: 6),
                        stockBadge,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.type} ${item.number}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (stockBadge != null) ...[
                      const SizedBox(width: 8),
                      stockBadge,
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // Показываем дополнительные поля только если showAllFields = true
            // МЕТКИ ПОЛЕЙ НА ИВРИТЕ (данные товара)
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

            // Количество - показываем всегда - НА ИВРИТЕ
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

            // ПРЕДУПРЕЖДЕНИЯ - локализованные (интерфейс)
            if (isWarningStock)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ ${l10n.remainingUnitsOnly(item.quantity)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            if (isLowStock)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🚨 ${l10n.urgentOrderStock}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Информация об обновлении - НА ИВРИТЕ (данные)
            if (showAllFields)
              Text(
                'עודכן: ${formatDate(item.lastUpdated)} ע"י ${item.updatedBy}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
