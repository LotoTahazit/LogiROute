import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../models/daily_metrics.dart';

/// Сервис агрегированных метрик для секции «Обзор».
///
/// Читает данные из `/companies/{companyId}/metrics/daily/{YYYY-MM-DD}`.
/// Daily Metrics заполняются Cloud Function, клиент только читает.
class MetricsService {
  final FirebaseFirestore _firestore;
  final String companyId;

  MetricsService({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Ссылка на документ метрик по dateKey (YYYY-MM-DD).
  ///
  /// Путь: `/companies/{companyId}/metrics/daily/{dateKey}`
  /// В Firestore: companies/{companyId} → metrics (col) → daily (doc) → days (col) → {dateKey} (doc)
  DocumentReference<Map<String, dynamic>> _metricsDoc(String dateKey) =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('metrics')
          .doc('daily')
          .collection('days')
          .doc(dateKey);

  /// Возвращает метрики за сегодня.
  ///
  /// Если документ не существует, возвращает пустые метрики с текущей датой.
  Future<DailyMetrics> getTodayMetrics() async {
    final dateKey = _dateFormat.format(DateTime.now());
    final doc = await _metricsDoc(dateKey).get();
    if (!doc.exists || doc.data() == null) {
      return DailyMetrics(date: dateKey);
    }
    return DailyMetrics.fromMap(Map<String, dynamic>.from(doc.data()! as Map));
  }

  /// Возвращает метрики за диапазон дат [from, to] включительно.
  ///
  /// Итерирует по каждому дню в диапазоне и возвращает только существующие документы.
  Future<List<DailyMetrics>> getMetricsRange(
    DateTime from,
    DateTime to,
  ) async {
    final results = <DailyMetrics>[];
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!current.isAfter(end)) {
      final dateKey = _dateFormat.format(current);
      final doc = await _metricsDoc(dateKey).get();
      if (doc.exists && doc.data() != null) {
        results.add(DailyMetrics.fromMap(
            Map<String, dynamic>.from(doc.data()! as Map)));
      }
      current = current.add(const Duration(days: 1));
    }
    return results;
  }

  /// Стрим метрик за сегодня (real-time updates через Firestore snapshots).
  ///
  /// Если документ не существует, эмитит пустые метрики с текущей датой.
  Stream<DailyMetrics> watchTodayMetrics() {
    final dateKey = _dateFormat.format(DateTime.now());
    return _metricsDoc(dateKey).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return DailyMetrics(date: dateKey);
      }
      return DailyMetrics.fromMap(
          Map<String, dynamic>.from(snap.data()! as Map));
    });
  }

  /// Пересчёт KPI за день через Cloud Function (admin/owner/super_admin).
  Future<Map<String, dynamic>> recalculateDailyMetrics({String? dateKey}) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('recalculateDailyMetrics');
    final result = await callable.call<Map<String, dynamic>>({
      'companyId': companyId,
      if (dateKey != null) 'date': dateKey,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
