import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/firestore_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logi_route_tab_bar.dart';

/// Support Console — "одна компания = вся история"
/// Только для super_admin. Выбираешь компанию → видишь всё:
/// billing, payments, webhooks, notifications, delivery logs, integrity.
/// Кнопка "Export diagnostic JSON" — всё в один файл.
class SupportConsoleScreen extends StatefulWidget {
  const SupportConsoleScreen({super.key});

  @override
  State<SupportConsoleScreen> createState() => _SupportConsoleScreenState();
}

class _SupportConsoleScreenState extends State<SupportConsoleScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  String? _selectedCompanyId;
  Map<String, dynamic>? _companyData;
  bool _isLoading = false;

  // Data for tabs
  List<Map<String, dynamic>> _auditEvents = [];
  List<Map<String, dynamic>> _paymentEvents = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _pushLogs = [];
  List<Map<String, dynamic>> _emailLogs = [];
  int _unreadCount = 0;
  int _userCount = 0;
  int _docsThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData(String companyId) async {
    setState(() {
      _isLoading = true;
      _selectedCompanyId = companyId;
    });

    try {
      final companyDoc = await FirestorePaths().companyDoc(companyId).get();
      _companyData = companyDoc.data();

      final results = await Future.wait([
        FirestorePaths()
            .audit(companyId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get(),
        FirestorePaths()
            .paymentEvents(companyId)
            .orderBy('processedAt', descending: true)
            .limit(20)
            .get(),
        FirestorePaths()
            .notifications(companyId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get(),
        FirestorePaths()
            .pushDeliveryLogs(companyId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get(),
        FirestorePaths()
            .emailDeliveryLogs(companyId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get(),
        FirestorePaths()
            .notifications(companyId)
            .where('read', isEqualTo: false)
            .get(),
        _firestore
            .collection('users')
            .where('companyId', isEqualTo: companyId)
            .get(),
        FirestorePaths()
            .invoices(companyId)
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(
                    DateTime(DateTime.now().year, DateTime.now().month, 1)))
            .get(),
      ]);

      _auditEvents = (results[0] as QuerySnapshot)
          .docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
      _paymentEvents = (results[1] as QuerySnapshot)
          .docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
      _notifications = (results[2] as QuerySnapshot)
          .docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
      _pushLogs = (results[3] as QuerySnapshot)
          .docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
      _emailLogs = (results[4] as QuerySnapshot)
          .docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
      _unreadCount = (results[5] as QuerySnapshot).docs.length;
      _userCount = (results[6] as QuerySnapshot).docs.length;
      _docsThisMonth = (results[7] as QuerySnapshot).docs.length;
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

  Future<void> _runIntegrityCheck() async {
    if (_selectedCompanyId == null) return;
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
    if (_companyData == null || _selectedCompanyId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final diagnostic = {
      'companyId': _selectedCompanyId,
      'exportedAt': DateTime.now().toIso8601String(),
      'company': _companyData,
      'stats': {
        'users': _userCount,
        'docsThisMonth': _docsThisMonth,
        'unreadNotifications': _unreadCount,
      },
      'auditEvents': _auditEvents,
      'paymentEvents': _paymentEvents,
      'notifications': _notifications,
      'pushDeliveryErrors': _pushLogs,
      'emailDeliveryErrors': _emailLogs,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.supportConsoleTitle),
          actions: [
            if (_selectedCompanyId != null) ...[
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
            : _isLoading
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
    final d = _companyData ?? {};
    final status = d['billingStatus'] ?? 'unknown';
    final plan = d['plan'] ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedCompanyId = null;
              _companyData = null;
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
                  Text(
                    d['nameHebrew'] ?? _selectedCompanyId ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('ID: $_selectedCompanyId',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _chip(l10n.chipStatus, status, _statusColor(status)),
                      _chip(l10n.chipPlan, plan, Colors.blue),
                      _chip(l10n.chipUsers, '$_userCount', Colors.indigo),
                      _chip(l10n.chipDocsMonth, '$_docsThisMonth', Colors.teal),
                      _chip(l10n.chipUnread, '$_unreadCount', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sectionBilling,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row(l10n.labelPaidUntil, _fmtDate(d['paidUntil'])),
                  _row(l10n.labelTrialUntil, _fmtDate(d['trialUntil'])),
                  _row(l10n.labelGracePeriodDays,
                      '${d['gracePeriodDays'] ?? 7}'),
                  _row(l10n.labelPaymentProvider, d['paymentProvider'] ?? '—'),
                  _row(l10n.labelPaymentCustomerId,
                      d['paymentCustomerId'] ?? '—'),
                  _row(l10n.labelSubscriptionId, d['subscriptionId'] ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sectionLimitsUsage,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row(l10n.labelMaxUsers,
                      '${(d['limits'] as Map?)?['maxUsers'] ?? 999}'),
                  _row(l10n.labelActualUsers, '$_userCount'),
                  _row(l10n.labelMaxDocsPerMonth,
                      '${(d['limits'] as Map?)?['maxDocsPerMonth'] ?? 99999}'),
                  _row(l10n.labelDocsThisMonth, '$_docsThisMonth'),
                  if (_userCount >= ((d['limits'] as Map?)?['maxUsers'] ?? 999))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.userLimitReached,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sectionModules,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...(d['modules'] as Map<String, dynamic>? ?? {}).entries.map(
                      (e) => _row(
                          e.key,
                          e.value == true
                              ? l10n.moduleEnabled
                              : l10n.moduleDisabled)),
                ],
              ),
            ),
          ),
        ],
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

  Widget _row(String label, String value) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: AppTheme.muted)),
              ],
            )
          : Row(
              children: [
                SizedBox(
                    width: 180,
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(
                    child: Text(value,
                        style: TextStyle(color: AppTheme.muted))),
              ],
            ),
    );
  }

  Widget _buildAuditTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_auditEvents.isEmpty) {
      return Center(child: Text(l10n.noAuditEvents));
    }
    return ListView.builder(
      itemCount: _auditEvents.length,
      itemBuilder: (context, i) {
        final e = _auditEvents[i];
        final type = e['type'] ?? '';
        final from = e['fromStatus'] ?? '';
        final to = e['toStatus'] ?? '';
        final reason = e['reason'] ?? '';
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
            '\n${_fmtTs(e['createdAt'])} • ${e['createdBy'] ?? ''}',
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
            '${n['type'] ?? ''} • ${read ? l10n.readStatus : l10n.unreadStatus}\n${_fmtTs(n['createdAt'])}',
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
