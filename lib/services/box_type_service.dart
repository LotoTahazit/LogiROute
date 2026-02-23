import 'package:cloud_firestore/cloud_firestore.dart';

class BoxTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String?
      companyId; // ID компании (опционально для обратной совместимости)

  BoxTypeService({this.companyId});

  // Получить все типы коробок из справочника для конкретной компании
  Future<List<Map<String, dynamic>>> getAllBoxTypes(
      [String? overrideCompanyId]) async {
    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      print('⚠️ Warning: companyId is null or empty in getAllBoxTypes');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('box_types')
          .where('companyId', isEqualTo: targetCompanyId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting box types: $e');
      return [];
    }
  }

  // Получить типы коробок в реальном времени для конкретной компании
  Stream<List<Map<String, dynamic>>> getBoxTypesStream(
      [String? overrideCompanyId]) {
    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      print('⚠️ Warning: companyId is null or empty in getBoxTypesStream');
      return Stream.value([]);
    }

    return _firestore
        .collection('box_types')
        .where('companyId', isEqualTo: targetCompanyId)
        .snapshots()
        .map((snapshot) {
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
    required String companyId, // ID компании - ОБЯЗАТЕЛЬНЫЙ
    int? volumeMl,
    int? quantityPerPallet,
    String? diameter,
    int? piecesPerBox,
    String? additionalInfo,
  }) async {
    try {
      // Проверяем, не существует ли уже такой מק"ט в этой компании
      final existing = await _firestore
          .collection('box_types')
          .where('productCode', isEqualTo: productCode)
          .where('companyId', isEqualTo: companyId)
          .get();

      if (existing.docs.isEmpty) {
        final data = {
          'productCode': productCode, // מק"ט - ПЕРВОЕ ПОЛЕ
          'type': type,
          'number': number,
          'companyId': companyId, // ID компании
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

        await _firestore.collection('box_types').add(data);
        print(
            '✅ Added box type: מק"ט $productCode ($type $number) for company $companyId');
      } else {
        print(
            'ℹ️ Box type already exists: מק"ט $productCode for company $companyId');
      }
    } catch (e) {
      print('❌ Error adding box type: $e');
      rethrow;
    }
  }

  // Удалить тип коробки из справочника
  Future<void> deleteBoxType(String id) async {
    try {
      await _firestore.collection('box_types').doc(id).delete();
      print('✅ Deleted box type: $id');
    } catch (e) {
      print('❌ Error deleting box type: $e');
      rethrow;
    }
  }

  // Обновить тип коробки
  Future<void> updateBoxType({
    required String id,
    required String type,
    required String number,
    required int volumeMl,
  }) async {
    try {
      await _firestore.collection('box_types').doc(id).update({
        'type': type,
        'number': number,
        'volumeMl': volumeMl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Updated box type: $id');
    } catch (e) {
      print('❌ Error updating box type: $e');
      rethrow;
    }
  }

  // Инициализация справочника (больше не нужна, пользователь сам добавляет)
  Future<void> initializeDefaultBoxTypes() async {
    // Справочник пустой при первом запуске
    // Пользователь добавляет типы по мере необходимости
    print('ℹ️ Box types collection ready (empty by default)');
  }

  // Получить доступные номера для конкретного типа и компании
  Future<List<Map<String, dynamic>>> getNumbersForType(
    String type,
    String companyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('box_types')
          .where('type', isEqualTo: type)
          .where('companyId', isEqualTo: companyId)
          .orderBy('number')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting numbers for type: $e');
      // Fallback: получаем без сортировки и сортируем на клиенте
      try {
        final snapshot = await _firestore
            .collection('box_types')
            .where('type', isEqualTo: type)
            .where('companyId', isEqualTo: companyId)
            .get();

        final results = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        results.sort((a, b) {
          final numA = int.tryParse(a['number'] as String) ?? 0;
          final numB = int.tryParse(b['number'] as String) ?? 0;
          return numA.compareTo(numB);
        });

        return results;
      } catch (e2) {
        print('Error in fallback query: $e2');
        return [];
      }
    }
  }

  // Получить уникальные типы (בביע, מכסה, כוס) для компании
  Future<List<String>> getUniqueTypes(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('box_types')
          .where('companyId', isEqualTo: companyId)
          .get();
      final types = snapshot.docs
          .map((doc) => doc.data()['type'] as String)
          .toSet()
          .toList();
      types.sort();
      return types;
    } catch (e) {
      print('Error getting unique types: $e');
      return ['בביע', 'מכסה', 'כוס']; // Fallback
    }
  }
}
