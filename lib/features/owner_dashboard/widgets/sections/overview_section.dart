import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/billing_state.dart';
import '../../../../models/company_settings.dart';
import '../../../../core/navigation/document_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/company_health_strip.dart';
import '../../../../screens/admin/usage_summary_screen.dart';
import '../../models/role_hierarchy.dart';
import '../../utils/audit_event_labels.dart';
import '../../models/audit_event.dart';
import '../../models/daily_metrics.dart';
import '../../repositories/audit_repository.dart';
import '../../services/audit_event_enricher.dart';
import '../../../../models/plan_limit_policy.dart';
import '../../services/entitlements_service.dart';
import '../../services/metrics_service.dart';

/// Секция «Обзор» Owner Dashboard.
///
/// Отображает:
/// - KPI-карточки: доставки сегодня, счета за месяц, складские движения, активные водители
/// - Алерты: приближение к лимитам (80% жёлтый, 100% красный), ошибки печати, просроченные платежи
/// - Лента «Последние события» — 20 записей из cross-module audit log
///
/// Данные загружаются из [MetricsService] (StreamBuilder) и [AuditRepository] (FutureBuilder).
///
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
class OverviewSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const OverviewSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  late MetricsService _metricsService;
  late AuditRepository _auditRepository;
  late Future<List<CrossModuleAuditEvent>> _eventsFuture;
  bool _recalculatingMetrics = false;

  @override
  void initState() {
    super.initState();
    _bindCompany(widget.companyId);
  }

  @override
  void didUpdateWidget(OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _bindCompany(widget.companyId);
    }
  }

  void _bindCompany(String companyId) {
    _metricsService = MetricsService(companyId: companyId);
    _auditRepository = AuditRepository(companyId: companyId);
    _eventsFuture = _auditRepository.getAuditLog(limit: 20);
  }

  bool _canRecalculateMetrics(BuildContext context) {
    final auth = context.read<AuthService>();
    final role = effectiveAppRole(
      actualRole: auth.userModel?.role,
      viewAsRole: auth.viewAsRole,
    );
    return role == AppRole.superAdmin ||
        role == AppRole.admin ||
        role == AppRole.owner;
  }

  Future<void> _recalculateMetrics(BuildContext context) async {
    if (_recalculatingMetrics) return;
    setState(() => _recalculatingMetrics = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _metricsService.recalculateDailyMetrics();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.metricsRecalculateDone)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.metricsRecalculateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _recalculatingMetrics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 500;
    return StreamBuilder<DailyMetrics>(
      stream: _metricsService.watchTodayMetrics(),
      builder: (context, metricsSnapshot) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_canRecalculateMetrics(context))
                CompanyHealthStrip(
                  companyId: widget.companyId,
                  companySettings: widget.companySettings,
                ),
              if (_canRecalculateMetrics(context))
                const SizedBox(height: 16),
              if (_canRecalculateMetrics(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UsageSummaryScreen(
                          companyId: widget.companyId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.insights, size: 18),
                    label: Text(AppLocalizations.of(context)!.usageSummaryTitle),
                  ),
                ),
              if (_canRecalculateMetrics(context))
                const SizedBox(height: 8),
              _buildMetricsBanner(context, metricsSnapshot),
              // KPI Cards
              _buildKpiSection(context, metricsSnapshot),
              const SizedBox(height: 24),
              // Alerts
              _buildAlertsSection(context, metricsSnapshot),
              const SizedBox(height: 24),
              // Latest events feed
              _buildEventsFeed(context),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // KPI Cards — Requirement 4.1, 4.6
  // ---------------------------------------------------------------------------

  Widget _buildMetricsBanner(
    BuildContext context,
    AsyncSnapshot<DailyMetrics> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    final metrics = snapshot.data;
    if (metrics == null || metrics.isCalculated) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canRecalc = _canRecalculateMetrics(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.insights_outlined,
                  size: 20, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.metricsNotCalculatedYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (canRecalc)
                TextButton.icon(
                  onPressed: _recalculatingMetrics
                      ? null
                      : () => _recalculateMetrics(context),
                  icon: _recalculatingMetrics
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.recalculateMetrics),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(
    BuildContext context,
    AsyncSnapshot<DailyMetrics> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = snapshot.data ?? DailyMetrics(date: '');
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    final cards = [
      _KpiCard(
        icon: Icons.local_shipping_outlined,
        label: l10n.deliveriesToday,
        value: metrics.deliveriesToday.toString(),
        moduleKey: 'logistics',
        modules: widget.companySettings.modules,
        fullWidth: narrow,
      ),
      _KpiCard(
        icon: Icons.receipt_long_outlined,
        label: l10n.invoicesThisMonth,
        value: metrics.invoicesThisMonth.toString(),
        moduleKey: 'accounting',
        modules: widget.companySettings.modules,
        fullWidth: narrow,
      ),
      _KpiCard(
        icon: Icons.warehouse_outlined,
        label: l10n.warehouseMovements,
        value: metrics.warehouseMovements.toString(),
        moduleKey: 'warehouse',
        modules: widget.companySettings.modules,
        fullWidth: narrow,
      ),
      _KpiCard(
        icon: Icons.person_pin_outlined,
        label: l10n.activeDriversKpi,
        value: metrics.activeDrivers.toString(),
        moduleKey: 'dispatcher',
        modules: widget.companySettings.modules,
        fullWidth: narrow,
      ),
    ];
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards,
    );
  }

  // ---------------------------------------------------------------------------
  // Alerts — Requirements 4.2, 4.3, 4.4
  // ---------------------------------------------------------------------------

  Widget _buildAlertsSection(
    BuildContext context,
    AsyncSnapshot<DailyMetrics> snapshot,
  ) {
    final alerts = <Widget>[];
    final limits = widget.companySettings.limits;
    final metrics = snapshot.data;
    final l10n = AppLocalizations.of(context)!;

    // Plan limit alerts (Req 4.3, 4.4)
    if (metrics != null) {
      _addLimitAlert(
        alerts,
        label: l10n.docsThisMonth,
        usage: metrics.invoicesThisMonth,
        limit: limits.maxDocsPerMonth,
      );
    }

    // Print errors alert (Req 4.2)
    if (metrics != null && metrics.printErrorsToday > 0) {
      alerts.add(_AlertTile(
        icon: Icons.print_disabled,
        message: l10n.printErrorsToday(metrics.printErrorsToday),
        level: metrics.printErrorsToday >= 5 ? 'critical' : 'warning',
      ));
    }

    // Overdue payments alert (Req 4.2)
    final billingEval = BillingState.evaluateFromSettings(widget.companySettings);
    if (billingEval.displayPhase == BillingDisplayPhase.grace) {
      alerts.add(_AlertTile(
        icon: Icons.payment,
        message: l10n.paymentOverdueGrace,
        level: 'warning',
      ));
    } else if (billingEval.storedStatus == 'suspended') {
      alerts.add(_AlertTile(
        icon: Icons.payment,
        message: l10n.accountSuspendedPayment,
        level: 'critical',
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)?.notifications ?? 'Notifications',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...alerts,
      ],
    );
  }

  void _addLimitAlert(
    List<Widget> alerts, {
    required String label,
    required int usage,
    required int limit,
  }) {
    final level = EntitlementsService.getAlertLevel(usage, limit);
    if (level == null) return;
    final pct = limit > 0 ? (usage * 100 ~/ limit) : 0;
    final l10n = AppLocalizations.of(context)!;
    final softNote = level == 'critical' &&
            PlanLimitPolicy.enforcement(PlanLimitKey.maxDocsPerMonth) ==
                LimitEnforcement.soft
        ? ' — ${l10n.limitEnforcementSoft}'
        : '';
    alerts.add(_AlertTile(
      icon: Icons.warning_amber_rounded,
      message: '$label: $usage / $limit ($pct%)$softNote',
      level: level,
    ));
  }

  // ---------------------------------------------------------------------------
  // Latest Events Feed — Requirement 4.5
  // ---------------------------------------------------------------------------

  Widget _buildEventsFeed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recentEventsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<CrossModuleAuditEvent>>(
          future: _eventsFuture,
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
                    l10n.errorLoadingEvents,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noRecentEvents)),
                ),
              );
            }

            return FutureBuilder<Map<String, AuditEventMeta>>(
              future: AuditEventEnricher.enrich(widget.companyId, events),
              builder: (context, metaSnap) {
                final meta = metaSnap.data ?? {};
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _EventTile(
                      event: events[index],
                      meta: meta[events[index].entity.docId],
                      companyId: widget.companyId,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// KPI-карточка (Material 3 Card).
///
/// Скрывается если модуль отключён (Req 12.2).
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? moduleKey;
  final ModuleEntitlements modules;
  final bool fullWidth;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.moduleKey,
    required this.modules,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (moduleKey != null && !modules[moduleKey!]) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return SizedBox(
      width: fullWidth ? double.infinity : 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плитка алерта с цветовой индикацией.
///
/// `level`: `'critical'` → красный, `'warning'` → жёлтый/оранжевый.
class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String message;
  final String level;

  const _AlertTile({
    required this.icon,
    required this.message,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = level == 'critical';
    final bgColor = isCritical ? Colors.red.shade50 : Colors.orange.shade50;
    final fgColor = isCritical ? Colors.red.shade700 : Colors.orange.shade800;

    return Card(
      color: bgColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: fgColor),
        title: Text(message, style: TextStyle(color: fgColor)),
      ),
    );
  }
}

/// Строка ленты событий аудита.
class _EventTile extends StatelessWidget {
  final CrossModuleAuditEvent event;
  final AuditEventMeta? meta;
  final String companyId;
  const _EventTile({
    required this.event,
    this.meta,
    required this.companyId,
  });

  static final _timeFmt = DateFormat('dd/MM HH:mm');

  bool get _canOpen =>
      event.entity.docId.isNotEmpty &&
      DocumentRouter.isSupported(event.entity.collection);

  void _openDocument(BuildContext context) {
    if (!_canOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noDocumentId)),
      );
      return;
    }
    DocumentRouter.open(
      context,
      companyId: companyId,
      collection: event.entity.collection,
      docId: event.entity.docId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timeStr =
        event.createdAt != null ? _timeFmt.format(event.createdAt!) : '—';

    return InkWell(
      onTap: () => _openDocument(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _moduleIcon(event.moduleKey, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AuditEventLabels.headline(event, l10n, meta: meta),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AuditEventLabels.actorLine(event.createdBy, l10n),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_canOpen) ...[
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => DocumentRouter.openInNewTab(
                  context,
                  companyId: companyId,
                  collection: event.entity.collection,
                  docId: event.entity.docId,
                ),
              ),
              Icon(Icons.chevron_left,
                  size: 20, color: theme.colorScheme.outline),
            ],
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleIcon(String moduleKey, ThemeData theme) {
    final IconData iconData;
    switch (moduleKey) {
      case 'logistics':
        iconData = Icons.local_shipping_outlined;
      case 'warehouse':
        iconData = Icons.warehouse_outlined;
      case 'accounting':
        iconData = Icons.receipt_long_outlined;
      case 'dispatcher':
        iconData = Icons.person_pin_outlined;
      default:
        iconData = Icons.info_outline;
    }
    return Icon(iconData, size: 20, color: theme.colorScheme.outline);
  }
}
