import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart';

String _mimeFor(String filename) {
  final n = filename.toLowerCase();
  if (n.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (n.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (n.endsWith('.pdf')) return 'application/pdf';
  if (n.endsWith('.json')) return 'application/json';
  return 'application/octet-stream';
}

void _triggerDownload(Blob blob, String filename) {
  final url = URL.createObjectURL(blob);
  final anchor = document.createElement('a') as HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Немедленный revokeObjectURL — частая причина «кликнул, ничего не скачалось».
  Future<void>.delayed(const Duration(seconds: 2), () {
    URL.revokeObjectURL(url);
  });
}

/// Скачивание файла на Web платформе
void downloadFile(List<int> bytes, String filename) {
  final data = Uint8List.fromList(bytes);
  final blobParts = ([data] as dynamic) as JSArray<BlobPart>;
  _triggerDownload(
    Blob(blobParts, BlobPropertyBag(type: _mimeFor(filename))),
    filename,
  );
}

/// Скачивание данных как Excel-совместимый HTML-файл (.xls)
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
  _triggerDownload(
    Blob(blobParts,
        BlobPropertyBag(type: 'application/vnd.ms-excel;charset=utf-8')),
    filename.replaceAll('.csv', '.xls'),
  );
}
