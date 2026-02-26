import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ArchiveService {
  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ArchiveService({required this.companyId});

  /// Архивировать историю изменений инвентаря старше указанного количества месяцев
  Future<Map<String, dynamic>> archiveInventoryHistory({
    int monthsOld = 3,
  }) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: monthsOld * 30));

      print('📦 [Archive] Starting inventory history archive...');
      print('📅 [Archive] Cutoff date: ${cutoffDate.toIso8601String()}');

      // Получаем старые записи
      final snapshot = await _firestore
          .collection('inventory_history')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp')
          .limit(1000) // Порциями по 1000
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ [Archive] No old records to archive');
        return {
          'success': true,
          'archived': 0,
          'message': 'No records to archive',
        };
      }

      // Конвертируем в JSON
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Сохраняем ID для возможности восстановления
        return data;
      }).toList();

      // Создаем имя файла с датой
      final fileName =
          'inventory_history_${cutoffDate.year}_${cutoffDate.month.toString().padLeft(2, '0')}.json';
      final filePath = 'archives/inventory_history/$fileName';

      // Загружаем в Firebase Storage
      final jsonData = jsonEncode(records);
      final ref = _storage.ref().child(filePath);

      await ref.putString(
        jsonData,
        metadata: SettableMetadata(
          contentType: 'application/json',
          customMetadata: {
            'recordCount': records.length.toString(),
            'cutoffDate': cutoffDate.toIso8601String(),
            'archivedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      print('✅ [Archive] Uploaded ${records.length} records to $filePath');

      // Помечаем записи как архивированные (не удаляем)
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'archived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'archiveFile': filePath,
        });
      }
      await batch.commit();

      print('✅ [Archive] Marked ${records.length} records as archived');

      return {
        'success': true,
        'archived': records.length,
        'filePath': filePath,
        'message': 'Successfully archived ${records.length} records',
      };
    } catch (e) {
      print('❌ [Archive] Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Архивировать завершенные заказы старше указанного количества месяцев
  Future<Map<String, dynamic>> archiveCompletedOrders({
    int monthsOld = 1,
  }) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: monthsOld * 30));

      print('📦 [Archive] Starting completed orders archive...');
      print('📅 [Archive] Cutoff date: ${cutoffDate.toIso8601String()}');

      // Получаем старые завершенные заказы
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('delivery_points')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .orderBy('completedAt')
          .limit(500) // Порциями по 500
          .get();

      if (snapshot.docs.isEmpty) {
        print('✅ [Archive] No old orders to archive');
        return {
          'success': true,
          'archived': 0,
          'message': 'No orders to archive',
        };
      }

      // Конвертируем в JSON
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).toList();

      // Создаем имя файла с датой
      final fileName =
          'completed_orders_${cutoffDate.year}_${cutoffDate.month.toString().padLeft(2, '0')}.json';
      final filePath = 'archives/orders/$fileName';

      // Загружаем в Firebase Storage
      final jsonData = jsonEncode(records);
      final ref = _storage.ref().child(filePath);

      await ref.putString(
        jsonData,
        metadata: SettableMetadata(
          contentType: 'application/json',
          customMetadata: {
            'recordCount': records.length.toString(),
            'cutoffDate': cutoffDate.toIso8601String(),
            'archivedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      print('✅ [Archive] Uploaded ${records.length} orders to $filePath');

      // Помечаем заказы как архивированные
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'archived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'archiveFile': filePath,
        });
      }
      await batch.commit();

      print('✅ [Archive] Marked ${records.length} orders as archived');

      return {
        'success': true,
        'archived': records.length,
        'filePath': filePath,
        'message': 'Successfully archived ${records.length} orders',
      };
    } catch (e) {
      print('❌ [Archive] Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Получить список всех архивов
  Future<List<Map<String, dynamic>>> listArchives() async {
    try {
      final archives = <Map<String, dynamic>>[];

      // Список архивов истории инвентаря
      final historyRef = _storage.ref().child('archives/inventory_history');
      final historyList = await historyRef.listAll();

      for (final item in historyList.items) {
        final metadata = await item.getMetadata();
        archives.add({
          'type': 'inventory_history',
          'name': item.name,
          'path': item.fullPath,
          'size': metadata.size,
          'created': metadata.timeCreated,
          'recordCount': metadata.customMetadata?['recordCount'],
        });
      }

      // Список архивов заказов
      final ordersRef = _storage.ref().child('archives/orders');
      final ordersList = await ordersRef.listAll();

      for (final item in ordersList.items) {
        final metadata = await item.getMetadata();
        archives.add({
          'type': 'orders',
          'name': item.name,
          'path': item.fullPath,
          'size': metadata.size,
          'created': metadata.timeCreated,
          'recordCount': metadata.customMetadata?['recordCount'],
        });
      }

      // Сортируем по дате создания
      archives.sort((a, b) =>
          (b['created'] as DateTime).compareTo(a['created'] as DateTime));

      return archives;
    } catch (e) {
      print('❌ [Archive] Error listing archives: $e');
      return [];
    }
  }

  /// Загрузить архив для просмотра
  Future<List<Map<String, dynamic>>> loadArchive(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final data = await ref.getData();

      if (data == null) {
        throw Exception('Archive file not found');
      }

      final jsonString = utf8.decode(data);
      final List<dynamic> records = jsonDecode(jsonString);

      return records.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ [Archive] Error loading archive: $e');
      rethrow;
    }
  }

  /// Получить URL для скачивания архива
  Future<String> getArchiveDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ [Archive] Error getting download URL: $e');
      rethrow;
    }
  }

  /// Восстановить данные из архива (если нужно)
  Future<Map<String, dynamic>> restoreFromArchive(String path) async {
    try {
      print('🔄 [Archive] Restoring from $path...');

      final records = await loadArchive(path);

      // Определяем тип архива по пути
      final isInventoryHistory = path.contains('inventory_history');
      final collection =
          isInventoryHistory ? 'inventory_history' : 'delivery_points';

      // Восстанавливаем записи
      final batch = _firestore.batch();
      int restored = 0;

      for (final record in records) {
        final id = record['_id'] as String?;
        if (id != null) {
          record.remove('_id');
          record.remove('archived');
          record.remove('archivedAt');
          record.remove('archiveFile');

          final docRef = _firestore.collection(collection).doc(id);
          batch.set(docRef, record);
          restored++;
        }
      }

      await batch.commit();

      print('✅ [Archive] Restored $restored records');

      return {
        'success': true,
        'restored': restored,
        'message': 'Successfully restored $restored records',
      };
    } catch (e) {
      print('❌ [Archive] Error restoring: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Получить статистику по архивам
  Future<Map<String, dynamic>> getArchiveStats() async {
    try {
      final archives = await listArchives();

      int totalSize = 0;
      int totalRecords = 0;
      int historyArchives = 0;
      int orderArchives = 0;

      for (final archive in archives) {
        totalSize += (archive['size'] as int?) ?? 0;
        totalRecords +=
            int.tryParse(archive['recordCount']?.toString() ?? '0') ?? 0;

        if (archive['type'] == 'inventory_history') {
          historyArchives++;
        } else {
          orderArchives++;
        }
      }

      return {
        'totalArchives': archives.length,
        'historyArchives': historyArchives,
        'orderArchives': orderArchives,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
        'totalRecords': totalRecords,
      };
    } catch (e) {
      print('❌ [Archive] Error getting stats: $e');
      return {};
    }
  }
}
