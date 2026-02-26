import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';

class ExportService {
  /// Экспорт инвентаря в CSV
  static void exportInventoryToCSV(List<InventoryItem> items) {
    // Заголовки
    final List<List<dynamic>> rows = [
      [
        'מק"ט',
        'סוג',
        'מספר',
        'כמות',
        'כמות במשטחים',
        'קוטר',
        'נפח',
        'ארוז',
        'מידע נוסף',
      ],
    ];

    // Данные
    for (final item in items) {
      rows.add([
        item.productCode,
        item.type,
        item.number,
        item.quantity,
        item.numberOfPallets,
        item.diameter ?? '',
        item.volume ?? '',
        item.piecesPerBox ?? '',
        item.additionalInfo ?? '',
      ]);
    }

    // Конвертируем в CSV
    final String csv = const ListToCsvConverter().convert(rows);

    // Добавляем BOM для правильного отображения в Excel
    final bom = [0xEF, 0xBB, 0xBF];
    final bytes = [...bom, ...utf8.encode(csv)];

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download =
          'inventory_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Экспорт истории изменений в CSV
  static void exportInventoryHistoryToCSV(
    List<Map<String, dynamic>> changes,
  ) {
    // Заголовки
    final List<List<dynamic>> rows = [
      [
        'תאריך',
        'שעה',
        'מק"ט',
        'סוג',
        'מספר',
        'שינוי',
        'כמות אחרי',
        'משתמש',
      ],
    ];

    // Данные
    for (final change in changes) {
      final timestamp = change['timestamp'] as DateTime?;
      rows.add([
        timestamp != null ? DateFormat('dd/MM/yyyy').format(timestamp) : '',
        timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '',
        change['productCode'] ?? '',
        change['type'] ?? '',
        change['number'] ?? '',
        change['quantityChange'] ?? 0,
        change['quantityAfter'] ?? 0,
        change['userName'] ?? '',
      ]);
    }

    // Конвертируем в CSV
    final String csv = const ListToCsvConverter().convert(rows);

    // Добавляем BOM для правильного отображения в Excel
    final bom = [0xEF, 0xBB, 0xBF];
    final bytes = [...bom, ...utf8.encode(csv)];

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download =
          'inventory_history_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
