import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
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

/// Скачивание CSV с UTF-8 BOM + sep=, (для корректного отображения в Excel)
void downloadCsv(String csvContent, String filename) {
  // sep=, — директива Excel: использовать запятую как разделитель (для локалей с ;)
  final withSep = 'sep=,\n$csvContent';
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(withSep)]);
  final blobParts = ([bytes] as dynamic) as JSArray<BlobPart>;
  final blob = Blob(blobParts, BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = URL.createObjectURL(blob);
  HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  URL.revokeObjectURL(url);
}
