/// Stub для платформ где нет поддержки скачивания файлов
void downloadFile(List<int> bytes, String filename) {
  throw UnsupportedError('File download is not supported on this platform');
}

/// Stub для скачивания CSV
void downloadCsv(String csvContent, String filename) {
  throw UnsupportedError('CSV download is not supported on this platform');
}
