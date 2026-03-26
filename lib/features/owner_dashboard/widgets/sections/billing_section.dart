import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/auth_service.dart';
import '../../models/billing_invoice.dart';
import '../../repositories/billing_repository.dart';
import '../../services/entitlements_service.dart';

/// Секция «Биллинг» Owner Dashboard.
///
/// Отображает:
/// - Текущий план, статус биллинга, дата окончания триала/периода
/// - Список модулей: включённые и addon
/// - Список счетов из billing_invoices
/// - Счётчики использования: записи/день, события печати/день, хранилище
/// - Триал: оставшиеся дни; Grace: предупреждение; Suspended/cancelled: блокирующий баннер
/// - Скрытие subscriptionId и paymentCustomerId от owner/admin
///
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8
class BillingSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const BillingSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<BillingSection> {
  late BillingRepository _billingRepo;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _initRepo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.read<AuthService>();
    final superAdmin = authService.userModel?.isSuperAdmin ?? false;
    if (superAdmin != _isSuperAdmin) {
      _isSuperAdmin = superAdmin;
      _initRepo();
    }
  }

  void _initRepo() {
    _billingRepo = BillingRepository(
      companyId: widget.companyId,
      isSuperAdmin: _isSuperAdmin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _billingRepo.watchBillingInfo(),
      builder: (context, billingSnapshot) {
        if (billingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (billingSnapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(
              l10n.billingErrorLoading,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final billingData = billingSnapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status banner (Req 6.5, 6.6, 6.7)
              _buildStatusBanner(context),
              // Plan & status card (Req 6.1)
              _buildPlanCard(context, billingData),
              const SizedBox(height: 16),
              // Modules list (Req 6.2)
              _buildModulesCard(context),
              const SizedBox(height: 16),
              // Usage counters (Req 6.4)
              _buildUsageCard(context, billingData),
              const SizedBox(height: 16),
              // Super admin sensitive fields (Req 6.8)
              if (_isSuperAdmin) ...[
                _buildSensitiveFieldsCard(context, billingData),
                const SizedBox(height: 16),
              ],
              // Invoices list (Req 6.3)
              _buildInvoicesSection(context),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Status Banner — Requirements 6.5, 6.6, 6.7
  // ---------------------------------------------------------------------------

  Widget _buildStatusBanner(BuildContext context) {
    final status = widget.companySettings.billingStatus;
    final l10n = AppLocalizations.of(context)!;

    if (status == 'suspended' || status == 'cancelled') {
      // Blocking banner (Req 6.7)
      return Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.block, color: Colors.red.shade700, size: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'suspended'
                          ? l10n.billingAccountSuspended
                          : l10n.billingAccountCancelled,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status == 'suspended'
                          ? l10n.billingPaymentRequired
                          : l10n.billingContactSupport,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'grace') {
      // Grace warning (Req 6.6)
      final paidUntil = widget.companySettings.paidUntil;
      final graceDays = widget.companySettings.gracePeriodDays;
      String graceMsg = l10n.billingGraceDefault(graceDays);
      if (paidUntil != null) {
        final endDate = paidUntil.add(Duration(days: graceDays));
        final remaining = endDate.difference(DateTime.now()).inDays;
        if (remaining > 0) {
          graceMsg = l10n.billingGraceRemaining(remaining);
        }
      }

      return Card(
        color: Colors.orange.shade50,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade800, size: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 560),
                child: Text(
                  graceMsg,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'trial') {
      // Trial remaining days (Req 6.5)
      final trialEndsAt = widget.companySettings.trialEndsAt;
      if (trialEndsAt != null) {
        final remaining =
            EntitlementsService.getTrialDaysRemaining(trialEndsAt);
        return Card(
          color: Colors.blue.shade50,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom,
                    color: Colors.blue.shade700, size: 32),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 220, maxWidth: 560),
                  child: Text(
                    l10n.billingTrialRemaining(remaining),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Plan & Status Card — Requirement 6.1
  // ---------------------------------------------------------------------------

  Widget _buildPlanCard(
      BuildContext context, Map<String, dynamic> billingData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = widget.companySettings;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingPlanDetails, style: theme.textTheme.titleMedium),
            const Divider(),
            _InfoRow(label: l10n.billingPlan, value: _planLabel(cs.plan, l10n)),
            _InfoRow(
                label: l10n.billingStatusLabel,
                value: _statusLabel(cs.billingStatus, l10n)),
            if (cs.trialEndsAt != null)
              _InfoRow(
                label: l10n.billingTrialEnds,
                value: dateFmt.format(cs.trialEndsAt!),
              ),
            if (cs.paidUntil != null)
              _InfoRow(
                label: l10n.billingPaidUntil,
                value: dateFmt.format(cs.paidUntil!),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modules List — Requirement 6.2
  // ---------------------------------------------------------------------------

  Widget _buildModulesCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final es = EntitlementsService(companySettings: widget.companySettings);
    final moduleKeys = [
      'warehouse',
      'logistics',
      'dispatcher',
      'accounting',
      'reports'
    ];

    final included = <String>[];
    final addons = <String>[];

    for (final key in moduleKeys) {
      if (es.isModuleAvailable(key)) {
        if (es.isAddon(key)) {
          addons.add(key);
        } else {
          included.add(key);
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingModules, style: theme.textTheme.titleMedium),
            const Divider(),
            if (included.isNotEmpty) ...[
              Text(l10n.billingIncludedInPlan,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: included
                    .map((k) => Chip(
                          avatar: Icon(_moduleIcon(k), size: 18),
                          label: Text(_moduleLabel(k, l10n)),
                        ))
                    .toList(),
              ),
            ],
            if (addons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.billingAddons,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.tertiary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: addons
                    .map((k) => Chip(
                          avatar: Icon(_moduleIcon(k), size: 18),
                          label: Text(_moduleLabel(k, l10n)),
                          side: BorderSide(color: theme.colorScheme.tertiary),
                        ))
                    .toList(),
              ),
            ],
            if (included.isEmpty && addons.isEmpty) Text(l10n.billingNoModules),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Usage Counters — Requirement 6.4
  // ---------------------------------------------------------------------------

  Widget _buildUsageCard(
      BuildContext context, Map<String, dynamic> billingData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final limits = widget.companySettings.limits;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingUsage, style: theme.textTheme.titleMedium),
            const Divider(),
            _UsageRow(
              icon: Icons.description_outlined,
              label: l10n.billingDocsPerMonth,
              limit: limits.maxDocsPerMonth,
            ),
            _UsageRow(
              icon: Icons.people_outlined,
              label: l10n.billingUsers,
              limit: limits.maxUsers,
            ),
            _UsageRow(
              icon: Icons.route_outlined,
              label: l10n.billingRoutesPerDay,
              limit: limits.maxRoutesPerDay,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sensitive Fields (super_admin only) — Requirement 6.8
  // ---------------------------------------------------------------------------

  Widget _buildSensitiveFieldsCard(
      BuildContext context, Map<String, dynamic> billingData) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings,
                    size: 20, color: theme.colorScheme.error),
                Text(AppLocalizations.of(context)!.billingSensitiveFields,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _InfoRow(
              label: 'Subscription ID',
              value: billingData['subscriptionId']?.toString() ?? '—',
            ),
            _InfoRow(
              label: 'Payment Customer ID',
              value: billingData['paymentCustomerId']?.toString() ?? '—',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Invoices List — Requirement 6.3
  // ---------------------------------------------------------------------------

  Widget _buildInvoicesSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.billingInvoices, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<List<BillingInvoice>>(
          future: _billingRepo.getBillingInvoices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.billingErrorLoadingInvoices,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              );
            }

            final invoices = snapshot.data ?? [];
            if (invoices.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.billingNoInvoices)),
                ),
              );
            }

            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _InvoiceTile(invoice: invoices[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _planLabel(String plan, AppLocalizations l10n) {
    switch (plan) {
      case 'warehouse_only':
        return l10n.billingPlanWarehouse;
      case 'ops':
        return l10n.billingPlanOps;
      case 'full':
        return l10n.billingPlanFull;
      default:
        return plan;
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'active':
        return l10n.billingStatusActive;
      case 'trial':
        return l10n.billingStatusTrial;
      case 'grace':
        return l10n.billingStatusGrace;
      case 'suspended':
        return l10n.billingStatusSuspended;
      case 'cancelled':
        return l10n.billingStatusCancelled;
      default:
        return status;
    }
  }

  static String _moduleLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'warehouse':
        return l10n.billingModuleWarehouse;
      case 'logistics':
        return l10n.billingModuleLogistics;
      case 'dispatcher':
        return l10n.billingModuleDispatcher;
      case 'accounting':
        return l10n.billingModuleAccounting;
      case 'reports':
        return l10n.billingModuleReports;
      default:
        return key;
    }
  }

  static IconData _moduleIcon(String key) {
    switch (key) {
      case 'warehouse':
        return Icons.warehouse_outlined;
      case 'logistics':
        return Icons.local_shipping_outlined;
      case 'dispatcher':
        return Icons.person_pin_outlined;
      case 'accounting':
        return Icons.receipt_long_outlined;
      case 'reports':
        return Icons.bar_chart_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// Строка информации (label: value).
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                Expanded(
                  child:
                      Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
    );
  }
}

/// Строка счётчика использования.
class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int limit;

  const _UsageRow({
    required this.icon,
    required this.label,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.billingLimit(limit),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                Text(
                  l10n.billingLimit(limit),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
    );
  }
}

/// Строка счёта (invoice).
class _InvoiceTile extends StatelessWidget {
  final BillingInvoice invoice;
  const _InvoiceTile({required this.invoice});

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final dateStr =
        invoice.issuedAt != null ? _dateFmt.format(invoice.issuedAt!) : '—';
    final statusColor = _invoiceStatusColor(invoice.status);

    return ListTile(
      leading: Icon(Icons.receipt_outlined, color: theme.colorScheme.outline),
      title: Text(
        invoice.description.isNotEmpty
            ? invoice.description
            : AppLocalizations.of(context)!.billingInvoiceDefault,
        maxLines: narrow ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dateStr),
          if (narrow) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _invoiceStatusLabel(
                        invoice.status, AppLocalizations.of(context)!),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: narrow
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _invoiceStatusLabel(
                        invoice.status, AppLocalizations.of(context)!),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
    );
  }

  static Color _invoiceStatusColor(BillingInvoiceStatus status) {
    switch (status) {
      case BillingInvoiceStatus.paid:
        return Colors.green;
      case BillingInvoiceStatus.pending:
        return Colors.orange;
      case BillingInvoiceStatus.overdue:
        return Colors.red;
      case BillingInvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  static String _invoiceStatusLabel(
      BillingInvoiceStatus status, AppLocalizations l10n) {
    switch (status) {
      case BillingInvoiceStatus.paid:
        return l10n.billingInvoicePaid;
      case BillingInvoiceStatus.pending:
        return l10n.billingInvoicePending;
      case BillingInvoiceStatus.overdue:
        return l10n.billingInvoiceOverdue;
      case BillingInvoiceStatus.cancelled:
        return l10n.billingInvoiceCancelled;
    }
  }
}
