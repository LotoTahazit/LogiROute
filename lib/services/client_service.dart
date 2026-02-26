import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  ClientService({required this.companyId}) {
    if (companyId.isEmpty) {
      throw Exception('companyId cannot be empty');
    }
  }

  /// Хелпер: возвращает ссылку на вложенную коллекцию клиентов компании
  CollectionReference<Map<String, dynamic>> _clientsCollection() {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('clients');
  }

  /// Получить всех клиентов, отсортированных по имени
  Future<List<ClientModel>> getAllClients([String? overrideCompanyId]) async {
    try {
      final snapshot = await _clientsCollection().orderBy('name').get();
      print(
          '📊 [Client] Loaded ${snapshot.docs.length} clients from companies/$companyId/clients');
      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Client] Error getting clients: $e');
      return [];
    }
  }

  /// Поиск клиентов по имени или номеру
  Future<List<ClientModel>> searchClients(String query,
      [String? overrideCompanyId]) async {
    if (query.isEmpty) return [];

    try {
      // Поиск по номеру клиента (если только цифры)
      if (RegExp(r'^\d+$').hasMatch(query)) {
        final snapshot = await _clientsCollection()
            .where('clientNumber', isGreaterThanOrEqualTo: query)
            .where('clientNumber', isLessThan: '$query\uf8ff')
            .limit(10)
            .get();

        print('📊 [Client] Found ${snapshot.docs.length} clients by number');
        return snapshot.docs
            .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Поиск по имени - корректная обработка иврита
      final searchQuery = _normalizeForSearch(query);
      final snapshot = await _clientsCollection()
          .where('nameLowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('nameLowercase', isLessThan: '$searchQuery\uf8ff')
          .limit(10)
          .get();

      print('📊 [Client] Found ${snapshot.docs.length} clients by name');
      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Client] Error searching clients: $e');
      return [];
    }
  }

  /// Нормализация строки для поиска (корректная обработка иврита)
  String _normalizeForSearch(String text) {
    // Для иврита просто возвращаем как есть, без toLowerCase()
    if (RegExp(r'[\u0590-\u05FF]').hasMatch(text)) {
      return text;
    }
    // Для латиницы используем toLowerCase()
    return text.toLowerCase();
  }

  /// Добавить нового клиента
  Future<void> addClient(ClientModel client) async {
    try {
      await _clientsCollection().add({
        ...client.toMap(),
        'nameLowercase': _normalizeForSearch(client.name),
      });
      print(
          '✅ [Client] Added client: ${client.name} in companies/$companyId/clients');
    } catch (e) {
      print('❌ [Client] Error adding client: $e');
      rethrow;
    }
  }

  /// Обновить существующего клиента
  Future<void> updateClient(String clientId, ClientModel client) async {
    try {
      await _clientsCollection().doc(clientId).update({
        ...client.toMap(),
        'nameLowercase': _normalizeForSearch(client.name),
      });
      print(
          '✅ [Client] Updated client: $clientId in companies/$companyId/clients');
    } catch (e) {
      print('❌ [Client] Error updating client: $e');
      rethrow;
    }
  }

  /// Получить клиента по ID
  Future<ClientModel?> getClientById(String clientId) async {
    try {
      final doc = await _clientsCollection().doc(clientId).get();
      if (doc.exists) {
        return ClientModel.fromMap(doc.data()!, doc.id);
      }
      print('⚠️ [Client] Client not found: $clientId');
      return null;
    } catch (e) {
      print('❌ [Client] Error getting client by ID: $e');
      return null;
    }
  }

  /// Найти клиента по имени и номеру
  Future<ClientModel?> findClientByNameAndNumber(
      String name, String clientNumber,
      [String? overrideCompanyId]) async {
    try {
      final snapshot = await _clientsCollection()
          .where('name', isEqualTo: name)
          .where('clientNumber', isEqualTo: clientNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ClientModel.fromMap(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print('❌ [Client] Error finding client by name and number: $e');
      return null;
    }
  }

  /// Очистить всех клиентов (только для текущей компании)
  Future<void> clearAllClients() async {
    try {
      final clients = await _clientsCollection().get();
      for (final doc in clients.docs) {
        await doc.reference.delete();
      }
      print('✅ [Client] Cleared all clients for companies/$companyId/clients');
    } catch (e) {
      print('❌ [Client] Error clearing clients: $e');
      rethrow;
    }
  }

  /// Исправить nameLowercase для существующих клиентов (если нужно)
  Future<void> fixHebrewSearchIndex() async {
    debugPrint('🔧 [ClientService] Fixing Hebrew search index...');

    try {
      final clients = await _clientsCollection().get();
      int fixedCount = 0;

      for (final doc in clients.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        final currentNameLowercase = data['nameLowercase'] ?? '';
        final correctNameLowercase = _normalizeForSearch(name);

        // Если nameLowercase неправильно сохранен (например, для иврита использовался toLowerCase())
        if (currentNameLowercase != correctNameLowercase) {
          await doc.reference.update({
            'nameLowercase': correctNameLowercase,
          });
          debugPrint(
              '✅ [ClientService] Fixed nameLowercase for "$name": "$currentNameLowercase" → "$correctNameLowercase"');
          fixedCount++;
        }
      }

      debugPrint(
          '✅ [ClientService] Fixed $fixedCount clients with Hebrew search index');
    } catch (e) {
      debugPrint('❌ [ClientService] Error fixing Hebrew search index: $e');
    }
  }

  /// Создать тестовых клиентов (однократно)
  Future<void> createTestClients([String? overrideCompanyId]) async {
    try {
      // Проверяем, есть ли клиенты для этой компании
      final existing = await _clientsCollection().limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint(
            'ℹ️ [TestData] Clients already exist for company $companyId');
        return;
      }

      final testAddresses = [
        {
          'number': '100001',
          'name': 'אחים פרץ',
          'address': 'רחוב החלוצים 10, תל אביב',
          'phone': '03-1234567',
          'contact': 'דוד פרץ'
        },
        {
          'number': '100002',
          'name': 'פיצוחי קליפורניה',
          'address': 'רחוב החלוצים 18, תל אביב',
          'phone': '03-2345678',
          'contact': 'רחל כהן'
        },
        {
          'number': '100003',
          'name': 'אחים שמאי',
          'address': 'רחוב הכרמל 12, תל אביב',
          'phone': '03-3456789',
          'contact': 'יוסי שמאי'
        },
        {
          'number': '100004',
          'name': 'חנות הכלבו',
          'address': 'רחוב דיזנגוף 25, תל אביב',
          'phone': '03-4567890',
          'contact': 'מיכל לוי'
        },
        {
          'number': '100005',
          'name': 'מחסן המזון',
          'address': 'רחוב הרצל 8, חיפה',
          'phone': '04-5678901',
          'contact': 'אבי כהן'
        },
        {
          'number': '100006',
          'name': 'מרכז הקניות',
          'address': 'שדרות בן גוריון 15, נתניה',
          'phone': '09-6789012',
          'contact': 'שרה אברהם'
        },
      ];

      for (final data in testAddresses) {
        try {
          final locations =
              await geocoding.locationFromAddress(data['address']!);

          // ❌ БЕЗ FALLBACK! Если геокодирование не удалось - пропускаем
          if (locations.isEmpty) {
            debugPrint(
                '❌ [TestData] No location found for "${data['address']}"');
            debugPrint(
                '⚠️ [TestData] Skipping client "${data['name']}" - geocoding required');
            continue;
          }

          final location = locations.first;
          final client = ClientModel(
            id: '',
            clientNumber: data['number']!,
            name: data['name']!,
            address: data['address']!,
            latitude: location.latitude,
            longitude: location.longitude,
            phone: data['phone']!,
            contactPerson: data['contact']!,
            companyId: companyId,
          );

          await addClient(client);
          debugPrint(
              '✅ [TestData] Created client "${data['name']}" at (${location.latitude}, ${location.longitude})');
        } catch (e) {
          debugPrint('❌ [TestData] Failed to geocode "${data['address']}": $e');
          debugPrint(
              '⚠️ [TestData] Skipping client "${data['name']}" - geocoding required');
        }
      }
    } catch (e) {
      debugPrint('❌ [TestData] Error creating test clients: $e');
    }
  }

  /// Удалить клиента
  Future<void> deleteClient(String clientId) async {
    try {
      await _clientsCollection().doc(clientId).delete();
      debugPrint(
          '✅ [ClientService] Deleted client: $clientId from companies/$companyId/clients');
    } catch (e) {
      debugPrint('❌ [ClientService] Error deleting client: $e');
      rethrow;
    }
  }
}
