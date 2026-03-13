import 'package:cloud_firestore/cloud_firestore.dart';

class BoxTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  // ✅ Статический кеш для всех компаний (бесконечный - очищается только при добавлении)
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration =
      Duration(days: 365); // Практически бесконечный

  BoxTypeService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию box_types компании
  CollectionReference<Map<String, dynamic>> _boxTypesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
        .collection('box_types');
  }

  // Получить все типы коробок из справочника для конкретной компании
  Future<List<Map<String, dynamic>>> getAllBoxTypes(
      [String? overrideCompanyId]) async {
    try {
      // ✅ Проверяем кеш
      final cacheKey = companyId;
      final cachedData = _cache[cacheKey];
      final cacheTime = _cacheTimestamps[cacheKey];

      if (cachedData != null &&
          cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        print(
            '💾 [BoxType] Using cached data for $companyId (${cachedData.length} items)');
        return cachedData;
      }

      // Загружаем из Firestore
      final snapshot = await _boxTypesCollection().get();
      final data = snapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id;
        return docData;
      }).toList();

      // ✅ Сохраняем в кеш
      _cache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();

      print(
          '📊 [BoxType] Loaded ${data.length} box types from companies/$companyId/box_types (cached)');
      return data;
    } catch (e) {
      print('❌ [BoxType] Error getting box types: $e');
      return [];
    }
  }

  /// Очистить кеш для конкретной компании
  static void clearCache(String companyId) {
    _cache.remove(companyId);
    _cacheTimestamps.remove(companyId);
    print('🗑️ [BoxType] Cache cleared for $companyId');
  }

  /// Очистить весь кеш
  static void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('🗑️ [BoxType] All cache cleared');
  }

  // Получить типы коробок в реальном времени для конкретной компании
  Stream<List<Map<String, dynamic>>> getBoxTypesStream(
      [String? overrideCompanyId]) {
    print('📡 [BoxType] Starting stream for companies/$companyId/box_types');
    return _boxTypesCollection().snapshots().map((snapshot) {
      print('📊 [BoxType] Stream update: ${snapshot.docs.length} box types');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Добавить новый тип коробки в справочник
  Future<void> addBoxType({
    required String productCode, // מק"ט - ПЕРВЫЙ ПАРАМЕТР
    required String type,
    required String number,
    String? companyId, // Игнорируется - используется из конструктора
    int? volumeMl,
    int? quantityPerPallet,
    String? diameter,
    int? piecesPerBox,
    String? additionalInfo,
  }) async {
    try {
      // Проверяем, не существует ли уже такой מק"ט в этой компании
      final existing = await _boxTypesCollection()
          .where('productCode', isEqualTo: productCode)
          .get();

      if (existing.docs.isEmpty) {
        final data = {
          'productCode': productCode, // מק"ט - ПЕРВОЕ ПОЛЕ
          'type': type,
          'number': number,
          'companyId': this.companyId, // Сохраняем для обратной совместимости
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Добавляем опциональные поля только если они не null
        if (volumeMl != null) data['volumeMl'] = volumeMl;
        if (quantityPerPallet != null) {
          data['quantityPerPallet'] = quantityPerPallet;
        }
        if (diameter != null) data['diameter'] = diameter;
        if (piecesPerBox != null) data['piecesPerBox'] = piecesPerBox;
        if (additionalInfo != null) data['additionalInfo'] = additionalInfo;

        await _boxTypesCollection().add(data);

        // ✅ Очищаем кеш после добавления
        clearCache(this.companyId);

        print(
            '✅ [BoxType] Added: מק"ט $productCode ($type $number) in companies/${this.companyId}/box_types');
      } else {
        print('ℹ️ [BoxType] Already exists: מק"ט $productCode');
      }
    } catch (e) {
      print('❌ [BoxType] Error adding box type: $e');
      rethrow;
    }
  }

  // Удалить тип коробки из справочника
  Future<void> deleteBoxType(String id) async {
    try {
      await _boxTypesCollection().doc(id).delete();
      print('✅ [BoxType] Deleted: $id from companies/$companyId/box_types');
    } catch (e) {
      print('❌ [BoxType] Error deleting box type: $e');
      rethrow;
    }
  }

  // Обновить тип коробки
  Future<void> updateBoxType({
    required String id,
    required String productCode,
    required String type,
    required String number,
    int? volumeMl,
    int? quantityPerPallet,
    String? diameter,
    int? piecesPerBox,
    String? additionalInfo,
  }) async {
    try {
      final data = <String, dynamic>{
        'productCode': productCode,
        'type': type,
        'number': number,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (volumeMl != null) data['volumeMl'] = volumeMl;
      if (quantityPerPallet != null) {
        data['quantityPerPallet'] = quantityPerPallet;
      }
      if (diameter != null) data['diameter'] = diameter;
      if (piecesPerBox != null) data['piecesPerBox'] = piecesPerBox;
      if (additionalInfo != null) data['additionalInfo'] = additionalInfo;

      await _boxTypesCollection().doc(id).update(data);
      print('✅ [BoxType] Updated: $id in companies/$companyId/box_types');
    } catch (e) {
      print('❌ [BoxType] Error updating box type: $e');
      rethrow;
    }
  }

  // Инициализация справочника (больше не нужна, пользователь сам добавляет)
  Future<void> initializeDefaultBoxTypes() async {
    print('ℹ️ [BoxType] Box types collection ready (empty by default)');
  }

  // Получить доступные номера для конкретного типа и компании
  Future<List<Map<String, dynamic>>> getNumbersForType(
    String type, [
    String? overrideCompanyId,
  ]) async {
    try {
      // ✅ Используем кэшированные данные из getAllBoxTypes
      final allBoxTypes = await getAllBoxTypes();

      final results =
          allBoxTypes.where((item) => item['type'] == type).toList();

      // Сортируем по номеру
      results.sort((a, b) {
        final numA = int.tryParse(a['number'] as String) ?? 0;
        final numB = int.tryParse(b['number'] as String) ?? 0;
        return numA.compareTo(numB);
      });

      print('📊 [BoxType] Found ${results.length} numbers for type $type');
      return results;
    } catch (e) {
      print('❌ [BoxType] Error getting numbers for type: $e');
      return [];
    }
  }

  // Получить уникальные типы (בביע, מכסה, כוס) для компании
  Future<List<String>> getUniqueTypes([String? overrideCompanyId]) async {
    try {
      // ✅ Используем кэшированные данные из getAllBoxTypes
      final allBoxTypes = await getAllBoxTypes();

      final types =
          allBoxTypes.map((item) => item['type'] as String).toSet().toList();
      types.sort();
      print('📊 [BoxType] Found ${types.length} unique types');
      return types;
    } catch (e) {
      print('❌ [BoxType] Error getting unique types: $e');
      return ['בביע', 'מכסה', 'כוס']; // Fallback
    }
  }
}
