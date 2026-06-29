import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import '../../core/correlation/correlation_context.dart';
import '../../models/client_model.dart';
import '../../models/delivery_point.dart';
import '../../models/import_wizard_type.dart';
import '../../models/usage_event.dart';
import '../../utils/delivery_point_address_resolver.dart';
import '../../utils/geocoding_helper.dart';
import '../../widgets/column_mapping_dialog.dart';
import '../client_import_service.dart';
import '../client_service.dart';
import '../delivery_point_import_service.dart';
import '../product_import_service.dart';
import '../product_type_service.dart';
import '../route_service.dart';
import 'import_row_parser.dart';

/// Результат выполнения импорта в wizard.
class ImportWizardResult {
  final int imported;
  final int updated;
  final int skipped;
  final List<String> errors;
  final List<int>? errorCsv;

  const ImportWizardResult({
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
    this.errorCsv,
  });
}

/// Выполнение импорта после превью (clients / products / delivery points).
class ImportWizardExecutor {
  static Future<ImportWizardResult> execute({
    required ImportWizardType type,
    required List<List<String>> rows,
    required Map<String, int> mapping,
    required String companyId,
    DuplicateMode duplicateMode = DuplicateMode.skip,
    String? userId,
    String? role,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final trace = correlationIf(
      operation: CorrelatedOperation.importExcel,
      companyId: companyId,
      userId: uid,
    );
    final parsed = ImportRowParser.parseRows(
      type: type,
      rows: rows,
      mapping: mapping,
    );
    final validCount = parsed.where(ImportRowParser.rowIsValid).length;
    final source = _sourceKey(type);

    unawaited(trace?.trackPilot(
      UsageEventName.importStarted,
      role: role,
      metadata: {'source': source, 'rows': validCount, 'wizard': true},
    ));

    ImportWizardResult result;
    switch (type) {
      case ImportWizardType.clients:
        result = await _importClients(
          parsed.cast<ParsedClientRow>(),
          companyId: companyId,
          duplicateMode: duplicateMode,
        );
      case ImportWizardType.products:
        result = await _importProducts(
          parsed.cast<ParsedProductRow>(),
          companyId: companyId,
          createdBy: uid,
        );
      case ImportWizardType.deliveryPoints:
        result = await _importDeliveryPoints(
          parsed.cast<ParsedDeliveryPointRow>(),
          companyId: companyId,
          userId: uid,
          correlationId: trace?.correlationId,
        );
    }

    unawaited(trace?.trackPilot(
      UsageEventName.importCompleted,
      role: role,
      metadata: {
        'source': source,
        'added': result.imported,
        'updated': result.updated,
        'skipped': result.skipped,
        'errors': result.errors.length,
        'wizard': true,
      },
    ));
    await trace?.audit(
      moduleKey: type == ImportWizardType.products ? 'warehouse' : 'logistics',
      type: 'data_imported',
      entityCollection: source,
      entityDocId: '${source}_wizard_import',
      extra: {
        'imported': result.imported,
        'updated': result.updated,
        'skipped': result.skipped,
        'errors': result.errors.length,
      },
    );

    return result;
  }

  static String _sourceKey(ImportWizardType type) => switch (type) {
        ImportWizardType.clients => 'clients',
        ImportWizardType.products => 'products',
        ImportWizardType.deliveryPoints => 'delivery_points',
      };

  static Future<ImportWizardResult> _importClients(
    List<ParsedClientRow> rows, {
    required String companyId,
    required DuplicateMode duplicateMode,
  }) async {
    final clientService = ClientService(companyId: companyId);
    int imported = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final row in rows.where((r) => r.isValid)) {
      try {
        double lat = row.latitude ?? 0;
        double lng = row.longitude ?? 0;
        if (lat == 0 && lng == 0 && row.address.isNotEmpty) {
          final geo = await GeocodingHelper.geocodeAddress(row.address);
          if (geo != null) {
            lat = geo['latitude']!;
            lng = geo['longitude']!;
          }
        }

        await clientService.addClient(ClientModel(
          id: '',
          clientNumber: row.clientNumber,
          name: row.name,
          address: row.address,
          latitude: lat,
          longitude: lng,
          phone: row.phone,
          contactPerson: row.contactPerson,
          vatId: row.vatId,
          companyId: companyId,
          zones: row.zones,
        ));
        imported++;
      } catch (e) {
        if (e.toString().contains('DUPLICATE')) {
          if (duplicateMode == DuplicateMode.update) {
            try {
              double lat = row.latitude ?? 0;
              double lng = row.longitude ?? 0;
              if (lat == 0 && lng == 0 && row.address.isNotEmpty) {
                final geo = await GeocodingHelper.geocodeAddress(row.address);
                if (geo != null) {
                  lat = geo['latitude']!;
                  lng = geo['longitude']!;
                }
              }
              await clientService.updateClientByNumber(
                companyId: companyId,
                clientNumber: row.clientNumber,
                name: row.name,
                address: row.address,
                latitude: lat,
                longitude: lng,
                phone: row.phone,
                contactPerson: row.contactPerson,
                vatId: row.vatId,
                zones: row.zones,
              );
              updated++;
            } catch (e2) {
              errors.add('שורה ${row.rowIndex}: $e2');
            }
          } else {
            skipped++;
          }
        } else {
          errors.add('שורה ${row.rowIndex}: $e');
        }
      }
    }

    return ImportWizardResult(
      imported: imported,
      updated: updated,
      skipped: skipped,
      errors: errors,
      errorCsv: _buildErrorCsv(errors),
    );
  }

  static Future<ImportWizardResult> _importProducts(
    List<ParsedProductRow> rows, {
    required String companyId,
    required String createdBy,
  }) async {
    final products = rows
        .where((r) => r.isValid)
        .map((r) => ProductImportService.toProductType(r, companyId, createdBy))
        .toList();
    final errors = <String>[];
    try {
      await ProductTypeService(companyId: companyId).importProductTypes(products);
    } catch (e) {
      errors.add(e.toString());
    }
    return ImportWizardResult(
      imported: products.length,
      errors: errors,
      errorCsv: _buildErrorCsv(errors),
    );
  }

  static Future<ImportWizardResult> _importDeliveryPoints(
    List<ParsedDeliveryPointRow> rows, {
    required String companyId,
    required String userId,
    String? correlationId,
  }) async {
    final routeService = RouteService(companyId: companyId);
    final clientService = ClientService(companyId: companyId);
    int imported = 0;
    final errors = <String>[];

    for (final row in rows.where((r) => r.isValid)) {
      try {
        double lat = row.latitude ?? 0;
        double lng = row.longitude ?? 0;
        String pointAddress = row.address;
        String? override = row.deliveryAddressOverride;
        double? overrideLat = row.deliveryAddressOverrideLat;
        double? overrideLng = row.deliveryAddressOverrideLng;

        if (row.clientNumber.isNotEmpty) {
          final clients =
              await clientService.searchClients(row.clientNumber, null, 1);
          if (clients.isNotEmpty) {
            final client = clients.first;
            final clientAddr = client.address.trim();
            if (override != null && override.isNotEmpty) {
              pointAddress = clientAddr;
            } else {
              final resolved = resolveImportPointAddresses(
                importedAddress: row.address,
                clientAddress: clientAddr,
              );
              pointAddress = resolved.pointAddress;
              override = resolved.deliveryAddressOverride;
            }
            if (DeliveryPoint.isValidCoordinates(
                client.latitude, client.longitude)) {
              lat = client.latitude;
              lng = client.longitude;
            }
          }
        }

        final geoAddress = override ?? pointAddress;
        if (override != null &&
            geoAddress.isNotEmpty &&
            overrideLat == null &&
            overrideLng == null) {
          final geo = await GeocodingHelper.geocodeAddress(override);
          if (geo != null) {
            overrideLat = geo['latitude'];
            overrideLng = geo['longitude'];
          }
        } else if (!DeliveryPoint.isValidCoordinates(lat, lng) &&
            geoAddress.isNotEmpty) {
          final geo = await GeocodingHelper.geocodeAddress(geoAddress);
          if (geo != null) {
            lat = geo['latitude']!;
            lng = geo['longitude']!;
          }
        }

        if (!DeliveryPoint.isValidCoordinates(lat, lng)) {
          errors.add('שורה ${row.rowIndex}: קואורדינטות לא תקינות');
          continue;
        }

        await routeService.addDeliveryPoint(
          DeliveryPoint(
            id: '',
            companyId: companyId,
            clientName: row.clientName,
            clientNumber: row.clientNumber.isEmpty ? null : row.clientNumber,
            address: pointAddress,
            latitude: lat,
            longitude: lng,
            deliveryAddressOverride: override,
            deliveryAddressOverrideLat: overrideLat,
            deliveryAddressOverrideLng: overrideLng,
            pallets: row.pallets,
            boxes: row.boxes > 0
                ? row.boxes
                : (row.pallets > 0 ? row.pallets * 4 : 1),
            urgency: row.urgency,
            zone: row.zone,
            taskNote: row.taskNote,
            openingTime:
                DeliveryPointImportService.parseOpeningTime(row.openingTimeRaw),
            status: DeliveryPoint.statusPending,
          ),
          createdByUid: userId.isNotEmpty ? userId : null,
          createdByRole: 'dispatcher',
          correlationId: correlationId,
        );
        imported++;
      } catch (e) {
        errors.add('שורה ${row.rowIndex}: $e');
      }
    }

    return ImportWizardResult(
      imported: imported,
      errors: errors,
      errorCsv: _buildErrorCsv(errors),
    );
  }

  static List<int>? _buildErrorCsv(List<String> errors) {
    if (errors.isEmpty) return null;
    final lines = [
      'row,error',
      ...errors.map((e) {
        final m = RegExp(r'^שורה (\d+): (.+)$').firstMatch(e);
        if (m != null) {
          final msg = m.group(2)!.replaceAll('"', '""');
          return '${m.group(1)},"$msg"';
        }
        return ',"${e.replaceAll('"', '""')}"';
      }),
    ];
    return utf8.encode(lines.join('\n'));
  }
}
