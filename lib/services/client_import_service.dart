import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'import_file_parser.dart';
import '../widgets/column_mapping_dialog.dart';
import '../l10n/app_localizations.dart';

/// Result of client import
class ClientImportResult {
  final int added;
  final int skipped;
  final List<String> errors;
  ClientImportResult(
      {this.added = 0, this.skipped = 0, this.errors = const []});
  int get total => added + skipped + errors.length;
}

/// Parsed client row with validation
class ParsedClientRow {
  final int rowIndex;
  final String clientNumber;
  final String name;
  final String address;
  final String? phone;
  final String? contactPerson;
  final String? vatId;
  final List<String> zones;
  final double? latitude;
  final double? longitude;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;

  ParsedClientRow({
    required this.rowIndex,
    required this.clientNumber,
    required this.name,
    required this.address,
    this.phone,
    this.contactPerson,
    this.vatId,
    this.zones = const [],
    this.latitude,
    this.longitude,
    this.errors = const [],
  });
}

/// Service for importing clients from Excel/CSV/XML
class ClientImportService {
  /// Target fields for clients with known aliases (Hebrew, English, Priority)
  static List<TargetField> getTargetFields(AppLocalizations l10n) => [
        TargetField(
          key: 'clientNumber',
          label: l10n.colClientNumber,
          required: true,
          aliases: [
            'מספר לקוח',
            'CUSTNAME',
            'clientNumber',
            'client_number',
            'מס לקוח',
            'CustomerCode',
            'קוד לקוח'
          ],
        ),
        TargetField(
          key: 'name',
          label: l10n.colName,
          required: true,
          aliases: [
            'שם',
            'name',
            'CUSTDES',
            'customerName',
            'שם לקוח',
            'CustomerName'
          ],
        ),
        TargetField(
          key: 'address',
          label: l10n.colAddress,
          required: true,
          aliases: [
            'כתובת',
            'address',
            'ADDRESS',
            'ADDR',
            'כתובת לקוח',
            'CustomerAddress'
          ],
        ),
        TargetField(
          key: 'phone',
          label: l10n.colPhone,
          required: false,
          aliases: [
            'טלפון',
            'phone',
            'PHONE',
            'tel',
            'telephone',
            'נייד',
            'CELLPHONE'
          ],
        ),
        TargetField(
          key: 'contactPerson',
          label: l10n.colContactPerson,
          required: false,
          aliases: [
            'איש קשר',
            'contactPerson',
            'contact',
            'CONTACT',
            'שם איש קשר'
          ],
        ),
        TargetField(
          key: 'vatId',
          label: l10n.colVatId,
          required: false,
          aliases: [
            'ח.פ',
            'חפ',
            'vatId',
            'VAT',
            'WTAXNUM',
            'ע.מ',
            'עוסק מורשה',
            'TaxId'
          ],
        ),
        TargetField(
          key: 'zones',
          label: l10n.colZones,
          required: false,
          aliases: ['אזורים', 'zones', 'zone', 'אזור', 'ZONE', 'region'],
        ),
        TargetField(
          key: 'latitude',
          label: l10n.colLatitude,
          required: false,
          aliases: ['קו רוחב', 'latitude', 'lat', 'LAT'],
        ),
        TargetField(
          key: 'longitude',
          label: l10n.colLongitude,
          required: false,
          aliases: ['קו אורך', 'longitude', 'lng', 'lon', 'LNG', 'LON'],
        ),
      ];

  /// Pick file → show column mapping → parse rows
  static Future<({List<ParsedClientRow>? rows, DuplicateMode duplicateMode})>
      pickAndParse(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final fileData = await ImportFileParser.pickAndParse();
    if (fileData == null) {
      return (rows: null, duplicateMode: DuplicateMode.skip);
    }

    if (!context.mounted) {
      return (rows: null, duplicateMode: DuplicateMode.skip);
    }
    final mapping = await showDialog<ColumnMapping>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ColumnMappingDialog(
        title: l10n.mapColumnsClients,
        sourceHeaders: fileData.headers,
        targetFields: getTargetFields(l10n),
        sampleRows: fileData.rows.take(3).toList(),
      ),
    );
    if (mapping == null) return (rows: null, duplicateMode: DuplicateMode.skip);

    final parsed = _parseWithMapping(fileData.rows, mapping.mapping);
    return (rows: parsed, duplicateMode: mapping.duplicateMode);
  }

  /// Parse rows using column mapping
  static List<ParsedClientRow> _parseWithMapping(
      List<List<String>> rows, Map<String, int> mapping) {
    final parsed = <ParsedClientRow>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final errors = <String>[];

      String getVal(String key) {
        final idx = mapping[key] ?? -1;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final clientNumber = getVal('clientNumber');
      final name = getVal('name');
      final address = getVal('address');

      if (clientNumber.isEmpty) {
        errors.add('מספר לקוח חסר');
      } else if (!RegExp(r'^\d{4,10}$').hasMatch(clientNumber)) {
        errors.add('מספר לקוח לא תקין');
      }
      if (name.isEmpty) errors.add('שם חסר');
      if (address.isEmpty) errors.add('כתובת חסרה');

      final zonesStr = getVal('zones');
      final zones = zonesStr.isNotEmpty
          ? zonesStr
              .split(',')
              .map((z) => z.trim())
              .where((z) => z.isNotEmpty)
              .toList()
          : <String>[];

      final lat = double.tryParse(getVal('latitude'));
      final lng = double.tryParse(getVal('longitude'));

      parsed.add(ParsedClientRow(
        rowIndex: i + 2,
        clientNumber: clientNumber,
        name: name,
        address: address,
        phone: getVal('phone').isEmpty ? null : getVal('phone'),
        contactPerson:
            getVal('contactPerson').isEmpty ? null : getVal('contactPerson'),
        vatId: getVal('vatId').isEmpty ? null : getVal('vatId'),
        zones: zones,
        latitude: lat,
        longitude: lng,
        errors: errors,
      ));
    }
    return parsed;
  }

  /// Create Excel template for client import
  static List<int> createTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Clients'];

    sheet.appendRow([
      TextCellValue('מספר לקוח *'),
      TextCellValue('שם *'),
      TextCellValue('כתובת *'),
      TextCellValue('טלפון'),
      TextCellValue('איש קשר'),
      TextCellValue('ח.פ'),
      TextCellValue('אזורים (center,south,north,jerusalem,sharon)'),
      TextCellValue('קו רוחב (Latitude)'),
      TextCellValue('קו אורך (Longitude)'),
    ]);

    sheet.appendRow([
      TextCellValue('100001'),
      TextCellValue('סופר שלום'),
      TextCellValue('הרצל 15, תל אביב'),
      TextCellValue('03-1234567'),
      TextCellValue('יוסי כהן'),
      TextCellValue(''),
      TextCellValue('center'),
      TextCellValue('32.0853'),
      TextCellValue('34.7818'),
    ]);
    sheet.appendRow([
      TextCellValue('100002'),
      TextCellValue('מאפיית הזהב'),
      TextCellValue('בן גוריון 42, חיפה'),
      TextCellValue('04-9876543'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('north'),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    return excel.encode()!;
  }

  /// Export existing clients to Excel
  static List<int> exportClients(List<Map<String, dynamic>> clients) {
    final excel = Excel.createExcel();
    final sheet = excel['Clients'];

    sheet.appendRow([
      TextCellValue('מספר לקוח'),
      TextCellValue('שם'),
      TextCellValue('כתובת'),
      TextCellValue('טלפון'),
      TextCellValue('איש קשר'),
      TextCellValue('ח.פ'),
      TextCellValue('אזורים'),
      TextCellValue('קו רוחב'),
      TextCellValue('קו אורך'),
    ]);

    for (final c in clients) {
      sheet.appendRow([
        TextCellValue(c['clientNumber']?.toString() ?? ''),
        TextCellValue(c['name']?.toString() ?? ''),
        TextCellValue(c['address']?.toString() ?? ''),
        TextCellValue(c['phone']?.toString() ?? ''),
        TextCellValue(c['contactPerson']?.toString() ?? ''),
        TextCellValue(c['vatId']?.toString() ?? ''),
        TextCellValue((c['zones'] as List<dynamic>?)?.join(',') ?? ''),
        TextCellValue(c['latitude']?.toString() ?? ''),
        TextCellValue(c['longitude']?.toString() ?? ''),
      ]);
    }

    return excel.encode()!;
  }
}
