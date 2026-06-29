import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'import_file_parser.dart';
import '../widgets/column_mapping_dialog.dart';
import '../l10n/app_localizations.dart';

/// Result of inventory import with counters and per-row errors
class InventoryImportResult {
  final int added;
  final int updated;
  final int skipped;
  final List<String> errors;
  InventoryImportResult({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
  });
  int get total => added + updated + skipped + errors.length;
}

/// Parsed row with validation errors
class ParsedInventoryRow {
  final int rowIndex;
  final String productCode;
  final String type;
  final String number;
  final int quantity;
  final int quantityPerPallet;
  final String? diameter;
  final String? volume;
  final int? piecesPerBox;
  final String? additionalInfo;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  ParsedInventoryRow({
    required this.rowIndex,
    required this.productCode,
    required this.type,
    required this.number,
    required this.quantity,
    required this.quantityPerPallet,
    this.diameter,
    this.volume,
    this.piecesPerBox,
    this.additionalInfo,
    this.errors = const [],
  });
}

/// Service for importing inventory items from Excel/CSV/XML
class InventoryImportService {
  /// Target fields for inventory with known aliases (Hebrew, English, Priority)
  static List<TargetField> getTargetFields(AppLocalizations l10n) => [
        TargetField(
          key: 'productCode',
          label: l10n.colProductCode,
          required: true,
          aliases: [
            'מק"ט',
            'מקט',
            'PARTNAME',
            'SKU',
            'productCode',
            'product_code',
            'קוד מוצר',
            'ItemCode'
          ],
        ),
        TargetField(
          key: 'type',
          label: l10n.colType,
          required: true,
          aliases: [
            'סוג',
            'type',
            'PARTDES',
            'category',
            'קטגוריה',
            'ItemType'
          ],
        ),
        TargetField(
          key: 'number',
          label: l10n.colNumber,
          required: true,
          aliases: ['מספר', 'number', 'num', 'PARTNUM', 'מספר מוצר'],
        ),
        TargetField(
          key: 'quantity',
          label: l10n.colQuantity,
          required: true,
          aliases: [
            'כמות',
            'quantity',
            'qty',
            'TQUANT',
            'QUANT',
            'stock',
            'מלאי'
          ],
        ),
        TargetField(
          key: 'quantityPerPallet',
          label: l10n.colQuantityPerPallet,
          required: true,
          aliases: [
            'כמות במשטח',
            'quantityPerPallet',
            'perPallet',
            'pallet',
            'משטח'
          ],
        ),
        TargetField(
          key: 'diameter',
          label: l10n.colDiameter,
          required: false,
          aliases: ['קוטר', 'diameter', 'DIAM'],
        ),
        TargetField(
          key: 'volume',
          label: l10n.colVolume,
          required: false,
          aliases: ['נפח', 'volume', 'vol', 'VOLUME'],
        ),
        TargetField(
          key: 'piecesPerBox',
          label: l10n.colPiecesPerBox,
          required: false,
          aliases: ['ארוז', 'piecesPerBox', 'perBox', 'box', 'יח בקרטון'],
        ),
        TargetField(
          key: 'additionalInfo',
          label: l10n.colAdditionalInfo,
          required: false,
          aliases: ['מידע נוסף', 'additionalInfo', 'notes', 'הערות', 'REMARK'],
        ),
      ];

  /// Pick file → show column mapping → parse rows
  static Future<({List<ParsedInventoryRow>? rows, DuplicateMode duplicateMode})>
      pickAndParse(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Pick and parse file
    final pick = await ImportFileParser.pickAndParse();
    final fileData = pick.data;
    if (fileData == null) {
      return (rows: null, duplicateMode: DuplicateMode.skip);
    }

    // 2. Show column mapping dialog
    if (!context.mounted) {
      return (rows: null, duplicateMode: DuplicateMode.skip);
    }
    final mapping = await showDialog<ColumnMapping>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ColumnMappingDialog(
        title: l10n.mapColumnsInventory,
        sourceHeaders: fileData.headers,
        targetFields: getTargetFields(l10n),
        sampleRows: fileData.rows.take(3).toList(),
      ),
    );
    if (mapping == null) return (rows: null, duplicateMode: DuplicateMode.skip);

    // 3. Parse rows using mapping
    final parsed = _parseWithMapping(fileData.rows, mapping.mapping);
    return (rows: parsed, duplicateMode: mapping.duplicateMode);
  }

  /// Parse rows using column mapping
  static List<ParsedInventoryRow> _parseWithMapping(
      List<List<String>> rows, Map<String, int> mapping) {
    final parsed = <ParsedInventoryRow>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final errors = <String>[];

      String getVal(String key) {
        final idx = mapping[key] ?? -1;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final productCode = getVal('productCode');
      final type = getVal('type');
      final number = getVal('number');
      final qtyStr = getVal('quantity');
      final qppStr = getVal('quantityPerPallet');

      if (productCode.isEmpty) errors.add('מק"ט חסר');
      if (type.isEmpty) errors.add('סוג חסר');
      if (number.isEmpty) errors.add('מספר חסר');

      final qty = int.tryParse(qtyStr.replaceAll(RegExp(r'[,\s]'), ''));
      if (qty == null || qty < 0) errors.add('כמות לא תקינה');

      final qpp = int.tryParse(qppStr.replaceAll(RegExp(r'[,\s]'), ''));
      if (qpp == null || qpp <= 0) errors.add('כמות במשטח לא תקינה');

      final diameterVal = getVal('diameter');
      final volumeVal = getVal('volume');
      final piecesStr = getVal('piecesPerBox');
      final infoVal = getVal('additionalInfo');

      parsed.add(ParsedInventoryRow(
        rowIndex: i + 2, // +2 for 1-based + header
        productCode: productCode,
        type: type,
        number: number,
        quantity: qty ?? 0,
        quantityPerPallet: qpp ?? 1,
        diameter: diameterVal.isEmpty ? null : diameterVal,
        volume: volumeVal.isEmpty ? null : volumeVal,
        piecesPerBox: int.tryParse(piecesStr.replaceAll(RegExp(r'[,\s]'), '')),
        additionalInfo: infoVal.isEmpty ? null : infoVal,
        errors: errors,
      ));
    }
    return parsed;
  }

  /// Create Excel template for inventory import
  static List<int> createTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];

    sheet.appendRow([
      TextCellValue('מק"ט *'),
      TextCellValue('סוג *'),
      TextCellValue('מספר *'),
      TextCellValue('כמות *'),
      TextCellValue('כמות במשטח *'),
      TextCellValue('קוטר'),
      TextCellValue('נפח'),
      TextCellValue('ארוז (יח\' בקרטון)'),
      TextCellValue('מידע נוסף'),
    ]);

    sheet.appendRow([
      TextCellValue('CUP100'),
      TextCellValue('גביע'),
      TextCellValue('100'),
      const IntCellValue(5000),
      const IntCellValue(2400),
      TextCellValue('73'),
      TextCellValue('100'),
      const IntCellValue(50),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('LID100'),
      TextCellValue('מכסה'),
      TextCellValue('100'),
      const IntCellValue(10000),
      const IntCellValue(4800),
      TextCellValue(''),
      TextCellValue(''),
      const IntCellValue(100),
      TextCellValue('שטוח'),
    ]);

    return excel.encode()!;
  }
}
