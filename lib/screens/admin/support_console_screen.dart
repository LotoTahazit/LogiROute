import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      _companyData = companyDoc.data();

      // Parallel loads
      final results = await Future.wait([
        // 0: audit (last 20 billing transitions)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('audit')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get(),
        // 1: payment_events (last 20)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('payment_events')
            .orderBy('processedAt', descending: true)
            .limit(20)
            .get(),
        // 2: notifications (last 20)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get(),
        // 3: push delivery logs (last 20 errors)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('push_delivery_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get(),
        // 4: email delivery logs (last 20 errors)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('email_delivery_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get(),
        // 5: unread notifications count
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('notifications')
            .where('read', isEqualTo: false)
            .count()
            .get(),
        // 6: user count
        _firestore
            .collection('users')
            .where('companyId', isEqualTo: companyId)
            .count()
            .get(),
        // 7: docs this month (invoices)
        _firestore
            .collection('companies')
            .doc(companyId)
            .collection('accounting')
            .doc('_root')
            .collection('invoices')
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(
                    DateTime(DateTime.now().year, DateTime.now().month, 1)))
            .count()
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
      _unreadCount = (results[5] as AggregateQuerySnapshot).count ?? 0;
      _userCount = (results[6] as AggregateQuerySnapshot).count ?? 0;
      _docsThisMonth = (results[7] as AggregateQuerySnapshot).count ?? 0;
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
                ? '✅ Integrity OK'
                : '❌ Integrity FAILED: ${data?['error'] ?? 'unknown'}'),
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
        const SnackBar(
          content: Text('📋 Diagnostic JSON copied to clipboard'),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support Console'),
          actions: [
            if (_selectedCompanyId != null) ...[
              IconButton(
                icon: const Icon(Icons.verified_user),
                tooltip: 'Verify Integrity',
                onPressed: _runIntegrityCheck,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export Diagnostic JSON',
                onPressed: _exportDiagnosticJson,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => _loadCompanyData(_selectedCompanyId!),
              ),
            ],
          ],
          bottom: _selectedCompanyId != null
              ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'סקירה'),
                    const Tab(text: 'Billing Audit'),
                    Tab(text: 'Payments (${_paymentEvents.length})'),
                    Tab(
                        text:
                            'Notifications (${_notifications.length}/$_unreadCount)'),
                    Tab(text: 'Push Errors (${_pushLogs.length})'),
                    Tab(text: 'Email Errors (${_emailLogs.length})'),
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
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('companies').orderBy('nameHebrew').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final companies = snapshot.data!.docs;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'חפש חברה...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
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
    final d = _companyData ?? {};
    final status = d['billingStatus'] ?? 'unknown';
    final plan = d['plan'] ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedCompanyId = null;
              _companyData = null;
            }),
            icon: const Icon(Icons.arrow_back),
            label: const Text('חזרה לרשימה'),
          ),
          const SizedBox(height: 8),

          // Company header
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
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _chip('Status', status, _statusColor(status)),
                      _chip('Plan', plan, Colors.blue),
                      _chip('Users', '$_userCount', Colors.indigo),
                      _chip('Docs/month', '$_docsThisMonth', Colors.teal),
                      _chip('Unread', '$_unreadCount', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Billing details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Billing',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row('paidUntil', _fmtDate(d['paidUntil'])),
                  _row('trialUntil', _fmtDate(d['trialUntil'])),
                  _row('gracePeriodDays', '${d['gracePeriodDays'] ?? 7}'),
                  _row('paymentProvider', d['paymentProvider'] ?? '—'),
                  _row('paymentCustomerId', d['paymentCustomerId'] ?? '—'),
                  _row('subscriptionId', d['subscriptionId'] ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Plan limits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Limits & Usage',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row('maxUsers',
                      '${(d['limits'] as Map?)?['maxUsers'] ?? 999}'),
                  _row('actual users', '$_userCount'),
                  _row('maxDocsPerMonth',
                      '${(d['limits'] as Map?)?['maxDocsPerMonth'] ?? 99999}'),
                  _row('docs this month', '$_docsThisMonth'),
                  if (_userCount >= ((d['limits'] as Map?)?['maxUsers'] ?? 999))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('⚠️ User limit reached',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Modules
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modules',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...(d['modules'] as Map<String, dynamic>? ?? {}).entries.map(
                      (e) => _row(
                          e.key, e.value == true ? '✅ enabled' : '❌ disabled')),
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
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 180,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              child:
                  Text(value, style: TextStyle(color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    if (_auditEvents.isEmpty) {
      return const Center(child: Text('No audit events'));
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
    if (_paymentEvents.isEmpty) {
      return const Center(child: Text('No payment events'));
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
    if (_notifications.isEmpty) {
      return const Center(child: Text('No notifications'));
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
            '${n['type'] ?? ''} • ${read ? '✓ read' : '● unread'}\n${_fmtTs(n['createdAt'])}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildPushLogsTab() {
    if (_pushLogs.isEmpty) {
      return const Center(
          child: Text('✅ No push delivery errors',
              style: TextStyle(color: Colors.green)));
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
    if (_emailLogs.isEmpty) {
      return const Center(
          child: Text('✅ No email delivery errors',
              style: TextStyle(color: Colors.green)));
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
