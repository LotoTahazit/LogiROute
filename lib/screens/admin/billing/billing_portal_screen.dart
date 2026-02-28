import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/company_context.dart';
import '../../../services/plan_limits_service.dart';
import '../../../services/checkout_service.dart';
import 'billing_helpers.dart';
import 'receipt_exporter.dart';

/// פורטל חיוב — מסך ניהול עצמי לצפייה בתוכנית, סטטוס, שימוש, היסטוריה
class BillingPortalScreen extends StatefulWidget {
  const BillingPortalScreen({super.key});

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
    final id = companyCtx.effectiveCompanyId ?? '';
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
        appBar: AppBar(title: const Text('פורטל חיוב')),
        body: const Center(child: Text('החברה לא נבחרה')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('פורטל חיוב')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection('companies').doc(_companyId).snapshots(),
          builder: (context, companySnap) {
            if (companySnap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('שגיאה בטעינת נתוני חברה'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => setState(() {}),
                      child: const Text('נסה שוב'),
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

                  // Section 2: Usage limits (placeholder — task 5)
                  _UsageLimitsSection(usageFuture: _usageFuture),
                  const SizedBox(height: 16),

                  // Section 3: Payment history (placeholder — task 6)
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
    final plan = companyData['plan'] as String? ?? 'full';
    final status = companyData['billingStatus'] as String? ?? 'active';
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${info.name}  ${info.price}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                'שולם עד: ${paidUntil.day}.${paidUntil.month}.${paidUntil.year}'
                '  (${daysLeft! > 0 ? 'נותרו $daysLeft ימים' : 'פג תוקף'})',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
            ],

            // Payment provider
            if (provider != null && provider.isNotEmpty)
              Text(
                'ספק תשלום: $provider',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),

            const SizedBox(height: 12),

            // Grace banner
            if (status == 'grace')
              MaterialBanner(
                backgroundColor: Colors.orange.shade50,
                content: Text(
                  'החברה בתקופת חסד. יש לשלם כדי להמשיך את השירות.',
                  style: TextStyle(color: Colors.orange.shade900),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _pay(context),
                    child: const Text('שלם עכשיו'),
                  ),
                ],
              ),

            // Pay now button for suspended / trial
            if (status == 'suspended' || status == 'trial')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: () => _pay(context),
                  icon: const Icon(Icons.payment),
                  label: const Text('שלם עכשיו'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),

            const SizedBox(height: 8),

            // Change plan button
            OutlinedButton(
              onPressed: () => _showChangePlanDialog(context),
              child: const Text('שנה תוכנית'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    try {
      await CheckoutService().createAndOpen(companyId: companyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('דף התשלום נפתח')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא ניתן לפתוח את דף התשלום'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

class _PlanChangeDialog extends StatelessWidget {
  final String currentPlan;
  final String companyId;

  const _PlanChangeDialog({
    required this.currentPlan,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final plans = availablePlans(currentPlan);

    return AlertDialog(
      title: const Text('שנה תוכנית'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final planKey = plans[index];
            final info = planDisplayInfo[planKey]!;
            return Card(
              child: ListTile(
                title: Text(
                  '${info.name}  ${info.price}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(info.modules.join(', ')),
                trailing: FilledButton(
                  onPressed: () => _confirmPlan(context, planKey),
                  child: const Text('בחר'),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
      ],
    );
  }

  Future<void> _confirmPlan(BuildContext context, String planKey) async {
    Navigator.pop(context);
    try {
      await CheckoutService().createAndOpen(companyId: companyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('דף התשלום נפתח')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא ניתן לפתוח את דף התשלום'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'שימוש במשאבים',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (usageFuture == null)
              const Text('אין נתוני שימוש')
            else
              FutureBuilder<PlanUsageReport>(
                future: usageFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'שגיאה בטעינת נתוני שימוש',
                      style: TextStyle(color: Colors.red.shade700),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final report = snapshot.data!;
                  final limits = report.limits;
                  return Column(
                    children: [
                      _UsageBar(
                        label: 'משתמשים',
                        current: report.currentUsers,
                        max: limits.maxUsers,
                      ),
                      const SizedBox(height: 12),
                      _UsageBar(
                        label: 'מסמכים/חודש',
                        current: report.currentDocsThisMonth,
                        max: limits.maxDocsPerMonth,
                      ),
                      const SizedBox(height: 12),
                      _UsageBar(
                        label: 'מסלולים/יום',
                        current: 0,
                        max: limits.maxRoutesPerDay,
                      ),
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

  const _UsageBar({
    required this.label,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.grey.shade200,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'היסטוריית תשלומים',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(companyId)
                  .collection('payment_events')
                  .orderBy('processedAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'שגיאה בטעינת היסטוריית תשלומים',
                    style: TextStyle(color: Colors.red.shade700),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('אין היסטוריית תשלומים');
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
    final type = data['type'] as String? ?? '';
    final provider = data['provider'] as String? ?? '';
    final processedAt = _formatTimestamp(data['processedAt']);
    final paidUntil = _formatTimestamp(data['paidUntil']);

    return ListTile(
      title: Text(type),
      subtitle: Text('$provider  •  $processedAt  →  $paidUntil'),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'הורד קבלה',
        onPressed: () => _showExportSheet(context),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'בחר פורמט',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

      await Clipboard.setData(ClipboardData(text: content));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הקבלה הועתקה')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בייצוא הקבלה'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
