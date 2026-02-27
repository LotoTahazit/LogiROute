import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/import_result.dart';
import '../models/product_type.dart';
import '../models/template_product.dart';
import '../utils/deduplication_engine.dart';

/// Сервис для работы с глобальными шаблонами товаров из /product_templates/.
/// Только чтение — запись в /product_templates/ запрещена с клиента.
class TemplateService {
  final FirebaseFirestore _firestore;

  /// Creates a [TemplateService].
  /// Accepts an optional [FirebaseFirestore] instance for testing.
  TemplateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _templatesCollection =>
      _firestore.collection('product_templates');

  /// Получить список уникальных businessType из /product_templates/.
  Future<List<String>> getAvailableBusinessTypes() async {
    try {
      final snapshot = await _templatesCollection.get();
      final businessTypes = snapshot.docs
          .map((doc) => doc.data()['businessType'] as String?)
          .where((type) => type != null && type.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      businessTypes.sort();
      return businessTypes;
    } catch (e) {
      print('❌ [TemplateService] Error getting business types: $e');
      return [];
    }
  }

  /// Получить шаблоны по businessType.
  /// Пропускает невалидные документы (где fromMap возвращает null).
  Future<List<TemplateProduct>> getTemplatesByBusinessType(
      String businessType) async {
    try {
      final snapshot = await _templatesCollection
          .where('businessType', isEqualTo: businessType)
          .get();

      final templates = <TemplateProduct>[];
      for (final doc in snapshot.docs) {
        final template = TemplateProduct.fromMap(doc.data(), doc.id);
        if (template != null) {
          templates.add(template);
        } else {
          print(
              '⚠️ [TemplateService] Skipping invalid template document: ${doc.id}');
        }
      }
      return templates;
    } catch (e) {
      print(
          '❌ [TemplateService] Error getting templates for businessType "$businessType": $e');
      return [];
    }
  }

  /// Импортировать выбранные шаблоны в коллекцию компании.
  ///
  /// Загружает существующие товары, дедуплицирует, записывает поштучно.
  /// При ошибке записи одного товара — продолжает импорт остальных.
  /// Возвращает [ImportResult] с итогами.
  Future<ImportResult> importSelectedTemplates({
    required String companyId,
    required String createdBy,
    required List<TemplateProduct> selectedTemplates,
  }) async {
    if (companyId.isEmpty) {
      throw ArgumentError('companyId cannot be empty');
    }

    print(
        'ℹ️ [TemplateService] Import started: ${selectedTemplates.length} templates selected for company $companyId');

    final productTypesRef =
        _firestore.collection('companies/$companyId/product_types');

    // Загрузить существующие товары компании
    final existingSnapshot = await productTypesRef.get();
    final existingProducts = existingSnapshot.docs
        .map((doc) => ProductType.fromMap(doc.data(), doc.id))
        .toList();

    // Дедупликация
    final (:toImport, :skipped) = DeduplicationEngine.filterDuplicates(
        selectedTemplates, existingProducts);

    print(
        'ℹ️ [TemplateService] Deduplication: ${skipped.length} duplicates skipped, ${toImport.length} to import');

    var addedCount = 0;
    var errorCount = 0;
    final errorProductNames = <String>[];

    // Поштучная запись каждого не-дубликата
    for (final template in toImport) {
      try {
        await productTypesRef.add({
          'companyId': companyId,
          'createdBy': createdBy,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'name': template.name,
          'productCode': template.productCode,
          'category': template.category,
          'unitsPerBox': template.unitsPerBox,
          'boxesPerPallet': template.boxesPerPallet,
          if (template.weight != null) 'weight': template.weight,
          if (template.volume != null) 'volume': template.volume,
        });
        addedCount++;
      } catch (e) {
        errorCount++;
        errorProductNames.add(template.name);
        print('❌ [TemplateService] Error importing "${template.name}": $e');
      }
    }

    final result = ImportResult(
      addedCount: addedCount,
      skippedCount: skipped.length,
      errorCount: errorCount,
      errorProductNames: errorProductNames,
    );

    print(
        '✅ [TemplateService] Import completed: added=${result.addedCount}, skipped=${result.skippedCount}, errors=${result.errorCount}');

    return result;
  }
}
