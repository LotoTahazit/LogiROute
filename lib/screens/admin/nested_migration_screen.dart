import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

/// Экран миграции данных в nested collections
class NestedMigrationScreen extends StatefulWidget {
  const NestedMigrationScreen({super.key});

  @override
  State<NestedMigrationScreen> createState() => _NestedMigrationScreenState();
}

class _NestedMigrationScreenState extends State<NestedMigrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isMigrating = false;
  final Map<String, MigrationStatus> _status = {};
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миграция в Nested Collections'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Предупреждение
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'ВАЖНО!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Миграция переносит данные из старых коллекций в новые вложенные\n'
                      '• Старые данные НЕ удаляются автоматически\n'
                      '• Рекомендуется сделать backup перед миграцией\n'
                      '• Процесс может занять несколько минут',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Статус миграции
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статус миграции:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Список коллекций
                      _buildCollectionStatus('box_types', 'Типы коробок'),
                      _buildCollectionStatus('clients', 'Клиенты'),
                      _buildCollectionStatus(
                          'delivery_points', 'Точки доставки'),
                      _buildCollectionStatus('invoices', 'Счета'),
                      _buildCollectionStatus('prices', 'Цены'),
                      _buildCollectionStatus('inventory', 'Инвентарь'),

                      const Divider(height: 32),

                      // Логи
                      const Text(
                        'Логи:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                _logs[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMigrating ? null : _startMigration,
                    icon: _isMigrating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label:
                        Text(_isMigrating ? 'Миграция...' : 'Начать миграцию'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMigrating ? null : _checkStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Проверить статус'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionStatus(String collection, String label) {
    final status = _status[collection] ?? MigrationStatus.pending;

    IconData icon;
    Color color;
    String statusText;

    switch (status) {
      case MigrationStatus.pending:
        icon = Icons.pending;
        color = Colors.grey;
        statusText = 'Ожидание';
        break;
      case MigrationStatus.inProgress:
        icon = Icons.sync;
        color = Colors.blue;
        statusText = 'В процессе...';
        break;
      case MigrationStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Завершено';
        break;
      case MigrationStatus.error:
        icon = Icons.error;
        color = Colors.red;
        statusText = 'Ошибка';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    print(message);
  }

  Future<void> _checkStatus() async {
    _log('🔍 Проверка статуса...');

    final collections = [
      'box_types',
      'clients',
      'delivery_points',
      'invoices',
      'prices',
      'inventory',
    ];

    for (final collection in collections) {
      final oldCount = await _firestore.collection(collection).count().get();
      _log('📊 $collection: ${oldCount.count} документов в старой коллекции');

      // Проверяем уникальные companyId в этой коллекции
      final snapshot = await _firestore.collection(collection).limit(100).get();
      final companyIds = <String>{};

      for (final doc in snapshot.docs) {
        final companyId = doc.data()['companyId'] as String?;
        if (companyId != null && companyId.isNotEmpty) {
          companyIds.add(companyId);
        } else {
          companyIds.add('(пусто)');
        }
      }

      _log('   CompanyIds: ${companyIds.join(", ")}');
    }
  }

  Future<void> _startMigration() async {
    final authService = context.read<AuthService>();
    final user = authService.userModel;

    if (user == null) {
      _log('❌ Пользователь не авторизован');
      return;
    }

    // Подтверждение
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
          'Вы уверены что хотите начать миграцию?\n\n'
          'Это действие перенесет все данные в новую структуру.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Начать'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMigrating = true;
      _logs.clear();
    });

    try {
      _log('🚀 Начало миграции...');

      // Собираем все уникальные companyId из старых коллекций
      final companyIds = <String>{};

      final collections = [
        'box_types',
        'clients',
        'delivery_points',
        'invoices',
        'prices',
        'inventory',
      ];

      _log('🔍 Поиск компаний в старых коллекциях...');

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (final doc in snapshot.docs) {
          final companyId = doc.data()['companyId'] as String?;
          if (companyId != null && companyId.isNotEmpty) {
            companyIds.add(companyId);
          }
        }
      }

      _log('📊 Найдено уникальных компаний: ${companyIds.length}');
      _log('   Компании: ${companyIds.join(", ")}');

      if (companyIds.isEmpty) {
        _log('⚠️ Не найдено компаний для миграции');
        return;
      }

      for (final companyId in companyIds) {
        _log('\n📦 Миграция компании: $companyId');

        // Мигрируем каждую коллекцию
        await _migrateCollection('box_types', companyId);
        await _migrateCollection('clients', companyId);
        await _migrateCollection('delivery_points', companyId);
        await _migrateCollection('invoices', companyId);
        await _migrateCollection('prices', companyId);
        await _migrateCollection('inventory', companyId);
      }

      _log('\n✅ Миграция завершена успешно!');

      // Спрашиваем, удалить ли старые коллекции
      if (mounted) {
        final deleteOld = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Миграция завершена'),
            content: const Text(
              'Миграция прошла успешно!\n\n'
              'Удалить старые коллекции?\n\n'
              'Это действие НЕОБРАТИМО. Убедитесь, что все данные '
              'корректно перенесены в nested collections.',
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Миграция завершена успешно!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _log('❌ Ошибка миграции: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateCollection(
      String collectionName, String companyId) async {
    setState(() {
      _status[collectionName] = MigrationStatus.inProgress;
    });

    try {
      _log('  🔄 Миграция $collectionName...');

      // Читаем ВСЕ документы из старой коллекции (без фильтра по companyId)
      final oldSnapshot = await _firestore.collection(collectionName).get();

      final docs = oldSnapshot.docs;
      _log('  📊 Найдено документов: ${docs.length}');

      if (docs.isEmpty) {
        _log('  ℹ️ Нет данных для миграции');
        setState(() {
          _status[collectionName] = MigrationStatus.completed;
        });
        return;
      }

      // Копируем в новую коллекцию
      final batch = _firestore.batch();
      int count = 0;

      for (final doc in docs) {
        final data = doc.data();

        // Добавляем companyId если его нет
        if (!data.containsKey('companyId') ||
            data['companyId'] == null ||
            data['companyId'] == '') {
          data['companyId'] = companyId;
        }

        final newRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection(collectionName)
            .doc(doc.id);

        batch.set(newRef, data);
        count++;

        // Commit каждые 500 документов
        if (count % 500 == 0) {
          await batch.commit();
          _log('  ✅ Перенесено: $count/${docs.length}');
        }
      }

      // Commit оставшиеся
      if (count % 500 != 0) {
        await batch.commit();
      }

      _log('  ✅ $collectionName: перенесено $count документов');

      setState(() {
        _status[collectionName] = MigrationStatus.completed;
      });
    } catch (e) {
      _log('  ❌ Ошибка в $collectionName: $e');
      setState(() {
        _status[collectionName] = MigrationStatus.error;
      });
      rethrow;
    }
  }

  Future<void> _deleteOldCollections() async {
    _log('\n🗑️ Начало удаления старых коллекций...');

    final collections = [
      'box_types',
      'clients',
      'delivery_points',
      'invoices',
      'prices',
      'inventory',
    ];

    for (final collection in collections) {
      try {
        _log('  🔄 Удаление $collection...');
        await _deleteCollection(collection);
        _log('  ✅ $collection удалена');
      } catch (e) {
        _log('  ❌ Ошибка удаления $collection: $e');
      }
    }

    _log('✅ Старые коллекции удалены!');
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

      _log('     📦 Удалено ${snapshot.docs.length} документов');

      if (snapshot.docs.length < batchSize) break;
    }
  }
}

enum MigrationStatus {
  pending,
  inProgress,
  completed,
  error,
}
