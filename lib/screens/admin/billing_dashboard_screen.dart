import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../l10n/app_localizations.dart';
import '../../services/firestore_paths.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logi_route_tab_bar.dart';

/// Billing & Compliance Dashboard для super_admin.
/// Один экран для управления 50–200 компаниями:
/// - Список компаний с status, paidUntil, trialUntil, lastPayment
/// - Фильтр по статусу
/// - Quick actions: extend paidUntil, set grace, run integrity check
class BillingDashboardScreen extends StatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _statusFilter = 'all';
  String _searchQuery = '';

  Map<String, String> _filterLabels(AppLocalizations l10n) => {
        'all': l10n.billingDashboardFilterAll,
        'trial': l10n.billingDashboardFilterTrial,
        'active': l10n.billingDashboardFilterActive,
        'grace': l10n.billingDashboardFilterGrace,
        'suspended': l10n.billingDashboardFilterSuspended,
        'cancelled': l10n.billingDashboardFilterCancelled,
      };

  Widget _buildStatusFilterPills(Map<String, String> filterLabels) {
    final keys = filterLabels.keys.toList();
    return LogiRoutePillSelector(
      labels: keys.map((k) => filterLabels[k]!).toList(),
      selectedIndex: keys.indexOf(_statusFilter),
      onSelected: (i) => setState(() => _statusFilter = keys[i]),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('companies');
    if (_statusFilter != 'all') {
      query = query.where('billingStatus', isEqualTo: _statusFilter);
    }
    return query.orderBy('nameHebrew');
  }

  Color _statusColor(String status) {
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

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String _daysUntil(DateTime? dt) {
    if (dt == null) return '';
    final days = dt.difference(DateTime.now()).inDays;
    if (days < 0) return '(${-days}d ago)';
    if (days == 0) return '(today)';
    return '(${days}d)';
  }

  Future<void> _extendPaidUntil(String companyId, String companyName) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;

    final noteController =
        TextEditingController(text: l10n.billingDashboardNoteDefault);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.billingDashboardExtendTitle(companyName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.billingDashboardExtendPaidUntil(_fmtDate(picked))),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: l10n.billingDashboardNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.billingDashboardExtendButton)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('registerManualPayment');
      await callable.call({
        'companyId': companyId,
        'paidUntilISO': picked.toIso8601String(),
        'note': noteController.text.trim().isEmpty
            ? l10n.billingDashboardNoteDefault
            : noteController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.billingDashboardExtendSuccess(
                  companyName, _fmtDate(picked))),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.billingDashboardError(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setStatus(
      String companyId, String companyName, String newStatus) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.billingDashboardChangeStatusTitle(companyName, newStatus)),
        content: Text(l10n.billingDashboardChangeStatusBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: _statusColor(newStatus)),
            child: Text(newStatus),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirestorePaths(firestore: _firestore).companyDoc(companyId).update({
        'billingStatus': newStatus,
        'billingStatusChangedAt': FieldValue.serverTimestamp(),
        'billingStatusChangedBy': 'super_admin:dashboard',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  l10n.billingDashboardStatusUpdated(companyName, newStatus)),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.billingDashboardError(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runIntegrityCheck() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyIntegrityChain');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.billingDashboardIntegrityRunning),
            backgroundColor: Colors.blue),
      );
      // Note: verifyIntegrityChain is a callable, scheduledIntegrityCheck is scheduled
      // For dashboard, we trigger the callable version
      await callable.call({});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.billingDashboardIntegrityDone),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.billingDashboardError(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seedBillingPricing() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.billingDashboardSeedPricingTitle),
        content: Text(l10n.billingDashboardSeedPricingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.billingDashboardSeedPricingButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.billingDashboardSeedPricingRunning),
          backgroundColor: Colors.blue,
        ),
      );
      final result = await FirebaseFunctions.instance
          .httpsCallable('seedBillingPricing')
          .call();
      final plans = (result.data as Map?)?['plans'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingDashboardSeedPricingDone(
              plans is List ? plans.join(', ') : '',
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingDashboardError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterLabels = _filterLabels(l10n);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.billingDashboardTitle),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.price_change_outlined),
            tooltip: l10n.billingDashboardSeedPricingTooltip,
            onPressed: _seedBillingPricing,
          ),
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: l10n.billingDashboardRunIntegrityTooltip,
            onPressed: _runIntegrityCheck,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusFilterPills(filterLabels),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: l10n.billingDashboardSearchHint,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatusFilterPills(filterLabels),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.billingDashboardSearchHint,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.toLowerCase()),
                        ),
                      ),
                    ],
                  ),
          ),

          // Company list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(l10n.billingDashboardNoCompanies));
                }

                var docs = snapshot.data!.docs;
                // Client-side search filter
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final name =
                        (data['nameHebrew'] ?? '').toString().toLowerCase();
                    final nameEn =
                        (data['nameEnglish'] ?? '').toString().toLowerCase();
                    final id = doc.id.toLowerCase();
                    return name.contains(_searchQuery) ||
                        nameEn.contains(_searchQuery) ||
                        id.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return _CompanyCard(
                      companyId: doc.id,
                      data: data,
                      statusColor: _statusColor,
                      fmtDate: _fmtDate,
                      daysUntil: _daysUntil,
                      onExtend: () => _extendPaidUntil(
                          doc.id, data['nameHebrew'] ?? doc.id),
                      onSetGrace: () => _setStatus(
                          doc.id, data['nameHebrew'] ?? doc.id, 'grace'),
                      onSetActive: () => _setStatus(
                          doc.id, data['nameHebrew'] ?? doc.id, 'active'),
                      onSuspend: () => _setStatus(
                          doc.id, data['nameHebrew'] ?? doc.id, 'suspended'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> data;
  final Color Function(String) statusColor;
  final String Function(DateTime?) fmtDate;
  final String Function(DateTime?) daysUntil;
  final VoidCallback onExtend;
  final VoidCallback onSetGrace;
  final VoidCallback onSetActive;
  final VoidCallback onSuspend;

  const _CompanyCard({
    required this.companyId,
    required this.data,
    required this.statusColor,
    required this.fmtDate,
    required this.daysUntil,
    required this.onExtend,
    required this.onSetGrace,
    required this.onSetActive,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final status = data['billingStatus'] as String? ?? 'active';
    final name = data['nameHebrew'] as String? ?? companyId;
    final nameEn = data['nameEnglish'] as String? ?? '';
    final plan = data['plan'] as String? ?? 'full';
    final provider = data['paymentProvider'] as String?;

    final paidUntil = data['paidUntil'] != null
        ? (data['paidUntil'] as Timestamp).toDate()
        : null;
    final trialUntil = data['trialUntil'] != null
        ? (data['trialUntil'] as Timestamp).toDate()
        : null;
    final graceDays = (data['gracePeriodDays'] as num?)?.toInt() ?? 7;
    final graceUntil = paidUntil?.add(Duration(days: graceDays));

    final color = statusColor(status);
    final isPaidExpired =
        paidUntil != null && paidUntil.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + status badge
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: narrow ? 240 : 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (nameEn.isNotEmpty)
                        Text(nameEn,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.muted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info grid
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _InfoChip(l10n.billingPlan, plan),
                if (provider != null) _InfoChip(l10n.billingLabelProvider, provider),
                _InfoChip(l10n.billingLabelPaidUntil,
                    '${fmtDate(paidUntil)} ${daysUntil(paidUntil)}',
                    warn: isPaidExpired),
                if (status == 'trial')
                  _InfoChip(l10n.billingLabelTrialUntil,
                      '${fmtDate(trialUntil)} ${daysUntil(trialUntil)}'),
                if (status == 'grace' && graceUntil != null)
                  _InfoChip(l10n.billingLabelGraceUntil,
                      '${fmtDate(graceUntil)} ${daysUntil(graceUntil)}',
                      warn: true),
                _InfoChip(l10n.billingLabelGraceDays, '$graceDays'),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Wrap(
              spacing: 4,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionBtn(
                    Icons.add_circle_outline,
                    l10n.billingActionExtend,
                    Colors.green,
                    onExtend),
                if (status != 'active')
                  _ActionBtn(
                      Icons.check_circle_outline,
                      l10n.billingActionActive,
                      Colors.green,
                      onSetActive),
                if (status == 'active')
                  _ActionBtn(
                      Icons.pause_circle_outline,
                      l10n.billingActionGrace,
                      Colors.orange,
                      onSetGrace),
                if (status != 'suspended' && status != 'cancelled')
                  _ActionBtn(
                      Icons.block, l10n.billingActionSuspend, Colors.red, onSuspend),
                Text(companyId,
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;
  const _InfoChip(this.label, this.value, {this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: warn ? Colors.red : Colors.black87)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
