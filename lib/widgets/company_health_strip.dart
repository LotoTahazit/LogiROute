import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/company_settings.dart';
import '../services/company_health_service.dart';

/// Компактная полоска операционного здоровья компании.
class CompanyHealthStrip extends StatefulWidget {
  const CompanyHealthStrip({
    super.key,
    required this.companyId,
    this.companySettings,
    this.refreshToken = 0,
  });

  final String companyId;
  final CompanySettings? companySettings;
  final int refreshToken;

  @override
  State<CompanyHealthStrip> createState() => _CompanyHealthStripState();
}

class _CompanyHealthStripState extends State<CompanyHealthStrip> {
  CompanyHealthSnapshot? _snap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CompanyHealthStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await CompanyHealthService(
        companyId: widget.companyId,
        companySettings: widget.companySettings,
      ).fetch();
      if (mounted) setState(() => _snap = snap);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _accountingLabel(AppLocalizations l10n, HealthCheckStatus s) {
    return switch (s) {
      HealthCheckStatus.fail => l10n.healthStripAccountingSyncFailed,
      HealthCheckStatus.warn => l10n.healthStripWarn,
      HealthCheckStatus.ok => l10n.healthStripOk,
    };
  }

  Color? _accountingColor(HealthCheckStatus s) => switch (s) {
        HealthCheckStatus.fail => Colors.red,
        HealthCheckStatus.warn => Colors.orange,
        HealthCheckStatus.ok => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading && _snap == null) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    final s = _snap;
    if (s == null) return const SizedBox.shrink();

    final cells = <Widget>[
      _Cell(label: l10n.healthStripCompany, value: s.companyName, theme: theme, boldValue: true),
      _StatusCell(label: l10n.healthStripBilling, status: s.billing, l10n: l10n, theme: theme),
      _StatusCell(label: l10n.healthStripGps, status: s.gps, l10n: l10n, theme: theme),
      _StatusCell(label: l10n.healthStripFirestore, status: s.firestore, l10n: l10n, theme: theme),
      _Cell(label: l10n.healthStripDrivers, value: '${s.driverCount}', theme: theme),
      _Cell(
        label: l10n.healthStripRoutes,
        value: l10n.healthStripRoutesActive(s.activeRoutes),
        theme: theme,
      ),
      _StatusCell(label: l10n.healthStripFcm, status: s.fcm, l10n: l10n, theme: theme),
      _Cell(
        label: l10n.healthStripAccounting,
        value: _accountingLabel(l10n, s.accounting),
        theme: theme,
        valueColor: _accountingColor(s.accounting),
      ),
    ];

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: theme.dividerColor,
                    ),
                  cells[i],
                ],
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: l10n.onboardingCenterRefresh,
                  visualDensity: VisualDensity.compact,
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
          ),
          if (s.lastError != null && s.lastError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.healthStripLastError}: ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.lastError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
    this.boldValue = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;
  final bool boldValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        if (value.isNotEmpty)
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: boldValue ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
      ],
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.label,
    required this.status,
    required this.l10n,
    required this.theme,
  });

  final String label;
  final HealthCheckStatus status;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      HealthCheckStatus.ok => (l10n.healthStripOk, Colors.green),
      HealthCheckStatus.warn => (l10n.healthStripWarn, Colors.orange),
      HealthCheckStatus.fail => (l10n.healthStripFail, Colors.red),
    };
    return _Cell(label: label, value: text, theme: theme, valueColor: color);
  }
}
