import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_type.dart';

/// Сервис управления типами товаров
class ProductTypeService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductTypeService({required this.companyId});

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('product_types');

  /// Получить все типы товаров компании
  Stream<List<ProductType>> getProductTypes({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _collection.orderBy('name');

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductType.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Получить типы товаров по категории
  Stream<List<ProductType>> getProductTypesByCategory(String category) {
    return _collection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductType.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Получить один тип товара
  Future<ProductType?> getProductType(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return ProductType.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Нормализация מק"ט: trim, uppercase, убрать двойные пробелы
  static String normalizeProductCode(String code) {
    return code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Проверить существует ли מק"ט в коллекции компании
  Future<bool> isProductCodeExists(String productCode) async {
    final normalized = normalizeProductCode(productCode);
    final snapshot = await _collection
        .where('productCode', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Создать тип товара (с проверкой дубликата מק"ט)
  Future<String> createProductType(ProductType productType) async {
    final normalized = normalizeProductCode(productType.productCode);
    if (await isProductCodeExists(normalized)) {
      throw Exception('DUPLICATE_PRODUCT_CODE:$normalized');
    }
    final normalizedProduct = ProductType(
      id: productType.id,
      companyId: productType.companyId,
      name: productType.name,
      productCode: normalized,
      category: productType.category,
      unitsPerBox: productType.unitsPerBox,
      boxesPerPallet: productType.boxesPerPallet,
      weight: productType.weight,
      volume: productType.volume,
      createdAt: productType.createdAt,
      createdBy: productType.createdBy,
    );
    final docRef = await _collection.add(normalizedProduct.toMap());
    print('✅ [ProductType] Created: ${normalizedProduct.name} (${docRef.id})');
    return docRef.id;
  }

  /// Обновить тип товара
  Future<void> updateProductType(String id, ProductType productType) async {
    await _collection.doc(id).update(productType.toMap());
    print('✅ [ProductType] Updated: ${productType.name}');
  }

  /// Удалить тип товара (мягкое удаление)
  Future<void> deleteProductType(String id) async {
    await _collection.doc(id).update({'isActive': false});
    print('🗑️ [ProductType] Deactivated: $id');
  }

  /// Жёсткое удаление (только если не используется)
  Future<void> hardDeleteProductType(String id) async {
    // TODO: Проверить что товар не используется в заказах
    await _collection.doc(id).delete();
    print('🗑️ [ProductType] Deleted: $id');
  }

  /// Базовые категории — всегда доступны в дропдауне
  static const List<String> baseCategories = [
    'general',
    'cups',
    'lids',
    'containers',
    'trays',
    'bottles',
    'bags',
    'boxes',
  ];

  /// Получить все категории (базовые + из товаров компании)
  Future<List<String>> getCategories() async {
    final snapshot = await _collection.get();
    final fromDb = snapshot.docs
        .map((doc) => doc.data()['category'] as String?)
        .where((cat) => cat != null && cat.isNotEmpty)
        .cast<String>()
        .toSet();
    final all = {...baseCategories, ...fromDb}.toList();
    all.sort();
    return all;
  }

  /// Импорт товаров из списка (для Excel/CSV)
  Future<void> importProductTypes(List<ProductType> products) async {
    final batch = _firestore.batch();

    for (final product in products) {
      final docRef = _collection.doc();
      batch.set(docRef, product.toMap());
    }

    await batch.commit();
    print('✅ [ProductType] Imported ${products.length} products');
  }
}
