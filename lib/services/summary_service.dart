import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/daily_summary.dart';
import '../models/invoice.dart';
import '../models/delivery_point.dart';

/// Service for managing daily summaries
/// ⚡ OPTIMIZATION: Aggregates data to reduce reads
///
/// Instead of querying 50+ invoices, read 1 summary document
class SummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String companyId;

  SummaryService({required this.companyId});

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Get or create daily invoice summary
  Future<DailySummary> getDailyInvoiceSummary(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final doc = await _firestore
          .collection('daily_summaries')
          .doc('invoices_$dateKey')
          .get();

      if (doc.exists) {
        return DailySummary.fromMap(doc.data()!, doc.id);
      }

      return DailySummary.empty(dateKey);
    } catch (e) {
      print('❌ [SummaryService] Error getting invoice summary: $e');
      return DailySummary.empty(_getDateKey(date));
    }
  }

  /// Get or create daily delivery summary
  Future<DeliverySummary> getDailyDeliverySummary(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final doc = await _firestore
          .collection('daily_summaries')
          .doc('deliveries_$dateKey')
          .get();

      if (doc.exists) {
        return DeliverySummary.fromMap(doc.data()!, doc.id);
      }

      return DeliverySummary.empty(dateKey);
    } catch (e) {
      print('❌ [SummaryService] Error getting delivery summary: $e');
      return DeliverySummary.empty(_getDateKey(date));
    }
  }

  /// Listen to daily invoice summary (realtime)
  /// ⚡ Only 1 document read per update instead of 50+
  Stream<DailySummary> watchDailyInvoiceSummary(DateTime date) {
    final dateKey = _getDateKey(date);
    return _firestore
        .collection('daily_summaries')
        .doc('invoices_$dateKey')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return DailySummary.fromMap(snapshot.data()!, snapshot.id);
      }
      return DailySummary.empty(dateKey);
    });
  }

  /// Listen to daily delivery summary (realtime)
  Stream<DeliverySummary> watchDailyDeliverySummary(DateTime date) {
    final dateKey = _getDateKey(date);
    return _firestore
        .collection('daily_summaries')
        .doc('deliveries_$dateKey')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return DeliverySummary.fromMap(snapshot.data()!, snapshot.id);
      }
      return DeliverySummary.empty(dateKey);
    });
  }

  /// Update invoice summary (called when invoice created/cancelled)
  /// Should be called via Cloud Function or transaction
  Future<void> updateInvoiceSummary(Invoice invoice) async {
    try {
      final dateKey = _getDateKey(invoice.createdAt);
      final summaryRef =
          _firestore.collection('daily_summaries').doc('invoices_$dateKey');

      await _firestore.runTransaction((transaction) async {
        final summary = await transaction.get(summaryRef);

        if (!summary.exists) {
          // Create new summary
          transaction.set(summaryRef, {
            'date': dateKey,
            'totalInvoices': 1,
            'totalAmount': invoice.totalWithVAT,
            'byStatus': {invoice.status.name: 1},
            'byDriver': {invoice.driverName: 1},
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing summary
          final data = summary.data();
          if (data == null) {
            debugPrint('❌ [Summary] Summary exists but data is null');
            return;
          }

          final byStatus = Map<String, int>.from(data['byStatus'] ?? {});
          final byDriver = Map<String, int>.from(data['byDriver'] ?? {});

          byStatus[invoice.status.name] =
              (byStatus[invoice.status.name] ?? 0) + 1;
          byDriver[invoice.driverName] =
              (byDriver[invoice.driverName] ?? 0) + 1;

          transaction.update(summaryRef, {
            'totalInvoices': FieldValue.increment(1),
            'totalAmount': FieldValue.increment(invoice.totalWithVAT),
            'byStatus': byStatus,
            'byDriver': byDriver,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('❌ [SummaryService] Error updating invoice summary: $e');
      rethrow;
    }
  }

  /// Update delivery summary (called when point status changes)
  Future<void> updateDeliverySummary(DeliveryPoint point) async {
    try {
      // Use createdAt or current date if deliveryDate doesn't exist
      final date = DateTime.now(); // TODO: Use actual delivery date from point
      final dateKey = _getDateKey(date);
      final summaryRef =
          _firestore.collection('daily_summaries').doc('deliveries_$dateKey');

      await _firestore.runTransaction((transaction) async {
        final summary = await transaction.get(summaryRef);

        final statusCounts = {
          'pending': 0,
          'assigned': 0,
          'in_progress': 0,
          'completed': 0,
          'cancelled': 0,
        };

        if (!summary.exists) {
          // Create new summary
          statusCounts[point.status] = 1;

          transaction.set(summaryRef, {
            'date': dateKey,
            'totalPoints': 1,
            ...statusCounts,
            'byDriver': {point.driverId ?? 'unassigned': 1},
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Update existing summary
          final data = summary.data();
          if (data == null) {
            debugPrint('❌ [Summary] Delivery summary exists but data is null');
            return;
          }

          final byDriver = Map<String, int>.from(data['byDriver'] ?? {});

          final driverKey = point.driverId ?? 'unassigned';
          byDriver[driverKey] = (byDriver[driverKey] ?? 0) + 1;

          transaction.update(summaryRef, {
            'totalPoints': FieldValue.increment(1),
            point.status: FieldValue.increment(1),
            'byDriver': byDriver,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('❌ [SummaryService] Error updating delivery summary: $e');
      rethrow;
    }
  }

  /// Rebuild summary from scratch (for data migration or fixes)
  Future<void> rebuildInvoiceSummary(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query all invoices for this date
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('accounting')
          .doc('_root')
          .collection('invoices')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      // Calculate summary
      int totalInvoices = 0;
      double totalAmount = 0.0;
      final byStatus = <String, int>{};
      final byDriver = <String, int>{};

      for (final doc in snapshot.docs) {
        final invoice = Invoice.fromMap(doc.data(), doc.id);
        totalInvoices++;
        totalAmount += invoice.totalWithVAT;
        byStatus[invoice.status.name] =
            (byStatus[invoice.status.name] ?? 0) + 1;
        byDriver[invoice.driverName] = (byDriver[invoice.driverName] ?? 0) + 1;
      }

      // Save summary
      await _firestore
          .collection('daily_summaries')
          .doc('invoices_$dateKey')
          .set({
        'date': dateKey,
        'totalInvoices': totalInvoices,
        'totalAmount': totalAmount,
        'byStatus': byStatus,
        'byDriver': byDriver,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print(
          '✅ [SummaryService] Rebuilt invoice summary for $dateKey: $totalInvoices invoices');
    } catch (e) {
      print('❌ [SummaryService] Error rebuilding invoice summary: $e');
      rethrow;
    }
  }

  /// Rebuild delivery summary from scratch
  Future<void> rebuildDeliverySummary(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query all delivery points for this date
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('logistics')
          .doc('_root')
          .collection('delivery_points')
          .where('deliveryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('deliveryDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      // Calculate summary
      int totalPoints = 0;
      final statusCounts = {
        'pending': 0,
        'assigned': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
      };
      final byDriver = <String, int>{};

      for (final doc in snapshot.docs) {
        final point = DeliveryPoint.fromMap(doc.data(), doc.id);
        totalPoints++;
        statusCounts[point.status] = (statusCounts[point.status] ?? 0) + 1;
        final driverKey = point.driverId ?? 'unassigned';
        byDriver[driverKey] = (byDriver[driverKey] ?? 0) + 1;
      }

      // Save summary
      await _firestore
          .collection('daily_summaries')
          .doc('deliveries_$dateKey')
          .set({
        'date': dateKey,
        'totalPoints': totalPoints,
        ...statusCounts,
        'byDriver': byDriver,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print(
          '✅ [SummaryService] Rebuilt delivery summary for $dateKey: $totalPoints points');
    } catch (e) {
      print('❌ [SummaryService] Error rebuilding delivery summary: $e');
      rethrow;
    }
  }
}
