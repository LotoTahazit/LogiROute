import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/template_product.dart';
import 'package:logiroute/services/template_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 6.3.1 Тест чтения шаблонов
  // Validates: Requirements 3.2
  // ---------------------------------------------------------------------------
  group('6.3.1 — getTemplatesByBusinessType reads templates from Firestore',
      () {
    late FakeFirebaseFirestore fakeFirestore;
    late TemplateService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = TemplateService(firestore: fakeFirestore);
    });

    test('returns matching templates for a given businessType', () async {
      // Arrange: write template documents to /product_templates/
      final templatesRef = fakeFirestore.collection('product_templates');

      await templatesRef.doc('t1').set({
        'name': 'Cup 100ml',
        'productCode': 'CUP-100',
        'category': 'cups',
        'unitsPerBox': 50,
        'boxesPerPallet': 20,
        'businessType': 'packaging',
      });
      await templatesRef.doc('t2').set({
        'name': 'Lid 100ml',
        'productCode': 'LID-100',
        'category': 'lids',
        'unitsPerBox': 100,
        'boxesPerPallet': 25,
        'weight': 0.5,
        'businessType': 'packaging',
      });
      await templatesRef.doc('t3').set({
        'name': 'White Bread',
        'productCode': 'BRD-001',
        'category': 'bread',
        'unitsPerBox': 10,
        'boxesPerPallet': 40,
        'businessType': 'food',
      });

      // Act
      final packagingTemplates =
          await service.getTemplatesByBusinessType('packaging');

      // Assert
      expect(packagingTemplates.length, equals(2));
      final names = packagingTemplates.map((t) => t.name).toSet();
      expect(names, containsAll(['Cup 100ml', 'Lid 100ml']));
      expect(names, isNot(contains('White Bread')));

      // Verify field mapping
      final cup =
          packagingTemplates.firstWhere((t) => t.productCode == 'CUP-100');
      expect(cup.name, 'Cup 100ml');
      expect(cup.category, 'cups');
      expect(cup.unitsPerBox, 50);
      expect(cup.boxesPerPallet, 20);
      expect(cup.businessType, 'packaging');
      expect(cup.weight, isNull);

      final lid =
          packagingTemplates.firstWhere((t) => t.productCode == 'LID-100');
      expect(lid.weight, 0.5);
    });

    test('skips invalid documents missing required fields', () async {
      final templatesRef = fakeFirestore.collection('product_templates');

      // Valid document
      await templatesRef.doc('valid').set({
        'name': 'Valid Product',
        'productCode': 'VP-001',
        'category': 'cups',
        'unitsPerBox': 10,
        'boxesPerPallet': 5,
        'businessType': 'packaging',
      });

      // Invalid document — missing 'name'
      await templatesRef.doc('invalid').set({
        'productCode': 'INV-001',
        'category': 'cups',
        'unitsPerBox': 10,
        'boxesPerPallet': 5,
        'businessType': 'packaging',
      });

      final results = await service.getTemplatesByBusinessType('packaging');

      expect(results.length, equals(1));
      expect(results.first.name, 'Valid Product');
    });

    test('returns empty list when no templates match businessType', () async {
      final templatesRef = fakeFirestore.collection('product_templates');

      await templatesRef.doc('t1').set({
        'name': 'Cup',
        'productCode': 'CUP-1',
        'category': 'cups',
        'unitsPerBox': 50,
        'boxesPerPallet': 20,
        'businessType': 'packaging',
      });

      final results = await service.getTemplatesByBusinessType('food');

      expect(results, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 6.3.2 Тест импорта
  // Validates: Requirements 6.1, 6.6
  // ---------------------------------------------------------------------------
  group('6.3.2 — importSelectedTemplates writes products to company collection',
      () {
    late FakeFirebaseFirestore fakeFirestore;
    late TemplateService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = TemplateService(firestore: fakeFirestore);
    });

    test('imports templates into /companies/{companyId}/product_types/',
        () async {
      const companyId = 'company-abc';
      const createdBy = 'user-123';

      final selectedTemplates = [
        TemplateProduct(
          id: 't1',
          name: 'Cup 100ml',
          productCode: 'CUP-100',
          category: 'cups',
          unitsPerBox: 50,
          boxesPerPallet: 20,
          weight: 1.5,
          businessType: 'packaging',
        ),
        TemplateProduct(
          id: 't2',
          name: 'Lid 100ml',
          productCode: 'LID-100',
          category: 'lids',
          unitsPerBox: 100,
          boxesPerPallet: 25,
          businessType: 'packaging',
        ),
      ];

      // Act
      final result = await service.importSelectedTemplates(
        companyId: companyId,
        createdBy: createdBy,
        selectedTemplates: selectedTemplates,
      );

      // Assert ImportResult
      expect(result.addedCount, equals(2));
      expect(result.skippedCount, equals(0));
      expect(result.errorCount, equals(0));
      expect(result.errorProductNames, isEmpty);

      // Verify documents written to Firestore
      final productTypesSnapshot = await fakeFirestore
          .collection('companies/$companyId/product_types')
          .get();

      expect(productTypesSnapshot.docs.length, equals(2));

      final writtenProducts =
          productTypesSnapshot.docs.map((d) => d.data()).toList();
      final writtenNames = writtenProducts.map((p) => p['name']).toSet();
      expect(writtenNames, containsAll(['Cup 100ml', 'Lid 100ml']));

      // Verify field mapping for one product
      final cupDoc =
          writtenProducts.firstWhere((p) => p['productCode'] == 'CUP-100');
      expect(cupDoc['companyId'], equals(companyId));
      expect(cupDoc['createdBy'], equals(createdBy));
      expect(cupDoc['isActive'], isTrue);
      expect(cupDoc['name'], 'Cup 100ml');
      expect(cupDoc['category'], 'cups');
      expect(cupDoc['unitsPerBox'], 50);
      expect(cupDoc['boxesPerPallet'], 20);
      expect(cupDoc['weight'], 1.5);

      // Lid has no weight/volume
      final lidDoc =
          writtenProducts.firstWhere((p) => p['productCode'] == 'LID-100');
      expect(lidDoc['weight'], isNull);
      expect(lidDoc['volume'], isNull);
    });

    test('skips duplicates based on existing products', () async {
      const companyId = 'company-abc';
      const createdBy = 'user-123';

      // Pre-populate existing product with same productCode
      await fakeFirestore
          .collection('companies/$companyId/product_types')
          .doc('existing-1')
          .set({
        'companyId': companyId,
        'name': 'Existing Cup',
        'productCode': 'CUP-100',
        'category': 'cups',
        'unitsPerBox': 50,
        'boxesPerPallet': 20,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'createdBy': 'someone',
      });

      final selectedTemplates = [
        TemplateProduct(
          id: 't1',
          name: 'Cup 100ml',
          productCode: 'CUP-100', // same productCode as existing
          category: 'cups',
          unitsPerBox: 50,
          boxesPerPallet: 20,
          businessType: 'packaging',
        ),
        TemplateProduct(
          id: 't2',
          name: 'Lid 100ml',
          productCode: 'LID-100', // new product
          category: 'lids',
          unitsPerBox: 100,
          boxesPerPallet: 25,
          businessType: 'packaging',
        ),
      ];

      final result = await service.importSelectedTemplates(
        companyId: companyId,
        createdBy: createdBy,
        selectedTemplates: selectedTemplates,
      );

      // Cup skipped (duplicate), Lid added
      expect(result.addedCount, equals(1));
      expect(result.skippedCount, equals(1));
      expect(result.errorCount, equals(0));

      // Verify only 2 docs total (1 existing + 1 new)
      final snapshot = await fakeFirestore
          .collection('companies/$companyId/product_types')
          .get();
      expect(snapshot.docs.length, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // 6.3.3 Тест дедупликации при повторном импорте
  // Validates: Requirements 5.5
  // ---------------------------------------------------------------------------
  group('6.3.3 — Repeated import deduplication (idempotent import)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TemplateService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = TemplateService(firestore: fakeFirestore);
    });

    test(
        'second import of same templates results in addedCount=0, skippedCount=N',
        () async {
      const companyId = 'company-xyz';
      const createdBy = 'user-456';

      final templates = [
        TemplateProduct(
          id: 't1',
          name: 'Cup 200ml',
          productCode: 'CUP-200',
          category: 'cups',
          unitsPerBox: 40,
          boxesPerPallet: 15,
          businessType: 'packaging',
        ),
        TemplateProduct(
          id: 't2',
          name: 'Plate Large',
          productCode: 'PLT-L',
          category: 'plates',
          unitsPerBox: 20,
          boxesPerPallet: 10,
          businessType: 'packaging',
        ),
        TemplateProduct(
          id: 't3',
          name: 'Bowl 500ml',
          productCode: 'BWL-500',
          category: 'bowls',
          unitsPerBox: 30,
          boxesPerPallet: 12,
          weight: 0.3,
          volume: 0.5,
          businessType: 'packaging',
        ),
      ];

      // First import — all should be added
      final firstResult = await service.importSelectedTemplates(
        companyId: companyId,
        createdBy: createdBy,
        selectedTemplates: templates,
      );

      expect(firstResult.addedCount, equals(3));
      expect(firstResult.skippedCount, equals(0));
      expect(firstResult.errorCount, equals(0));

      // Second import — all should be skipped as duplicates
      final secondResult = await service.importSelectedTemplates(
        companyId: companyId,
        createdBy: createdBy,
        selectedTemplates: templates,
      );

      expect(secondResult.addedCount, equals(0));
      expect(secondResult.skippedCount, equals(3));
      expect(secondResult.errorCount, equals(0));

      // Verify total documents in Firestore — still only 3
      final snapshot = await fakeFirestore
          .collection('companies/$companyId/product_types')
          .get();
      expect(snapshot.docs.length, equals(3));
    });
  });
}
