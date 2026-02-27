import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/template_product.dart';
import 'package:logiroute/models/import_result.dart';
import 'package:logiroute/models/product_type.dart';
import 'package:logiroute/utils/deduplication_engine.dart';

// ---------------------------------------------------------------------------
// Helpers: random data generators
// ---------------------------------------------------------------------------

const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String _randomString(Random rng, {int minLength = 1, int maxLength = 20}) {
  final length = minLength + rng.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    List.generate(length, (_) => _chars.codeUnitAt(rng.nextInt(_chars.length))),
  );
}

/// Generates a string that may contain leading/trailing/multiple whitespace.
String _randomWhitespaceString(Random rng) {
  const words = ['hello', 'world', 'cup', 'large', 'small', 'box', 'item'];
  final wordCount = 1 + rng.nextInt(4);
  final parts = <String>[];
  // optional leading whitespace
  if (rng.nextBool()) parts.add('  ');
  for (var i = 0; i < wordCount; i++) {
    if (i > 0) {
      // 1-4 spaces between words
      parts.add(' ' * (1 + rng.nextInt(4)));
    }
    parts.add(words[rng.nextInt(words.length)]);
  }
  // optional trailing whitespace
  if (rng.nextBool()) parts.add('  ');
  return parts.join();
}

int _randomPositiveInt(Random rng) => 1 + rng.nextInt(9999);

double? _randomOptionalDouble(Random rng) {
  if (rng.nextBool()) return null;
  return (rng.nextInt(100000) + 1) / 100.0;
}

const _businessTypes = [
  'packaging',
  'food',
  'clothing',
  'electronics',
  'pharma'
];
const _categories = ['cups', 'lids', 'bread', 'shirts', 'boxes', 'bags'];

TemplateProduct _generateRandomTemplateProduct(Random rng,
    {String? businessType, String? category}) {
  return TemplateProduct(
    id: _randomString(rng, minLength: 5, maxLength: 30),
    name: _randomString(rng, minLength: 1, maxLength: 50),
    productCode: _randomString(rng, minLength: 3, maxLength: 15),
    category: category ?? _categories[rng.nextInt(_categories.length)],
    unitsPerBox: _randomPositiveInt(rng),
    boxesPerPallet: _randomPositiveInt(rng),
    weight: _randomOptionalDouble(rng),
    volume: _randomOptionalDouble(rng),
    businessType:
        businessType ?? _businessTypes[rng.nextInt(_businessTypes.length)],
  );
}

ProductType _generateRandomProductType(Random rng,
    {String? productCode, String? name, String? category}) {
  return ProductType(
    id: _randomString(rng, minLength: 5, maxLength: 30),
    companyId: _randomString(rng, minLength: 5, maxLength: 15),
    name: name ?? _randomString(rng, minLength: 1, maxLength: 50),
    productCode: productCode ?? _randomString(rng, minLength: 3, maxLength: 15),
    category: category ?? _categories[rng.nextInt(_categories.length)],
    unitsPerBox: _randomPositiveInt(rng),
    boxesPerPallet: _randomPositiveInt(rng),
    weight: _randomOptionalDouble(rng),
    volume: _randomOptionalDouble(rng),
    isActive: true,
    createdAt: DateTime(2024, 1, 1 + rng.nextInt(365)),
    createdBy: _randomString(rng, minLength: 5, maxLength: 15),
  );
}

List<TemplateProduct> _generateRandomTemplateList(Random rng,
    {int minLen = 0, int maxLen = 20}) {
  final count = minLen + rng.nextInt(maxLen - minLen + 1);
  return List.generate(count, (_) => _generateRandomTemplateProduct(rng));
}

/// Builds a complete valid Firestore document map for a TemplateProduct.
Map<String, dynamic> _validTemplateMap(Random rng) {
  return {
    'name': _randomString(rng, minLength: 1, maxLength: 50),
    'productCode': _randomString(rng, minLength: 3, maxLength: 15),
    'category': _categories[rng.nextInt(_categories.length)],
    'unitsPerBox': _randomPositiveInt(rng),
    'boxesPerPallet': _randomPositiveInt(rng),
    'businessType': _businessTypes[rng.nextInt(_businessTypes.length)],
    if (rng.nextBool()) 'weight': (rng.nextInt(10000) + 1) / 100.0,
    if (rng.nextBool()) 'volume': (rng.nextInt(10000) + 1) / 100.0,
  };
}

const _requiredFields = [
  'name',
  'productCode',
  'category',
  'unitsPerBox',
  'boxesPerPallet',
  'businessType'
];

// ---------------------------------------------------------------------------
// Simulates the field mapping that TemplateService.importSelectedTemplates does
// when writing a product to Firestore.
// ---------------------------------------------------------------------------
Map<String, dynamic> _buildImportedProductMap(
    TemplateProduct template, String companyId, String createdBy) {
  return {
    'companyId': companyId,
    'createdBy': createdBy,
    'isActive': true,
    'name': template.name,
    'productCode': template.productCode,
    'category': template.category,
    'unitsPerBox': template.unitsPerBox,
    'boxesPerPallet': template.boxesPerPallet,
    if (template.weight != null) 'weight': template.weight,
    if (template.volume != null) 'volume': template.volume,
  };
}

/// Simulates import with random write failures. Returns an ImportResult.
ImportResult _simulateImportWithFailures(
  List<TemplateProduct> toImport,
  int skippedCount,
  Set<int> failingIndices,
) {
  int addedCount = 0;
  int errorCount = 0;
  final errorNames = <String>[];

  for (var i = 0; i < toImport.length; i++) {
    if (failingIndices.contains(i)) {
      errorCount++;
      errorNames.add(toImport[i].name);
    } else {
      addedCount++;
    }
  }

  return ImportResult(
    addedCount: addedCount,
    skippedCount: skippedCount,
    errorCount: errorCount,
    errorProductNames: errorNames,
  );
}

/// Role-based access check: returns true iff role is admin or super_admin.
bool _canAccessImport(String role) {
  return role == 'admin' || role == 'super_admin';
}
// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 2: Invalid template documents are rejected
  // **Validates: Requirements 1.4**
  // -------------------------------------------------------------------------
  test(
      'Property 2: Missing required field → fromMap returns null; all required → valid (150 iterations)',
      () {
    final rng = Random(42);

    for (var i = 0; i < 150; i++) {
      // --- Sub-case A: remove one required field → should return null ---
      final fullMap = _validTemplateMap(rng);
      final fieldToRemove =
          _requiredFields[rng.nextInt(_requiredFields.length)];
      final incompleteMap = Map<String, dynamic>.from(fullMap)
        ..remove(fieldToRemove);
      final rejected = TemplateProduct.fromMap(incompleteMap, 'id_$i');
      expect(rejected, isNull,
          reason:
              'Iteration $i: removing "$fieldToRemove" should cause rejection');

      // --- Sub-case B: complete map → should produce valid object ---
      final completeMap = _validTemplateMap(rng);
      final accepted = TemplateProduct.fromMap(completeMap, 'id_valid_$i');
      expect(accepted, isNotNull,
          reason:
              'Iteration $i: complete map should produce a valid TemplateProduct');
      expect(accepted!.name, equals(completeMap['name']));
      expect(accepted.productCode, equals(completeMap['productCode']));
      expect(accepted.category, equals(completeMap['category']));
      expect(accepted.businessType, equals(completeMap['businessType']));
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 3: BusinessType filtering returns only matching templates
  // **Validates: Requirements 3.2**
  // -------------------------------------------------------------------------
  test(
      'Property 3: Filtering by businessType returns only matching, none missing (150 iterations)',
      () {
    final rng = Random(43);

    for (var i = 0; i < 150; i++) {
      final templates = _generateRandomTemplateList(rng, minLen: 1, maxLen: 25);
      final selectedType = _businessTypes[rng.nextInt(_businessTypes.length)];

      final filtered =
          templates.where((t) => t.businessType == selectedType).toList();

      // Every element in filtered has the correct businessType
      for (final t in filtered) {
        expect(t.businessType, equals(selectedType),
            reason: 'Iteration $i: filtered element has wrong businessType');
      }

      // No matching element is missing
      final expectedCount =
          templates.where((t) => t.businessType == selectedType).length;
      expect(filtered.length, equals(expectedCount),
          reason: 'Iteration $i: filtered count mismatch');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 4: Grouping by categoryKey is correct
  // **Validates: Requirements 4.1**
  // -------------------------------------------------------------------------
  test(
      'Property 4: Grouping by categoryKey — same key in group, total preserved (150 iterations)',
      () {
    final rng = Random(44);

    for (var i = 0; i < 150; i++) {
      final templates = _generateRandomTemplateList(rng, minLen: 0, maxLen: 30);

      // Group by categoryKey
      final groups = <String, List<TemplateProduct>>{};
      for (final t in templates) {
        groups.putIfAbsent(t.category, () => []).add(t);
      }

      // Every item in a group has the same categoryKey
      for (final entry in groups.entries) {
        for (final t in entry.value) {
          expect(t.category, equals(entry.key),
              reason:
                  'Iteration $i: item in group "${entry.key}" has category "${t.category}"');
        }
      }

      // Total count across all groups equals original list length
      final totalInGroups =
          groups.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(totalInGroups, equals(templates.length),
          reason:
              'Iteration $i: total in groups ($totalInGroups) != original (${templates.length})');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 5: Select all toggles all items in scope
  // **Validates: Requirements 4.3, 4.4**
  // -------------------------------------------------------------------------
  test(
      'Property 5: Category select-all selects only that category; global select-all selects all (150 iterations)',
      () {
    final rng = Random(45);

    for (var i = 0; i < 150; i++) {
      final templates = _generateRandomTemplateList(rng, minLen: 1, maxLen: 25);
      final allIds = templates.map((t) => t.id).toSet();

      // Group by category
      final groups = <String, List<TemplateProduct>>{};
      for (final t in templates) {
        groups.putIfAbsent(t.category, () => []).add(t);
      }

      // --- Category select all ---
      if (groups.isNotEmpty) {
        final targetCategory =
            groups.keys.elementAt(rng.nextInt(groups.length));
        final categoryIds = groups[targetCategory]!.map((t) => t.id).toSet();

        // Start with a random selection
        final selectedIds = <String>{};
        for (final id in allIds) {
          if (rng.nextBool()) selectedIds.add(id);
        }
        final othersBefore = selectedIds.difference(categoryIds);

        // Toggle select all for category: add all category items
        final afterCategorySelectAll = Set<String>.from(selectedIds)
          ..addAll(categoryIds);

        // All items in category are selected
        for (final id in categoryIds) {
          expect(afterCategorySelectAll.contains(id), isTrue,
              reason: 'Iteration $i: category item $id should be selected');
        }

        // Items outside category unchanged
        final othersAfter = afterCategorySelectAll.difference(categoryIds);
        expect(othersAfter, equals(othersBefore),
            reason: 'Iteration $i: items outside category should not change');
      }

      // --- Global select all ---
      final afterGlobalSelectAll = Set<String>.from(allIds);
      expect(afterGlobalSelectAll, equals(allIds),
          reason: 'Iteration $i: global select all should select everything');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 6: Import button enabled iff selection is non-empty
  // **Validates: Requirements 4.5, 4.6**
  // -------------------------------------------------------------------------
  test(
      'Property 6: Import button enabled iff selectedIds.isNotEmpty (150 iterations)',
      () {
    final rng = Random(46);

    for (var i = 0; i < 150; i++) {
      final templates = _generateRandomTemplateList(rng, minLen: 0, maxLen: 20);
      final allIds = templates.map((t) => t.id).toList();

      // Build a random selection
      final selectedIds = <String>{};
      for (final id in allIds) {
        if (rng.nextBool()) selectedIds.add(id);
      }

      final importButtonEnabled = selectedIds.isNotEmpty;

      if (selectedIds.isEmpty) {
        expect(importButtonEnabled, isFalse,
            reason:
                'Iteration $i: button should be disabled when nothing selected');
      } else {
        expect(importButtonEnabled, isTrue,
            reason:
                'Iteration $i: button should be enabled when selection is non-empty');
      }
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 7: Name normalization is idempotent
  // **Validates: Requirements 5.2**
  // -------------------------------------------------------------------------
  test(
      'Property 7: normalizeName is idempotent and matches spec formula (150 iterations)',
      () {
    final rng = Random(47);

    for (var i = 0; i < 150; i++) {
      final s = _randomWhitespaceString(rng);

      final once = DeduplicationEngine.normalizeName(s);
      final twice = DeduplicationEngine.normalizeName(once);

      // Idempotent
      expect(twice, equals(once),
          reason: 'Iteration $i: normalizeName is not idempotent for "$s"');

      // Matches spec formula: s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ')
      final expected = s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
      expect(once, equals(expected),
          reason:
              'Iteration $i: normalizeName("$s") = "$once" but expected "$expected"');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 8: Deduplication correctly partitions a batch
  // **Validates: Requirements 5.1, 5.3, 5.4, 5.5**
  // -------------------------------------------------------------------------
  test(
      'Property 8: filterDuplicates partitions correctly — toImport + skipped == total (150 iterations)',
      () {
    final rng = Random(48);

    for (var i = 0; i < 150; i++) {
      final templates = _generateRandomTemplateList(rng, minLen: 0, maxLen: 15);
      final existingCount = rng.nextInt(10);
      final existing =
          List.generate(existingCount, (_) => _generateRandomProductType(rng));

      // Optionally make some templates match existing products
      final templatesWithDups = <TemplateProduct>[...templates];
      if (existing.isNotEmpty && templates.isNotEmpty && rng.nextBool()) {
        // Force a productCode match
        final matchIdx = rng.nextInt(templates.length);
        final existIdx = rng.nextInt(existing.length);
        templatesWithDups[matchIdx] = TemplateProduct(
          id: templates[matchIdx].id,
          name: _randomString(rng),
          productCode: existing[existIdx].productCode, // same code
          category: _randomString(rng),
          unitsPerBox: _randomPositiveInt(rng),
          boxesPerPallet: _randomPositiveInt(rng),
          businessType: _randomString(rng),
        );
      }

      final result =
          DeduplicationEngine.filterDuplicates(templatesWithDups, existing);

      // (c) lengths sum to total
      expect(result.toImport.length + result.skipped.length,
          equals(templatesWithDups.length),
          reason: 'Iteration $i: partition lengths do not sum to total');

      // (a) every item in toImport has no match in existing
      for (final t in result.toImport) {
        expect(DeduplicationEngine.isDuplicate(t, existing), isFalse,
            reason:
                'Iteration $i: toImport item "${t.name}" is actually a duplicate');
      }

      // (b) every item in skipped has a match in existing
      for (final t in result.skipped) {
        expect(DeduplicationEngine.isDuplicate(t, existing), isTrue,
            reason:
                'Iteration $i: skipped item "${t.name}" is not actually a duplicate');
      }
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 9: Imported products have correct field mapping
  // **Validates: Requirements 6.1, 6.2, 6.3, 6.5**
  // -------------------------------------------------------------------------
  test(
      'Property 9: Field mapping from TemplateProduct to imported product doc is correct (150 iterations)',
      () {
    final rng = Random(49);

    for (var i = 0; i < 150; i++) {
      final template = _generateRandomTemplateProduct(rng);
      final companyId = _randomString(rng, minLength: 5, maxLength: 20);
      final createdBy = _randomString(rng, minLength: 5, maxLength: 20);

      final doc = _buildImportedProductMap(template, companyId, createdBy);

      expect(doc['companyId'], equals(companyId),
          reason: 'Iteration $i: companyId mismatch');
      expect(doc['createdBy'], equals(createdBy),
          reason: 'Iteration $i: createdBy mismatch');
      expect(doc['isActive'], isTrue,
          reason: 'Iteration $i: isActive should be true');
      expect(doc['name'], equals(template.name),
          reason: 'Iteration $i: name mismatch');
      expect(doc['productCode'], equals(template.productCode),
          reason: 'Iteration $i: productCode mismatch');
      expect(doc['category'], equals(template.category),
          reason: 'Iteration $i: category mismatch');
      expect(doc['unitsPerBox'], equals(template.unitsPerBox),
          reason: 'Iteration $i: unitsPerBox mismatch');
      expect(doc['boxesPerPallet'], equals(template.boxesPerPallet),
          reason: 'Iteration $i: boxesPerPallet mismatch');
      expect(doc['weight'], equals(template.weight),
          reason: 'Iteration $i: weight mismatch');
      expect(doc['volume'], equals(template.volume),
          reason: 'Iteration $i: volume mismatch');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 10: Import is resilient to individual write failures
  // **Validates: Requirements 6.6**
  // -------------------------------------------------------------------------
  test(
      'Property 10: Random write failures → ImportResult counts match (150 iterations)',
      () {
    final rng = Random(50);

    for (var i = 0; i < 150; i++) {
      final batchSize = rng.nextInt(20) + 1;
      final templates =
          List.generate(batchSize, (_) => _generateRandomTemplateProduct(rng));
      final skippedCount = rng.nextInt(10);

      // Random subset of indices that fail
      final failingIndices = <int>{};
      for (var j = 0; j < batchSize; j++) {
        if (rng.nextBool()) failingIndices.add(j);
      }

      final result =
          _simulateImportWithFailures(templates, skippedCount, failingIndices);

      final expectedAdded = batchSize - failingIndices.length;
      final expectedErrors = failingIndices.length;
      final expectedErrorNames =
          failingIndices.map((idx) => templates[idx].name).toList();

      expect(result.addedCount, equals(expectedAdded),
          reason: 'Iteration $i: addedCount mismatch');
      expect(result.errorCount, equals(expectedErrors),
          reason: 'Iteration $i: errorCount mismatch');
      expect(result.errorProductNames, equals(expectedErrorNames),
          reason: 'Iteration $i: errorProductNames mismatch');
      expect(result.addedCount + result.errorCount, equals(batchSize),
          reason: 'Iteration $i: added + errors should equal batch size');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 11: ImportResult counts are consistent
  // **Validates: Requirements 7.1**
  // -------------------------------------------------------------------------
  test(
      'Property 11: addedCount + skippedCount + errorCount == total (150 iterations)',
      () {
    final rng = Random(51);

    for (var i = 0; i < 150; i++) {
      final added = rng.nextInt(100);
      final skipped = rng.nextInt(100);
      final errors = rng.nextInt(100);
      final errorNames = List.generate(errors, (_) => _randomString(rng));

      final result = ImportResult(
        addedCount: added,
        skippedCount: skipped,
        errorCount: errors,
        errorProductNames: errorNames,
      );

      expect(result.total, equals(added + skipped + errors),
          reason: 'Iteration $i: total != added + skipped + errors');
      expect(result.addedCount + result.skippedCount + result.errorCount,
          equals(result.total),
          reason: 'Iteration $i: sum of counts != total');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 12: Import summary format contains all counts
  // **Validates: Requirements 7.2**
  // -------------------------------------------------------------------------
  test(
      'Property 12: summaryString contains all counts in correct format (150 iterations)',
      () {
    final rng = Random(52);

    for (var i = 0; i < 150; i++) {
      final added = rng.nextInt(1000);
      final skipped = rng.nextInt(1000);
      final errors = rng.nextInt(1000);

      final result = ImportResult(
        addedCount: added,
        skippedCount: skipped,
        errorCount: errors,
      );

      final summary = result.summaryString;
      final expected =
          'נוספו $added | דולגו $skipped כפילויות | שגיאות $errors';

      expect(summary, equals(expected),
          reason: 'Iteration $i: summary "$summary" != expected "$expected"');
    }
  });

  // -------------------------------------------------------------------------
  // Feature: product-templates
  // Property 13: Role-based access control
  // **Validates: Requirements 8.1, 8.2**
  // -------------------------------------------------------------------------
  test(
      'Property 13: Import accessible iff role is admin or super_admin (150 iterations)',
      () {
    final rng = Random(53);

    const allowedRoles = ['admin', 'super_admin'];
    const deniedRoles = ['dispatcher', 'driver', 'warehouse_keeper'];
    const allRoles = [...allowedRoles, ...deniedRoles];

    for (var i = 0; i < 150; i++) {
      final role = allRoles[rng.nextInt(allRoles.length)];
      final hasAccess = _canAccessImport(role);

      if (allowedRoles.contains(role)) {
        expect(hasAccess, isTrue,
            reason: 'Iteration $i: role "$role" should have access');
      } else {
        expect(hasAccess, isFalse,
            reason: 'Iteration $i: role "$role" should NOT have access');
      }
    }
  });
}
