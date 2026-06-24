import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../services/company_context.dart';
import '../../models/delivery_point.dart';
import '../../models/invoice.dart';
import '../../services/firestore_paths.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logi_route_tab_bar.dart';

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
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
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
                  Text(l10n.periodLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(
                          '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(l10n.toLabel),
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
            LogiRouteTabBar(
              controller: _tabController,
              tabs: [
                LogiRouteTabItem(
                    label: l10n.deliveriesTab,
                    icon: Icons.local_shipping),
                LogiRouteTabItem(
                    label: l10n.invoicesTab, icon: Icons.receipt_long),
                LogiRouteTabItem(
                    label: l10n.driversTab, icon: Icons.person),
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
    final l10n = AppLocalizations.of(context)!;
    if (companyId.isEmpty) {
      return Center(child: Text(l10n.noCompanySelected));
    }

    return FutureBuilder<_DeliveryStats>(
      future: _fetchDeliveryStats(companyId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = snap.data!;
        final total = s.completed + s.pending + s.inProgress + s.cancelled;
        final rate = total > 0 ? (s.completed / total * 100) : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatRow(l10n.totalPointsReport, '$total'),
            _StatRow(l10n.completedReport, '${s.completed}',
                color: Colors.green),
            _StatRow(l10n.pendingReport, '${s.pending}', color: Colors.blue),
            _StatRow(l10n.onTheWay, '${s.inProgress}', color: Colors.orange),
            _StatRow(l10n.cancelledReport, '${s.cancelled}', color: Colors.red),
            const Divider(height: 32),
            _StatRow(l10n.totalPalletsReport, '${s.totalPallets}'),
            _StatRow(l10n.palletsDelivered, '${s.deliveredPallets}',
                color: Colors.green),
            const Divider(height: 32),
            _PercentBar(label: l10n.completionPercent, value: rate),
          ],
        );
      },
    );
  }

  Future<_DeliveryStats> _fetchDeliveryStats(String companyId) async {
    final snap = await FirestorePaths.deliveryPointsOf(companyId)
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
    final l10n = AppLocalizations.of(context)!;
    if (companyId.isEmpty) {
      return Center(child: Text(l10n.noCompanySelected));
    }

    return FutureBuilder<_InvoiceStats>(
      future: _fetchInvoiceStats(companyId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = snap.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatRow(l10n.totalDocumentsReport, '${s.total}'),
            _StatRow(l10n.taxInvoicesReport, '${s.invoices}'),
            _StatRow(l10n.taxInvoiceReceiptsReport, '${s.taxReceipts}'),
            _StatRow(l10n.receiptsReport, '${s.receipts}'),
            _StatRow(l10n.deliveryNotesReport, '${s.deliveryNotes}'),
            _StatRow(l10n.creditNotesReport, '${s.creditNotes}',
                color: Colors.red),
            const Divider(height: 32),
            _StatRow(
                l10n.netBeforeVatReport, '₪${s.netTotal.toStringAsFixed(2)}'),
            _StatRow(l10n.vatAmountReport, '₪${s.vatTotal.toStringAsFixed(2)}'),
            _StatRow(
                l10n.grossWithVatReport, '₪${s.grossTotal.toStringAsFixed(2)}',
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
        // Период по ДАТЕ ДОКУМЕНТА (deliveryDate) — единый базис с owner-отчётом
        // и period-lock. createdAt (момент черновика) увёл бы числа на стыке
        // месяцев и расходился бы со сводкой owner.
        .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('deliveryDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final invoices =
        snap.docs.map((d) => Invoice.fromMap(d.data(), d.id)).toList();
    final active = invoices.where((i) => i.isLive).toList();

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
    final l10n = AppLocalizations.of(context)!;
    if (companyId.isEmpty) {
      return Center(child: Text(l10n.noCompanySelected));
    }

    return FutureBuilder<List<_DriverPerf>>(
      future: _fetchDriverPerf(companyId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final drivers = snap.data!;
        if (drivers.isEmpty) {
          return Center(child: Text(l10n.noDataForPeriod));
        }

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
                    Text(
                        d.name == '__no_driver__'
                            ? l10n.noDriverAssigned
                            : d.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat(l10n.pointsLabel, '${d.total}'),
                        _MiniStat(l10n.completedLabel, '${d.completed}',
                            color: Colors.green),
                        _MiniStat(l10n.cancelledLabel, '${d.cancelled}',
                            color: Colors.red),
                        _MiniStat(l10n.palletsLabel, '${d.pallets}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PercentBar(label: l10n.completionLabel, value: rate),
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
    final snap = await FirestorePaths.deliveryPointsOf(companyId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final points =
        snap.docs.map((d) => DeliveryPoint.fromMap(d.data(), d.id)).toList();
    final byDriver = <String, List<DeliveryPoint>>{};
    for (final p in points) {
      final key = p.driverName ?? p.driverId ?? '__no_driver__';
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
                fontWeight: bold ? FontWeight.bold : FontWeight.w700,
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
          backgroundColor: AppTheme.surfaceHi,
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
              style: TextStyle(fontSize: 10, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
