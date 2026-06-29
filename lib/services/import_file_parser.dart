import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';

/// Result of file parsing — raw headers + rows
class ParsedFileData {
  final List<String> headers;
  final List<List<String>> rows;
  final String sourceFormat; // xlsx, csv, xml
  final String fileName;

  ParsedFileData({
    required this.headers,
    required this.rows,
    required this.sourceFormat,
    required this.fileName,
  });
}

/// Результат выбора файла: [data] или код ошибки ([error]).
class ImportPickResult {
  final ParsedFileData? data;
  /// cancelled | read_failed | parse_failed
  final String? error;

  const ImportPickResult({this.data, this.error});
}

/// Universal file parser: Excel, CSV (auto-detect delimiter/encoding), Priority XML
class ImportFileParser {
  static const _allowedExtensions = ['xlsx', 'xls', 'csv', 'tsv', 'txt', 'xml'];
  static const _preferredSheets = ['Clients', 'Client', 'Template', 'Products'];

  /// Pick spreadsheet file (xlsx/csv only) for import wizard.
  static Future<ImportPickResult> pickSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const ImportPickResult(error: 'cancelled');
    }

    final file = result.files.first;
    final ext = file.extension?.toLowerCase() ?? '';
    var bytes = file.bytes;
    if (bytes == null && file.readStream != null) {
      try {
        final chunks = await file.readStream!.toList();
        bytes = Uint8List.fromList(chunks.expand((c) => c).toList());
      } catch (_) {
        return const ImportPickResult(error: 'read_failed');
      }
    }
    if (bytes == null) return const ImportPickResult(error: 'read_failed');

    final ParsedFileData? data;
    if (ext == 'csv') {
      data = _parseCsv(bytes, file.name, ext);
    } else {
      data = _parseExcel(bytes, file.name);
    }
    if (data == null) return const ImportPickResult(error: 'parse_failed');
    return ImportPickResult(data: data);
  }

  /// Pick file and parse to raw data
  static Future<ImportPickResult> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const ImportPickResult(error: 'cancelled');
    }

    final file = result.files.first;
    final ext = file.extension?.toLowerCase() ?? '';
    var bytes = file.bytes;
    if (bytes == null && file.readStream != null) {
      try {
        final chunks = await file.readStream!.toList();
        bytes = Uint8List.fromList(chunks.expand((c) => c).toList());
      } catch (_) {
        return const ImportPickResult(error: 'read_failed');
      }
    }
    if (bytes == null) return const ImportPickResult(error: 'read_failed');

    ParsedFileData? data;
    if (ext == 'xml') {
      data = _parseXml(bytes, file.name);
    } else if (ext == 'csv' || ext == 'tsv' || ext == 'txt') {
      data = _parseCsv(bytes, file.name, ext);
    } else {
      data = _parseExcel(bytes, file.name);
    }
    if (data == null) return const ImportPickResult(error: 'parse_failed');
    return ImportPickResult(data: data);
  }

  static Sheet? _pickSheet(Excel excel) {
    for (final name in _preferredSheets) {
      final sheet = excel.tables[name];
      if (sheet != null && _sheetHasData(sheet)) return sheet;
    }
    Sheet? best;
    var bestScore = 0;
    for (final sheet in excel.tables.values) {
      final score = _dataRowCount(sheet);
      if (score > bestScore) {
        bestScore = score;
        best = sheet;
      }
    }
    return bestScore > 0 ? best : null;
  }

  static bool _sheetHasData(Sheet sheet) => _dataRowCount(sheet) > 0;

  static int _dataRowCount(Sheet sheet) {
    if (sheet.rows.length < 2) return 0;
    var count = 0;
    for (int i = 1; i < sheet.rows.length; i++) {
      if (sheet.rows[i]
          .any((c) => (c?.value?.toString().trim() ?? '').isNotEmpty)) {
        count++;
      }
    }
    return count;
  }

  /// Parse Excel file — лист с данными (не пустой Sheet1).
  static ParsedFileData? _parseExcel(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = _pickSheet(excel);
    if (sheet == null || sheet.rows.isEmpty) return null;

    final headers =
        sheet.rows.first.map((c) => c?.value?.toString().trim() ?? '').toList();

    final rows = <List<String>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row =
          sheet.rows[i].map((c) => c?.value?.toString().trim() ?? '').toList();
      if (row.any((v) => v.isNotEmpty)) {
        while (row.length < headers.length) {
          row.add('');
        }
        rows.add(row);
      }
    }
    if (rows.isEmpty) return null;

    return ParsedFileData(
      headers: headers,
      rows: rows,
      sourceFormat: 'xlsx',
      fileName: fileName,
    );
  }

  /// Parse CSV/TSV with auto-detect delimiter and encoding
  static ParsedFileData? _parseCsv(
      Uint8List bytes, String fileName, String ext) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    String delimiter;
    if (ext == 'tsv') {
      delimiter = '\t';
    } else {
      delimiter = _detectDelimiter(content);
    }

    final csvRows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(content, fieldDelimiter: delimiter);

    if (csvRows.length < 2) return null;

    final headers = csvRows.first.map((c) => c.toString().trim()).toList();
    final rows = <List<String>>[];
    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i].map((c) => c.toString().trim()).toList();
      if (row.any((v) => v.isNotEmpty)) {
        while (row.length < headers.length) {
          row.add('');
        }
        rows.add(row);
      }
    }

    return ParsedFileData(
      headers: headers,
      rows: rows,
      sourceFormat: 'csv',
      fileName: fileName,
    );
  }

  static String _detectDelimiter(String content) {
    final lines = content.split('\n').take(5).toList();
    final delimiters = [',', ';', '\t', '|'];
    int maxCount = 0;
    String best = ',';

    for (final d in delimiters) {
      int count = 0;
      for (final line in lines) {
        count += d.allMatches(line).length;
      }
      if (count > maxCount) {
        maxCount = count;
        best = d;
      }
    }
    return best;
  }

  static ParsedFileData? _parseXml(Uint8List bytes, String fileName) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final doc = XmlDocument.parse(content);
    final root = doc.rootElement;
    final recordElements = root.childElements.toList();
    if (recordElements.isEmpty) return null;

    final fieldNames = <String>{};
    for (final record in recordElements) {
      for (final field in record.childElements) {
        fieldNames.add(field.name.local);
      }
    }

    final headers = fieldNames.toList();
    final rows = <List<String>>[];

    for (final record in recordElements) {
      final row = <String>[];
      for (final h in headers) {
        final el = record.getElement(h);
        row.add(el?.innerText.trim() ?? '');
      }
      if (row.any((v) => v.isNotEmpty)) {
        rows.add(row);
      }
    }

    if (rows.isEmpty) return null;

    return ParsedFileData(
      headers: headers,
      rows: rows,
      sourceFormat: 'xml',
      fileName: fileName,
    );
  }
}
