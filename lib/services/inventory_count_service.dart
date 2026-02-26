import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_count.dart';
import '../models/count_item.dart';
import '../models/suspicious_order.dart';
import '../models/inventory_item.dart';

class InventoryCountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  InventoryCountService({required this.companyId});

  /// Начать новую инвентаризацию
  Future<String> startNewCount({
    required String userName,
    required List<InventoryItem> currentInventory,
  }) async {
    try {
      // Создаем список товаров для подсчета
      final items = currentInventory.map((item) {
        return CountItem(
          productCode: item.productCode,
          type: item.type,
          number: item.number,
          expectedQuantity: item.quantity,
        );
      }).toList();

      // Создаем новую сессию подсчета
      final count = InventoryCount(
        id: '',
        startedAt: DateTime.now(),
        status: 'in_progress',
        userName: userName,
        items: items,
        summary: CountSummary(
          totalItems: items.length,
          checkedItems: 0,
          itemsWithDifference: 0,
          totalShortage: 0,
          totalSurplus: 0,
        ),
      );

      final docRef =
          await _firestore.collection('inventory_counts').add(count.toMap());

      print('✅ [InventoryCount] Started new count: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [InventoryCount] Error starting count: $e');
      rethrow;
    }
  }

  /// Обновить фактическое количество товара
  Future<void> updateItemCount({
    required String countId,
    required String productCode,
    required int actualQuantity,
    String? notes,
  }) async {
    try {
      final docRef = _firestore.collection('inventory_counts').doc(countId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Count not found');
      }

      final count = InventoryCount.fromMap(doc.data()!, doc.id);

      // Находим товар в списке
      final itemIndex =
          count.items.indexWhere((item) => item.productCode == productCode);
      if (itemIndex == -1) {
        throw Exception('Item not found in count');
      }

      // Обновляем товар
      final updatedItem = count.items[itemIndex].copyWith(
        actualQuantity: actualQuantity,
        checkedAt: DateTime.now(),
        notes: notes,
      );

      // Если есть расхождение, ищем подозрительные заказы
      List<SuspiciousOrder> suspiciousOrders = [];
      if (updatedItem.hasDifference) {
        suspiciousOrders = await findSuspiciousOrders(
          productCode: productCode,
          difference: updatedItem.difference!,
          countDate: count.startedAt,
        );
      }

      final itemWithOrders =
          updatedItem.copyWith(relatedOrders: suspiciousOrders);

      // Обновляем список товаров
      final updatedItems = List<CountItem>.from(count.items);
      updatedItems[itemIndex] = itemWithOrders;

      // Пересчитываем сводку
      final updatedSummary = _calculateSummary(updatedItems);

      // Сохраняем изменения
      await docRef.update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'summary': updatedSummary.toMap(),
      });

      print('✅ [InventoryCount] Updated item: $productCode');
    } catch (e) {
      print('❌ [InventoryCount] Error updating item: $e');
      rethrow;
    }
  }

  /// Завершить инвентаризацию
  Future<void> completeCount(String countId) async {
    try {
      await _firestore.collection('inventory_counts').doc(countId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [InventoryCount] Completed count: $countId');
    } catch (e) {
      print('❌ [InventoryCount] Error completing count: $e');
      rethrow;
    }
  }

  /// Получить текущую активную инвентаризацию
  Future<InventoryCount?> getActiveCount() async {
    try {
      final snapshot = await _firestore
          .collection('inventory_counts')
          .where('status', isEqualTo: 'in_progress')
          .orderBy('startedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return InventoryCount.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      print('❌ [InventoryCount] Error getting active count: $e');
      return null;
    }
  }

  /// Получить инвентаризацию по ID
  Future<InventoryCount?> getCountById(String countId) async {
    try {
      final doc =
          await _firestore.collection('inventory_counts').doc(countId).get();

      if (!doc.exists) {
        return null;
      }

      return InventoryCount.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ [InventoryCount] Error getting count: $e');
      return null;
    }
  }

  /// Получить все инвентаризации (для админа/диспетчера)
  Stream<List<InventoryCount>> getAllCountsStream() {
    return _firestore
        .collection('inventory_counts')
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryCount.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Найти подозрительные заказы
  Future<List<SuspiciousOrder>> findSuspiciousOrders({
    required String productCode,
    required int difference,
    required DateTime countDate,
  }) async {
    try {
      // Ищем точки доставки за последние 14 дней
      final fromDate = countDate.subtract(const Duration(days: 14));

      final pointsSnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('delivery_points')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(countDate))
          .get();

      final suspicious = <SuspiciousOrder>[];

      for (final pointDoc in pointsSnapshot.docs) {
        final pointData = pointDoc.data();
        final boxTypes = pointData['boxTypes'] as List<dynamic>?;

        if (boxTypes == null) continue;

        // Проверяем, есть ли этот товар в точке доставки
        int totalQuantity = 0;
        for (final box in boxTypes) {
          if (box['productCode'] == productCode) {
            totalQuantity += (box['quantity'] as int? ?? 0);
          }
        }

        if (totalQuantity == 0) continue;

        // Анализируем подозрительность
        final status = pointData['status'] as String? ?? '';
        final orderInRoute = pointData['orderInRoute'] as int? ?? 0;
        final clientName = pointData['clientName'] as String? ?? 'לא ידוע';
        final completedAt = pointData['completedAt'] as Timestamp?;

        String suspicionLevel = 'low';
        String reason = '';

        if (difference < 0) {
          // Недостача
          if (status == 'completed') {
            suspicionLevel = 'high';
            reason = 'ייתכן שלא הונחו כל הפריטים';
          } else if (status == 'in_progress' || status == 'assigned') {
            suspicionLevel = 'medium';
            reason = 'ייתכן שהונחו יותר מדי פריטים';
          }
        } else if (difference > 0) {
          // Излишек
          if (status == 'cancelled') {
            suspicionLevel = 'high';
            reason = 'ייתכן שלא הוחזר למלאי';
          } else if (status == 'in_progress' || status == 'assigned') {
            suspicionLevel = 'medium';
            reason = 'ייתכן שהונחו פחות פריטים';
          }
        }

        if (suspicionLevel != 'low') {
          suspicious.add(SuspiciousOrder(
            orderId: pointDoc.id,
            orderNumber: orderInRoute,
            clientName: clientName,
            quantity: totalQuantity,
            status: status,
            deliveredAt: completedAt?.toDate(),
            suspicionLevel: suspicionLevel,
            reason: reason,
          ));
        }
      }

      // Сортируем по уровню подозрения (high -> medium -> low)
      suspicious.sort((a, b) {
        const levels = {'high': 0, 'medium': 1, 'low': 2};
        return (levels[a.suspicionLevel] ?? 3)
            .compareTo(levels[b.suspicionLevel] ?? 3);
      });

      return suspicious;
    } catch (e) {
      print('❌ [InventoryCount] Error finding suspicious orders: $e');
      return [];
    }
  }

  /// Подтвердить инвентаризацию и обновить инвентарь
  Future<void> approveAndUpdateInventory(String countId) async {
    try {
      final count = await getCountById(countId);
      if (count == null) {
        throw Exception('Count not found');
      }

      if (count.status != 'completed') {
        throw Exception('Count is not completed');
      }

      // Обновляем инвентарь для всех товаров с расхождениями
      final batch = _firestore.batch();

      for (final item in count.items) {
        if (item.hasDifference && item.actualQuantity != null) {
          // Находим товар в инвентаре
          final inventoryQuery = await _firestore
              .collection('companies')
              .doc(companyId)
              .collection('inventory')
              .where('productCode', isEqualTo: item.productCode)
              .limit(1)
              .get();

          if (inventoryQuery.docs.isNotEmpty) {
            final inventoryDoc = inventoryQuery.docs.first;
            batch.update(inventoryDoc.reference, {
              'quantity': item.actualQuantity,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Помечаем подсчет как утвержденный
      batch.update(_firestore.collection('inventory_counts').doc(countId), {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('✅ [InventoryCount] Approved and updated inventory: $countId');
    } catch (e) {
      print('❌ [InventoryCount] Error approving count: $e');
      rethrow;
    }
  }

  /// Пересчитать сводку
  CountSummary _calculateSummary(List<CountItem> items) {
    int checkedItems = 0;
    int itemsWithDifference = 0;
    int totalShortage = 0;
    int totalSurplus = 0;

    for (final item in items) {
      if (item.isChecked) {
        checkedItems++;

        if (item.hasDifference) {
          itemsWithDifference++;

          if (item.isShortage) {
            totalShortage += item.difference!.abs();
          } else if (item.isSurplus) {
            totalSurplus += item.difference!;
          }
        }
      }
    }

    return CountSummary(
      totalItems: items.length,
      checkedItems: checkedItems,
      itemsWithDifference: itemsWithDifference,
      totalShortage: totalShortage,
      totalSurplus: totalSurplus,
    );
  }
}
