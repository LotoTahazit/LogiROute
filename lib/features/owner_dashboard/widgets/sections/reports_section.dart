import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../models/accounting_doc.dart';
import '../../repositories/accounting_docs_repository.dart';

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
  late final AccountingDocsRepository _docsRepo;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _docsRepo = AccountingDocsRepository(companyId: widget.companyId);
    _tabController = TabController(length: 3, vsync: this);
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
          child: StreamBuilder<List<AccountingDoc>>(
            stream: _docsRepo.watchDocs(),
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
                  .where((d) =>
                      d.status != AccountingDocStatus.draft &&
                      d.status != AccountingDocStatus.voidedBeforeDelivery)
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
  final List<AccountingDoc> docs;
  const _MonthlyReport({required this.docs});

  Map<String, _MonthData> _groupByMonth(List<AccountingDoc> docs) {
    final map = <String, _MonthData>{};
    final fmt = DateFormat('yyyy-MM');
    for (final doc in docs) {
      final date = doc.issuedAt ?? doc.createdAt;
      if (date == null) continue;
      final key = fmt.format(date);
      final e = map[key] ?? const _MonthData();
      map[key] = _MonthData(
          count: e.count + 1,
          net: e.net + doc.totals.net,
          vat: e.vat + doc.totals.vat,
          gross: e.gross + doc.totals.gross);
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
    final b = StringBuffer('month,docs,net,vat,gross\n');
    for (final m in months) {
      final d = data[m]!;
      b.writeln(
          '$m,${d.count},${d.net.toStringAsFixed(2)},${d.vat.toStringAsFixed(2)},${d.gross.toStringAsFixed(2)}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
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
  final List<AccountingDoc> docs;
  const _VatReport({required this.docs});

  Map<String, _VatData> _group(List<AccountingDoc> docs) {
    final map = <String, _VatData>{};
    final fmt = DateFormat('yyyy-MM');
    for (final doc in docs) {
      final date = doc.issuedAt ?? doc.createdAt;
      if (date == null) continue;
      final key = fmt.format(date);
      final e = map[key] ?? const _VatData();
      map[key] =
          _VatData(base: e.base + doc.totals.net, vat: e.vat + doc.totals.vat);
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
    final b = StringBuffer('month,tax_base,vat\n');
    for (final m in months) {
      final d = data[m]!;
      b.writeln('$m,${d.base.toStringAsFixed(2)},${d.vat.toStringAsFixed(2)}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
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
  final List<AccountingDoc> docs;
  const _ClientReport({required this.docs});

  Map<String, _ClientData> _groupByClient(
      List<AccountingDoc> docs, AppLocalizations l10n) {
    final map = <String, _ClientData>{};
    for (final doc in docs) {
      final name =
          doc.customerName.isNotEmpty ? doc.customerName : l10n.unknownCustomer;
      final e = map[name] ?? _ClientData(taxId: doc.customerTaxId);
      map[name] = _ClientData(
          taxId: e.taxId ?? doc.customerTaxId,
          count: e.count + 1,
          net: e.net + doc.totals.net,
          vat: e.vat + doc.totals.vat,
          gross: e.gross + doc.totals.gross);
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
    final b = StringBuffer('customer,tax_id,docs,net,vat,gross\n');
    for (final c in clients) {
      final d = data[c]!;
      b.writeln(
          '$c,${d.taxId ?? ""},${d.count},${d.net.toStringAsFixed(2)},${d.vat.toStringAsFixed(2)},${d.gross.toStringAsFixed(2)}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx)!.csvCopiedToClipboard)));
    }
  }
}
