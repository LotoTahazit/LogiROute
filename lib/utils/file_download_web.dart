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

/// Скачивание данных как Excel-совместимый HTML-файл (.xls)
/// Гарантирует корректное отображение UTF-8 (иврит) в Excel любой локали.
/// Контент должен быть tab-separated (TSV).
void downloadCsv(String tsvContent, String filename) {
  final lines =
      tsvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final sb = StringBuffer();
  sb.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" '
      'xmlns:x="urn:schemas-microsoft-com:office:excel">');
  sb.writeln('<head><meta charset="utf-8">'
      '<style>td,th{mso-number-format:"\\@";white-space:nowrap;}'
      'th{font-weight:bold;background:#e0e0e0;}</style></head>');
  sb.writeln('<body><table border="1" dir="rtl">');
  for (int i = 0; i < lines.length; i++) {
    sb.write('<tr>');
    final cells = lines[i].split('\t');
    for (final cell in cells) {
      final tag = i == 0 ? 'th' : 'td';
      final escaped = cell
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      // Render URLs as clickable hyperlinks in Excel
      if (i > 0 && cell.startsWith('http')) {
        sb.write('<$tag><a href="$cell">פתח מסמך</a></$tag>');
      } else {
        sb.write('<$tag>$escaped</$tag>');
      }
    }
    sb.writeln('</tr>');
  }
  sb.writeln('</table></body></html>');

  final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
  final blobParts = ([bytes] as dynamic) as JSArray<BlobPart>;
  final blob = Blob(blobParts,
      BlobPropertyBag(type: 'application/vnd.ms-excel;charset=utf-8'));
  final xlsName = filename.replaceAll('.csv', '.xls');
  final url = URL.createObjectURL(blob);
  HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', xlsName)
    ..click();
  URL.revokeObjectURL(url);
}
