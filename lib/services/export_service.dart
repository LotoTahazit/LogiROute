import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart';
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
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

    // Создаем Blob из сырых байтов (не из строки — иначе ломается multi-byte UTF-8)
    final blobParts = ([bytes] as dynamic) as JSArray<BlobPart>;
    final blob =
        Blob(blobParts, BlobPropertyBag(type: 'text/csv;charset=utf-8'));
    final url = URL.createObjectURL(blob);
    try {
      final anchor = HTMLAnchorElement()
        ..href = url
        ..download =
            'inventory_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv';
      document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      URL.revokeObjectURL(url);
    }
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
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

    // Создаем Blob из сырых байтов (не из строки — иначе ломается multi-byte UTF-8)
    final blobParts = ([bytes] as dynamic) as JSArray<BlobPart>;
    final blob =
        Blob(blobParts, BlobPropertyBag(type: 'text/csv;charset=utf-8'));
    final url = URL.createObjectURL(blob);
    try {
      final anchor = HTMLAnchorElement()
        ..href = url
        ..download =
            'inventory_history_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv';
      document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      URL.revokeObjectURL(url);
    }
  }
}
