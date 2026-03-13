import 'dart:js_interop';
import 'package:web/web.dart';

/// Скачивание файла на Web платформе
void downloadFile(List<int> bytes, String filename) {
  final blobParts = ([bytes] as dynamic) as JSArray<BlobPart>;
  final blob = Blob(blobParts);
  final url = URL.createObjectURL(blob);
  HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  URL.revokeObjectURL(url);
}
