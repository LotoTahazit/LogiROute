import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/import/import_alias_packs.dart';
import 'package:logiroute/services/import/import_column_matcher.dart';
import 'package:logiroute/services/import/import_confidence_engine.dart';
import 'package:logiroute/services/import/import_header_intelligence.dart';
import 'package:logiroute/services/import/import_sample_recognizer.dart';
import 'package:logiroute/widgets/column_mapping_dialog.dart';

TargetField _field(String key, {bool required = false, List<String> aliases = const []}) =>
    TargetField(key: key, label: key, required: required, aliases: aliases);

void main() {
  group('ImportHeaderIntelligence', () {
    test('normalizes case, spaces, punctuation', () {
      expect(ImportHeaderIntelligence.normalize('Customer_Name'), 'customername');
      expect(ImportHeaderIntelligence.normalize('  Phone-1  '), 'phone1');
      expect(ImportHeaderIntelligence.normalize('מק"ט'), 'מקט');
    });

    test('expands abbreviations', () {
      expect(ImportHeaderIntelligence.normalize('Cust'), 'customer');
      expect(ImportHeaderIntelligence.normalize('Addr'), 'address');
      expect(ImportHeaderIntelligence.normalize('CustName'), 'customername');
    });
  });

  group('ImportAliasPacks', () {
    test('detects Priority headers', () {
      final pack = ImportAliasPacks.detectPack(
        ['CustCode', 'CustName', 'ADDR', 'Phone1'],
      );
      expect(pack, ImportAliasPack.priority);
    });

    test('detects SAP headers', () {
      final pack = ImportAliasPacks.detectPack(
        ['CardCode', 'CardName', 'ItemCode', 'ItemName'],
      );
      expect(pack, ImportAliasPack.sapBusinessOne);
    });

    test('detects Hashavshevet headers', () {
      final pack = ImportAliasPacks.detectPack(
        ['מספר לקוח', 'שם לקוח', 'כתובת', 'מק"ט'],
      );
      expect(pack, ImportAliasPack.hashavshevet);
    });
  });

  group('ImportSampleRecognizer', () {
    test('recognizes phone column', () {
      final scores = ImportSampleRecognizer.scoreColumn([
        '0541234567',
        '0529876543',
        '0541112233',
      ]);
      expect(scores['phone'], greaterThanOrEqualTo(50));
    });

    test('recognizes VAT column', () {
      final scores = ImportSampleRecognizer.scoreColumn([
        '123456789',
        '987654321',
        '514789632',
      ]);
      expect(scores['vatId'], greaterThanOrEqualTo(40));
    });

    test('recognizes address column', () {
      final scores = ImportSampleRecognizer.scoreColumn([
        'ул. Герцль 15',
        'רחוב הרצל 10',
        'Street 5, Tel Aviv',
      ]);
      expect(scores['address'], greaterThanOrEqualTo(30));
    });

    test('recognizes company name column', () {
      final scores = ImportSampleRecognizer.scoreColumn([
        'ООО Ромашка',
        'חברה בע"מ',
        'Acme Ltd',
      ]);
      expect(scores['clientName'], greaterThanOrEqualTo(30));
    });
  });

  group('ImportColumnMatcher v2', () {
    test('English headers auto-map clients', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['Client Number', 'Customer Name', 'Address', 'Phone'],
        targetFields: [
          _field('clientNumber', required: true, aliases: ['client number']),
          _field('name', required: true, aliases: ['customer name']),
          _field('address', required: true, aliases: ['address']),
          _field('phone', aliases: ['phone']),
        ],
      );
      expect(s.mapping['clientNumber'], 0);
      expect(s.mapping['name'], 1);
      expect(s.confidenceByField['name'], greaterThanOrEqualTo(70));
    });

    test('Hebrew headers auto-map delivery points', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['מספר לקוח', 'שם לקוח', 'כתובת', 'קרטונים'],
        targetFields: [
          _field('clientNumber', aliases: ['מספר לקוח']),
          _field('clientName', required: true, aliases: ['שם לקוח']),
          _field('address', required: true, aliases: ['כתובת']),
          _field('boxes', aliases: ['קרטונים']),
        ],
      );
      expect(s.mapping['clientName'], 1);
      expect(s.confidenceByField['clientName'], greaterThanOrEqualTo(85));
      expect(s.detectedPack, ImportAliasPack.hashavshevet);
    });

    test('Russian CSV headers', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['номер клиента', 'название', 'адрес'],
        targetFields: [
          _field('clientNumber', required: true, aliases: ['номер клиента']),
          _field('name', required: true, aliases: ['название']),
          _field('address', required: true, aliases: ['адрес']),
        ],
      );
      expect(s.mapping['name'], 1);
      expect(s.confidenceByField['address'], greaterThanOrEqualTo(70));
    });

    test('Priority ERP headers', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['CustCode', 'CustName', 'ADDR', 'Notes'],
        targetFields: [
          _field('clientNumber', aliases: ['custcode']),
          _field('clientName', required: true, aliases: ['custname']),
          _field('address', aliases: ['addr']),
        ],
      );
      expect(s.detectedPack, ImportAliasPack.priority);
      expect(s.mapping['clientNumber'], 0);
      expect(s.mapping['clientName'], 1);
    });

    test('SAP headers', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['CardCode', 'CardName', 'Street'],
        targetFields: [
          _field('clientNumber', aliases: ['cardcode']),
          _field('name', required: true, aliases: ['cardname']),
          _field('address', aliases: ['street']),
        ],
      );
      expect(s.detectedPack, ImportAliasPack.sapBusinessOne);
      expect(s.mapping['name'], 1);
    });

    test('sample data boosts unknown header mapping', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['ColA', 'ColB', 'ColC'],
        targetFields: [
          _field('phone', aliases: ['phone']),
          _field('vatId', aliases: ['vat']),
          _field('address', aliases: ['address']),
        ],
        sampleRows: [
          ['0541234567', '123456789', 'ул. Герцль 15'],
          ['0521112233', '987654321', 'רחוב הרצל 1'],
        ],
      );
      expect(s.mapping['phone'], 0);
      expect(s.mapping['vatId'], 1);
      expect(s.mapping['address'], 2);
      expect(s.confidenceByField['phone'], greaterThanOrEqualTo(50));
    });

    test('learned header boosts mapping', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['MyCustomCol', 'Address'],
        targetFields: [
          _field('name', required: true, aliases: ['name']),
          _field('address', required: true, aliases: ['address']),
        ],
        learnedHeaders: {'mycustomcol': 'name'},
      );
      expect(s.mapping['name'], 0);
      expect(s.confidenceByField['name'], greaterThanOrEqualTo(70));
    });

    test('unused columns listed', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['CustCode', 'CustName', 'ADDR', 'Notes', 'Extra1'],
        targetFields: [
          _field('clientNumber', aliases: ['custcode']),
          _field('clientName', aliases: ['custname']),
          _field('address', aliases: ['addr']),
        ],
      );
      expect(s.unusedColumnIndexes, contains(3));
      expect(s.unusedColumnIndexes, contains(4));
      expect(s.unusedColumnIndexes, isNot(contains(0)));
    });

    test('mixed language headers', () {
      final s = ImportColumnMatcher.suggestMapping(
        sourceHeaders: ['CustCode', 'שם לקוח', 'адрес', 'Phone'],
        targetFields: [
          _field('clientNumber', aliases: ['custcode']),
          _field('clientName', required: true, aliases: ['שם לקוח']),
          _field('address', aliases: ['адрес']),
          _field('phone', aliases: ['phone']),
        ],
      );
      expect(s.mapping['clientNumber'], 0);
      expect(s.mapping['clientName'], 1);
      expect(s.mapping['address'], 2);
      expect(s.mapping['phone'], 3);
    });
  });

  group('ImportConfidenceEngine', () {
    test('level missing for required unmapped field', () {
      final level = ImportConfidenceEngine.levelFor(
        field: _field('name', required: true),
        columnIndex: -1,
        confidence: 0,
      );
      expect(level, ImportConfidenceLevel.missing);
    });

    test('level high for strong match', () {
      final level = ImportConfidenceEngine.levelFor(
        field: _field('name'),
        columnIndex: 0,
        confidence: 90,
      );
      expect(level, ImportConfidenceLevel.high);
    });
  });
}
