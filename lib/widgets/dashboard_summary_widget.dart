import 'package:flutter/material.dart';
import '../models/daily_summary.dart';
import '../services/summary_service.dart';

/// Dashboard summary widget using optimized queries
/// ⚡ OPTIMIZATION: Reads 1 summary doc instead of 50+ invoices
///
/// Cost comparison:
/// - Old: 50+ reads per load + realtime updates
/// - New: 1 read per load + 1 read per update
/// Savings: ~98% reduction in reads
class DashboardSummaryWidget extends StatelessWidget {
  final DateTime date;
  final String companyId;

  const DashboardSummaryWidget({
    super.key,
    required this.date,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final summaryService = SummaryService(companyId: companyId);

    return StreamBuilder<DailySummary>(
      stream: summaryService.watchDailyInvoiceSummary(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data ?? DailySummary.empty('');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סיכום יומי - ${summary.date}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'סה"כ חשבוניות',
                  summary.totalInvoices.toString(),
                  Icons.receipt,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'סה"כ סכום',
                  '₪${summary.totalAmount.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'לפי סטטוס:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...summary.byStatus.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getStatusLabel(entry.key)),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'לפי נהג:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...summary.byDriver.entries.take(5).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'פעיל';
      case 'cancelled':
        return 'מבוטל';
      case 'draft':
        return 'טיוטה';
      default:
        return status;
    }
  }
}

/// Delivery summary widget
class DeliverySummaryWidget extends StatelessWidget {
  final DateTime date;
  final String companyId;

  const DeliverySummaryWidget({
    super.key,
    required this.date,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final summaryService = SummaryService(companyId: companyId);

    return StreamBuilder<DeliverySummary>(
      stream: summaryService.watchDailyDeliverySummary(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data ?? DeliverySummary.empty('');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'משלוחים - ${summary.date}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildProgressBar(
                  'התקדמות',
                  summary.completionRate,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusChip(
                      'ממתין',
                      summary.pending,
                      Colors.orange,
                    ),
                    _buildStatusChip(
                      'בדרך',
                      summary.activePoints,
                      Colors.blue,
                    ),
                    _buildStatusChip(
                      'הושלם',
                      summary.completed,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${percentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
