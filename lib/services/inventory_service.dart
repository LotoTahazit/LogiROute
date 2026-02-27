import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/box_type.dart';
import '../models/inventory_change.dart';
import '../models/product_type.dart';

class InventoryService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InventoryService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию инвентаря компании
  CollectionReference<Map<String, dynamic>> _inventoryCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('inventory');
  }

  /// Хелпер: product_types коллекция
  CollectionReference<Map<String, dynamic>> _productTypesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('product_types');
  }

  /// Записать изменение в историю
  Future<void> _logChange({
    required String productCode,
    required String type,
    required String number,
    required int quantityChange,
    required int quantityBefore,
    required int quantityAfter,
    required String userName,
    required String action,
    String? reason,
  }) async {
    try {
      final change = InventoryChange(
        id: '',
        productCode: productCode,
        type: type,
        number: number,
        quantityChange: quantityChange,
        quantityBefore: quantityBefore,
        quantityAfter: quantityAfter,
        timestamp: DateTime.now(),
        userName: userName,
        action: action,
        reason: reason,
      );

      await _firestore.collection('inventory_history').add(change.toMap());
      print(
          '✅ [History] Logged: $productCode ${quantityChange > 0 ? '+' : ''}$quantityChange');
    } catch (e) {
      print('❌ [History] Error: $e');
    }
  }

  /// Добавить товар (прибавить к существующему)
  Future<void> addInventory({
    required String productCode,
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
      productCode: productCode,
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
    required String productCode,
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
    bool addToExisting = false,
  }) async {
    try {
      final id = InventoryItem.generateId(productCode);

      int finalQuantity = quantity;
      int quantityBefore = 0;

      if (addToExisting) {
        final doc = await _inventoryCollection().doc(id).get();
        if (doc.exists) {
          quantityBefore = doc.data()!['quantity'] as int;
          finalQuantity = quantityBefore + quantity;
          print(
              '➕ [Inventory] Adding $quantity to existing $quantityBefore = $finalQuantity');
        }
      } else {
        final doc = await _inventoryCollection().doc(id).get();
        if (doc.exists) {
          quantityBefore = doc.data()!['quantity'] as int;
        }
      }

      final data = {
        'productCode': productCode,
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

      await _inventoryCollection().doc(id).set(
            data,
            SetOptions(merge: true),
          );

      final changeAmount = finalQuantity - quantityBefore;
      await _logChange(
        productCode: productCode,
        type: type,
        number: number,
        quantityChange: changeAmount,
        quantityBefore: quantityBefore,
        quantityAfter: finalQuantity,
        userName: userName,
        action: addToExisting ? 'add' : 'update',
      );

      print(
          '✅ [Inventory] Updated: מק"ט $productCode ($type $number) = $finalQuantity יח\'');
    } catch (e) {
      print('❌ [Inventory] Error updating inventory: $e');
      rethrow;
    }
  }

  /// Получить все товары на складе
  Future<List<InventoryItem>> getInventory() async {
    try {
      final snapshot = await _inventoryCollection().get();
      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Inventory] Error getting inventory: $e');
      return [];
    }
  }

  /// Получить товары в реальном времени
  Stream<List<InventoryItem>> getInventoryStream({int limit = 200}) {
    print('📊 [Inventory] Starting stream with limit: $limit');
    return _inventoryCollection().limit(limit).snapshots().map((snapshot) {
      print('📊 [Inventory] Stream update: ${snapshot.docs.length} items');
      final items = <InventoryItem>[];
      for (final doc in snapshot.docs) {
        try {
          final item = InventoryItem.fromMap(doc.data(), doc.id);
          items.add(item);
        } catch (e) {
          print('❌ [Inventory] Error parsing item ${doc.id}: $e');
          print('📄 [Inventory] Problematic data: ${doc.data()}');
        }
      }
      return items;
    });
  }

  /// Проверить доступность товара для заказа
  Future<Map<String, dynamic>> checkAvailability(List<BoxType> boxTypes) async {
    try {
      final inventory = await getInventory();

      final Map<String, int> requested = {};
      for (final box in boxTypes) {
        final item = inventory.firstWhere(
          (i) => i.type == box.type && i.number == box.number,
          orElse: () => throw Exception(
            'ITEM_NOT_FOUND:${box.type}:${box.number}',
          ),
        );

        final productCode = item.productCode;
        requested[productCode] = (requested[productCode] ?? 0) + box.quantity;
      }

      final List<String> insufficient = [];
      final Map<String, Map<String, dynamic>> details = {};

      for (final entry in requested.entries) {
        final productCode = entry.key;
        final requestedQty = entry.value;

        final item = inventory.firstWhere(
          (i) => i.productCode == productCode,
          orElse: () => throw Exception('PRODUCT_CODE_NOT_FOUND:$productCode'),
        );

        final availableQty = item.quantity;

        if (availableQty < requestedQty) {
          insufficient.add(
              '${item.type}|${item.number}|${item.productCode}|$availableQty|$requestedQty');
          details[productCode] = {
            'requested': requestedQty,
            'available': availableQty,
            'missing': requestedQty - availableQty,
            'type': item.type,
            'number': item.number,
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
      final errorMsg = e.toString();
      return {
        'available': false,
        'insufficient': [errorMsg],
        'details': {},
      };
    }
  }

  /// Списать товар со склада при создании заказа
  Future<void> deductStock(List<BoxType> boxTypes, String userName) async {
    try {
      final inventory = await getInventory();

      final Map<String, int> toDeduct = {};
      for (final box in boxTypes) {
        final item = inventory.firstWhere(
          (i) => i.type == box.type && i.number == box.number,
          orElse: () => throw Exception(
            'ITEM_NOT_FOUND:${box.type}:${box.number}',
          ),
        );

        final productCode = item.productCode;
        toDeduct[productCode] = (toDeduct[productCode] ?? 0) + box.quantity;
      }

      for (final entry in toDeduct.entries) {
        final productCode = entry.key;
        final quantity = entry.value;

        final doc = await _inventoryCollection().doc(productCode).get();

        if (doc.exists) {
          final data = doc.data()!;
          final currentQty = data['quantity'] as int;
          final newQty = currentQty - quantity;
          final type = data['type'] as String;
          final number = data['number'] as String;

          await _inventoryCollection().doc(productCode).update({
            'quantity': newQty >= 0 ? newQty : 0,
            'lastUpdated': FieldValue.serverTimestamp(),
            'updatedBy': userName,
          });

          await _logChange(
            productCode: productCode,
            type: type,
            number: number,
            quantityChange: -quantity,
            quantityBefore: currentQty,
            quantityAfter: newQty >= 0 ? newQty : 0,
            userName: userName,
            action: 'deduct',
            reason: 'Списание при создании заказа',
          );

          print(
              '✅ [Inventory] Deducted $quantity from מק"ט $productCode (new: $newQty)');
        } else {
          print('⚠️ [Inventory] Item מק"ט $productCode not found in inventory');
        }
      }
    } catch (e) {
      print('❌ [Inventory] Error deducting stock: $e');
      rethrow;
    }
  }

  /// Удалить товар из инвентаря
  Future<void> deleteInventoryItem(String productCode) async {
    try {
      await _inventoryCollection().doc(productCode).delete();
      print('✅ [Inventory] Deleted item: מק"ט $productCode');
    } catch (e) {
      print('❌ [Inventory] Error deleting item: $e');
      rethrow;
    }
  }

  /// Ручная синхронизация: создать/обновить product_types для всех товаров на складе
  Future<Map<String, int>> syncAllToProductTypes(String userName) async {
    int created = 0;
    int skipped = 0;
    int updated = 0;
    int errors = 0;

    try {
      final inventorySnapshot = await _inventoryCollection().get();
      final existingPT = await _productTypesCollection().get();

      final existingMap = <String, Map<String, String>>{};
      for (final d in existingPT.docs) {
        final code = d.data()['productCode'] as String?;
        if (code != null) {
          existingMap[code] = {
            'docId': d.id,
            'name': d.data()['name'] as String? ?? ''
          };
        }
      }

      for (final doc in inventorySnapshot.docs) {
        final data = doc.data();
        final productCode = data['productCode']?.toString() ?? '';
        if (productCode.isEmpty) {
          skipped++;
          continue;
        }

        final expectedName =
            '${data['type'] ?? ''} ${data['number'] ?? ''}'.trim();

        if (existingMap.containsKey(productCode)) {
          final existing = existingMap[productCode]!;
          if (existing['name'] != expectedName) {
            try {
              await _productTypesCollection().doc(existing['docId']!).update({
                'name': expectedName,
                'unitsPerBox': (data['piecesPerBox'] as int?) ?? 1,
                'boxesPerPallet': (data['quantityPerPallet'] as int?) ?? 1,
              });
              updated++;
            } catch (e) {
              errors++;
            }
          } else {
            skipped++;
          }
          continue;
        }

        try {
          final product = ProductType(
            id: '',
            companyId: companyId,
            name: expectedName,
            productCode: productCode,
            category: 'general',
            unitsPerBox: (data['piecesPerBox'] as int?) ?? 1,
            boxesPerPallet: (data['quantityPerPallet'] as int?) ?? 1,
            createdAt: DateTime.now(),
            createdBy: userName,
          );
          await _productTypesCollection().add(product.toMap());
          existingMap[productCode] = {'docId': '', 'name': expectedName};
          created++;
        } catch (e) {
          errors++;
          print('⚠️ [Sync] Error syncing $productCode: $e');
        }
      }

      print(
          '🔄 [Sync] Done: created=$created, updated=$updated, skipped=$skipped, errors=$errors');
    } catch (e) {
      print('❌ [Sync] Error: $e');
    }

    return {
      'created': created,
      'updated': updated,
      'skipped': skipped,
      'errors': errors
    };
  }
}
