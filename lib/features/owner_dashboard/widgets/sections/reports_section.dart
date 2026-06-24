import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../utils/file_download_stub.dart'
    if (dart.library.html) '../../../../utils/file_download_web.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/invoice.dart';
import '../../../../models/company_settings.dart';
import '../../../../models/inventory_item.dart';
import '../../../../services/firestore_paths.dart';
import '../../../../widgets/logi_route_tab_bar.dart';

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

  /// Активные вкладки отчётов в зависимости от модулей компании.
  /// 'stock' — складские остатки (если включён модуль «Склад»); финансовые
  /// вкладки (выручка/НДС/клиенты) показываем всегда (счета из бухгалтерии).
  late final List<String> _tabKeys;

  @override
  void initState() {
    super.initState();
    final m = widget.companySettings.modules;
    _tabKeys = [
      if (m.warehouse) 'stock',
      'monthly',
      'vat',
      'client',
    ];
    _tabController = TabController(length: _tabKeys.length, vsync: this);
  }

  LogiRouteTabItem _tabItem(String key, AppLocalizations l10n) {
    switch (key) {
      case 'stock':
        return LogiRouteTabItem(
            icon: Icons.inventory_2_outlined, label: l10n.reportStockTab);
      case 'monthly':
        return LogiRouteTabItem(
            icon: Icons.calendar_month, label: l10n.monthlyReport);
      case 'vat':
        return LogiRouteTabItem(
            icon: Icons.account_balance, label: l10n.vatReport);
      case 'client':
        return LogiRouteTabItem(icon: Icons.people, label: l10n.clientReport);
      default:
        return LogiRouteTabItem(icon: Icons.bar_chart, label: key);
    }
  }

  /// Stream invoices — суммы через [Invoice] (per-line НДС, скидка, credit notes).
  Stream<List<_ReportDoc>> _watchInvoices() {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('accounting')
        .doc('_root')
        .collection('invoices')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final invoice = Invoice.fromMap(doc.data(), doc.id);
              if (!invoice.isLive) return null;
              return _ReportDoc(
                // Период מע"מ/выручки — по ДАТЕ ДОКУМЕНТА (deliveryDate), как и
                // period-lock в issueInvoice. finalizedAt (момент выписки на
                // сервере) мог бы увести документ в соседний месяц на стыке.
                date: invoice.deliveryDate,
                net: invoice.subtotalBeforeVAT,
                vat: invoice.vatAmount,
                gross: invoice.totalWithVAT,
                customerName: invoice.clientName,
                customerTaxId: invoice.clientNumber,
                status: invoice.status.name,
              );
            })
            .whereType<_ReportDoc>()
            .toList());
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 12 : 24, 24, narrow ? 12 : 24, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined,
                  size: 28, color: theme.colorScheme.primary),
              Text(
                l10n.reportsTitle,
                style: narrow
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LogiRouteTabBar(
          controller: _tabController,
          isScrollable: narrow,
          tabs: [for (final k in _tabKeys) _tabItem(k, l10n)],
        ),
        Expanded(
          child: StreamBuilder<List<_ReportDoc>>(
            stream: _watchInvoices(),
            builder: (context, snapshot) {
              // Складская вкладка не зависит от счетов: при ошибке/загрузке
              // финансовых данных она всё равно работает (свой стрим).
              final hasFinErr = snapshot.hasError;
              final finLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final docs = snapshot.data ?? [];

              Widget financial(Widget child) {
                if (finLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (hasFinErr) {
                  return Center(
                      child: Text(l10n.errorLoadingData,
                          style: TextStyle(color: theme.colorScheme.error)));
                }
                return child;
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  for (final k in _tabKeys)
                    if (k == 'stock')
                      _StockReport(companyId: widget.companyId)
                    else if (k == 'monthly')
                      financial(_MonthlyReport(docs: docs))
                    else if (k == 'vat')
                      financial(_VatReport(docs: docs))
                    else
                      financial(_ClientReport(docs: docs)),
                ],
              );
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    if (months.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: Wrap(
          alignment: WrapAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () => _csv(context, months, data),
              icon: const Icon(Icons.download, size: 18),
              label: Text(l10n.exportCsv),
            ),
          ],
        ),
      ),
      Expanded(
          child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
              ),
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    if (months.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    final totalVat = months.fold<double>(0, (s, m) => s + vatData[m]!.vat);
    final totalBase = months.fold<double>(0, (s, m) => s + vatData[m]!.base);
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.totalVatForPeriod,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary)),
                          const SizedBox(height: 4),
                          Text('\u20AA${totalVat.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary)),
                          const SizedBox(height: 4),
                          Text(
                              '${l10n.taxBase}: \u20AA${totalBase.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary)),
                        ]))),
            FilledButton.icon(
                onPressed: () => _csv(context, months, vatData),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.exportCsv)),
          ],
        ),
      ),
      Expanded(
          child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.monthColumn)),
                  DataColumn(label: Text(l10n.taxBaseAmount), numeric: true),
                  DataColumn(label: Text(l10n.vatAmount), numeric: true),
                  DataColumn(label: Text(l10n.vatRateColumn), numeric: true),
                ],
                rows: months.map((m) {
                  final d = vatData[m]!;
                  final rate = d.base > 0 ? (d.vat / d.base * 100) : 18.0;
                  return DataRow(cells: [
                    DataCell(Text(m)),
                    DataCell(Text('\u20AA${d.base.toStringAsFixed(2)}')),
                    DataCell(Text('\u20AA${d.vat.toStringAsFixed(2)}')),
                    DataCell(Text('${rate.toStringAsFixed(1)}%')),
                  ]);
                }).toList(),
              ),
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
  final String name;
  final String? taxId;
  final int count;
  final double net;
  final double vat;
  final double gross;
  const _ClientData({
    this.name = '',
    this.taxId,
    this.count = 0,
    this.net = 0,
    this.vat = 0,
    this.gross = 0,
  });
}

class _ClientReport extends StatelessWidget {
  final List<_ReportDoc> docs;
  const _ClientReport({required this.docs});

  Map<String, _ClientData> _groupByClient(
      List<_ReportDoc> docs, AppLocalizations l10n) {
    final map = <String, _ClientData>{};
    for (final doc in docs) {
      final name = doc.customerName.isNotEmpty
          ? doc.customerName
          : l10n.unknownCustomer;
      final key = (doc.customerTaxId != null && doc.customerTaxId!.isNotEmpty)
          ? doc.customerTaxId!
          : name;
      final e = map[key] ?? _ClientData(name: name, taxId: doc.customerTaxId);
      map[key] = _ClientData(
          name: e.name.isNotEmpty ? e.name : name,
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    if (clients.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.customersCount(clients.length),
                style: theme.textTheme.titleMedium),
            FilledButton.icon(
                onPressed: () => _csv(context, clients, cData),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.exportCsv)),
          ],
        ),
      ),
      Expanded(
          child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 24),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.customerColumn)),
                  DataColumn(label: Text(l10n.taxIdShort)),
                  DataColumn(label: Text(l10n.documentsColumn), numeric: true),
                  DataColumn(label: Text(l10n.netAmount), numeric: true),
                  DataColumn(label: Text(l10n.vatAmount), numeric: true),
                  DataColumn(label: Text(l10n.grossAmount), numeric: true),
                ],
                rows: clients.map((key) {
                  final d = cData[key]!;
                  return DataRow(cells: [
                    DataCell(Text(d.name.isNotEmpty ? d.name : key)),
                    DataCell(Text(d.taxId ?? '\u2014')),
                    DataCell(Text(d.count.toString())),
                    DataCell(Text(d.net.toStringAsFixed(2))),
                    DataCell(Text(d.vat.toStringAsFixed(2))),
                    DataCell(Text(d.gross.toStringAsFixed(2))),
                  ]);
                }).toList(),
              ),
            )),
      )),
    ]);
  }

  void _csv(
      BuildContext ctx, List<String> clients, Map<String, _ClientData> data) {
    const t = '\t';
    final b =
        StringBuffer('לקוח$tח.פ./ע.מ.$tמסמכים$tנטו$tמע"מ$tברוטו\n');
    for (final key in clients) {
      final d = data[key]!;
      final label = d.name.isNotEmpty ? d.name : key;
      b.writeln(
          '$label$t${d.taxId ?? ""}$t${d.count}$t${d.net.toStringAsFixed(2)}$t${d.vat.toStringAsFixed(2)}$t${d.gross.toStringAsFixed(2)}');
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

// ---------------------------------------------------------------------------
// Stock Report (базовый складской отчёт — для владельца/админа любого плана
// со складом, включая «только склад»). Остатки, миштахи, итоги, экспорт CSV.
// ---------------------------------------------------------------------------

class _StockReport extends StatelessWidget {
  final String companyId;
  const _StockReport({required this.companyId});

  Stream<List<InventoryItem>> _watch() {
    return FirestorePaths().inventory(companyId).snapshots().map((s) =>
        s.docs.map((d) => InventoryItem.fromMap(d.data(), d.id)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return StreamBuilder<List<InventoryItem>>(
      stream: _watch(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
              child: Text(l10n.errorLoadingData,
                  style: TextStyle(color: theme.colorScheme.error)));
        }
        final items = List<InventoryItem>.from(snap.data ?? [])
          ..sort((a, b) => a.productCode.compareTo(b.productCode));
        if (items.isEmpty) {
          return Center(child: Text(l10n.noDataToDisplay));
        }
        final totalUnits = items.fold<int>(0, (s, i) => s + i.quantity);
        final totalPallets =
            items.fold<int>(0, (s, i) => s + i.numberOfPallets);
        return Column(children: [
          Padding(
            padding: EdgeInsets.all(narrow ? 12 : 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                        label: l10n.reportStockTotalSkus,
                        value: items.length.toString()),
                    _StatChip(
                        label: l10n.reportStockTotalUnits,
                        value: totalUnits.toString()),
                    _StatChip(
                        label: l10n.reportStockTotalPallets,
                        value: totalPallets.toString()),
                  ],
                ),
                FilledButton.icon(
                    onPressed: () => _csv(context, items),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.exportCsv)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 24),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.reportStockSku)),
                      DataColumn(label: Text(l10n.reportStockProduct)),
                      DataColumn(
                          label: Text(l10n.reportStockQty), numeric: true),
                      DataColumn(
                          label: Text(l10n.reportStockPallets), numeric: true),
                    ],
                    rows: items.map((i) {
                      final desc = '${i.type} ${i.number}'.trim();
                      return DataRow(cells: [
                        DataCell(Text(i.productCode)),
                        DataCell(Text(desc)),
                        DataCell(Text(i.quantity.toString())),
                        DataCell(Text(i.numberOfPallets.toString())),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  void _csv(BuildContext ctx, List<InventoryItem> items) {
    final l10n = AppLocalizations.of(ctx)!;
    const t = '\t';
    final b = StringBuffer(
        '${l10n.reportStockSku}$t${l10n.reportStockProduct}$t${l10n.reportStockQty}$t${l10n.reportStockPallets}\n');
    for (final i in items) {
      final desc = '${i.type} ${i.number}'.trim();
      b.writeln('${i.productCode}$t$desc$t${i.quantity}$t${i.numberOfPallets}');
    }
    if (kIsWeb) {
      downloadCsv(b.toString(),
          'stock_report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv');
    } else {
      Clipboard.setData(ClipboardData(text: b.toString()));
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.csvCopiedToClipboard)));
    }
  }
}

/// Небольшой чип со статистикой (значение + подпись).
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
        ],
      ),
    );
  }
}
