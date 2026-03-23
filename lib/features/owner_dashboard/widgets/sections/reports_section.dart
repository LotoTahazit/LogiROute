import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../utils/file_download_stub.dart'
    if (dart.library.html) '../../../../utils/file_download_web.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';

/// Lightweight data class for report aggregation (from invoices collection)
class _ReportDoc {
  final DateTime? date;
  final double net;
  final double vat;
  final double gross;
  final String customerName;
  final String? customerTaxId;
  final String status;

  const _ReportDoc({
    this.date,
    this.net = 0,
    this.vat = 0,
    this.gross = 0,
    this.customerName = '',
    this.customerTaxId,
    this.status = '',
  });
}

class ReportsSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;
  const ReportsSection(
      {super.key, required this.companyId, required this.companySettings});
  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  /// Stream invoices from the actual collection where dispatcher creates them
  Stream<List<_ReportDoc>> _watchInvoices() {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final d = doc.data();
              // Compute amounts from items
              final items = d['items'] as List<dynamic>? ?? [];
              double totalBefore = 0;
              for (final item in items) {
                final m = item as Map<String, dynamic>;
                totalBefore += ((m['quantity'] ?? 0) as num).toDouble() *
                    ((m['pricePerUnit'] ?? 0) as num).toDouble();
              }
              final discount = ((d['discount'] ?? 0) as num).toDouble();
              final vatRate = ((d['vatRate'] ?? 0.17) as num).toDouble();
              final net = totalBefore * (1 - discount / 100);
              final vatAmt = net * vatRate;
              final gross = net + vatAmt;

              DateTime? date;
              if (d['createdAt'] != null) {
                date = (d['createdAt'] as Timestamp).toDate();
              }

              return _ReportDoc(
                date: date,
                net: net,
                vat: vatAmt,
                gross: gross,
                customerName: d['clientName'] as String? ?? '',
                customerTaxId: d['clientNumber'] as String?,
                status: d['status'] as String? ?? '',
              );
            }).toList());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(children: [
            Icon(Icons.bar_chart_outlined,
                size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(l10n.reportsTitle, style: theme.textTheme.headlineSmall),
          ]),
        ),
        const SizedBox(height: 16),
        TabBar(controller: _tabController, tabs: [
          Tab(icon: const Icon(Icons.calendar_month), text: l10n.monthlyReport),
          Tab(icon: const Icon(Icons.account_balance), text: l10n.vatReport),
          Tab(icon: const Icon(Icons.people), text: l10n.clientReport),
        ]),
        Expanded(
          child: StreamBuilder<List<_ReportDoc>>(
            stream: _watchInvoices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text(l10n.errorLoadingData,
                        style: TextStyle(color: theme.colorScheme.error)));
              }
              final allDocs = snapshot.data ?? [];
              final docs = allDocs
                  .where((d) => d.status != 'draft' && d.status != 'cancelled')
                  .toList();
              return TabBarView(controller: _tabController, children: [
                _MonthlyReport(docs: docs),
                _VatReport(docs: docs),
                _ClientReport(docs: docs),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly Report
// ---------------------------------------------------------------------------

class _MonthData {
  final int count;
  final double net;
  final double vat;
  final double gross;
  const _MonthData(
      {this.count = 0, this.net = 0, this.vat = 0, this.gross = 0});
}

class _MonthlyReport extends StatelessWidget {
  final List<_ReportDoc> docs;
  const _MonthlyReport({required this.docs});

  Map<String, _MonthData> _groupByMonth(List<_ReportDoc> docs) {
    final map = <String, _MonthData>{};
    final fmt = DateFormat('yyyy-MM');
    for (final doc in docs) {
      if (doc.date == null) continue;
      final key = fmt.format(doc.date!);
      final e = map[key] ?? const _MonthData();
      map[key] = _MonthData(
          count: e.count + 1,
          net: e.net + doc.net,
          vat: e.vat + doc.vat,
          gross: e.gross + doc.gross);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final data = _groupByMonth(docs);
    final months = data.keys.toList()..sort((a, b) => b.compareTo(a));
    if (months.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            FilledButton.icon(
                onPressed: () => _csv(context, months, data),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.exportCsv)),
          ])),
      Expanded(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.monthColumn)),
                DataColumn(label: Text(l10n.documentsColumn), numeric: true),
                DataColumn(label: Text(l10n.netAmount), numeric: true),
                DataColumn(label: Text(l10n.vatAmount), numeric: true),
                DataColumn(label: Text(l10n.grossAmount), numeric: true),
              ],
              rows: [
                ...months.map((m) {
                  final d = data[m]!;
                  return DataRow(cells: [
                    DataCell(Text(m)),
                    DataCell(Text(d.count.toString())),
                    DataCell(Text(d.net.toStringAsFixed(2))),
                    DataCell(Text(d.vat.toStringAsFixed(2))),
                    DataCell(Text(d.gross.toStringAsFixed(2))),
                  ]);
                }),
                DataRow(
                    color: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest),
                    cells: [
                      DataCell(Text(l10n.totalSummary,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          months
                              .fold<int>(0, (s, m) => s + data[m]!.count)
                              .toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          months
                              .fold<double>(0, (s, m) => s + data[m]!.net)
                              .toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          months
                              .fold<double>(0, (s, m) => s + data[m]!.vat)
                              .toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                          months
                              .fold<double>(0, (s, m) => s + data[m]!.gross)
                              .toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]),
              ],
            )),
      )),
    ]);
  }

  void _csv(
      BuildContext ctx, List<String> months, Map<String, _MonthData> data) {
    const t = '\t';
    final b = StringBuffer('חודש$tמסמכים$tנטו$tמע"מ$tברוטו\n');
    for (final m in months) {
      final d = data[m]!;
      b.writeln(
          '$m$t${d.count}$t${d.net.toStringAsFixed(2)}$t${d.vat.toStringAsFixed(2)}$t${d.gross.toStringAsFixed(2)}');
    }
    if (kIsWeb) {
      downloadCsv(b.toString(),
          'monthly_report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
    } else {
      Clipboard.setData(ClipboardData(text: b.toString()));
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx)!.csvCopiedToClipboard)));
    }
  }
}

// ---------------------------------------------------------------------------
// VAT Report
// ---------------------------------------------------------------------------

class _VatData {
  final double base;
  final double vat;
  const _VatData({this.base = 0, this.vat = 0});
}

class _VatReport extends StatelessWidget {
  final List<_ReportDoc> docs;
  const _VatReport({required this.docs});

  Map<String, _VatData> _group(List<_ReportDoc> docs) {
    final map = <String, _VatData>{};
    final fmt = DateFormat('yyyy-MM');
    for (final doc in docs) {
      if (doc.date == null) continue;
      final key = fmt.format(doc.date!);
      final e = map[key] ?? const _VatData();
      map[key] = _VatData(base: e.base + doc.net, vat: e.vat + doc.vat);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vatData = _group(docs);
    final months = vatData.keys.toList()..sort((a, b) => b.compareTo(a));
    if (months.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    final totalVat = months.fold<double>(0, (s, m) => s + vatData[m]!.vat);
    final totalBase = months.fold<double>(0, (s, m) => s + vatData[m]!.base);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.totalVatForPeriod,
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text('\u20AA${totalVat.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              '${l10n.taxBase}: \u20AA${totalBase.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall),
                        ]))),
            const Spacer(),
            FilledButton.icon(
                onPressed: () => _csv(context, months, vatData),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.exportCsv)),
          ])),
      Expanded(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.monthColumn)),
                DataColumn(label: Text(l10n.taxBaseAmount), numeric: true),
                DataColumn(label: Text(l10n.vatAmount), numeric: true),
                DataColumn(label: Text(l10n.vatRateColumn), numeric: true),
              ],
              rows: months.map((m) {
                final d = vatData[m]!;
                final rate = d.base > 0 ? (d.vat / d.base * 100) : 0.0;
                return DataRow(cells: [
                  DataCell(Text(m)),
                  DataCell(Text('\u20AA${d.base.toStringAsFixed(2)}')),
                  DataCell(Text('\u20AA${d.vat.toStringAsFixed(2)}')),
                  DataCell(Text('${rate.toStringAsFixed(1)}%')),
                ]);
              }).toList(),
            )),
      )),
    ]);
  }

  void _csv(BuildContext ctx, List<String> months, Map<String, _VatData> data) {
    const t = '\t';
    final b = StringBuffer('חודש$tבסיס מס$tמע"מ\n');
    for (final m in months) {
      final d = data[m]!;
      b.writeln(
          '$m$t${d.base.toStringAsFixed(2)}$t${d.vat.toStringAsFixed(2)}');
    }
    if (kIsWeb) {
      downloadCsv(b.toString(),
          'vat_report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
    } else {
      Clipboard.setData(ClipboardData(text: b.toString()));
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx)!.csvCopiedToClipboard)));
    }
  }
}

// ---------------------------------------------------------------------------
// Client Report
// ---------------------------------------------------------------------------

class _ClientData {
  final String? taxId;
  final int count;
  final double net;
  final double vat;
  final double gross;
  const _ClientData(
      {this.taxId, this.count = 0, this.net = 0, this.vat = 0, this.gross = 0});
}

class _ClientReport extends StatelessWidget {
  final List<_ReportDoc> docs;
  const _ClientReport({required this.docs});

  Map<String, _ClientData> _groupByClient(
      List<_ReportDoc> docs, AppLocalizations l10n) {
    final map = <String, _ClientData>{};
    for (final doc in docs) {
      final name =
          doc.customerName.isNotEmpty ? doc.customerName : l10n.unknownCustomer;
      final e = map[name] ?? _ClientData(taxId: doc.customerTaxId);
      map[name] = _ClientData(
          taxId: e.taxId ?? doc.customerTaxId,
          count: e.count + 1,
          net: e.net + doc.net,
          vat: e.vat + doc.vat,
          gross: e.gross + doc.gross);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cData = _groupByClient(docs, l10n);
    final clients = cData.keys.toList()
      ..sort((a, b) => cData[b]!.gross.compareTo(cData[a]!.gross));
    if (clients.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(l10n.customersCount(clients.length),
                style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
                onPressed: () => _csv(context, clients, cData),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.exportCsv)),
          ])),
      Expanded(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.customerColumn)),
                DataColumn(label: Text(l10n.taxIdShort)),
                DataColumn(label: Text(l10n.documentsColumn), numeric: true),
                DataColumn(label: Text(l10n.netAmount), numeric: true),
                DataColumn(label: Text(l10n.vatAmount), numeric: true),
                DataColumn(label: Text(l10n.grossAmount), numeric: true),
              ],
              rows: clients.map((name) {
                final d = cData[name]!;
                return DataRow(cells: [
                  DataCell(Text(name)),
                  DataCell(Text(d.taxId ?? '\u2014')),
                  DataCell(Text(d.count.toString())),
                  DataCell(Text(d.net.toStringAsFixed(2))),
                  DataCell(Text(d.vat.toStringAsFixed(2))),
                  DataCell(Text(d.gross.toStringAsFixed(2))),
                ]);
              }).toList(),
            )),
      )),
    ]);
  }

  void _csv(
      BuildContext ctx, List<String> clients, Map<String, _ClientData> data) {
    const t = '\t';
    final b =
        StringBuffer('לקוח$tח.פ./ע.מ.$tמסמכים$tנטו$tמע"מ$tברוטו\n');
    for (final c in clients) {
      final d = data[c]!;
      b.writeln(
          '$c$t${d.taxId ?? ""}$t${d.count}$t${d.net.toStringAsFixed(2)}$t${d.vat.toStringAsFixed(2)}$t${d.gross.toStringAsFixed(2)}');
    }
    if (kIsWeb) {
      downloadCsv(b.toString(),
          'client_report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
    } else {
      Clipboard.setData(ClipboardData(text: b.toString()));
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx)!.csvCopiedToClipboard)));
    }
  }
}
