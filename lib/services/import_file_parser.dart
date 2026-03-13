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

/// Universal file parser: Excel, CSV (auto-detect delimiter/encoding), Priority XML
class ImportFileParser {
  static const _allowedExtensions = ['xlsx', 'xls', 'csv', 'tsv', 'txt', 'xml'];

  /// Pick file and parse to raw data
  static Future<ParsedFileData?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final ext = file.extension?.toLowerCase() ?? '';
    final bytes = file.bytes;
    if (bytes == null) return null;

    if (ext == 'xml') {
      return _parseXml(bytes, file.name);
    } else if (ext == 'csv' || ext == 'tsv' || ext == 'txt') {
      return _parseCsv(bytes, file.name, ext);
    } else {
      return _parseExcel(bytes, file.name);
    }
  }

  /// Parse Excel file
  static ParsedFileData? _parseExcel(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.length < 2) return null;

    final headers =
        sheet.rows.first.map((c) => c?.value?.toString().trim() ?? '').toList();

    final rows = <List<String>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row =
          sheet.rows[i].map((c) => c?.value?.toString().trim() ?? '').toList();
      // Skip completely empty rows
      if (row.any((v) => v.isNotEmpty)) {
        // Pad to header length
        while (row.length < headers.length) {
          row.add('');
        }
        rows.add(row);
      }
    }

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
    // Try UTF-8 first, then Windows-1255 (Hebrew)
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      // Fallback: Latin1 (covers Windows-1255 byte range)
      content = latin1.decode(bytes);
    }

    // Auto-detect delimiter
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

  /// Detect CSV delimiter by counting occurrences in first few lines
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

  /// Parse Priority XML format (CUSTDES, PARTDES, etc.)
  static ParsedFileData? _parseXml(Uint8List bytes, String fileName) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final doc = XmlDocument.parse(content);
    final root = doc.rootElement;

    // Priority exports: root contains repeated elements (e.g. <CUSTDES>, <PARTDES>)
    // Each child element's sub-elements are fields
    final recordElements = root.childElements.toList();
    if (recordElements.isEmpty) return null;

    // Collect all unique field names from all records
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
