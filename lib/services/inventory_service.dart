import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/box_type.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить товар (прибавить к существующему)
  Future<void> addInventory({
    required String type,
    required String number,
    int? volumeMl,
    required int quantity,
    required int quantityPerPallet,
    required String userName,
    String? diameter,
    String? volume,
    int? piecesPerBox,
    String? additionalInfo,
  }) async {
    return updateInventory(
      type: type,
      number: number,
      volumeMl: volumeMl,
      quantity: quantity,
      quantityPerPallet: quantityPerPallet,
      userName: userName,
      diameter: diameter,
      volume: volume,
      piecesPerBox: piecesPerBox,
      additionalInfo: additionalInfo,
      addToExisting: true,
    );
  }

  /// Обновить остаток товара (или добавить новый)
  Future<void> updateInventory({
    required String type,
    required String number,
    int? volumeMl,
    required int quantity,
    required int quantityPerPallet,
    required String userName,
    String? diameter,
    String? volume,
    int? piecesPerBox,
    String? additionalInfo,
    bool addToExisting = false, // Флаг: прибавлять к существующему или заменить
  }) async {
    try {
      final id = InventoryItem.generateId(type, number);

      int finalQuantity = quantity;

      // Если нужно прибавить к существующему
      if (addToExisting) {
        final doc = await _firestore.collection('inventory').doc(id).get();
        if (doc.exists) {
          final currentQty = doc.data()!['quantity'] as int;
          finalQuantity = currentQty + quantity;
          print(
              '➕ [Inventory] Adding $quantity to existing $currentQty = $finalQuantity');
        }
      }

      final data = {
        'type': type,
        'number': number,
        'quantity': finalQuantity,
        'quantityPerPallet': quantityPerPallet,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userName,
      };

      if (volumeMl != null) data['volumeMl'] = volumeMl;
      if (diameter != null && diameter.isNotEmpty) data['diameter'] = diameter;
      if (volume != null && volume.isNotEmpty) data['volume'] = volume;
      if (piecesPerBox != null) data['piecesPerBox'] = piecesPerBox;
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        data['additionalInfo'] = additionalInfo;
      }

      await _firestore.collection('inventory').doc(id).set(
            data,
            SetOptions(merge: true),
          );

      print('✅ [Inventory] Updated: $type $number = $finalQuantity יח\'');
    } catch (e) {
      print('❌ [Inventory] Error updating inventory: $e');
      rethrow;
    }
  }

  /// Получить все товары на складе
  Future<List<InventoryItem>> getInventory() async {
    try {
      final snapshot = await _firestore.collection('inventory').get();

      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Inventory] Error getting inventory: $e');
      return [];
    }
  }

  /// Получить товары в реальном времени
  /// ⚡ OPTIMIZED: Added limit to prevent excessive reads
  Stream<List<InventoryItem>> getInventoryStream({int limit = 200}) {
    print('📊 [Inventory] Starting stream with limit: $limit');
    return _firestore
        .collection('inventory')
        .limit(limit) // ✅ Limit to prevent reading entire collection
        .snapshots()
        .map((snapshot) {
      print('📊 [Inventory] Stream update: ${snapshot.docs.length} items');
      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Проверить доступность товара для заказа
  Future<Map<String, dynamic>> checkAvailability(List<BoxType> boxTypes) async {
    try {
      final inventory = await getInventory();

      // Группируем запрошенные коробки по типу и номеру
      final Map<String, int> requested = {};
      for (final box in boxTypes) {
        final key = InventoryItem.generateId(box.type, box.number);
        requested[key] = (requested[key] ?? 0) + box.quantity;
      }

      // Проверяем доступность каждого типа
      final List<String> insufficient = [];
      final Map<String, Map<String, int>> details = {};

      for (final entry in requested.entries) {
        final id = entry.key;
        final requestedQty = entry.value;

        // Ищем товар в инвентаре
        final item = inventory.firstWhere(
          (i) => i.id == id,
          orElse: () => InventoryItem(
            id: id,
            type: '',
            number: '',
            volumeMl: null,
            quantity: 0,
            quantityPerPallet: 1,
            lastUpdated: DateTime.now(),
            updatedBy: '',
          ),
        );

        final availableQty = item.quantity;

        if (availableQty < requestedQty) {
          insufficient.add(item.toShortString());
          details[id] = {
            'requested': requestedQty,
            'available': availableQty,
            'missing': requestedQty - availableQty,
          };
        }
      }

      return {
        'available': insufficient.isEmpty,
        'insufficient': insufficient,
        'details': details,
      };
    } catch (e) {
      print('❌ [Inventory] Error checking availability: $e');
      return {
        'available': false,
        'insufficient': ['Error checking inventory'],
        'details': {},
      };
    }
  }

  /// Списать товар со склада при создании заказа
  Future<void> deductStock(List<BoxType> boxTypes, String userName) async {
    try {
      // Группируем коробки по типу и номеру
      final Map<String, int> toDeduct = {};
      for (final box in boxTypes) {
        final key = InventoryItem.generateId(box.type, box.number);
        toDeduct[key] = (toDeduct[key] ?? 0) + box.quantity;
      }

      // Списываем каждый тип
      for (final entry in toDeduct.entries) {
        final id = entry.key;
        final quantity = entry.value;

        final doc = await _firestore.collection('inventory').doc(id).get();

        if (doc.exists) {
          final currentQty = doc.data()!['quantity'] as int;
          final newQty = currentQty - quantity;

          await _firestore.collection('inventory').doc(id).update({
            'quantity': newQty >= 0 ? newQty : 0,
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedBy': userName,
          });

          print('✅ [Inventory] Deducted $quantity from $id (new: $newQty)');
        } else {
          print('⚠️ [Inventory] Item $id not found in inventory');
        }
      }
    } catch (e) {
      print('❌ [Inventory] Error deducting stock: $e');
      rethrow;
    }
  }

  /// Удалить товар из инвентаря
  Future<void> deleteInventoryItem(String id) async {
    try {
      await _firestore.collection('inventory').doc(id).delete();
      print('✅ [Inventory] Deleted item: $id');
    } catch (e) {
      print('❌ [Inventory] Error deleting item: $e');
      rethrow;
    }
  }
}
