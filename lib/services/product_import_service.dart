import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product_type.dart';

/// Сервис импорта товаров из Excel/CSV
class ProductImportService {
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

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final extension = file.extension?.toLowerCase();

      if (extension == 'csv') {
        return await _importFromCSV(file, companyId, createdBy);
      } else if (extension == 'xlsx' || extension == 'xls') {
        return await _importFromExcel(file, companyId, createdBy);
      }

      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Импорт из CSV
  static Future<List<ProductType>> _importFromCSV(
    PlatformFile file,
    String companyId,
    String createdBy,
  ) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('No file data');

    final csvString = String.fromCharCodes(bytes);
    final rows = const CsvToListConverter().convert(csvString);

    return _parseRows(rows, companyId, createdBy);
  }

  /// Импорт из Excel
  static Future<List<ProductType>> _importFromExcel(
    PlatformFile file,
    String companyId,
    String createdBy,
  ) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('No file data');

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) throw Exception('No sheet found');

    final rows = sheet.rows.map((row) {
      return row.map((cell) => cell?.value?.toString() ?? '').toList();
    }).toList();

    return _parseRows(rows, companyId, createdBy);
  }

  /// Парсинг строк в ProductType
  /// Формат: Название, Мק"ט, Категория, Единиц в коробке, Коробок на паллете, Вес, Объём
  static List<ProductType> _parseRows(
    List<List<dynamic>> rows,
    String companyId,
    String createdBy,
  ) {
    final products = <ProductType>[];

    // Пропускаем заголовок (первая строка)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      if (row.length < 5) continue; // Минимум 5 колонок

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

  /// Создать шаблон Excel для скачивания
  static List<int> createTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Template'];

    // Заголовки
    sheet.appendRow([
      TextCellValue('שם המוצר'),
      TextCellValue('מק"ט'),
      TextCellValue('קטגוריה'),
      TextCellValue('יחידות בקופסה'),
      TextCellValue('קופסאות במשטח'),
      TextCellValue('משקל (ק"ג)'),
      TextCellValue('נפח (ליטר)'),
    ]);

    // Примеры
    sheet.appendRow([
      TextCellValue('גביע 100'),
      TextCellValue('1001'),
      TextCellValue('cups'),
      IntCellValue(20),
      IntCellValue(50),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    sheet.appendRow([
      TextCellValue('מכסה שטוח'),
      TextCellValue('1030'),
      TextCellValue('lids'),
      IntCellValue(60),
      IntCellValue(40),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    return excel.encode()!;
  }

  /// Экспорт существующих товаров в Excel
  static List<int> exportProducts(List<ProductType> products) {
    final excel = Excel.createExcel();
    final sheet = excel['Products'];

    // Заголовки
    sheet.appendRow([
      TextCellValue('שם המוצר'),
      TextCellValue('מק"ט'),
      TextCellValue('קטגוריה'),
      TextCellValue('יחידות בקופסה'),
      TextCellValue('קופסאות במשטח'),
      TextCellValue('משקל (ק"ג)'),
      TextCellValue('נפח (ליטר)'),
    ]);

    // Данные
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
