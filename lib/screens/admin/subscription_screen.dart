import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/checkout_service.dart';

/// מסך ניהול מנוי — צפייה בתוכנית, היסטוריית תשלומים, שינוי תוכנית
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _firestore = FirebaseFirestore.instance;

  static const _planInfo = {
    'warehouse_only':
        _PlanInfo('מחסן בלבד', 149, 'ניהול מלאי בלבד', Icons.warehouse),
    'ops': _PlanInfo(
        'תפעול', 299, 'מחסן + לוגיסטיקה + דוחות', Icons.local_shipping),
    'full': _PlanInfo(
        'מלא', 499, 'כל המודולים כולל הנהלת חשבונות', Icons.all_inclusive),
    'custom': _PlanInfo('מותאם אישית', 0, 'תוכנית מותאמת', Icons.tune),
  };

  @override
  Widget build(BuildContext context) {
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId ?? '';
    if (companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('מנוי')),
        body: const Center(child: Text('לא נבחרה חברה')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ניהול מנוי')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('companies')
              .doc(companyId)
              .collection('settings')
              .doc('settings')
              .snapshots(),
          builder: (context, settingsSnap) {
            return StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore.collection('companies').doc(companyId).snapshots(),
              builder: (context, companySnap) {
                if (!companySnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final companyData =
                    companySnap.data?.data() as Map<String, dynamic>? ?? {};
                final plan = companyData['plan'] as String? ?? 'full';
                final status =
                    companyData['billingStatus'] as String? ?? 'active';
                final paidUntil = companyData['paidUntil'] != null
                    ? (companyData['paidUntil'] as Timestamp).toDate()
                    : null;
                final provider = companyData['paymentProvider'] as String?;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Current plan card
                    _buildCurrentPlan(
                        plan, status, paidUntil, provider, companyId),
                    const SizedBox(height: 16),

                    // Plan options
                    Text('שנה תוכנית',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._planInfo.entries.where((e) => e.key != 'custom').map(
                        (e) =>
                            _buildPlanOption(e.key, e.value, plan, companyId)),

                    const SizedBox(height: 24),

                    // Payment history
                    Text('היסטוריית תשלומים',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _PaymentHistory(companyId: companyId),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentPlan(String plan, String status, DateTime? paidUntil,
      String? provider, String companyId) {
    final info = _planInfo[plan] ?? _planInfo['full']!;
    final statusColor = _statusColor(status);

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(info.icon, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('התוכנית הנוכחית',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      Text(info.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (info.price > 0)
              Text('₪${info.price}/חודש',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            if (paidUntil != null)
              Text(
                  'שולם עד: ${paidUntil.day}.${paidUntil.month}.${paidUntil.year}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            if (provider != null)
              Text('ספק תשלום: $provider',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            if (status == 'grace' || status == 'suspended' || status == 'trial')
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await CheckoutService().createAndOpen(companyId: companyId);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('שגיאה: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.payment),
                label: const Text('שלם עכשיו'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(
      String planKey, _PlanInfo info, String currentPlan, String companyId) {
    final isCurrent = planKey == currentPlan;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isCurrent ? Colors.blue : Colors.grey.shade300,
            width: isCurrent ? 2 : 1),
      ),
      child: ListTile(
        leading: Icon(info.icon, color: isCurrent ? Colors.blue : Colors.grey),
        title: Text(info.name,
            style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(info.description),
        trailing: isCurrent
            ? const Chip(
                label: Text('נוכחי'),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white, fontSize: 11))
            : Text('₪${info.price}/חודש',
                style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: isCurrent
            ? null
            : () => _requestPlanChange(planKey, info, companyId),
      ),
    );
  }

  Future<void> _requestPlanChange(
      String newPlan, _PlanInfo info, String companyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('שנה ל${info.name}?'),
        content: Text(
            'התוכנית תשתנה ל${info.name} (₪${info.price}/חודש).\nהשינוי ייכנס לתוקף מיד.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('שנה תוכנית')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid ?? 'unknown';

      await _firestore
          .collection('companies')
          .doc(companyId)
          .update({'plan': newPlan});
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('settings')
          .update({'plan': newPlan});

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit')
          .add({
        'moduleKey': 'billing',
        'type': 'billing_status_changed',
        'entity': {'collection': 'companies', 'docId': companyId},
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'reason': 'Plan changed to $newPlan',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('התוכנית שונתה ל${info.name}'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
}

class _PlanInfo {
  final String name;
  final int price;
  final String description;
  final IconData icon;
  const _PlanInfo(this.name, this.price, this.description, this.icon);
}

/// היסטוריית תשלומים — מציג payment_events של החברה
class _PaymentHistory extends StatelessWidget {
  final String companyId;
  const _PaymentHistory({required this.companyId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('payment_events')
          .orderBy('processedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('אין היסטוריית תשלומים',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? '';
              final provider = data['provider'] as String? ?? '';
              final paidUntil = data['paidUntil'] != null
                  ? (data['paidUntil'] as Timestamp).toDate()
                  : null;
              final processedAt = data['processedAt'] != null
                  ? (data['processedAt'] as Timestamp).toDate()
                  : null;

              final icon =
                  type == 'payment_received' ? Icons.check_circle : Icons.info;
              final color =
                  type == 'payment_received' ? Colors.green : Colors.grey;

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(_typeLabel(type)),
                subtitle: Text([
                  if (provider.isNotEmpty) 'ספק: $provider',
                  if (paidUntil != null)
                    'שולם עד: ${paidUntil.day}.${paidUntil.month}.${paidUntil.year}',
                ].join(' · ')),
                trailing: processedAt != null
                    ? Text(
                        '${processedAt.day}.${processedAt.month}.${processedAt.year}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500))
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'payment_received':
        return 'תשלום התקבל';
      case 'subscription_cancelled':
        return 'מנוי בוטל';
      default:
        return type;
    }
  }
}
