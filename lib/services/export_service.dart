import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../utils/file_download_stub.dart'
    if (dart.library.html) '../utils/file_download_web.dart';

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

    downloadCsv(csv,
        'inventory_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
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

    downloadCsv(csv,
        'inventory_history_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
  }
}
