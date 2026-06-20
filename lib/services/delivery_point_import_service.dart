import 'package:flutter/material.dart';
import '../models/delivery_point.dart';
import '../utils/geocoding_helper.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/column_mapping_dialog.dart';
import '../widgets/import_preview_dialog.dart';
import '../services/company_context.dart';
import '../services/route_service.dart';
import 'import_file_parser.dart';
import '../l10n/app_localizations.dart';

class ParsedDeliveryPointRow {
  final int rowIndex;
  final String clientNumber;
  final String clientName;
  final String address;
  final double? latitude;
  final double? longitude;
  final int pallets;
  final int boxes;
  final String urgency;
  final String? zone;
  final String? taskNote;
  final String? openingTimeRaw;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  ParsedDeliveryPointRow({
    required this.rowIndex,
    required this.clientNumber,
    required this.clientName,
    required this.address,
    this.latitude,
    this.longitude,
    this.pallets = 0,
    this.boxes = 0,
    this.urgency = 'normal',
    this.zone,
    this.taskNote,
    this.openingTimeRaw,
    this.errors = const [],
  });
}

/// Импорт точек доставки из Excel/CSV/XML (паттерн ClientImportService).
class DeliveryPointImportService {
  static List<TargetField> getTargetFields(AppLocalizations l10n) => [
        TargetField(
          key: 'clientNumber',
          label: l10n.colClientNumber,
          aliases: [
            'מספר לקוח',
            'clientNumber',
            'client_number',
            'מס לקוח',
            'CustomerCode',
            'код клиента',
            'номер клиента',
          ],
        ),
        TargetField(
          key: 'clientName',
          label: l10n.colName,
          required: true,
          aliases: [
            'שם',
            'שם לקוח',
            'clientName',
            'client_name',
            'name',
            'CUSTDES',
            'имя',
            'клиент',
          ],
        ),
        TargetField(
          key: 'address',
          label: l10n.colAddress,
          required: true,
          aliases: [
            'כתובת',
            'address',
            'ADDR',
            'адрес',
            'Address',
          ],
        ),
        TargetField(
          key: 'latitude',
          label: l10n.colLatitude,
          aliases: ['קו רוחב', 'latitude', 'lat', 'LAT', 'широта'],
        ),
        TargetField(
          key: 'longitude',
          label: l10n.colLongitude,
          aliases: ['קו אורך', 'longitude', 'lng', 'lon', 'LNG', 'долгота'],
        ),
        TargetField(
          key: 'pallets',
          label: l10n.pallets,
          aliases: ['משטחים', 'pallets', 'pallet', 'паллеты', 'паллет'],
        ),
        TargetField(
          key: 'boxes',
          label: l10n.boxes,
          aliases: ['קרטונים', 'boxes', 'box', 'коробки', 'коробок'],
        ),
        TargetField(
          key: 'urgency',
          label: l10n.urgency,
          aliases: ['דחיפות', 'urgency', 'срочность', 'приоритет'],
        ),
        TargetField(
          key: 'zone',
          label: l10n.colZones,
          aliases: ['אזור', 'zone', 'zones', 'зона', 'район'],
        ),
        TargetField(
          key: 'taskNote',
          label: l10n.taskNoteLabel,
          aliases: [
            'הערה',
            'taskNote',
            'task_note',
            'задание',
            'примечание',
          ],
        ),
        TargetField(
          key: 'openingTime',
          label: l10n.openingTime,
          aliases: [
            'שעת פתיחה',
            'openingTime',
            'opening_time',
            'время открытия',
          ],
        ),
      ];

  static Future<List<ParsedDeliveryPointRow>?> pickAndParse(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final fileData = await ImportFileParser.pickAndParse();
    if (fileData == null || !context.mounted) return null;

    final mapping = await showDialog<ColumnMapping>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ColumnMappingDialog(
        title: l10n.mapColumnsDeliveryPoints,
        sourceHeaders: fileData.headers,
        targetFields: getTargetFields(l10n),
        sampleRows: fileData.rows.take(3).toList(),
        showDuplicateMode: false,
      ),
    );
    if (mapping == null) return null;
    return _parseWithMapping(fileData.rows, mapping.mapping);
  }

  static List<ParsedDeliveryPointRow> _parseWithMapping(
      List<List<String>> rows, Map<String, int> mapping) {
    final parsed = <ParsedDeliveryPointRow>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final errors = <String>[];

      String getVal(String key) {
        final idx = mapping[key] ?? -1;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      final clientName = getVal('clientName');
      final address = getVal('address');
      final clientNumber = getVal('clientNumber');

      if (clientName.isEmpty) errors.add('שם לקוח חסר');
      if (address.isEmpty) errors.add('כתובת חסרה');
      if (clientNumber.isNotEmpty &&
          !RegExp(r'^\d{4,10}$').hasMatch(clientNumber)) {
        errors.add('מספר לקוח לא תקין');
      }

      final lat = double.tryParse(getVal('latitude'));
      final lng = double.tryParse(getVal('longitude'));
      if (lat != null && lng != null &&
          !DeliveryPoint.isValidCoordinates(lat, lng)) {
        errors.add('קואורדינטות מחוץ לישראל');
      }

      final pallets = int.tryParse(getVal('pallets')) ?? 0;
      final boxes = int.tryParse(getVal('boxes')) ?? 0;

      parsed.add(ParsedDeliveryPointRow(
        rowIndex: i + 2,
        clientNumber: clientNumber,
        clientName: clientName,
        address: address,
        latitude: lat,
        longitude: lng,
        pallets: pallets,
        boxes: boxes,
        urgency: _normalizeUrgency(getVal('urgency')),
        zone: getVal('zone').isEmpty ? null : getVal('zone'),
        taskNote: getVal('taskNote').isEmpty ? null : getVal('taskNote'),
        openingTimeRaw:
            getVal('openingTime').isEmpty ? null : getVal('openingTime'),
        errors: errors,
      ));
    }
    return parsed;
  }

  static String _normalizeUrgency(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return 'normal';
    if (v.contains('very') || v.contains('מאוד') || v.contains('очень')) {
      return 'very_urgent';
    }
    if (v.contains('urgent') ||
        v.contains('דחוף') ||
        v.contains('сроч') ||
        v == '1') {
      return 'urgent';
    }
    return 'normal';
  }

  static DateTime? _parseOpeningTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, min);
  }

  /// Полный цикл: файл → маппинг → превью → геокодинг → Firestore.
  static Future<void> runImport(BuildContext context) async {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final rows = await pickAndParse(context);
    if (rows == null || !context.mounted) return;

    final previewRows = rows
        .map((r) => ImportPreviewRow(
              rowIndex: r.rowIndex,
              values: [
                r.clientNumber,
                r.clientName,
                r.address,
                '${r.pallets}',
                '${r.boxes}',
                r.urgency,
              ],
              errors: r.errors,
            ))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ImportPreviewDialog(
        title: l10n.importDeliveryPointsTitle,
        columns: [
          l10n.colClientNumber,
          l10n.colName,
          l10n.colAddress,
          l10n.pallets,
          l10n.boxes,
          l10n.urgency,
        ],
        rows: previewRows,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final routeService = RouteService(companyId: companyId);
    int added = 0;
    final errors = <String>[];

    for (final row in rows.where((r) => r.isValid)) {
      try {
        double lat = row.latitude ?? 0;
        double lng = row.longitude ?? 0;

        if (!DeliveryPoint.isValidCoordinates(lat, lng) &&
            row.address.isNotEmpty) {
          final geo = await GeocodingHelper.geocodeAddress(row.address);
          if (geo != null) {
            lat = geo['latitude']!;
            lng = geo['longitude']!;
          }
        }

        if (!DeliveryPoint.isValidCoordinates(lat, lng)) {
          errors.add(l10n.importRowError(row.rowIndex, 'קואורדינטות לא תקינות'));
          continue;
        }

        final point = DeliveryPoint(
          id: '',
          companyId: companyId,
          clientName: row.clientName,
          clientNumber: row.clientNumber.isEmpty ? null : row.clientNumber,
          address: row.address,
          latitude: lat,
          longitude: lng,
          pallets: row.pallets,
          boxes: row.boxes > 0 ? row.boxes : (row.pallets > 0 ? row.pallets * 4 : 1),
          urgency: row.urgency,
          zone: row.zone,
          taskNote: row.taskNote,
          openingTime: _parseOpeningTime(row.openingTimeRaw),
          status: DeliveryPoint.statusPending,
        );
        await routeService.addDeliveryPoint(point);
        added++;
      } catch (e) {
        errors.add(l10n.importRowError(row.rowIndex, e.toString()));
      }
    }

    if (context.mounted) {
      SnackbarHelper.showSuccess(
        context,
        l10n.importResultMessage(added, errors.length),
      );
    }
  }
}
