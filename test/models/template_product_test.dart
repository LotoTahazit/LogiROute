import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/template_product.dart';

void main() {
  /// Helper: полный набор полей для валидного документа.
  Map<String, dynamic> fullMap({
    String name = 'כוס 8oz',
    String productCode = 'SKU-001',
    String category = 'cups',
    int unitsPerBox = 50,
    int boxesPerPallet = 40,
    double? weight = 0.15,
    double? volume = 0.25,
    String businessType = 'packaging',
  }) {
    return {
      'name': name,
      'productCode': productCode,
      'category': category,
      'unitsPerBox': unitsPerBox,
      'boxesPerPallet': boxesPerPallet,
      if (weight != null) 'weight': weight,
      if (volume != null) 'volume': volume,
      'businessType': businessType,
    };
  }

  const testId = 'tpl-123';

  group('TemplateProduct.fromMap', () {
    test('full set of fields → correct TemplateProduct object', () {
      final map = fullMap();
      final result = TemplateProduct.fromMap(map, testId);

      expect(result, isNotNull);
      expect(result!.id, testId);
      expect(result.name, 'כוס 8oz');
      expect(result.productCode, 'SKU-001');
      expect(result.category, 'cups');
      expect(result.unitsPerBox, 50);
      expect(result.boxesPerPallet, 40);
      expect(result.weight, 0.15);
      expect(result.volume, 0.25);
      expect(result.businessType, 'packaging');
    });

    test('missing required field "name" → returns null', () {
      final map = fullMap()..remove('name');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('missing required field "productCode" → returns null', () {
      final map = fullMap()..remove('productCode');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('missing required field "category" → returns null', () {
      final map = fullMap()..remove('category');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('missing required field "unitsPerBox" → returns null', () {
      final map = fullMap()..remove('unitsPerBox');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('missing required field "boxesPerPallet" → returns null', () {
      final map = fullMap()..remove('boxesPerPallet');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('missing required field "businessType" → returns null', () {
      final map = fullMap()..remove('businessType');
      expect(TemplateProduct.fromMap(map, testId), isNull);
    });

    test('optional fields weight/volume = null → still creates valid object',
        () {
      final map = fullMap(weight: null, volume: null);
      final result = TemplateProduct.fromMap(map, testId);

      expect(result, isNotNull);
      expect(result!.weight, isNull);
      expect(result.volume, isNull);
      // All required fields are still correct
      expect(result.name, 'כוס 8oz');
      expect(result.productCode, 'SKU-001');
      expect(result.category, 'cups');
      expect(result.unitsPerBox, 50);
      expect(result.boxesPerPallet, 40);
      expect(result.businessType, 'packaging');
    });

    test('optional fields weight/volume present → correctly mapped', () {
      final map = fullMap(weight: 1.5, volume: 3.75);
      final result = TemplateProduct.fromMap(map, testId);

      expect(result, isNotNull);
      expect(result!.weight, 1.5);
      expect(result.volume, 3.75);
    });
  });
}
