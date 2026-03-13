import 'package:cloud_firestore/cloud_firestore.dart';

/// DailyMetrics-документ: `/companies/{companyId}/metrics/daily/{YYYY-MM-DD}`
///
/// Агрегированные дневные метрики компании. Заполняются Cloud Function,
/// клиент только читает.
class DailyMetrics {
  final String date;
  final int deliveriesToday;
  final int invoicesThisMonth;
  final int warehouseMovements;
  final int activeDrivers;
  final int printEventsToday;
  final int printErrorsToday;
  final int recordsCreatedToday;
  final DateTime? updatedAt;

  DailyMetrics({
    required this.date,
    this.deliveriesToday = 0,
    this.invoicesThisMonth = 0,
    this.warehouseMovements = 0,
    this.activeDrivers = 0,
    this.printEventsToday = 0,
    this.printErrorsToday = 0,
    this.recordsCreatedToday = 0,
    this.updatedAt,
  });

  factory DailyMetrics.fromMap(Map<String, dynamic> map) {
    int i(String key) => ((map[key] ?? 0) as num).toInt();
    return DailyMetrics(
      date: map['date'] ?? '',
      deliveriesToday: i('deliveriesToday'),
      invoicesThisMonth: i('invoicesThisMonth'),
      warehouseMovements: i('warehouseMovements'),
      activeDrivers: i('activeDrivers'),
      printEventsToday: i('printEventsToday'),
      printErrorsToday: i('printErrorsToday'),
      recordsCreatedToday: i('recordsCreatedToday'),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'deliveriesToday': deliveriesToday,
      'invoicesThisMonth': invoicesThisMonth,
      'warehouseMovements': warehouseMovements,
      'activeDrivers': activeDrivers,
      'printEventsToday': printEventsToday,
      'printErrorsToday': printErrorsToday,
      'recordsCreatedToday': recordsCreatedToday,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
