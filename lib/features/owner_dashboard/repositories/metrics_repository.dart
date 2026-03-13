import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_metrics.dart';

/// Репозиторий для чтения агрегированных дневных метрик компании.
///
/// Работает с коллекцией `/companies/{companyId}/metrics/daily/days/{YYYY-MM-DD}`.
/// Read-only: метрики заполняются Cloud Functions, клиент только читает.
///
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class MetricsRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  MetricsRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на документ метрик по [dateKey] (YYYY-MM-DD).
  ///
  /// Путь: companies/{companyId} → metrics (col) → daily (doc) → days (col) → {dateKey} (doc)
  DocumentReference<Map<String, dynamic>> _metricsDoc(String dateKey) =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('metrics')
          .doc('daily')
          .collection('days')
          .doc(dateKey);

  /// Загружает метрики за указанный день.
  ///
  /// Возвращает `null`, если документ не существует.
  Future<DailyMetrics?> getDailyMetrics(String dateKey) async {
    final doc = await _metricsDoc(dateKey).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return DailyMetrics.fromMap(doc.data()!);
  }

  /// Стрим метрик за указанный день (real-time updates через Firestore snapshots).
  ///
  /// Эмитит `null`, если документ не существует.
  Stream<DailyMetrics?> watchDailyMetrics(String dateKey) {
    return _metricsDoc(dateKey).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return null;
      }
      return DailyMetrics.fromMap(snap.data()!);
    });
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for MetricsRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
