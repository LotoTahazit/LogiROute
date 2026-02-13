import 'package:cloud_firestore/cloud_firestore.dart';

class BoxTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить все типы коробок из справочника
  Future<List<Map<String, dynamic>>> getAllBoxTypes() async {
    try {
      final snapshot = await _firestore.collection('box_types').get();
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

  // Получить типы коробок в реальном времени
  Stream<List<Map<String, dynamic>>> getBoxTypesStream() {
    return _firestore.collection('box_types').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Добавить новый тип коробки в справочник
  Future<void> addBoxType({
    required String type,
    required String number,
    int? volumeMl,
    int? quantityPerPallet,
    String? diameter,
    int? piecesPerBox,
    String? additionalInfo,
  }) async {
    try {
      // Проверяем, не существует ли уже такая комбинация
      final existing = await _firestore
          .collection('box_types')
          .where('type', isEqualTo: type)
          .where('number', isEqualTo: number)
          .get();

      if (existing.docs.isEmpty) {
        final data = {
          'type': type,
          'number': number,
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
        print('✅ Added box type: $type $number');
      } else {
        print('ℹ️ Box type already exists: $type $number');
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

  // Получить доступные номера для конкретного типа
  Future<List<Map<String, dynamic>>> getNumbersForType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('box_types')
          .where('type', isEqualTo: type)
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

  // Получить уникальные типы (בביע, מכסה, כוס)
  Future<List<String>> getUniqueTypes() async {
    try {
      final snapshot = await _firestore.collection('box_types').get();
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
