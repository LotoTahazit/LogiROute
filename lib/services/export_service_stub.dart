// Заглушка для Android - экспорт не поддерживается
class ExportService {
  static void exportInventoryToCSV(List<dynamic> items) {
    throw UnsupportedError('CSV export is only available on web platform');
  }

  static void exportInventoryHistoryToCSV(List<dynamic> history) {
    throw UnsupportedError('CSV export is only available on web platform');
  }
}
