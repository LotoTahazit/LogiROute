import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price.dart';

class PriceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все цены
  Future<List<Price>> getAllPrices() async {
    try {
      final snapshot = await _firestore.collection('prices').get();
      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Price] Error getting prices: $e');
      return [];
    }
  }

  /// Получить цены в реальном времени
  Stream<List<Price>> getPricesStream() {
    return _firestore.collection('prices').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Получить цену для конкретного товара
  Future<Price?> getPrice(String type, String number) async {
    try {
      final id = Price.generateId(type, number);
      final doc = await _firestore.collection('prices').doc(id).get();

      if (doc.exists) {
        return Price.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ [Price] Error getting price for $type $number: $e');
      return null;
    }
  }

  /// Установить/обновить цену
  Future<void> setPrice({
    required String type,
    required String number,
    required double priceBeforeVAT,
    required String userName,
  }) async {
    try {
      final id = Price.generateId(type, number);

      final data = {
        'type': type,
        'number': number,
        'priceBeforeVAT': priceBeforeVAT,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userName,
      };

      await _firestore
          .collection('prices')
          .doc(id)
          .set(data, SetOptions(merge: true));

      print('✅ [Price] Updated price for $type $number: ₪$priceBeforeVAT');
    } catch (e) {
      print('❌ [Price] Error setting price: $e');
      rethrow;
    }
  }

  /// Удалить цену
  Future<void> deletePrice(String id) async {
    try {
      await _firestore.collection('prices').doc(id).delete();
      print('✅ [Price] Deleted price: $id');
    } catch (e) {
      print('❌ [Price] Error deleting price: $e');
      rethrow;
    }
  }

  /// Получить цены для списка товаров
  Future<Map<String, double>> getPricesForItems(
    List<Map<String, String>> items,
  ) async {
    try {
      final Map<String, double> prices = {};

      for (final item in items) {
        final type = item['type']!;
        final number = item['number']!;
        final price = await getPrice(type, number);

        if (price != null) {
          prices[Price.generateId(type, number)] = price.priceBeforeVAT;
        }
      }

      return prices;
    } catch (e) {
      print('❌ [Price] Error getting prices for items: $e');
      return {};
    }
  }
}
