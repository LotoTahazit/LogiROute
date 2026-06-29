import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/box_type.dart';
import '../models/inventory_change.dart';
import '../models/product_type.dart';

class InventoryService {
  static const int defaultListLimit = 200;
  static const int exportBatchSize = 500;

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
        .collection('warehouse')
        .doc('_root')
        .collection('inventory');
  }

  /// Хелпер: product_types коллекция
  CollectionReference<Map<String, dynamic>> _productTypesCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('warehouse')
        .doc('_root')
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
    String? barcode,
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
        barcode: barcode,
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('warehouse')
          .doc('_root')
          .collection('inventory_history')
          .add(change.toMap());
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
    String? barcode,
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
      barcode: barcode,
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
    String? barcode,
    bool addToExisting = false,
  }) async {
    try {
      final id = InventoryItem.generateId(productCode);

      int finalQuantity = quantity;
      int quantityBefore = 0;

      if (addToExisting) {
        final doc = await _inventoryCollection().doc(id).get();
        if (doc.exists) {
          quantityBefore = (doc.data()!['quantity'] as num).toInt();
          finalQuantity = quantityBefore + quantity;
          print(
              '➕ [Inventory] Adding $quantity to existing $quantityBefore = $finalQuantity');
        }
      } else {
        final doc = await _inventoryCollection().doc(id).get();
        if (doc.exists) {
          quantityBefore = (doc.data()!['quantity'] as num).toInt();
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
      if (barcode != null && barcode.trim().isNotEmpty) {
        final trimmed = barcode.trim();
        await _assertBarcodeUnique(trimmed, exceptProductCode: productCode);
        data['barcode'] = trimmed;
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

  /// Список склада (bounded). Для full export — [fetchAllInventoryForExport].
  Future<List<InventoryItem>> getInventory({int limit = defaultListLimit}) async {
    try {
      final snapshot = await _inventoryCollection()
          .orderBy('productCode')
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Inventory] Error getting inventory: $e');
      return [];
    }
  }

  /// Full read для export / инвентаризации — paginated, явное действие.
  Future<List<InventoryItem>> fetchAllInventoryForExport({
    void Function(int loaded)? onProgress,
  }) async {
    final all = <InventoryItem>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> query = _inventoryCollection()
          .orderBy('productCode')
          .limit(exportBatchSize);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;
      all.addAll(snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id)));
      onProgress?.call(all.length);
      cursor = snapshot.docs.last;
      if (snapshot.docs.length < exportBatchSize) break;
      if (all.length >= 10000) break;
    }
    return all;
  }

  Future<InventoryItem?> getItemByProductCode(String productCode) async {
    if (productCode.isEmpty) return null;
    final doc =
        await _inventoryCollection().doc(InventoryItem.generateId(productCode)).get();
    if (!doc.exists) return null;
    return InventoryItem.fromMap(doc.data()!, doc.id);
  }

  Future<InventoryItem?> getItemByTypeAndNumber(String type, String number) async {
    if (type.isEmpty || number.isEmpty) return null;
    final snap = await _inventoryCollection()
        .where('type', isEqualTo: type)
        .where('number', isEqualTo: number)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return InventoryItem.fromMap(doc.data(), doc.id);
  }

  Future<Map<String, InventoryItem>> getItemsForBoxTypes(
      List<BoxType> boxTypes) async {
    final map = <String, InventoryItem>{};
    for (final box in boxTypes) {
      InventoryItem? item;
      if (box.productCode.isNotEmpty) {
        item = await getItemByProductCode(box.productCode);
      }
      item ??= await getItemByTypeAndNumber(box.type, box.number);
      if (item != null) map[item.productCode] = item;
    }
    return map;
  }

  Future<Map<String, InventoryItem>> getItemsByProductCodes(
      Iterable<String> codes) async {
    final map = <String, InventoryItem>{};
    for (final code in codes.where((c) => c.isNotEmpty).toSet()) {
      final item = await getItemByProductCode(code);
      if (item != null) map[code] = item;
    }
    return map;
  }

  InventoryItem? _itemForBox(BoxType box, Map<String, InventoryItem> items) {
    if (box.productCode.isNotEmpty) {
      final byCode = items[box.productCode];
      if (byCode != null) return byCode;
    }
    for (final item in items.values) {
      if (item.type == box.type && item.number == box.number) return item;
    }
    return null;
  }

  /// Получить товары в реальном времени (bounded)
  Stream<List<InventoryItem>> getInventoryStream({int limit = defaultListLimit}) {
    print('📊 [Inventory] Starting stream with limit: $limit');
    return _inventoryCollection()
        .orderBy('productCode')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
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

  /// Проверить доступность — только нужные SKU, без full warehouse read.
  Future<Map<String, dynamic>> checkAvailability(List<BoxType> boxTypes) async {
    try {
      final items = await getItemsForBoxTypes(boxTypes);

      final Map<String, int> requested = {};
      for (final box in boxTypes) {
        final item = _itemForBox(box, items);
        if (item == null) {
          throw Exception('ITEM_NOT_FOUND:${box.type}:${box.number}');
        }

        final productCode = item.productCode;
        requested[productCode] = (requested[productCode] ?? 0) + box.quantity;
      }

      final List<String> insufficient = [];
      final Map<String, Map<String, dynamic>> details = {};

      for (final entry in requested.entries) {
        final productCode = entry.key;
        final requestedQty = entry.value;
        final item = items[productCode];
        if (item == null) {
          throw Exception('PRODUCT_CODE_NOT_FOUND:$productCode');
        }

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

  /// Списать товар — точечные reads по SKU.
  Future<void> deductStock(List<BoxType> boxTypes, String userName,
      {String? reason}) async {
    try {
      final items = await getItemsForBoxTypes(boxTypes);

      final Map<String, int> toDeduct = {};
      for (final box in boxTypes) {
        final item = _itemForBox(box, items);
        if (item == null) {
          throw Exception('ITEM_NOT_FOUND:${box.type}:${box.number}');
        }
        final productCode = item.productCode;
        toDeduct[productCode] = (toDeduct[productCode] ?? 0) + box.quantity;
      }

      for (final entry in toDeduct.entries) {
        final productCode = entry.key;
        final quantity = entry.value;

        final doc = await _inventoryCollection().doc(productCode).get();

        if (doc.exists) {
          final data = doc.data()!;
          final currentQty = (data['quantity'] as num).toInt();
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
            reason: reason ?? 'order_creation',
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
                'unitsPerBox': (data['piecesPerBox'] as num?)?.toInt() ?? 1,
                'boxesPerPallet':
                    (data['quantityPerPallet'] as num?)?.toInt() ?? 1,
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
            unitsPerBox: (data['piecesPerBox'] as num?)?.toInt() ?? 1,
            boxesPerPallet: (data['quantityPerPallet'] as num?)?.toInt() ?? 1,
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

  /// Проверка: один штрихкод — одна позиция.
  Future<void> _assertBarcodeUnique(
    String barcode, {
    String? exceptProductCode,
  }) async {
    final byField = await _inventoryCollection()
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (byField.docs.isNotEmpty) {
      final found = InventoryItem.fromMap(
        byField.docs.first.data(),
        byField.docs.first.id,
      );
      if (found.productCode != exceptProductCode) {
        throw Exception('BARCODE_DUPLICATE');
      }
    }
    final byId = await _inventoryCollection().doc(barcode).get();
    if (byId.exists && byId.id != exceptProductCode) {
      throw Exception('BARCODE_DUPLICATE');
    }
  }

  /// Обновить ברקוד позиции (или очистить, если пусто).
  Future<void> updateItemBarcode({
    required String productCode,
    String? barcode,
    required String userName,
  }) async {
    final trimmed = barcode?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _assertBarcodeUnique(trimmed, exceptProductCode: productCode);
    }

    final id = InventoryItem.generateId(productCode);
    final doc = await _inventoryCollection().doc(id).get();
    if (!doc.exists) throw Exception('ITEM_NOT_FOUND');

    final update = <String, dynamic>{
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': userName,
    };
    if (trimmed == null || trimmed.isEmpty) {
      update['barcode'] = FieldValue.delete();
    } else {
      update['barcode'] = trimmed;
    }
    await _inventoryCollection().doc(id).update(update);
  }

  /// Поиск позиции по ברקוד или מק"ט (документ id = productCode).
  Future<InventoryItem?> findByScanCode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return null;

    final byId = await _inventoryCollection().doc(code).get();
    if (byId.exists) {
      return InventoryItem.fromMap(byId.data()!, byId.id);
    }

    final byBarcode = await _inventoryCollection()
        .where('barcode', isEqualTo: code)
        .limit(1)
        .get();
    if (byBarcode.docs.isNotEmpty) {
      final doc = byBarcode.docs.first;
      return InventoryItem.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  /// Приход/расход по сканированию (только при включённом מחסן ממוחשב).
  Future<InventoryItem> applyBarcodeScan({
    required String scanCode,
    required int quantityDelta,
    required String userName,
  }) async {
    if (quantityDelta == 0) {
      throw Exception('INVALID_QUANTITY');
    }
    final item = await findByScanCode(scanCode);
    if (item == null) throw Exception('BARCODE_NOT_FOUND');

    final before = item.quantity;
    final after = before + quantityDelta;
    if (after < 0) throw Exception('INSUFFICIENT_STOCK');

    await _inventoryCollection().doc(item.id).update({
      'quantity': after,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': userName,
    });

    await _logChange(
      productCode: item.productCode,
      type: item.type,
      number: item.number,
      quantityChange: quantityDelta,
      quantityBefore: before,
      quantityAfter: after,
      userName: userName,
      action: quantityDelta > 0 ? 'barcode_in' : 'barcode_out',
      reason: 'barcode_scan',
      barcode: scanCode.trim(),
    );

    return item.copyWith(
      quantity: after,
      lastUpdated: DateTime.now(),
      updatedBy: userName,
    );
  }
}
