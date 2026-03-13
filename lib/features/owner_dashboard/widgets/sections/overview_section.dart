import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../models/audit_event.dart';
import '../../models/daily_metrics.dart';
import '../../repositories/audit_repository.dart';
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
  late final MetricsService _metricsService;
  late final AuditRepository _auditRepository;

  @override
  void initState() {
    super.initState();
    _metricsService = MetricsService(companyId: widget.companyId);
    _auditRepository = AuditRepository(companyId: widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DailyMetrics>(
      stream: _metricsService.watchTodayMetrics(),
      builder: (context, metricsSnapshot) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

  Widget _buildKpiSection(
    BuildContext context,
    AsyncSnapshot<DailyMetrics> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = snapshot.data ?? DailyMetrics(date: '');
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _KpiCard(
          icon: Icons.local_shipping_outlined,
          label: l10n.deliveriesToday,
          value: metrics.deliveriesToday.toString(),
          moduleKey: 'logistics',
          modules: widget.companySettings.modules,
        ),
        _KpiCard(
          icon: Icons.receipt_long_outlined,
          label: l10n.invoicesThisMonth,
          value: metrics.invoicesThisMonth.toString(),
          moduleKey: 'accounting',
          modules: widget.companySettings.modules,
        ),
        _KpiCard(
          icon: Icons.warehouse_outlined,
          label: l10n.warehouseMovements,
          value: metrics.warehouseMovements.toString(),
          moduleKey: 'warehouse',
          modules: widget.companySettings.modules,
        ),
        _KpiCard(
          icon: Icons.person_pin_outlined,
          label: l10n.activeDriversKpi,
          value: metrics.activeDrivers.toString(),
          moduleKey: 'dispatcher',
          modules: widget.companySettings.modules,
        ),
      ],
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
    final billingStatus = widget.companySettings.billingStatus;
    if (billingStatus == 'grace' || billingStatus == 'suspended') {
      alerts.add(_AlertTile(
        icon: Icons.payment,
        message: billingStatus == 'suspended'
            ? l10n.accountSuspendedPayment
            : l10n.paymentOverdueGrace,
        level: billingStatus == 'suspended' ? 'critical' : 'warning',
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
    alerts.add(_AlertTile(
      icon: Icons.warning_amber_rounded,
      message: '$label: $usage / $limit ($pct%)',
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
          future: _auditRepository.getAuditLog(limit: 20),
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

            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _EventTile(event: events[index]),
              ),
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

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.moduleKey,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    // Hide card if module is disabled
    if (moduleKey != null && !modules[moduleKey!]) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
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
              Text(label, style: theme.textTheme.bodySmall),
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
  const _EventTile({required this.event});

  static final _timeFmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        event.createdAt != null ? _timeFmt.format(event.createdAt!) : '—';

    return ListTile(
      dense: true,
      leading: _moduleIcon(event.moduleKey, theme),
      title: Text(event.type),
      subtitle: Text(
        '${event.entity.collection}/${event.entity.docId}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr, style: theme.textTheme.bodySmall),
          Text(
              event.createdBy.length > 8
                  ? '${event.createdBy.substring(0, 8)}…'
                  : event.createdBy,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
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
