import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../utils/file_download_stub.dart'
    if (dart.library.html) '../utils/file_download_web.dart';

class ExportService {
  /// Экспорт инвентаря в CSV (tab-separated для Excel)
  static void exportInventoryToCSV(List<InventoryItem> items) {
    const t = '\t';
    final buffer = StringBuffer();
    buffer.writeln(
        'מק"ט${t}סוג${t}מספר${t}כמות${t}כמות במשטחים${t}קוטר${t}נפח${t}ארוז${t}מידע נוסף');

    for (final item in items) {
      buffer.writeln([
        item.productCode,
        item.type,
        item.number,
        item.quantity,
        item.numberOfPallets,
        item.diameter ?? '',
        item.volume ?? '',
        item.piecesPerBox ?? '',
        item.additionalInfo ?? '',
      ].join(t));
    }

    downloadCsv(buffer.toString(),
        'inventory_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
  }

  /// Экспорт истории изменений в CSV (tab-separated для Excel)
  static void exportInventoryHistoryToCSV(
    List<Map<String, dynamic>> changes,
  ) {
    const t = '\t';
    final buffer = StringBuffer();
    buffer.writeln(
        'תאריך${t}שעה${t}מק"ט${t}סוג${t}מספר${t}שינוי${t}כמות אחרי${t}משתמש');

    for (final change in changes) {
      final timestamp = change['timestamp'] as DateTime?;
      buffer.writeln([
        timestamp != null ? DateFormat('dd/MM/yyyy').format(timestamp) : '',
        timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '',
        change['productCode'] ?? '',
        change['type'] ?? '',
        change['number'] ?? '',
        change['quantityChange'] ?? 0,
        change['quantityAfter'] ?? 0,
        change['userName'] ?? '',
      ].join(t));
    }

    downloadCsv(buffer.toString(),
        'inventory_history_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
  }
}
