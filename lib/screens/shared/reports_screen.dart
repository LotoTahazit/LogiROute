import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/company_context.dart';
import '../../models/delivery_point.dart';
import '../../models/invoice.dart';

/// מסך דוחות — סטטיסטיקות משלוחים, חשבוניות וביצועי נהגים
/// Module: reports (gated via ModuleGuard)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('he'),
    );
    if (picked != null)
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דוחות'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Period selector
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('תקופה: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(
                          '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('עד'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(
                          '${_toDate.day}/${_toDate.month}/${_toDate.year}'),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                    text: 'משלוחים',
                    icon: Icon(Icons.local_shipping, size: 18)),
                Tab(text: 'חשבוניות', icon: Icon(Icons.receipt_long, size: 18)),
                Tab(text: 'נהגים', icon: Icon(Icons.person, size: 18)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DeliveryReport(from: _fromDate, to: _toDate),
                  _InvoiceReport(from: _fromDate, to: _toDate),
                  _DriverReport(from: _fromDate, to: _toDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// Delivery Report Tab
// =========================================================

class _DeliveryReport extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _DeliveryReport({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return const Center(child: Text('לא נבחרה חברה'));

    return FutureBuilder<_DeliveryStats>(
      future: _fetchDeliveryStats(companyId),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final s = snap.data!;
        final total = s.completed + s.pending + s.inProgress + s.cancelled;
        final rate = total > 0 ? (s.completed / total * 100) : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatRow('סה"כ נקודות', '$total'),
            _StatRow('הושלמו', '${s.completed}', color: Colors.green),
            _StatRow('ממתינות', '${s.pending}', color: Colors.blue),
            _StatRow('בדרך', '${s.inProgress}', color: Colors.orange),
            _StatRow('בוטלו', '${s.cancelled}', color: Colors.red),
            const Divider(height: 32),
            _StatRow('סה"כ משטחים', '${s.totalPallets}'),
            _StatRow('משטחים שנמסרו', '${s.deliveredPallets}',
                color: Colors.green),
            const Divider(height: 32),
            _PercentBar(label: 'אחוז השלמה', value: rate),
          ],
        );
      },
    );
  }

  Future<_DeliveryStats> _fetchDeliveryStats(String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_points')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final points =
        snap.docs.map((d) => DeliveryPoint.fromMap(d.data(), d.id)).toList();
    return _DeliveryStats(
      completed:
          points.where((p) => p.status == DeliveryPoint.statusCompleted).length,
      pending:
          points.where((p) => p.status == DeliveryPoint.statusPending).length,
      inProgress: points
          .where((p) =>
              p.status == DeliveryPoint.statusAssigned ||
              p.status == DeliveryPoint.statusInProgress)
          .length,
      cancelled:
          points.where((p) => p.status == DeliveryPoint.statusCancelled).length,
      totalPallets: points.fold<int>(0, (s, p) => s + p.pallets),
      deliveredPallets: points
          .where((p) => p.status == DeliveryPoint.statusCompleted)
          .fold<int>(0, (s, p) => s + p.pallets),
    );
  }
}

class _DeliveryStats {
  final int completed,
      pending,
      inProgress,
      cancelled,
      totalPallets,
      deliveredPallets;
  _DeliveryStats({
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.cancelled,
    required this.totalPallets,
    required this.deliveredPallets,
  });
}

// =========================================================
// Invoice Report Tab
// =========================================================

class _InvoiceReport extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _InvoiceReport({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return const Center(child: Text('לא נבחרה חברה'));

    return FutureBuilder<_InvoiceStats>(
      future: _fetchInvoiceStats(companyId),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final s = snap.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatRow('סה"כ מסמכים', '${s.total}'),
            _StatRow('חשבוניות מס', '${s.invoices}'),
            _StatRow('חשבוניות מס/קבלה', '${s.taxReceipts}'),
            _StatRow('קבלות', '${s.receipts}'),
            _StatRow('תעודות משלוח', '${s.deliveryNotes}'),
            _StatRow('זיכויים', '${s.creditNotes}', color: Colors.red),
            const Divider(height: 32),
            _StatRow('סה"כ לפני מע"מ', '₪${s.netTotal.toStringAsFixed(2)}'),
            _StatRow('מע"מ', '₪${s.vatTotal.toStringAsFixed(2)}'),
            _StatRow('סה"כ כולל מע"מ', '₪${s.grossTotal.toStringAsFixed(2)}',
                color: Colors.green, bold: true),
          ],
        );
      },
    );
  }

  Future<_InvoiceStats> _fetchInvoiceStats(String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final invoices =
        snap.docs.map((d) => Invoice.fromMap(d.data(), d.id)).toList();
    final active = invoices
        .where((i) =>
            i.status == InvoiceStatus.issued ||
            i.status == InvoiceStatus.active)
        .toList();

    return _InvoiceStats(
      total: active.length,
      invoices: active
          .where((i) => i.documentType == InvoiceDocumentType.invoice)
          .length,
      taxReceipts: active
          .where((i) => i.documentType == InvoiceDocumentType.taxInvoiceReceipt)
          .length,
      receipts: active
          .where((i) => i.documentType == InvoiceDocumentType.receipt)
          .length,
      deliveryNotes: active
          .where((i) => i.documentType == InvoiceDocumentType.delivery)
          .length,
      creditNotes: active
          .where((i) => i.documentType == InvoiceDocumentType.creditNote)
          .length,
      netTotal: active.fold<double>(0, (s, i) => s + i.subtotalBeforeVAT),
      vatTotal: active.fold<double>(0, (s, i) => s + i.vatAmount),
      grossTotal: active.fold<double>(0, (s, i) => s + i.totalWithVAT),
    );
  }
}

class _InvoiceStats {
  final int total, invoices, taxReceipts, receipts, deliveryNotes, creditNotes;
  final double netTotal, vatTotal, grossTotal;
  _InvoiceStats({
    required this.total,
    required this.invoices,
    required this.taxReceipts,
    required this.receipts,
    required this.deliveryNotes,
    required this.creditNotes,
    required this.netTotal,
    required this.vatTotal,
    required this.grossTotal,
  });
}

// =========================================================
// Driver Performance Report Tab
// =========================================================

class _DriverReport extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  const _DriverReport({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return const Center(child: Text('לא נבחרה חברה'));

    return FutureBuilder<List<_DriverPerf>>(
      future: _fetchDriverPerf(companyId),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final drivers = snap.data!;
        if (drivers.isEmpty)
          return const Center(child: Text('אין נתונים לתקופה'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final d = drivers[index];
            final rate = d.total > 0 ? (d.completed / d.total * 100) : 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat('נקודות', '${d.total}'),
                        _MiniStat('הושלמו', '${d.completed}',
                            color: Colors.green),
                        _MiniStat('בוטלו', '${d.cancelled}', color: Colors.red),
                        _MiniStat('משטחים', '${d.pallets}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PercentBar(label: 'השלמה', value: rate),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_DriverPerf>> _fetchDriverPerf(String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_points')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final points =
        snap.docs.map((d) => DeliveryPoint.fromMap(d.data(), d.id)).toList();
    final byDriver = <String, List<DeliveryPoint>>{};
    for (final p in points) {
      final key = p.driverName ?? p.driverId ?? 'ללא נהג';
      byDriver.putIfAbsent(key, () => []).add(p);
    }

    final result = byDriver.entries.map((e) {
      final pts = e.value;
      return _DriverPerf(
        name: e.key,
        total: pts.length,
        completed:
            pts.where((p) => p.status == DeliveryPoint.statusCompleted).length,
        cancelled:
            pts.where((p) => p.status == DeliveryPoint.statusCancelled).length,
        pallets: pts.fold<int>(0, (s, p) => s + p.pallets),
      );
    }).toList();

    result.sort((a, b) => b.completed.compareTo(a.completed));
    return result;
  }
}

class _DriverPerf {
  final String name;
  final int total, completed, cancelled, pallets;
  _DriverPerf(
      {required this.name,
      required this.total,
      required this.completed,
      required this.cancelled,
      required this.pallets});
}

// =========================================================
// Shared UI widgets
// =========================================================

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  const _StatRow(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color ?? Colors.black87,
              )),
        ],
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  final String label;
  final double value;
  const _PercentBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 80
        ? Colors.green
        : value >= 50
            ? Colors.orange
            : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('${value.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black87)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
