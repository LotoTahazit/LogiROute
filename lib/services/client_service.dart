import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? companyId;

  ClientService({this.companyId});

  /// Получить всех клиентов, отсортированных по имени
  Future<List<ClientModel>> getAllClients([String? overrideCompanyId]) async {
    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      print('⚠️ Warning: companyId is null or empty in getAllClients');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('companyId', isEqualTo: targetCompanyId)
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Поиск клиентов по имени или номеру
  Future<List<ClientModel>> searchClients(String query,
      [String? overrideCompanyId]) async {
    if (query.isEmpty) return [];

    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      print('⚠️ Warning: companyId is null or empty in searchClients');
      return [];
    }

    try {
      // Поиск по номеру клиента (если только цифры)
      if (RegExp(r'^\d+$').hasMatch(query)) {
        final snapshot = await _firestore
            .collection('clients')
            .where('companyId', isEqualTo: targetCompanyId)
            .where('clientNumber', isGreaterThanOrEqualTo: query)
            .where('clientNumber', isLessThan: '$query\uf8ff')
            .limit(10)
            .get();

        return snapshot.docs
            .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Поиск по имени - корректная обработка иврита
      final searchQuery = _normalizeForSearch(query);
      final snapshot = await _firestore
          .collection('clients')
          .where('companyId', isEqualTo: targetCompanyId)
          .where('nameLowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('nameLowercase', isLessThan: '$searchQuery\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
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
    await _firestore.collection('clients').add({
      ...client.toMap(),
      'nameLowercase': _normalizeForSearch(client.name),
    });
  }

  /// Обновить существующего клиента
  Future<void> updateClient(String clientId, ClientModel client) async {
    await _firestore.collection('clients').doc(clientId).update({
      ...client.toMap(),
      'nameLowercase': _normalizeForSearch(client.name),
    });
  }

  /// Получить клиента по ID
  Future<ClientModel?> getClientById(String clientId) async {
    try {
      final doc = await _firestore.collection('clients').doc(clientId).get();
      if (doc.exists) {
        return ClientModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Найти клиента по имени и номеру
  Future<ClientModel?> findClientByNameAndNumber(
      String name, String clientNumber,
      [String? overrideCompanyId]) async {
    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      print(
          '⚠️ Warning: companyId is null or empty in findClientByNameAndNumber');
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('companyId', isEqualTo: targetCompanyId)
          .where('name', isEqualTo: name)
          .where('clientNumber', isEqualTo: clientNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ClientModel.fromMap(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Очистить всех клиентов
  Future<void> clearAllClients() async {
    final clients = await _firestore.collection('clients').get();
    for (final doc in clients.docs) {
      await doc.reference.delete();
    }
  }

  /// Исправить nameLowercase для существующих клиентов (если нужно)
  Future<void> fixHebrewSearchIndex() async {
    debugPrint('🔧 [ClientService] Fixing Hebrew search index...');

    final clients = await _firestore.collection('clients').get();
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
  }

  /// Создать тестовых клиентов (однократно)
  Future<void> createTestClients([String? overrideCompanyId]) async {
    final targetCompanyId = overrideCompanyId ?? companyId;
    if (targetCompanyId == null || targetCompanyId.isEmpty) {
      throw Exception('companyId is required for createTestClients');
    }

    // Проверяем, есть ли клиенты для этой компании
    final existing = await _firestore
        .collection('clients')
        .where('companyId', isEqualTo: targetCompanyId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

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
        final locations = await geocoding.locationFromAddress(data['address']!);

        // ❌ БЕЗ FALLBACK! Если геокодирование не удалось - пропускаем
        if (locations.isEmpty) {
          debugPrint('❌ [TestData] No location found for "${data['address']}"');
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
          companyId: targetCompanyId,
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
  }

  /// Удалить клиента
  Future<void> deleteClient(String clientId) async {
    await _firestore.collection('clients').doc(clientId).delete();
    debugPrint('✅ [ClientService] Deleted client: $clientId');
  }
}
