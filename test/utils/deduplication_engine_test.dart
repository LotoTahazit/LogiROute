import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/product_type.dart';
import 'package:logiroute/models/template_product.dart';
import 'package:logiroute/utils/deduplication_engine.dart';

void main() {
  group('DeduplicationEngine.normalizeName', () {
    test('trims and lowercases', () {
      expect(
          DeduplicationEngine.normalizeName('  Hello World  '), 'hello world');
    });

    test('collapses multiple whitespace into single space', () {
      expect(DeduplicationEngine.normalizeName('Cup  Large'), 'cup large');
    });

    test('handles empty string', () {
      expect(DeduplicationEngine.normalizeName(''), '');
    });

    test('handles string with only whitespace', () {
      expect(DeduplicationEngine.normalizeName('   '), '');
    });

    test('handles tabs and newlines', () {
      expect(DeduplicationEngine.normalizeName('\tHello\n World\t'),
          'hello world');
    });

    test('already normalized string stays the same', () {
      expect(DeduplicationEngine.normalizeName('hello world'), 'hello world');
    });

    test('is idempotent', () {
      const input = '  Cup   Large  ';
      final once = DeduplicationEngine.normalizeName(input);
      final twice = DeduplicationEngine.normalizeName(once);
      expect(twice, once);
    });
  });

  group('DeduplicationEngine.filterDuplicates', () {
    TemplateProduct makeTemplate({
      String name = 'Product',
      String productCode = 'SKU-001',
      String category = 'cups',
    }) {
      return TemplateProduct(
        id: 'tpl-1',
        name: name,
        productCode: productCode,
        category: category,
        unitsPerBox: 10,
        boxesPerPallet: 5,
        businessType: 'packaging',
      );
    }

    ProductType makeExisting({
      String name = 'Product',
      String productCode = 'SKU-001',
      String category = 'cups',
    }) {
      return ProductType(
        id: 'pt-1',
        companyId: 'comp-1',
        name: name,
        productCode: productCode,
        category: category,
        unitsPerBox: 10,
        boxesPerPallet: 5,
        createdAt: DateTime.now(),
        createdBy: 'user-1',
      );
    }

    test('empty templates returns empty results', () {
      final result = DeduplicationEngine.filterDuplicates([], []);
      expect(result.toImport, isEmpty);
      expect(result.skipped, isEmpty);
    });

    test('all templates are new when no existing products', () {
      final templates = [
        makeTemplate(productCode: 'A'),
        makeTemplate(productCode: 'B', name: 'Other'),
      ];
      final result = DeduplicationEngine.filterDuplicates(templates, []);
      expect(result.toImport.length, 2);
      expect(result.skipped, isEmpty);
    });

    test('all templates are skipped when all are duplicates', () {
      final templates = [makeTemplate(productCode: 'SKU-001')];
      final existing = [makeExisting(productCode: 'SKU-001')];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.toImport, isEmpty);
      expect(result.skipped.length, 1);
    });

    test('partitions correctly with mixed duplicates and new', () {
      final templates = [
        makeTemplate(productCode: 'SKU-001', name: 'Cup A', category: 'cups'),
        makeTemplate(
            productCode: 'SKU-NEW', name: 'New Item', category: 'lids'),
      ];
      final existing = [makeExisting(productCode: 'SKU-001')];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.toImport.length, 1);
      expect(result.skipped.length, 1);
      expect(result.toImport.first.productCode, 'SKU-NEW');
      expect(result.skipped.first.productCode, 'SKU-001');
    });

    test('toImport + skipped length equals templates length', () {
      final templates = [
        makeTemplate(productCode: 'A', name: 'Item A', category: 'cups'),
        makeTemplate(productCode: 'B', name: 'Item B', category: 'lids'),
        makeTemplate(productCode: 'C', name: 'Item C', category: 'cups'),
      ];
      final existing = [makeExisting(productCode: 'B')];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.toImport.length + result.skipped.length, templates.length);
    });

    test('detects duplicate by normalizedName + categoryKey fallback', () {
      final templates = [
        makeTemplate(
            productCode: 'DIFFERENT-SKU',
            name: '  Cup Large  ',
            category: 'cups'),
      ];
      final existing = [
        makeExisting(
            productCode: 'OTHER-SKU', name: 'cup large', category: 'cups'),
      ];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.skipped.length, 1);
      expect(result.toImport, isEmpty);
    });

    test('same name different category is not a duplicate', () {
      final templates = [
        makeTemplate(
            productCode: 'NEW-SKU', name: 'Cup Large', category: 'lids'),
      ];
      final existing = [
        makeExisting(
            productCode: 'OTHER-SKU', name: 'Cup Large', category: 'cups'),
      ];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.toImport.length, 1);
      expect(result.skipped, isEmpty);
    });

    test('each product is evaluated independently', () {
      final templates = [
        makeTemplate(productCode: 'DUP-1', name: 'A', category: 'cups'),
        makeTemplate(productCode: 'NEW-1', name: 'B', category: 'lids'),
        makeTemplate(productCode: 'DUP-2', name: 'C', category: 'cups'),
      ];
      final existing = [
        makeExisting(productCode: 'DUP-1'),
        makeExisting(productCode: 'DUP-2'),
      ];
      final result = DeduplicationEngine.filterDuplicates(templates, existing);
      expect(result.toImport.length, 1);
      expect(result.skipped.length, 2);
      expect(result.toImport.first.productCode, 'NEW-1');
    });
  });

  group('DeduplicationEngine.isDuplicate', () {
    TemplateProduct makeTemplate({
      String name = 'Product',
      String productCode = 'SKU-001',
      String category = 'cups',
    }) {
      return TemplateProduct(
        id: 'tpl-1',
        name: name,
        productCode: productCode,
        category: category,
        unitsPerBox: 10,
        boxesPerPallet: 5,
        businessType: 'packaging',
      );
    }

    ProductType makeExisting({
      String name = 'Product',
      String productCode = 'SKU-001',
      String category = 'cups',
    }) {
      return ProductType(
        id: 'pt-1',
        companyId: 'comp-1',
        name: name,
        productCode: productCode,
        category: category,
        unitsPerBox: 10,
        boxesPerPallet: 5,
        createdAt: DateTime.now(),
        createdBy: 'user-1',
      );
    }

    test('match by productCode returns true', () {
      final template = makeTemplate(productCode: 'SKU-100');
      final existing = [
        makeExisting(
            productCode: 'SKU-100', name: 'Different Name', category: 'lids'),
      ];
      expect(DeduplicationEngine.isDuplicate(template, existing), isTrue);
    });

    test('match by normalizedName + categoryKey returns true', () {
      final template = makeTemplate(
        productCode: 'NEW-SKU',
        name: '  Cup Large  ',
        category: 'cups',
      );
      final existing = [
        makeExisting(
            productCode: 'OTHER-SKU', name: 'cup large', category: 'cups'),
      ];
      expect(DeduplicationEngine.isDuplicate(template, existing), isTrue);
    });

    test('same name but different category returns false', () {
      final template = makeTemplate(
        productCode: 'NEW-SKU',
        name: 'Cup Large',
        category: 'lids',
      );
      final existing = [
        makeExisting(
            productCode: 'OTHER-SKU', name: 'Cup Large', category: 'cups'),
      ];
      expect(DeduplicationEngine.isDuplicate(template, existing), isFalse);
    });

    test('no matches returns false', () {
      final template = makeTemplate(
        productCode: 'UNIQUE-SKU',
        name: 'Unique Product',
        category: 'lids',
      );
      final existing = [
        makeExisting(
            productCode: 'SKU-001', name: 'Other Product', category: 'cups'),
        makeExisting(
            productCode: 'SKU-002', name: 'Another Product', category: 'lids'),
      ];
      expect(DeduplicationEngine.isDuplicate(template, existing), isFalse);
    });

    test('empty existing list returns false', () {
      final template = makeTemplate();
      expect(DeduplicationEngine.isDuplicate(template, []), isFalse);
    });
  });
}
