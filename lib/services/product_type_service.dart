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

  /// Создать тип товара
  Future<String> createProductType(ProductType productType) async {
    final docRef = await _collection.add(productType.toMap());
    print('✅ [ProductType] Created: ${productType.name} (${docRef.id})');
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

  /// Получить все категории
  Future<List<String>> getCategories() async {
    final snapshot = await _collection.get();
    final categories = snapshot.docs
        .map((doc) => doc.data()['category'] as String?)
        .where((cat) => cat != null && cat.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
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

  /// Создать шаблонные товары для типа бизнеса
  Future<void> createTemplateProducts(
      String businessType, String createdBy) async {
    List<ProductType> templates = [];

    switch (businessType) {
      case 'packaging':
        templates = [
          ProductType(
            id: '',
            companyId: companyId,
            name: 'גביע 100',
            productCode: '1001',
            category: 'cups',
            unitsPerBox: 20,
            boxesPerPallet: 50,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
          ProductType(
            id: '',
            companyId: companyId,
            name: 'גביע 250',
            productCode: '1002',
            category: 'cups',
            unitsPerBox: 20,
            boxesPerPallet: 40,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
          ProductType(
            id: '',
            companyId: companyId,
            name: 'מכסה שטוח',
            productCode: '1030',
            category: 'lids',
            unitsPerBox: 60,
            boxesPerPallet: 40,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
        ];
        break;
      case 'food':
        templates = [
          ProductType(
            id: '',
            companyId: companyId,
            name: 'לחם לבן',
            productCode: '2001',
            category: 'bread',
            unitsPerBox: 10,
            boxesPerPallet: 30,
            weight: 0.5,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
          ProductType(
            id: '',
            companyId: companyId,
            name: 'חלב 1 ליטר',
            productCode: '2002',
            category: 'dairy',
            unitsPerBox: 12,
            boxesPerPallet: 40,
            weight: 1.0,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
        ];
        break;
      case 'clothing':
        templates = [
          ProductType(
            id: '',
            companyId: companyId,
            name: 'חולצה S',
            productCode: '3001',
            category: 'shirts',
            unitsPerBox: 10,
            boxesPerPallet: 20,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
          ProductType(
            id: '',
            companyId: companyId,
            name: 'חולצה M',
            productCode: '3002',
            category: 'shirts',
            unitsPerBox: 10,
            boxesPerPallet: 20,
            createdAt: DateTime.now(),
            createdBy: createdBy,
          ),
        ];
        break;
    }

    if (templates.isNotEmpty) {
      await importProductTypes(templates);
    }
  }
}
