import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/system_event.dart';

/// Репозиторий для чтения системных событий компании.
///
/// Работает с коллекцией `/companies/{companyId}/systemEvents/{eventId}`.
/// Read-only: системные события заполняются Cloud Functions / сервером,
/// клиент только читает.
///
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class SystemEventsRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  SystemEventsRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию systemEvents компании.
  CollectionReference<Map<String, dynamic>> get _systemEventsCollection =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('systemEvents');

  /// Стрим системных событий в реальном времени, отсортированных
  /// по убыванию `createdAt`.
  ///
  /// Если [statusFilter] указан, возвращает только события с данным статусом.
  Stream<List<SystemEvent>> watchSystemEvents({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _systemEventsCollection;

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        return SystemEvent.fromMap(data);
      }).toList();
    });
  }

  /// Возвращает статистику ретраев по всем системным событиям.
  ///
  /// Результат содержит:
  /// - `totalRetries` — сумма `retryCount` по всем событиям
  /// - `totalEvents` — общее количество событий
  /// - `successCount` — количество событий со статусом `success`
  /// - `successRate` — процент успешных (0.0–100.0), или 0.0 если событий нет
  Future<Map<String, dynamic>> getRetryStats() async {
    final snapshot = await _systemEventsCollection.get();

    int totalRetries = 0;
    int totalEvents = snapshot.docs.length;
    int successCount = 0;

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      totalRetries += ((data['retryCount'] ?? 0) as num).toInt();
      if (data['status'] == 'success') {
        successCount++;
      }
    }

    final successRate =
        totalEvents > 0 ? (successCount / totalEvents) * 100.0 : 0.0;

    return {
      'totalRetries': totalRetries,
      'totalEvents': totalEvents,
      'successCount': successCount,
      'successRate': successRate,
    };
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for SystemEventsRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
