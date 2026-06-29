import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/company_context.dart';
import '../../../services/billing_state.dart';
import '../../../services/plan_limits_service.dart';
import '../../../services/checkout_service.dart';
import '../../../widgets/checkout_ui_helper.dart';
import '../../../services/firestore_paths.dart';
import '../../../utils/file_download_stub.dart'
    if (dart.library.html) '../../../utils/file_download_web.dart';
import '../../../models/plan_limit_policy.dart';
import 'billing_helpers.dart';
import 'receipt_exporter.dart';
import '../../../theme/app_theme.dart';

String _localizedPlanName(String planKey, AppLocalizations l10n) {
  switch (planKey) {
    case 'logistics':
      return l10n.planLogistics;
    case 'warehouse_only':
      return l10n.planWarehouseOnly;
    case 'ops':
      return l10n.planOps;
    case 'full':
      return l10n.planFull;
    default:
      return planDisplayInfo[planKey]?.name ?? planKey;
  }
}

/// פורטל חיוב — מסך ניהול עצמי לצפייה בתוכנית, סטטוס, שימוש, היסטוריה
class BillingPortalScreen extends StatefulWidget {
  const BillingPortalScreen({super.key, this.companyId});

  /// Явный tenant из Support Console / Customer Health (H2).
  final String? companyId;

  @override
  State<BillingPortalScreen> createState() => _BillingPortalScreenState();
}

class _BillingPortalScreenState extends State<BillingPortalScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _companyId = '';
  Future<PlanUsageReport>? _usageFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyCtx = CompanyContext.of(context);
    final id = widget.companyId ?? companyCtx.effectiveCompanyId ?? '';
    if (id != _companyId) {
      _companyId = id;
      if (_companyId.isNotEmpty) {
        _usageFuture = PlanLimitsService(companyId: _companyId).checkUsage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)?.billingPortal ??
                'Billing Portal')),
        body: Center(
            child: Text(AppLocalizations.of(context)?.noCompanySelected ??
                'No company selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)?.billingPortal ??
                'Billing Portal'),
            Text(
              _companyId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirestorePaths(firestore: _firestore)
              .companyDoc(_companyId)
              .snapshots(),
          builder: (context, companySnap) {
            if (companySnap.hasError) {
              final l10n = AppLocalizations.of(context)!;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.companyLoadError),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => setState(() {}),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }
            if (!companySnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final companyData =
                companySnap.data?.data() as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Plan status
                  _PlanStatusSection(
                    companyData: companyData,
                    companyId: _companyId,
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Usage limits
                  _UsageLimitsSection(usageFuture: _usageFuture),
                  const SizedBox(height: 16),

                  // Section 3: Payment history
                  _PaymentHistorySection(companyId: _companyId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Plan Status
// ---------------------------------------------------------------------------

class _PlanStatusSection extends StatelessWidget {
  final Map<String, dynamic> companyData;
  final String companyId;

  const _PlanStatusSection({
    required this.companyData,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = companyData['plan'] as String? ?? 'full';
    final status = companyData['billingStatus'] as String? ?? 'active';
    final billingEval = BillingState.evaluateFromMap(companyData);
    final showGraceBanner =
        billingEval.displayPhase == BillingDisplayPhase.grace;
    final showPayCta = !billingEval.allowsAccess ||
        billingEval.displayPhase == BillingDisplayPhase.grace ||
        status == 'trial';
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final paidUntilTs = companyData['paidUntil'];
    final provider = companyData['paymentProvider'] as String?;

    final info = planDisplayInfo[plan] ?? planDisplayInfo['full']!;
    final chipColor = statusColors[status] ?? Colors.grey;

    DateTime? paidUntil;
    if (paidUntilTs is Timestamp) {
      paidUntil = paidUntilTs.toDate();
    }

    final daysLeft =
        paidUntil != null ? remainingDays(paidUntil, DateTime.now()) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan badge + status chip
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
                      Text(
                        _localizedPlanName(plan, l10n),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizedPlanDescription(plan, l10n),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPlanModulesLine(plan, l10n),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.priceArrow(info.promoPrice, 3, info.price),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        l10n.billingExtraDriverMonthly(
                          billingAddons.extraDriverPerMonth,
                          billingAddons.includedDrivers,
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: chipColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // paidUntil + remaining days
            if (paidUntil != null) ...[
              Text(
                '${l10n.paidUntil}: ${paidUntil.day}.${paidUntil.month}.${paidUntil.year}'
                '  (${daysLeft! > 0 ? l10n.daysRemaining(daysLeft) : l10n.expired})',
                style: TextStyle(fontSize: 14, color: AppTheme.muted),
              ),
              const SizedBox(height: 4),
            ],

            // Payment provider
            if (provider != null && provider.isNotEmpty)
              Text(
                '${l10n.paymentProvider}: $provider',
                style: TextStyle(fontSize: 13, color: AppTheme.muted),
              ),

            const SizedBox(height: 12),

            // Grace banner (incl. expired trial within grace window — C3)
            if (showGraceBanner)
              MaterialBanner(
                backgroundColor: Colors.orange.shade50,
                content: Text(
                  l10n.gracePeriodBanner,
                  style: TextStyle(color: Colors.orange.shade900),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _pay(context),
                    child: Text(l10n.payNow),
                  ),
                ],
              ),

            // Pay now for blocked / trial / grace
            if (showPayCta && !showGraceBanner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: () => _pay(context),
                  icon: const Icon(Icons.payment),
                  label: Text(l10n.payNow),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),

            const SizedBox(height: 8),

            // Change plan button
            OutlinedButton(
              onPressed: () => _showChangePlanDialog(context),
              child: Text(l10n.changePlan),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    await CheckoutUiHelper.run(
      context: context,
      checkout: () => CheckoutService().createAndOpen(
        companyId: companyId,
        userId: FirebaseAuth.instance.currentUser?.uid,
      ),
      onOpened: () {
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentPageOpened)),
        );
      },
    );
  }

  void _showChangePlanDialog(BuildContext context) {
    final currentPlan = companyData['plan'] as String? ?? 'full';
    showDialog(
      context: context,
      builder: (ctx) => _PlanChangeDialog(
        currentPlan: currentPlan,
        companyId: companyId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog: Plan Change
// ---------------------------------------------------------------------------

Widget _buildPlanOfferCard(
  BuildContext context, {
  required String planKey,
  required AppLocalizations l10n,
  required bool isCurrent,
  required bool narrow,
  VoidCallback? onSelect,
}) {
  final info = planDisplayInfo[planKey]!;
  return Card(
    margin: EdgeInsets.zero,
    color: isCurrent ? Colors.blue.shade50 : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: isCurrent ? Colors.blue : Colors.grey.shade300,
        width: isCurrent ? 2 : 1,
      ),
    ),
    child: ListTile(
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _localizedPlanName(planKey, l10n),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isCurrent)
            Chip(
              label: Text(
                l10n.planCurrentBadge,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              backgroundColor: Colors.blue,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizedPlanDescription(planKey, l10n)),
          const SizedBox(height: 4),
          Text(l10n.priceArrow(info.promoPrice, 3, info.price)),
          Text(l10n.setupAndIntegrationStr(info.setupFee)),
          Text(
            l10n.minimumMonths(minSubscriptionMonths),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Text(
            l10n.billingExtraDriverMonthly(
              billingAddons.extraDriverPerMonth,
              billingAddons.includedDrivers,
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Text(
            l10n.billingExtraWarehouseMonthly(
              billingAddons.extraWarehousePerMonth,
              billingAddons.includedWarehouseLocations,
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Text(
            l10n.billingDedicatedExportMonthly(
              billingAddons.dedicatedExportPerMonth,
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.planModulesLabel} ${formatPlanModulesLine(planKey, l10n)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          if (onSelect != null && narrow) ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: onSelect, child: Text(l10n.select)),
          ],
        ],
      ),
      trailing: onSelect != null && !narrow
          ? FilledButton(onPressed: onSelect, child: Text(l10n.select))
          : null,
    ),
  );
}

class _PlanChangeDialog extends StatelessWidget {
  final String currentPlan;
  final String companyId;

  const _PlanChangeDialog({
    required this.currentPlan,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plans = availablePlans(currentPlan);
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return AlertDialog(
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      title: Text(l10n.changePlan),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildPlanOfferCard(
              context,
              planKey: currentPlan,
              l10n: l10n,
              isCurrent: true,
              narrow: narrow,
            ),
            if (plans.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.changePlanTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...plans.map(
                (planKey) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPlanOfferCard(
                    context,
                    planKey: planKey,
                    l10n: l10n,
                    isCurrent: false,
                    narrow: narrow,
                    onSelect: () => _confirmPlan(context, planKey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.planAccountingNote,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              l10n.planBackupNote,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Future<void> _confirmPlan(BuildContext context, String planKey) async {
    Navigator.pop(context);
    await CheckoutUiHelper.run(
      context: context,
      checkout: () => CheckoutService().createAndOpen(
        companyId: companyId,
        userId: FirebaseAuth.instance.currentUser?.uid,
      ),
      onOpened: () {
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentPageOpened)),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Usage Limits
// ---------------------------------------------------------------------------

class _UsageLimitsSection extends StatelessWidget {
  final Future<PlanUsageReport>? usageFuture;

  const _UsageLimitsSection({this.usageFuture});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.resourceUsage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (usageFuture == null)
              Text(l10n.noUsageData)
            else
              FutureBuilder<PlanUsageReport>(
                future: usageFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      l10n.usageLoadError,
                      style: TextStyle(color: Colors.red.shade700),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final report = snapshot.data!;
                  final limits = report.limits;
                  return Column(
                    children: [
                      _UsageBar(
                        label: l10n.usersUsage,
                        current: report.currentUsers,
                        max: limits.maxUsers,
                        limitKey: PlanLimitKey.maxUsers,
                      ),
                      const SizedBox(height: 12),
                      _UsageBar(
                        label: l10n.docsPerMonth,
                        current: report.currentDocsThisMonth,
                        max: limits.maxDocsPerMonth,
                        limitKey: PlanLimitKey.maxDocsPerMonth,
                      ),
                      const SizedBox(height: 12),
                      _UsageBar(
                        label: l10n.routesPerDay,
                        current: 0,
                        max: limits.maxRoutesPerDay,
                        limitKey: PlanLimitKey.maxRoutesPerDay,
                      ),
                      if (report.hasWarnings) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.limitSoftExceededNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final PlanLimitKey limitKey;

  const _UsageBar({
    required this.label,
    required this.current,
    required this.max,
    required this.limitKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enforcement = PlanLimitPolicy.enforcement(limitKey);
    if (enforcement == LimitEnforcement.notEnforced) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(limitEnforcementLabel(enforcement, l10n)),
        trailing: Text(
          l10n.billingLimit(max),
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    final level = usageWarningLevel(current, max);
    final color = switch (level) {
      UsageWarningLevel.normal => Colors.green,
      UsageWarningLevel.warning => Colors.amber,
      UsageWarningLevel.critical => Colors.red,
    };
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            if (level == UsageWarningLevel.warning)
              const Icon(Icons.warning, color: Colors.amber, size: 18),
            if (level == UsageWarningLevel.critical)
              const Icon(Icons.warning, color: Colors.red, size: 18),
            const SizedBox(width: 4),
            Text(
              formatUsage(current, max),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Text(
          limitEnforcementLabel(enforcement, l10n),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: AppTheme.surfaceHi,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3: Payment History
// ---------------------------------------------------------------------------

class _PaymentHistorySection extends StatelessWidget {
  final String companyId;

  const _PaymentHistorySection({required this.companyId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentHistory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirestorePaths()
                  .paymentEvents(companyId)
                  .orderBy('processedAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    l10n.error,
                    style: TextStyle(color: Colors.red.shade700),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Text(l10n.noPaymentHistory);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _PaymentEventTile(
                      eventId: doc.id,
                      data: data,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentEventTile extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;

  const _PaymentEventTile({
    required this.eventId,
    required this.data,
  });

  String _formatTimestamp(dynamic value) {
    if (value == null) return '—';
    DateTime dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is DateTime) {
      dt = value;
    } else {
      return value.toString();
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final type = data['type'] as String? ?? '';
    final provider = data['provider'] as String? ?? '';
    final processedAt = _formatTimestamp(data['processedAt']);
    final paidUntil = _formatTimestamp(data['paidUntil']);

    return ListTile(
      title: Text(type),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$provider  •  $processedAt  →  $paidUntil'),
          if (narrow) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.download),
                tooltip: AppLocalizations.of(context)?.downloadReceipt ??
                    'Download receipt',
                onPressed: () => _showExportSheet(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ],
      ),
      trailing: narrow
          ? null
          : IconButton(
              icon: const Icon(Icons.download),
              tooltip: AppLocalizations.of(context)?.downloadReceipt ??
                  'Download receipt',
              onPressed: () => _showExportSheet(context),
            ),
    );
  }

  void _showExportSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.selectFormat,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              onTap: () {
                Navigator.pop(ctx);
                _exportReceipt(context, 'json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _exportReceipt(context, 'csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildEventData() {
    final processedAt = data['processedAt'];
    final paidUntil = data['paidUntil'];

    String toIso(dynamic value) {
      if (value == null) return '';
      if (value is Timestamp) return value.toDate().toIso8601String();
      if (value is DateTime) return value.toIso8601String();
      if (value is String) return value;
      return value.toString();
    }

    return {
      'eventId': eventId,
      'type': data['type'] ?? '',
      'provider': data['provider'] ?? '',
      'amount': data['amount'],
      'currency': (data['currency'] as String?) ?? 'ILS',
      'processedAt': toIso(processedAt),
      'paidUntil': toIso(paidUntil),
    };
  }

  Future<void> _exportReceipt(BuildContext context, String format) async {
    try {
      final eventData = _buildEventData();
      final content = format == 'json'
          ? ReceiptExporter.toJson(eventData)
          : ReceiptExporter.toCsv(eventData);

      if (kIsWeb) {
        if (format == 'csv') {
          downloadCsv(content, 'receipt.csv');
        } else {
          downloadFile(utf8.encode(content), 'receipt.json');
        }
      } else {
        await Clipboard.setData(ClipboardData(text: content));
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.receiptCopied)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptExportError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
