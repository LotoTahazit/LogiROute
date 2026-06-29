import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer_health_summary.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/customer_health_dashboard_service.dart';
import 'support_console_screen.dart';

/// Customer Health Dashboard — таблица всех компаний, только super_admin.
class CustomerHealthDashboardScreen extends StatefulWidget {
  const CustomerHealthDashboardScreen({super.key});

  @override
  State<CustomerHealthDashboardScreen> createState() =>
      _CustomerHealthDashboardScreenState();
}

class _CustomerHealthDashboardScreenState
    extends State<CustomerHealthDashboardScreen> {
  final _service = CustomerHealthDashboardService();
  List<CustomerHealthSummary> _rows = [];
  CustomerHealthFilter _filter = CustomerHealthFilter.all;
  bool _loading = false;
  bool _hasMore = false;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static final _timeFmt = DateFormat('dd/MM/yy HH:mm');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final page = await _service.loadPage(refresh: true);
      if (mounted) {
        setState(() {
          _rows = page.rows;
          _hasMore = page.hasMore;
          _lastDoc = page.lastDocument;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _lastDoc == null) return;
    setState(() => _loading = true);
    try {
      final page = await _service.loadPage(startAfter: _lastDoc);
      if (mounted) {
        setState(() {
          _rows = [..._rows, ...page.rows];
          _hasMore = page.hasMore;
          _lastDoc = page.lastDocument;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CustomerHealthSummary> get _filtered =>
      _rows.where((r) => r.matchesFilter(_filter)).toList();

  void _openSupportConsole(String companyId) {
    CompanyContext.activateCompany(context, companyId);
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SupportConsoleScreen(initialCompanyId: companyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();

    if (auth.userModel?.isSuperAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.customerHealthDashboardTitle)),
        body: Center(child: Text(l10n.demoCompanySuperAdminOnly)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerHealthDashboardTitle),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<CustomerHealthFilter>(
              segments: [
                ButtonSegment(
                    value: CustomerHealthFilter.all,
                    label: Text(l10n.customerHealthFilterAll)),
                ButtonSegment(
                    value: CustomerHealthFilter.healthy,
                    label: Text(l10n.customerHealthHealthy)),
                ButtonSegment(
                    value: CustomerHealthFilter.warning,
                    label: Text(l10n.customerHealthWarning)),
                ButtonSegment(
                    value: CustomerHealthFilter.critical,
                    label: Text(l10n.customerHealthCritical)),
                ButtonSegment(
                    value: CustomerHealthFilter.demo,
                    label: Text(l10n.customerHealthFilterDemo)),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: _loading && _rows.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text(l10n.customerHealthNoRows))
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  columns: [
                                    DataColumn(
                                        label: Text(l10n.healthStripCompany)),
                                    DataColumn(
                                        label:
                                            Text(l10n.customerHealthCompanyId)),
                                    DataColumn(label: Text(l10n.chipPlan)),
                                    DataColumn(
                                        label: Text(l10n.billingStatusLabel)),
                                    DataColumn(
                                        label: Text(l10n.healthStripSetup)),
                                    DataColumn(
                                        label: Text(l10n.customerHealthStatus)),
                                    DataColumn(
                                        label: Text(l10n.healthStripDrivers)),
                                    DataColumn(
                                        label: Text(l10n.healthStripRoutes)),
                                    DataColumn(
                                        label:
                                            Text(l10n.customerHealthFailedSync)),
                                    DataColumn(
                                        label:
                                            Text(l10n.customerHealthStaleGps)),
                                    DataColumn(
                                        label: Text(
                                            l10n.customerHealthLastActivity)),
                                    DataColumn(
                                        label: Text(l10n.healthStripProblems)),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: _filtered.map((r) {
                                    return DataRow(
                                      onSelectChanged: (_) =>
                                          _openSupportConsole(r.companyId),
                                      cells: [
                                        DataCell(Text(r.companyName)),
                                        DataCell(Text(
                                          r.companyId,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        )),
                                        DataCell(Text(r.plan)),
                                        DataCell(Text(r.billingStatus)),
                                        DataCell(Text('${r.setupPercent}%')),
                                        DataCell(
                                          Text(
                                            r.healthLevel.label(l10n),
                                            style: TextStyle(
                                              color: r.healthLevel.color(),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${r.activeDrivers}')),
                                        DataCell(Text('${r.activeRoutes}')),
                                        DataCell(Text('${r.failedSyncCount}')),
                                        DataCell(Text('${r.staleGpsDrivers}')),
                                        DataCell(Text(
                                          r.lastActivity != null
                                              ? _timeFmt.format(r.lastActivity!)
                                              : '—',
                                        )),
                                        DataCell(Text('${r.problemsCount}')),
                                        DataCell(
                                          r.isDemo
                                              ? Chip(
                                                  label: Text(
                                                    l10n.customerHealthDemoBadge,
                                                    style: const TextStyle(
                                                        fontSize: 11),
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _loadMore,
                                icon: const Icon(Icons.expand_more),
                                label: Text(l10n.customerHealthLoadMore),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
