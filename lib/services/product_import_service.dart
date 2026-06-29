import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product_type.dart';

/// Parsed product row with validation
class ParsedProductRow {
  final int rowIndex;
  final String productCode;
  final String productName;
  final String category;
  final int unitsPerBox;
  final int boxesPerPallet;
  final int? quantity;
  final String? barcode;
  final int? piecesPerBox;
  final double? volume;
  final double? weight;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  ParsedProductRow({
    required this.rowIndex,
    required this.productCode,
    required this.productName,
    this.category = 'general',
    this.unitsPerBox = 1,
    this.boxesPerPallet = 1,
    this.quantity,
    this.barcode,
    this.piecesPerBox,
    this.volume,
    this.weight,
    this.errors = const [],
  });
}

/// Сервис импорта товаров из Excel/CSV
class ProductImportService {
  static const _preferredSheets = ['Template', 'Products', 'Sheet1'];

  /// Выбрать и импортировать файл
  static Future<List<ProductType>?> pickAndImportFile(
    String companyId,
    String createdBy,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final extension = file.extension?.toLowerCase();

      if (extension == 'csv') {
        return await _importFromCSV(file, companyId, createdBy);
      }
      if (extension == 'xlsx' || extension == 'xls') {
        return await _importFromExcel(file, companyId, createdBy);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (file.readStream == null) return null;
    final chunks = await file.readStream!.toList();
    return Uint8List.fromList(chunks.expand((c) => c).toList());
  }

  static Sheet? _pickSheet(Excel excel) {
    for (final name in _preferredSheets) {
      final sheet = excel.tables[name];
      if (sheet != null && _sheetRowCount(sheet) > 0) return sheet;
    }
    Sheet? best;
    var bestScore = 0;
    for (final sheet in excel.tables.values) {
      final score = _sheetRowCount(sheet);
      if (score > bestScore) {
        bestScore = score;
        best = sheet;
      }
    }
    return bestScore > 0 ? best : null;
  }

  static int _sheetRowCount(Sheet sheet) {
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

  static Future<List<ProductType>> _importFromCSV(
    PlatformFile file,
    String companyId,
    String createdBy,
  ) async {
    final bytes = await _readBytes(file);
    if (bytes == null) throw Exception('read_failed');

    final csvString = String.fromCharCodes(bytes);
    final rows = const CsvToListConverter().convert(csvString);
    return _parseRows(rows, companyId, createdBy);
  }

  static Future<List<ProductType>> _importFromExcel(
    PlatformFile file,
    String companyId,
    String createdBy,
  ) async {
    final bytes = await _readBytes(file);
    if (bytes == null) throw Exception('read_failed');

    final excel = Excel.decodeBytes(bytes);
    final sheet = _pickSheet(excel);
    if (sheet == null) throw Exception('parse_failed');

    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();

    return _parseRows(rows, companyId, createdBy);
  }

  static List<ProductType> _parseRows(
    List<List<dynamic>> rows,
    String companyId,
    String createdBy,
  ) {
    final products = <ProductType>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;

      try {
        final name = row[0].toString().trim();
        final productCode = row[1].toString().trim();
        final category = row.length > 2 ? row[2].toString().trim() : 'general';
        final unitsPerBox = int.tryParse(row[3].toString()) ?? 1;
        final boxesPerPallet = int.tryParse(row[4].toString()) ?? 1;
        final weight =
            row.length > 5 ? double.tryParse(row[5].toString()) : null;
        final volume =
            row.length > 6 ? double.tryParse(row[6].toString()) : null;

        if (name.isEmpty || productCode.isEmpty) continue;

        products.add(ProductType(
          id: '',
          companyId: companyId,
          name: name,
          productCode: productCode,
          category: category.isEmpty ? 'general' : category,
          unitsPerBox: unitsPerBox,
          boxesPerPallet: boxesPerPallet,
          weight: weight,
          volume: volume,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        ));
      } catch (e) {
        print('Error parsing row $i: $e');
        continue;
      }
    }

    return products;
  }

  /// Parse rows using column mapping (wizard / manual mapping).
  static List<ParsedProductRow> parseWithMapping(
    List<List<String>> rows,
    Map<String, int> mapping,
  ) {
    final parsed = <ParsedProductRow>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final errors = <String>[];

      String getVal(String key) {
        final idx = mapping[key] ?? -1;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final productCode = getVal('productCode');
      final productName = getVal('productName');
      if (productCode.isEmpty) errors.add('מק"ט חסר');
      if (productName.isEmpty) errors.add('שם מוצר חסר');

      final category = getVal('category');
      parsed.add(ParsedProductRow(
        rowIndex: i + 2,
        productCode: productCode,
        productName: productName,
        category: category.isEmpty ? 'general' : category,
        unitsPerBox: int.tryParse(getVal('unitsPerBox')) ?? 1,
        boxesPerPallet: 1,
        quantity: int.tryParse(getVal('quantity')),
        barcode: getVal('barcode').isEmpty ? null : getVal('barcode'),
        piecesPerBox: int.tryParse(getVal('piecesPerBox')),
        volume: double.tryParse(getVal('volume')),
        weight: double.tryParse(getVal('weight')),
        errors: errors,
      ));
    }
    return parsed;
  }

  static ProductType toProductType(
    ParsedProductRow row,
    String companyId,
    String createdBy,
  ) {
    return ProductType(
      id: '',
      companyId: companyId,
      name: row.productName,
      productCode: row.productCode,
      category: row.category,
      unitsPerBox: row.unitsPerBox,
      boxesPerPallet: row.boxesPerPallet,
      weight: row.weight,
      volume: row.volume,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  static List<int> createTemplate() {
    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', 'Template');
    }
    final sheet = excel['Template'];

    sheet.appendRow([
      TextCellValue('שם המוצר'),
      TextCellValue('מק"ט'),
      TextCellValue('קטגוריה'),
      TextCellValue('יחידות בקופסה'),
      TextCellValue('קופסאות במשטח'),
      TextCellValue('משקל (ק"ג)'),
      TextCellValue('נפח (ליטר)'),
    ]);

    sheet.appendRow([
      TextCellValue('גביע 100'),
      TextCellValue('1001'),
      TextCellValue('cups'),
      const IntCellValue(20),
      const IntCellValue(50),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    sheet.appendRow([
      TextCellValue('מכסה שטוח'),
      TextCellValue('1030'),
      TextCellValue('lids'),
      const IntCellValue(60),
      const IntCellValue(40),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    return excel.encode()!;
  }

  static List<int> exportProducts(List<ProductType> products) {
    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', 'Products');
    }
    final sheet = excel['Products'];

    sheet.appendRow([
      TextCellValue('שם המוצר'),
      TextCellValue('מק"ט'),
      TextCellValue('קטגוריה'),
      TextCellValue('יחידות בקופסה'),
      TextCellValue('קופסאות במשטח'),
      TextCellValue('משקל (ק"ג)'),
      TextCellValue('נפח (ליטר)'),
    ]);

    for (final product in products) {
      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.productCode),
        TextCellValue(product.category),
        IntCellValue(product.unitsPerBox),
        IntCellValue(product.boxesPerPallet),
        TextCellValue(product.weight?.toString() ?? ''),
        TextCellValue(product.volume?.toString() ?? ''),
      ]);
    }

    return excel.encode()!;
  }
}
