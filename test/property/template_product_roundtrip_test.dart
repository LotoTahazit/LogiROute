import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/template_product.dart';

/// Generates a random string of [length] from alphanumeric + Hebrew-like chars.
String _randomString(Random rng, {int minLength = 1, int maxLength = 20}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_';
  final length = minLength + rng.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// Generates a random positive int (1..9999).
int _randomPositiveInt(Random rng) => 1 + rng.nextInt(9999);

/// Generates a random positive double or null (50% chance of null).
double? _randomOptionalDouble(Random rng) {
  if (rng.nextBool()) return null;
  return (rng.nextInt(100000) + 1) / 100.0; // 0.01 .. 1000.00
}

/// Generates a random TemplateProduct with random field values.
TemplateProduct generateRandomTemplateProduct(Random rng) {
  return TemplateProduct(
    id: _randomString(rng, minLength: 5, maxLength: 30),
    name: _randomString(rng, minLength: 1, maxLength: 50),
    productCode: _randomString(rng, minLength: 3, maxLength: 15),
    category: _randomString(rng, minLength: 2, maxLength: 20),
    unitsPerBox: _randomPositiveInt(rng),
    boxesPerPallet: _randomPositiveInt(rng),
    weight: _randomOptionalDouble(rng),
    volume: _randomOptionalDouble(rng),
    businessType: _randomString(rng, minLength: 3, maxLength: 15),
  );
}

void main() {
  // Feature: product-templates, Property 1: TemplateProduct round-trip serialization
  // **Validates: Requirements 1.3**
  test(
      'TemplateProduct round-trip: toMap then fromMap preserves all fields (100+ iterations)',
      () {
    final rng = Random(42); // fixed seed for reproducibility

    for (var i = 0; i < 150; i++) {
      final template = generateRandomTemplateProduct(rng);
      final map = template.toMap();
      final restored = TemplateProduct.fromMap(map, template.id);

      expect(restored, isNotNull,
          reason: 'Iteration $i: fromMap returned null');
      expect(restored, equals(template),
          reason: 'Iteration $i: round-trip failed for $template');
    }
  });
}
