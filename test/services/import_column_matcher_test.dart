import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/client_import_service.dart';
import 'package:logiroute/services/delivery_point_import_service.dart';
import 'package:logiroute/services/import/import_column_matcher.dart';
import 'package:logiroute/models/import_wizard_type.dart';
import 'package:logiroute/models/saved_import_mapping.dart';
import 'package:logiroute/utils/delivery_point_address_resolver.dart';
import 'package:logiroute/widgets/column_mapping_dialog.dart';

TargetField _field(String key, {bool required = false, List<String> aliases = const []}) =>
    TargetField(key: key, label: key, required: required, aliases: aliases);

void main() {
  group('ImportColumnMatcher', () {
    test('English headers auto-map clients', () {
      final headers = [
        'Client Number',
        'Customer Name',
        'Address',
        'Phone',
      ];
      final fields = [
        _field('clientNumber', required: true, aliases: ['client number']),
        _field('name', required: true, aliases: ['customer name', 'name']),
        _field('address', required: true, aliases: ['address']),
        _field('phone', aliases: ['phone']),
      ];
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: headers,
        targetFields: fields,
      );
      expect(s.mapping['clientNumber'], 0);
      expect(s.mapping['name'], 1);
      expect(s.mapping['address'], 2);
      expect(s.confidenceByField['name'], greaterThanOrEqualTo(70));
    });

    test('Hebrew headers auto-map delivery points', () {
      final headers = ['מספר לקוח', 'שם לקוח', 'כתובת', 'קרטונים'];
      final fields = [
        _field('clientNumber', aliases: ['מספר לקוח']),
        _field('clientName', required: true, aliases: ['שם לקוח']),
        _field('address', required: true, aliases: ['כתובת']),
        _field('boxes', aliases: ['קרטונים']),
      ];
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: headers,
        targetFields: fields,
      );
      expect(s.mapping['clientName'], 1);
      expect(s.confidenceByField['clientName'], 100);
    });

    test('Russian CSV headers', () {
      final headers = ['номер клиента', 'название', 'адрес'];
      final fields = [
        _field('clientNumber', required: true, aliases: ['номер клиента']),
        _field('name', required: true, aliases: ['название']),
        _field('address', required: true, aliases: ['адрес']),
      ];
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: headers,
        targetFields: fields,
      );
      expect(s.mapping['name'], 1);
      expect(s.confidenceByField['address'], greaterThanOrEqualTo(70));
    });

    test('extra columns ignored', () {
      final headers = ['CustCode', 'CustName', 'ADDR', 'Notes', 'Extra1'];
      final fields = [
        _field('clientNumber', aliases: ['custcode']),
        _field('clientName', aliases: ['custname']),
        _field('address', aliases: ['addr']),
      ];
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: headers,
        targetFields: fields,
      );
      expect(s.mapping.values.where((i) => i >= 0).length, 3);
      expect(s.mapping.values.contains(3), isFalse);
      expect(s.mapping.values.contains(4), isFalse);
    });

    test('fuzzy CustName maps to clientName with confidence >= 70', () {
      final headers = ['CustName'];
      final fields = [
        _field('clientName', aliases: ['client name', 'customer name', 'CustName']),
      ];
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: headers,
        targetFields: fields,
      );
      expect(s.mapping['clientName'], 0);
      expect(s.confidenceByField['clientName'], greaterThanOrEqualTo(70));
    });

    test('saved mapping similarity >= 0.7', () {
      final saved = SavedImportMapping(
        id: '1',
        companyId: 'c1',
        importType: ImportWizardType.clients,
        name: 't',
        sourceHeaders: ['CustCode', 'CustName', 'ADDR'],
        mapping: {'clientNumber': 0, 'name': 1, 'address': 2},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u',
      );
      final newHeaders = ['CustCode', 'CustName', 'ADDR', 'Phone'];
      final score = ImportColumnMatcher.headersSimilarity(
        newHeaders,
        saved.sourceHeaders,
      );
      expect(score, greaterThanOrEqualTo(0.7));
    });
  });

  group('ImportRowParser validation', () {
    test('missing required client fields', () {
      final rows = [
        ['', '', ''],
      ];
      final mapping = {'clientNumber': 0, 'name': 1, 'address': 2};
      final parsed = ClientImportService.parseWithMapping(rows, mapping);
      expect(parsed.first.isValid, isFalse);
      expect(parsed.first.errors, isNotEmpty);
    });

    test('delivery requires clientName OR clientNumber and address OR override', () {
      final rows = [
        ['', '', '', ''],
        ['100001', '', '', 'רחוב א'],
        ['', 'חנות', 'רחוב ב', ''],
      ];
      final mapping = {
        'clientNumber': 0,
        'clientName': 1,
        'address': 2,
        'deliveryAddressOverride': 3,
      };
      final parsed =
          DeliveryPointImportService.parseWithMapping(rows, mapping);
      expect(parsed[0].isValid, isFalse);
      expect(parsed[1].isValid, isTrue);
      expect(parsed[2].isValid, isTrue);
    });
  });

  group('deliveryAddressOverride import path', () {
    test('override does not replace client address in resolveImportPointAddresses', () {
      final resolved = resolveImportPointAddresses(
        importedAddress: 'רחוב פריקה 5',
        clientAddress: 'רחוב לקוח 1',
      );
      expect(resolved.pointAddress, 'רחוב לקוח 1');
      expect(resolved.deliveryAddressOverride, 'רחוב פריקה 5');
    });

    test('explicit deliveryAddressOverride column parsed separately', () {
      final rows = [
        ['100001', 'לקוח', 'רחוב לקוח 1', 'רחוב פריקה 5'],
      ];
      final mapping = {
        'clientNumber': 0,
        'clientName': 1,
        'address': 2,
        'deliveryAddressOverride': 3,
      };
      final parsed =
          DeliveryPointImportService.parseWithMapping(rows, mapping);
      expect(parsed.first.deliveryAddressOverride, 'רחוב פריקה 5');
      expect(parsed.first.address, 'רחוב לקוח 1');

      final resolved = resolveImportPointAddresses(
        importedAddress: parsed.first.address,
        clientAddress: 'רחוב לקוח 1',
      );
      expect(resolved.deliveryAddressOverride, isNull);

      final withOverride = (
        pointAddress: 'רחוב לקוח 1',
        deliveryAddressOverride: parsed.first.deliveryAddressOverride,
      );
      expect(withOverride.pointAddress, 'רחוב לקוח 1');
      expect(withOverride.deliveryAddressOverride, 'רחוב פריקה 5');
    });
  });
}
