import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  static const _filterOptions = {
    'all': 'הכל',
    'trial': '🧪 Trial',
    'active': '✅ Active',
    'grace': '⏳ Grace',
    'suspended': '🚫 Suspended',
    'cancelled': '❌ Cancelled',
  };

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;

    final noteController =
        TextEditingController(text: 'Extended via dashboard');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Extend $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set paidUntil to: ${_fmtDate(picked)}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Extend')),
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
            ? 'Extended via dashboard'
            : noteController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ $companyName extended to ${_fmtDate(picked)}'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setStatus(
      String companyId, String companyName, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change $companyName → $newStatus?'),
        content: Text('This will immediately change the billing status.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
      await _firestore.collection('companies').doc(companyId).update({
        'billingStatus': newStatus,
        'billingStatusChangedAt': FieldValue.serverTimestamp(),
        'billingStatusChangedBy': 'super_admin:dashboard',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ $companyName → $newStatus'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runIntegrityCheck() async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyIntegrityChain');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('🔗 Running integrity check...'),
            backgroundColor: Colors.blue),
      );
      // Note: verifyIntegrityChain is a callable, scheduledIntegrityCheck is scheduled
      // For dashboard, we trigger the callable version
      await callable.call({});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Integrity check complete'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'Run Integrity Check',
            onPressed: _runIntegrityCheck,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.entries.map((e) {
                        final isSelected = _statusFilter == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(e.value),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _statusFilter = e.key),
                            selectedColor: e.key == 'all'
                                ? Colors.deepPurple.shade100
                                : _statusColor(e.key).withValues(alpha: 0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'חיפוש...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No companies found'));
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
    final graceDays = data['gracePeriodDays'] as int? ?? 7;
    final graceUntil =
        paidUntil != null ? paidUntil.add(Duration(days: graceDays)) : null;

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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (nameEn.isNotEmpty)
                        Text(nameEn,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
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
                _InfoChip('Plan', plan),
                if (provider != null) _InfoChip('Provider', provider),
                _InfoChip('Paid until',
                    '${fmtDate(paidUntil)} ${daysUntil(paidUntil)}',
                    warn: isPaidExpired),
                if (status == 'trial')
                  _InfoChip('Trial until',
                      '${fmtDate(trialUntil)} ${daysUntil(trialUntil)}'),
                if (status == 'grace' && graceUntil != null)
                  _InfoChip('Grace until',
                      '${fmtDate(graceUntil)} ${daysUntil(graceUntil)}',
                      warn: true),
                _InfoChip('Grace days', '$graceDays'),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                _ActionBtn(
                    Icons.add_circle_outline, 'Extend', Colors.green, onExtend),
                const SizedBox(width: 4),
                if (status != 'active')
                  _ActionBtn(Icons.check_circle_outline, 'Active', Colors.green,
                      onSetActive),
                if (status != 'active') const SizedBox(width: 4),
                if (status == 'active')
                  _ActionBtn(Icons.pause_circle_outline, 'Grace', Colors.orange,
                      onSetGrace),
                if (status == 'active') const SizedBox(width: 4),
                if (status != 'suspended' && status != 'cancelled')
                  _ActionBtn(Icons.block, 'Suspend', Colors.red, onSuspend),
                const Spacer(),
                Text(companyId,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400)),
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
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
