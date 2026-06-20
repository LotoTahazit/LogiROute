import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/checkout_service.dart';
import '../../services/cross_module_audit_service.dart';
import '../../services/firestore_paths.dart';
import '../../theme/app_theme.dart';

/// Subscription management screen
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _firestore = FirebaseFirestore.instance;

  _PlanInfo _getPlanInfo(String key, AppLocalizations l10n) {
    switch (key) {
      case 'logistics':
        return _PlanInfo(l10n.planLogistics, 790, 590, 0, l10n.planDescLogistics,
            Icons.local_shipping_outlined);
      case 'warehouse_only':
        return _PlanInfo(l10n.planWarehouseOnly, 490, 390, 0,
            l10n.planDescWarehouse, Icons.warehouse);
      case 'ops':
        return _PlanInfo(l10n.planOps, 1190, 890, 0, l10n.planDescOps,
            Icons.inventory_2_outlined);
      case 'full':
        return _PlanInfo(l10n.planFull, 1490, 1120, 0, l10n.planDescFull,
            Icons.all_inclusive);
      default:
        return _PlanInfo(l10n.planFull, 1490, 1120, 0, l10n.planDescFull,
            Icons.all_inclusive);
    }
  }

  static const _planKeys = ['logistics', 'warehouse_only', 'ops', 'full'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId ?? '';
    if (companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.subscriptionTitle)),
        body: Center(child: Text(l10n.noCompanySelectedSub)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionManagementTitle)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirestorePaths(firestore: _firestore)
              .companySettings(companyId)
              .doc('settings')
              .snapshots(),
          builder: (context, settingsSnap) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirestorePaths(firestore: _firestore)
                  .companyDoc(companyId)
                  .snapshots(),
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
                    _buildCurrentPlan(
                        plan, status, paidUntil, provider, companyId, l10n),
                    const SizedBox(height: 16),
                    Text(l10n.changePlanTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._planKeys.map((k) => _buildPlanOption(
                        k, _getPlanInfo(k, l10n), plan, companyId, l10n)),
                    const SizedBox(height: 24),
                    Text(l10n.paymentHistoryTitle,
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
      String? provider, String companyId, AppLocalizations l10n) {
    final info = _getPlanInfo(plan, l10n);
    final statusColor = _statusColor(status);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(info.icon, color: Colors.blue, size: 28),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: narrow ? 220 : 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.currentPlanLabel,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.muted)),
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
            if (info.price > 0) ...[
              Text(l10n.promoMonthlyPrice(info.promoPrice, 3),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(l10n.thenMonthlyPrice(info.price),
                  style: TextStyle(fontSize: 13, color: AppTheme.muted)),
              Text(l10n.setupAndIntegration(info.setupFee),
                  style: TextStyle(fontSize: 13, color: AppTheme.muted)),
              Text(l10n.minimumMonths(12),
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
            if (paidUntil != null)
              Text(
                  l10n.paidUntilDate(
                      '${paidUntil.day}.${paidUntil.month}.${paidUntil.year}'),
                  style: TextStyle(fontSize: 13, color: AppTheme.muted)),
            if (provider != null)
              Text(l10n.paymentProviderLabel(provider),
                  style: TextStyle(fontSize: 13, color: AppTheme.muted)),
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
                            content: Text(l10n.errorPrefix(e.toString())),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.payment),
                label: Text(l10n.payNowButton),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(String planKey, _PlanInfo info, String currentPlan,
      String companyId, AppLocalizations l10n) {
    final isCurrent = planKey == currentPlan;
    final narrow = MediaQuery.sizeOf(context).width < 600;
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.description),
            if (narrow && isCurrent) ...[
              const SizedBox(height: 6),
              Chip(
                  label: Text(l10n.currentChip),
                  backgroundColor: Colors.blue,
                  labelStyle:
                      const TextStyle(color: Colors.white, fontSize: 11)),
            ],
            if (narrow && !isCurrent) ...[
              const SizedBox(height: 6),
              Text(l10n.monthlyPriceShort(info.promoPrice),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(l10n.afterPromoPrice(3, info.price),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ],
        ),
        trailing: narrow
            ? null
            : isCurrent
                ? Chip(
                    label: Text(l10n.currentChip),
                    backgroundColor: Colors.blue,
                    labelStyle:
                        const TextStyle(color: Colors.white, fontSize: 11))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.monthlyPriceShort(info.promoPrice),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(l10n.afterPromoPrice(3, info.price),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
        onTap: isCurrent
            ? null
            : () => _requestPlanChange(planKey, info, companyId, l10n),
      ),
    );
  }

  Future<void> _requestPlanChange(String newPlan, _PlanInfo info,
      String companyId, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.changePlanConfirmTitle(info.name)),
        content: Text(l10n.changePlanConfirmBody(
            info.name, info.promoPrice, 3, info.price, info.setupFee, 12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.changePlanButton)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.currentUser?.uid ?? 'unknown';

      await FirestorePaths(firestore: _firestore)
          .companyDoc(companyId)
          .update({'plan': newPlan});
      await FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc('settings')
          .update({'plan': newPlan});

      await FirestorePaths(firestore: _firestore).audit(companyId).add({
        'moduleKey': 'billing',
        'type': CrossModuleAuditService.typeBillingStatusChanged,
        'entity': {'collection': 'companies', 'docId': companyId},
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'reason': 'Plan changed to $newPlan',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.planChangedSuccess(info.name)),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.errorPrefix(e.toString())),
              backgroundColor: Colors.red),
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
  final int promoPrice;
  final int setupFee;
  final String description;
  final IconData icon;
  const _PlanInfo(this.name, this.price, this.promoPrice, this.setupFee,
      this.description, this.icon);
}

/// Payment history widget
class _PaymentHistory extends StatelessWidget {
  final String companyId;
  const _PaymentHistory({required this.companyId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirestorePaths()
          .paymentEvents(companyId)
          .orderBy('processedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l10n.noPaymentHistorySub,
                    style: TextStyle(color: AppTheme.muted)),
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
                title: Text(_typeLabel(type, l10n)),
                subtitle: Text([
                  if (provider.isNotEmpty) l10n.providerPrefix(provider),
                  if (paidUntil != null)
                    l10n.paidUntilDate(
                        '${paidUntil.day}.${paidUntil.month}.${paidUntil.year}'),
                ].join(' · ')),
                trailing: processedAt != null
                    ? Text(
                        '${processedAt.day}.${processedAt.month}.${processedAt.year}',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.muted))
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'payment_received':
        return l10n.paymentReceived;
      case 'subscription_cancelled':
        return l10n.subscriptionCancelled;
      default:
        return type;
    }
  }
}
