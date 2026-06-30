import 'dart:convert';
import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import '../../features/owner_dashboard/services/metrics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/onboarding_section.dart';
import '../../models/support_diagnostic_snapshot.dart';
import '../../services/accounting_sync_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/company_health_service.dart';
import '../../services/support_diagnostic_service.dart';
import '../../services/usage_analytics_service.dart';
import '../../models/usage_event.dart';
import '../../theme/app_theme.dart';
import 'company_remote_config_screen.dart';
import 'data_integrity_screen.dart';
import '../../widgets/logi_route_tab_bar.dart';
import '../../widgets/role_router.dart';
import 'billing/billing_portal_screen.dart';
import 'subscription_screen.dart';

/// Support Console — "одна компания = вся история"
/// Только для super_admin. Выбираешь компанию → видишь всё:
/// billing, payments, webhooks, notifications, delivery logs, integrity.
/// Кнопка "Export diagnostic JSON" — всё в один файл.
class SupportConsoleScreen extends StatefulWidget {
  const SupportConsoleScreen({super.key, this.initialCompanyId});

  final String? initialCompanyId;

  @override
  State<SupportConsoleScreen> createState() => _SupportConsoleScreenState();
}

class _SupportConsoleScreenState extends State<SupportConsoleScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  final _diagService = SupportDiagnosticService();

  String? _selectedCompanyId;
  SupportDiagnosticSnapshot? _diag;
  bool _isLoading = false;
  bool _retryingSync = false;
  String _correlationFilter = '';
  final _correlationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final id = widget.initialCompanyId;
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCompanyData(id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _correlationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _auditEvents => _diag?.auditEvents ?? [];
  List<Map<String, dynamic>> get _paymentEvents => _diag?.paymentEvents ?? [];
  List<Map<String, dynamic>> get _notifications => _diag?.notifications ?? [];
  List<Map<String, dynamic>> get _pushLogs => _diag?.pushLogs ?? [];
  List<Map<String, dynamic>> get _emailLogs => _diag?.emailLogs ?? [];
  Map<String, String> get _userNames => _diag?.userNames ?? {};
  int get _unreadCount => _diag?.unreadNotifications ?? 0;

  Future<void> _loadCompanyData(String companyId) async {
    setState(() {
      _isLoading = true;
      _selectedCompanyId = companyId;
    });
    CompanyContext.activateCompany(context, companyId);

    try {
      final snap = await _diagService.load(companyId);
      if (mounted) setState(() => _diag = snap);
      final auth = context.read<AuthService>();
      unawaited(UsageAnalyticsService.track(
        companyId: companyId,
        userId: auth.currentUser?.uid ?? '',
        role: auth.userModel?.role ?? 'super_admin',
        event: UsageEventName.supportOpened,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _migrateAccountingCounters({bool allCompanies = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!allCompanies && _selectedCompanyId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Миграция counters'),
        content: Text(allCompanies
            ? 'Объединить legacy-ключи (invoice→tax_invoice) у ВСЕХ компаний?'
            : 'Объединить legacy-ключи для $_selectedCompanyId?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Мигрировать')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final payload = allCompanies
          ? <String, dynamic>{}
          : {'companyId': _selectedCompanyId};
      final res = await FirebaseFunctions.instance
          .httpsCallable('migrateAccountingCounters')
          .call(payload);
      final data = Map<String, dynamic>.from(res.data as Map);
      final results = (data['results'] as List?) ?? [];
      final merged = results.fold<int>(
          0, (s, r) => s + ((r as Map)['merged'] as int? ?? 0));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'OK: ${data['companies']} компаний, $merged ключей объединено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runIntegrityCheck() async {
    if (!_verifySelectedCompanyContext()) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyIntegrityChain');
      final result = await callable.call({'companyId': _selectedCompanyId});
      if (mounted) {
        final data = result.data as Map<String, dynamic>?;
        final valid = data?['valid'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(valid
                ? l10n.integrityOk
                : l10n.integrityFailed(data?['error'] ?? 'unknown')),
            backgroundColor: valid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportDiagnosticJson() async {
    if (_diag == null || _selectedCompanyId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final d = _diag!;

    final diagnostic = {
      'companyId': _selectedCompanyId,
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': d.summaryLine(),
      'settings': d.settings.toFirestore(),
      'tenantHealth': {
        'setupPercent': d.tenant.setupPercent,
        'driverCount': d.tenant.driverCount,
        'activeRoutes': d.tenant.activeRoutes,
        'failedSyncCount': d.tenant.failedSyncCount,
        'staleGpsDrivers': d.tenant.staleGpsDrivers,
        'problemsCount': d.tenant.problemsCount,
        'lastSyncError': d.tenant.lastSyncError,
      },
      'metrics': d.metrics.toMap(),
      'stats': {
        'totalUsers': d.totalUsers,
        'fcmTokenUsers': d.fcmTokenUsers,
        'pendingDeliveryPoints': d.pendingDeliveryPoints,
        'cancelledDeliveryPoints': d.cancelledDeliveryPoints,
        'unreadNotifications': d.unreadNotifications,
        'invoicesThisMonth': d.metrics.invoicesThisMonth,
      },
      'recentErrors': d.recentErrors
          .map((e) => {
                'source': e.source,
                'type': e.type,
                'message': e.message,
                'correlationId': e.correlationId,
                'at': e.at?.toIso8601String(),
              })
          .toList(),
      'correlationIds': d.recentErrors
          .map((e) => e.correlationId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
      'auditEvents': d.auditEvents,
      'paymentEvents': d.paymentEvents,
      'notifications': d.notifications,
      'pushDeliveryErrors': d.pushLogs,
      'emailDeliveryErrors': d.emailLogs,
    };

    final json = const JsonEncoder.withIndent('  ').convert(diagnostic);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.diagnosticCopied),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _fmtTs(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}.${d.month}.${d.year}';
    }
    if (ts is DateTime) {
      return '${ts.day}.${ts.month}.${ts.year}';
    }
    return ts.toString();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.blue;
      case 'grace':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _healthColor(HealthCheckStatus s) {
    switch (s) {
      case HealthCheckStatus.ok:
        return Colors.green;
      case HealthCheckStatus.warn:
        return Colors.orange;
      case HealthCheckStatus.fail:
        return Colors.red;
    }
  }

  String _sectionTitle(AppLocalizations l10n, OnboardingSectionId id) {
    switch (id) {
      case OnboardingSectionId.companyDetails:
        return l10n.launchCenterCardCompanyDetails;
      case OnboardingSectionId.firstOwnerAdmin:
        return l10n.launchCenterCardFirstOwnerAdmin;
      case OnboardingSectionId.clients:
        return l10n.launchCenterCardClients;
      case OnboardingSectionId.products:
        return l10n.launchCenterCardProducts;
      case OnboardingSectionId.drivers:
        return l10n.launchCenterCardDrivers;
      case OnboardingSectionId.warehouse:
        return l10n.launchCenterCardWarehouse;
      case OnboardingSectionId.accounting:
        return l10n.launchCenterCardAccounting;
      case OnboardingSectionId.gps:
        return l10n.launchCenterCardGps;
      case OnboardingSectionId.firstRoute:
        return l10n.launchCenterCardFirstRoute;
      case OnboardingSectionId.testDelivery:
        return l10n.launchCenterCardTestDelivery;
      case OnboardingSectionId.goLive:
        return l10n.launchCenterCardGoLive;
    }
  }

  bool _verifySelectedCompanyContext() {
    final id = _selectedCompanyId;
    if (id == null || id.isEmpty) return false;
    CompanyContext.activateCompany(context, id);
    final effective = CompanyContext.of(context).effectiveCompanyId;
    if (effective != id) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.noCompanySelected} ($id ≠ $effective)'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  void _openBillingPortal() {
    if (!_verifySelectedCompanyContext()) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BillingPortalScreen(companyId: _selectedCompanyId),
      ),
    );
  }

  void _openSubscription() {
    if (!_verifySelectedCompanyContext()) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(companyId: _selectedCompanyId),
      ),
    );
  }

  Future<void> _openAsRole(String role) async {
    if (!_verifySelectedCompanyContext()) return;
    final companyId = _selectedCompanyId!;
    context.read<AuthService>().setViewAsRole(role);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleRouter()),
      (r) => r.isFirst,
    );
  }

  Future<void> _recalculateMetrics() async {
    if (!_verifySelectedCompanyContext()) return;
    final companyId = _selectedCompanyId!;
    final l10n = AppLocalizations.of(context)!;
    try {
      await MetricsService(companyId: companyId).recalculateDailyMetrics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recalculateMetrics),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCompanyData(companyId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _retryAccountingSync() async {
    final entry = _diag?.latestSyncEntry;
    final companyId = _selectedCompanyId;
    if (entry == null || companyId == null || entry.status != 'failed') return;
    setState(() => _retryingSync = true);
    try {
      await AccountingSyncService(companyId: companyId).retry(entry.invoiceId);
      if (mounted) await _loadCompanyData(companyId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _retryingSync = false);
    }
  }

  Future<void> _copySummary() async {
    final line = _diag?.summaryLine();
    if (line == null) return;
    await Clipboard.setData(ClipboardData(text: line));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.diagnosticCopied),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<SupportErrorEntry> get _filteredErrors {
    final errors = _diag?.recentErrors ?? [];
    if (_correlationFilter.trim().isEmpty) return errors;
    final f = _correlationFilter.trim();
    return errors.where((e) => e.matchesCorrelation(f)).toList();
  }

  List<Map<String, dynamic>> get _filteredAuditEvents {
    if (_correlationFilter.trim().isEmpty) return _auditEvents;
    final f = _correlationFilter.trim();
    return _auditEvents
        .where((e) => (e['correlationId'] as String? ?? '').contains(f))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();

    if (auth.userModel?.isSuperAdmin != true) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.supportConsoleTitle)),
          body: Center(child: Text(l10n.demoCompanySuperAdminOnly)),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.supportConsoleTitle),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_selectedCompanyId != null) ...[
              IconButton(
                icon: const Icon(Icons.published_with_changes,
                    color: Colors.white),
                tooltip: 'Миграция accounting counters',
                onPressed: () => _migrateAccountingCounters(),
              ),
              IconButton(
                icon: const Icon(Icons.verified_user),
                tooltip: l10n.verifyIntegrity,
                onPressed: _runIntegrityCheck,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: l10n.exportDiagnosticJson,
                onPressed: _exportDiagnosticJson,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshData,
                onPressed: () => _loadCompanyData(_selectedCompanyId!),
              ),
            ],
          ],
          bottom: _selectedCompanyId != null
              ? LogiRouteAppBarTabBar.labels(
                  controller: _tabController,
                  labels: [
                    l10n.tabOverview,
                    l10n.tabBillingAudit,
                    l10n.tabPayments(_paymentEvents.length),
                    l10n.tabNotifications(
                        _notifications.length, _unreadCount),
                    l10n.tabPushErrors(_pushLogs.length),
                    l10n.tabEmailErrors(_emailLogs.length),
                  ],
                )
              : null,
        ),
        body: _selectedCompanyId == null
            ? _buildCompanySelector()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompanyContextHeader(l10n),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildAuditTab(),
                              _buildPaymentsTab(),
                              _buildNotificationsTab(),
                              _buildPushLogsTab(),
                              _buildEmailLogsTab(),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompanyContextHeader(AppLocalizations l10n) {
    final id = _selectedCompanyId!;
    final name = _diag != null
        ? (_diag!.settings.nameHebrew.isNotEmpty
            ? _diag!.settings.nameHebrew
            : _diag!.settings.nameEnglish)
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHi,
        border: Border(
          bottom: BorderSide(color: AppTheme.muted.withValues(alpha: 0.22)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null && name.isNotEmpty)
            Text(
              name,
              style: TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          Text(
            id,
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySelector() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('companies').orderBy('nameHebrew').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final companies = snapshot.data!.docs;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: l10n.searchCompany,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, i) {
                  final doc = companies[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['billingStatus'] ?? 'unknown';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(status),
                      radius: 8,
                    ),
                    title: Text(data['nameHebrew'] ?? doc.id),
                    subtitle:
                        Text('$status • ${data['plan'] ?? '—'} • ${doc.id}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _loadCompanyData(doc.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context)!;
    final d = _diag;
    if (d == null) return const SizedBox.shrink();

    final settings = d.settings;
    final tenant = d.tenant;
    final status = settings.billingStatus;
    final plan = settings.plan;
    final nextSection = d.nextMissingRequiredSection;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedCompanyId = null;
              _diag = null;
              _correlationFilter = '';
              _correlationController.clear();
            }),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.backToList),
          ),
          const SizedBox(height: 8),
          Card(
            color: _statusColor(status).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.nameHebrew.isNotEmpty
                              ? settings.nameHebrew
                              : settings.nameEnglish,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.exportDiagnosticJson,
                        icon: const Icon(Icons.content_copy, size: 20),
                        onPressed: _copySummary,
                      ),
                    ],
                  ),
                  Text('ID: ${d.companyId}',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  Text(
                    '${l10n.healthStripProblems}: ${tenant.problemsCount} • '
                    '${l10n.customerHealthLastActivity}: '
                    '${tenant.lastActivity != null ? _fmtTs(Timestamp.fromDate(tenant.lastActivity!)) : '—'}',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _chip(l10n.chipStatus, status, _statusColor(status)),
                      _chip(l10n.chipPlan, plan, AppTheme.accent),
                      _chip(l10n.healthStripSetup, '${tenant.setupPercent}%',
                          AppTheme.green),
                      _chip(l10n.healthStripDrivers, '${tenant.driverCount}',
                          AppTheme.accentSoft),
                      _chip(l10n.healthStripRoutes, '${tenant.activeRoutes}',
                          AppTheme.muted),
                      _chip(l10n.chipUnread, '$_unreadCount', AppTheme.warning),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            l10n.supportDiagQuickActions,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _loadCompanyData(d.companyId),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refreshData),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openAsRole('owner'),
                  icon: const Icon(Icons.business),
                  label: Text(l10n.supportDiagOpenAsOwner),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openAsRole('dispatcher'),
                  icon: const Icon(Icons.local_shipping),
                  label: Text(l10n.supportDiagOpenAsDispatcher),
                ),
                OutlinedButton.icon(
                  onPressed: _recalculateMetrics,
                  icon: const Icon(Icons.calculate),
                  label: Text(l10n.recalculateMetrics),
                ),
                OutlinedButton.icon(
                  onPressed: _openBillingPortal,
                  icon: const Icon(Icons.payment),
                  label: Text(l10n.billingPortal),
                ),
                OutlinedButton.icon(
                  onPressed: _openSubscription,
                  icon: const Icon(Icons.subscriptions),
                  label: Text(l10n.subscription),
                ),
                OutlinedButton.icon(
                  onPressed: _runIntegrityCheck,
                  icon: const Icon(Icons.verified_user),
                  label: Text(l10n.verifyIntegrity),
                ),
              ],
            ),
          ),
          _panel(
            l10n.sectionBilling,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(l10n.chipPlan, plan),
                _row(l10n.billingStatusLabel, status),
                _row(l10n.labelTrialUntil, _fmtDate(settings.trialEndsAt)),
                _row(l10n.paidUntil, _fmtDate(settings.paidUntil)),
                _row(l10n.labelGracePeriodDays,
                    '${settings.gracePeriodDays}'),
                if (d.lastSuccessfulPayment != null)
                  _row(
                    l10n.supportDiagLastPayment,
                    '${d.lastSuccessfulPayment!['provider']} • '
                    '${d.lastSuccessfulPayment!['amount']} '
                    '${d.lastSuccessfulPayment!['currency'] ?? 'ILS'} • '
                    '${_fmtTs(d.lastSuccessfulPayment!['processedAt'])}',
                  ),
                if (d.lastFailedPayment != null)
                  _row(
                    l10n.supportDiagFailedPayment,
                    '${d.lastFailedPayment!['error']} • '
                    '${_fmtTs(d.lastFailedPayment!['processedAt'])}',
                    valueColor: Colors.red,
                  ),
              ],
            ),
          ),
          _panel(
            l10n.healthStripSetup,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(l10n.healthStripSetup, '${tenant.setupPercent}%'),
                _row(
                  l10n.supportDiagSetupNext,
                  nextSection == null
                      ? l10n.setupWizardStatusCompleted
                      : _sectionTitle(l10n, nextSection),
                  valueColor:
                      nextSection == null ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
          _panel(
            l10n.supportDiagUsersDrivers,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(l10n.supportDiagTotalUsers, '${d.totalUsers}'),
                _row(l10n.healthStripDrivers, '${tenant.driverCount}'),
                _row(l10n.supportDiagActiveDrivers,
                    '${d.metrics.activeDrivers}'),
                _row(l10n.customerHealthStaleGps, '${tenant.staleGpsDrivers}',
                    valueColor: tenant.staleGpsDrivers > 0
                        ? Colors.orange
                        : null),
              ],
            ),
          ),
          _panel(
            l10n.healthStripRoutes,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(l10n.supportDiagActiveRoutes, '${tenant.activeRoutes}'),
                _row(l10n.supportDiagPendingPoints,
                    '${d.pendingDeliveryPoints}'),
                _row(l10n.supportDiagCompletedToday,
                    '${d.metrics.deliveriesToday}'),
                if (d.cancelledDeliveryPoints > 0)
                  _row(l10n.supportDiagCancelledPoints,
                      '${d.cancelledDeliveryPoints}',
                      valueColor: Colors.red),
              ],
            ),
          ),
          _panel(
            l10n.healthStripAccounting,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(
                  l10n.supportDiagSyncStatus,
                  d.latestSyncEntry?.status ?? '—',
                  valueColor: _healthColor(tenant.accounting),
                ),
                _row(l10n.customerHealthFailedSync, '${tenant.failedSyncCount}',
                    valueColor: tenant.failedSyncCount > 0
                        ? Colors.red
                        : null),
                if (tenant.lastSyncError != null)
                  _row(l10n.healthStripLastError, tenant.lastSyncError!,
                      valueColor: Colors.red),
                if (d.latestSyncEntry?.status == 'failed')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _retryingSync ? null : _retryAccountingSync,
                      icon: _retryingSync
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay),
                      label: Text(l10n.retry),
                    ),
                  ),
              ],
            ),
          ),
          _panel(
            l10n.supportDiagNotifications,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(
                  l10n.healthStripFcm,
                  '${d.fcmTokenUsers}/${d.totalUsers}',
                  valueColor: d.fcmTokenUsers == 0 && d.totalUsers > 0
                      ? Colors.orange
                      : Colors.green,
                ),
                _row(l10n.chipUnread, '$_unreadCount'),
                if (_pushLogs.isNotEmpty)
                  _row(
                    l10n.supportDiagLastPush,
                    '${_pushLogs.first['errorCode'] ?? '—'} • '
                    '${_fmtTs(_pushLogs.first['timestamp'])}',
                  ),
                if (_emailLogs.isNotEmpty)
                  _row(
                    l10n.supportDiagLastEmail,
                    '${_emailLogs.first['errorCode'] ?? '—'} • '
                    '${_fmtTs(_emailLogs.first['timestamp'])}',
                  ),
              ],
            ),
          ),
          _panel(
            l10n.remoteConfigTitle,
            RemoteConfigReadonlyBlock(companyId: d.companyId),
          ),
          _panel(
            l10n.dataIntegrityTitle,
            DataIntegrityReadonlyBlock(companyId: d.companyId),
          ),
          _panel(
            l10n.supportDiagRecentErrors,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _correlationController,
                  decoration: InputDecoration(
                    labelText: l10n.supportDiagFilterCorrelation,
                    prefixIcon: const Icon(Icons.filter_alt),
                    suffixIcon: _correlationFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _correlationFilter = '';
                              _correlationController.clear();
                            }),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _correlationFilter = v),
                ),
                const SizedBox(height: 8),
                if (_filteredErrors.isEmpty)
                  Text(l10n.noAuditEvents,
                      style: TextStyle(color: AppTheme.muted))
                else
                  ..._filteredErrors.map((e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          e.source == 'audit' ? Icons.history : Icons.error,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                        title: Text(e.type,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${e.message}\n'
                          '${e.correlationId != null ? 'cid: ${e.correlationId}\n' : ''}'
                          '${e.at != null ? _fmtTs(Timestamp.fromDate(e.at!)) : '—'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        isThreeLine: true,
                        onTap: e.correlationId != null
                            ? () {
                                setState(() {
                                  _correlationFilter = e.correlationId!;
                                  _correlationController.text = e.correlationId!;
                                });
                                _tabController.animateTo(1);
                              }
                            : null,
                      )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.supportDiagLoadedAt}: ${_fmtTs(Timestamp.fromDate(d.loadedAt))}',
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value',
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final style = TextStyle(color: valueColor ?? AppTheme.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: style),
              ],
            )
          : Row(
              children: [
                SizedBox(
                    width: 180,
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Text(value, style: style)),
              ],
            ),
    );
  }

  /// Имя актора по uid (для аудита: показываем имя, а не код).
  /// 'system' и неизвестные uid — как есть.
  String _actorName(dynamic actor) {
    final id = (actor ?? '').toString();
    if (id.isEmpty || id == 'system') return id;
    final name = _userNames[id];
    return (name != null && name.isNotEmpty) ? name : id;
  }

  Widget _buildAuditTab() {
    final l10n = AppLocalizations.of(context)!;
    final events = _filteredAuditEvents;
    if (events.isEmpty) {
      return Center(child: Text(l10n.noAuditEvents));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        final type = e['type'] ?? '';
        final from = e['fromStatus'] ?? '';
        final to = e['toStatus'] ?? '';
        final reason = e['reason'] ?? '';
        final cid = e['correlationId'] as String? ?? '';
        final op = e['operation'] as String? ?? '';
        return ListTile(
          dense: true,
          leading: Icon(
            type.contains('billing') ? Icons.payments : Icons.history,
            size: 20,
            color: type.contains('billing') ? Colors.orange : Colors.grey,
          ),
          title: Text(type, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${from.isNotEmpty ? '$from → $to' : ''}'
            '${reason.isNotEmpty ? ' • $reason' : ''}'
            '${cid.isNotEmpty ? '\ncid: $cid' : ''}'
            '${op.isNotEmpty ? ' • $op' : ''}'
            '\n${_fmtTs(e['createdAt'])} • ${_actorName(e['createdBy'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_paymentEvents.isEmpty) {
      return Center(child: Text(l10n.noPaymentEvents));
    }
    return ListView.builder(
      itemCount: _paymentEvents.length,
      itemBuilder: (context, i) {
        final e = _paymentEvents[i];
        final provider = e['provider'] ?? '—';
        final amount = e['amount'] ?? 0;
        final currency = e['currency'] ?? 'ILS';
        final error = e['error'];
        return ListTile(
          dense: true,
          leading: Icon(
            error != null ? Icons.error : Icons.check_circle,
            color: error != null ? Colors.red : Colors.green,
            size: 20,
          ),
          title: Text('$provider • $amount $currency',
              style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${error ?? 'OK'}\n${_fmtTs(e['processedAt'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_notifications.isEmpty) {
      return Center(child: Text(l10n.noNotifications));
    }
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, i) {
        final n = _notifications[i];
        final read = n['read'] == true;
        final severity = n['severity'] ?? 'info';
        return ListTile(
          dense: true,
          leading: Icon(
            severity == 'critical'
                ? Icons.error
                : severity == 'warning'
                    ? Icons.warning_amber
                    : Icons.info_outline,
            color: severity == 'critical'
                ? Colors.red
                : severity == 'warning'
                    ? Colors.orange
                    : Colors.blue,
            size: 20,
          ),
          title: Text(
            n['title'] ?? '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: read ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${(n['body'] ?? '').toString().isNotEmpty ? '${n['body']}\n' : ''}'
            '${n['type'] ?? ''} • ${read ? l10n.readStatus : l10n.unreadStatus} • ${_fmtTs(n['createdAt'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildPushLogsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_pushLogs.isEmpty) {
      return Center(
          child: Text(l10n.noPushErrors,
              style: const TextStyle(color: Colors.green)));
    }
    return ListView.builder(
      itemCount: _pushLogs.length,
      itemBuilder: (context, i) {
        final l = _pushLogs[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: Colors.red, size: 20),
          title: Text(l['errorCode'] ?? 'unknown',
              style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${l['errorMessage'] ?? ''}\nuid: ${l['uid'] ?? '—'} • ${_fmtTs(l['timestamp'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildEmailLogsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_emailLogs.isEmpty) {
      return Center(
          child: Text(l10n.noEmailErrors,
              style: const TextStyle(color: Colors.green)));
    }
    return ListView.builder(
      itemCount: _emailLogs.length,
      itemBuilder: (context, i) {
        final l = _emailLogs[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.email, color: Colors.red, size: 20),
          title: Text('${l['errorCode'] ?? 'unknown'} → ${l['email'] ?? ''}',
              style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${l['errorMessage'] ?? ''}\ntype: ${l['notifType'] ?? '—'} • ${_fmtTs(l['timestamp'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
