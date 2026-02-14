import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily summary for dashboard
/// ⚡ OPTIMIZATION: Single document instead of querying all invoices
///
/// Updated via Cloud Function or transaction when invoices change
/// Typical size: ~500 bytes vs 50+ invoice reads
class DailySummary {
  final String date; // yyyy-MM-dd
  final int totalInvoices;
  final double totalAmount;
  final Map<String, int> byStatus; // {active: 42, cancelled: 3}
  final Map<String, int> byDriver; // {driver1: 15, driver2: 20}
  final DateTime lastUpdated;

  DailySummary({
    required this.date,
    required this.totalInvoices,
    required this.totalAmount,
    required this.byStatus,
    required this.byDriver,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalInvoices': totalInvoices,
      'totalAmount': totalAmount,
      'byStatus': byStatus,
      'byDriver': byDriver,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map, String id) {
    return DailySummary(
      date: id,
      totalInvoices: map['totalInvoices'] ?? 0,
      totalAmount: (map['totalAmount'] is num)
          ? (map['totalAmount'] as num).toDouble()
          : 0.0,
      byStatus: Map<String, int>.from(map['byStatus'] ?? {}),
      byDriver: Map<String, int>.from(map['byDriver'] ?? {}),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory DailySummary.empty(String date) {
    return DailySummary(
      date: date,
      totalInvoices: 0,
      totalAmount: 0.0,
      byStatus: {},
      byDriver: {},
      lastUpdated: DateTime.now(),
    );
  }
}

/// Delivery summary for dispatcher dashboard
class DeliverySummary {
  final String date; // yyyy-MM-dd
  final int totalPoints;
  final int pending;
  final int assigned;
  final int inProgress;
  final int completed;
  final int cancelled;
  final Map<String, int> byDriver; // {driverId: count}
  final DateTime lastUpdated;

  DeliverySummary({
    required this.date,
    required this.totalPoints,
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.byDriver,
    required this.lastUpdated,
  });

  int get activePoints => assigned + inProgress;
  double get completionRate =>
      totalPoints > 0 ? (completed / totalPoints) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalPoints': totalPoints,
      'pending': pending,
      'assigned': assigned,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
      'byDriver': byDriver,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory DeliverySummary.fromMap(Map<String, dynamic> map, String id) {
    return DeliverySummary(
      date: id,
      totalPoints: map['totalPoints'] ?? 0,
      pending: map['pending'] ?? 0,
      assigned: map['assigned'] ?? 0,
      inProgress: map['inProgress'] ?? 0,
      completed: map['completed'] ?? 0,
      cancelled: map['cancelled'] ?? 0,
      byDriver: Map<String, int>.from(map['byDriver'] ?? {}),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory DeliverySummary.empty(String date) {
    return DeliverySummary(
      date: date,
      totalPoints: 0,
      pending: 0,
      assigned: 0,
      inProgress: 0,
      completed: 0,
      cancelled: 0,
      byDriver: {},
      lastUpdated: DateTime.now(),
    );
  }
}
