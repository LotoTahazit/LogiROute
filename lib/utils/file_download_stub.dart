/// Stub для платформ где нет поддержки скачивания файлов
void downloadFile(List<int> bytes, String filename) {
  throw UnsupportedError('File download is not supported on this platform');
}
