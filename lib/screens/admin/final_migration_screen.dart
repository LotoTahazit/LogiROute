import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/locale_service.dart';

/// Финальная миграция: перемещение оставшихся коллекций внутрь компании
class FinalMigrationScreen extends StatefulWidget {
  const FinalMigrationScreen({super.key});

  @override
  State<FinalMigrationScreen> createState() => _FinalMigrationScreenState();
}

class _FinalMigrationScreenState extends State<FinalMigrationScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;
  final List<String> _logs = [];
  final _scrollController = ScrollController();

  // Маппинг: старая коллекция → новая коллекция внутри компании
  final Map<String, String> _collectionsToMigrate = {
    'settings': 'settings',
    'companySettings': 'company_info',
    'cached_routes': 'cached_routes',
    'backups': 'backups',
    'inventory_counts': 'inventory_counts',
    'inventory_history': 'inventory_history',
    'counters': 'counters',
    'daily_summaries': 'daily_summaries',
    'driver_locations': 'driver_locations',
    'notifications': 'notifications',
  };

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    _addLog('🔍 Проверка коллекций на ROOT уровне...\n');

    for (final entry in _collectionsToMigrate.entries) {
      final oldCollection = entry.key;
      try {
        final snapshot = await _firestore.collection(oldCollection).get();
        _addLog('📊 $oldCollection: ${snapshot.docs.length} документов');
      } catch (e) {
        _addLog('❌ Ошибка проверки $oldCollection: $e');
      }
    }

    _addLog('\n🔍 Проверка коллекций внутри Y.C. Plast...\n');

    for (final entry in _collectionsToMigrate.entries) {
      final newCollection = entry.value;
      try {
        final snapshot = await _firestore
            .collection('companies')
            .doc('Y.C. Plast')
            .collection(newCollection)
            .get();
        _addLog(
            '📊 companies/Y.C. Plast/$newCollection: ${snapshot.docs.length} документов');
      } catch (e) {
        _addLog('❌ Ошибка проверки $newCollection: $e');
      }
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _startMigration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Подтверждение миграции'),
        content: const Text(
          'Вы уверены, что хотите переместить все коллекции внутрь компании?\n\n'
          'Это действие:\n'
          '• Скопирует данные в новое место\n'
          '• Удалит старые коллекции\n'
          '• Потребует обновления кода сервисов\n\n'
          'Убедитесь, что сделали backup!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Начать миграцию'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    _addLog('🚀 Начало финальной миграции...\n');

    const companyId = 'Y.C. Plast';

    for (final entry in _collectionsToMigrate.entries) {
      final oldCollection = entry.key;
      final newCollection = entry.value;

      try {
        _addLog(
            '🔄 Миграция $oldCollection → companies/$companyId/$newCollection');
        await _migrateCollection(oldCollection, companyId, newCollection);
        _addLog('✅ $oldCollection перенесена\n');
      } catch (e) {
        _addLog('❌ Ошибка миграции $oldCollection: $e\n');
      }
    }

    _addLog('✅ Миграция завершена!\n');

    // Спрашиваем об удалении старых коллекций
    if (mounted) {
      final deleteOld = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Миграция завершена'),
          content: const Text(
            'Все коллекции перенесены внутрь компании!\n\n'
            'Удалить старые коллекции с ROOT уровня?\n\n'
            'ВНИМАНИЕ: После удаления старый код перестанет работать!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Оставить старые'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Удалить старые'),
            ),
          ],
        ),
      );

      if (deleteOld == true) {
        await _deleteOldCollections();
      }
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _migrateCollection(
    String oldCollection,
    String companyId,
    String newCollection,
  ) async {
    // Читаем все документы из старой коллекции
    final oldSnapshot = await _firestore.collection(oldCollection).get();

    if (oldSnapshot.docs.isEmpty) {
      _addLog('   ℹ️ Нет данных для миграции');
      return;
    }

    _addLog('   📊 Найдено документов: ${oldSnapshot.docs.length}');

    // Копируем в новую коллекцию
    final batch = _firestore.batch();
    int count = 0;

    for (final doc in oldSnapshot.docs) {
      final data = doc.data();

      final newRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection(newCollection)
          .doc(doc.id);

      batch.set(newRef, data);
      count++;

      // Commit каждые 500 документов
      if (count % 500 == 0) {
        await batch.commit();
        _addLog('   ✅ Перенесено: $count/${oldSnapshot.docs.length}');
      }
    }

    // Commit оставшиеся
    if (count % 500 != 0) {
      await batch.commit();
    }

    _addLog('   ✅ Перенесено документов: $count');
  }

  Future<void> _deleteOldCollections() async {
    _addLog('\n🗑️ Начало удаления старых коллекций...\n');

    for (final oldCollection in _collectionsToMigrate.keys) {
      try {
        _addLog('🔄 Удаление $oldCollection...');
        await _deleteCollection(oldCollection);
        _addLog('✅ $oldCollection удалена\n');
      } catch (e) {
        _addLog('❌ Ошибка удаления $oldCollection: $e\n');
      }
    }

    _addLog('✅ Старые коллекции удалены!');
  }

  Future<void> _deleteCollection(String collectionName) async {
    const batchSize = 500;

    while (true) {
      final snapshot =
          await _firestore.collection(collectionName).limit(batchSize).get();

      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _addLog('     📦 Удалено ${snapshot.docs.length} документов');

      if (snapshot.docs.length < batchSize) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔄 Финальная миграция коллекций'),
          backgroundColor: Colors.orange,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Финальная миграция',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Этот скрипт переместит следующие коллекции внутрь компании:\n\n'
                        '• settings → companies/Y.C. Plast/settings/\n'
                        '• companySettings → companies/Y.C. Plast/company_info/\n'
                        '• cached_routes → companies/Y.C. Plast/cached_routes/\n'
                        '• backups → companies/Y.C. Plast/backups/\n'
                        '• inventory_counts → companies/Y.C. Plast/inventory_counts/\n'
                        '• inventory_history → companies/Y.C. Plast/inventory_history/\n'
                        '• counters → companies/Y.C. Plast/counters/\n'
                        '• daily_summaries → companies/Y.C. Plast/daily_summaries/\n'
                        '• driver_locations → companies/Y.C. Plast/driver_locations/\n'
                        '• notifications → companies/Y.C. Plast/notifications/\n\n'
                        '⚠️ После миграции нужно обновить код сервисов!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (narrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _checkStatus,
                      icon: const Icon(Icons.search),
                      label: const Text('Проверить статус'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _startMigration,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Начать миграцию'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _checkStatus,
                        icon: const Icon(Icons.search),
                        label: const Text('Проверить статус'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _startMigration,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Начать миграцию'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade200,
                        child: const Text(
                          '📋 Лог операций',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _logs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Нажмите кнопку для начала',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      _logs[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
