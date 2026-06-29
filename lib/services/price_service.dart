import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price.dart';

class PriceService {
  static const int defaultListLimit = 300;

  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PriceService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию цен компании
  CollectionReference<Map<String, dynamic>> _pricesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('prices');
  }

  /// Список цен (bounded).
  Future<List<Price>> getAllPrices({int limit = defaultListLimit}) async {
    try {
      final snapshot =
          await _pricesCollection().orderBy('type').limit(limit).get();
      print(
          '📊 [Price] Loaded ${snapshot.docs.length} prices from companies/$companyId/prices');
      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Price] Error getting prices: $e');
      return [];
    }
  }

  /// Stream цен (bounded).
  Stream<List<Price>> getPricesStream({int limit = defaultListLimit}) {
    print('📡 [Price] Starting stream for companies/$companyId/prices');
    return _pricesCollection()
        .orderBy('type')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      print('📊 [Price] Stream update: ${snapshot.docs.length} prices');
      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Получить цену для конкретного товара
  Future<Price?> getPrice(String type, String number) async {
    try {
      final id = Price.generateId(companyId, type, number);
      final doc = await _pricesCollection().doc(id).get();

      if (doc.exists) {
        print(
            '✅ [Price] Found price for $type $number in companies/$companyId/prices');
        return Price.fromMap(doc.data()!, doc.id);
      }
      print(
          '⚠️ [Price] Price not found for $type $number in companies/$companyId/prices');
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
      final id = Price.generateId(companyId, type, number);

      final data = {
        'companyId': companyId,
        'type': type,
        'number': number,
        'priceBeforeVAT': priceBeforeVAT,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userName,
      };

      await _pricesCollection().doc(id).set(data, SetOptions(merge: true));

      print(
          '✅ [Price] Updated price for $type $number: ₪$priceBeforeVAT in companies/$companyId/prices');
    } catch (e) {
      print('❌ [Price] Error setting price: $e');
      rethrow;
    }
  }

  /// Удалить цену
  Future<void> deletePrice(String id) async {
    try {
      await _pricesCollection().doc(id).delete();
      print('✅ [Price] Deleted price: $id from companies/$companyId/prices');
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
          prices[Price.generateId(companyId, type, number)] =
              price.priceBeforeVAT;
        }
      }

      return prices;
    } catch (e) {
      print('❌ [Price] Error getting prices for items: $e');
      return {};
    }
  }
}
