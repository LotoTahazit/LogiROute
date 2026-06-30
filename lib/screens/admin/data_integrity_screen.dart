import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/integrity_issue.dart';
import '../../services/auth_service.dart';
import '../../services/data_integrity_service.dart';
import '../../theme/app_theme.dart';

/// Data Integrity Checker — экран запуска проверки и работы с проблемами.
/// Доступ: super_admin / owner / admin.
class DataIntegrityScreen extends StatefulWidget {
  const DataIntegrityScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<DataIntegrityScreen> createState() => _DataIntegrityScreenState();
}

class _DataIntegrityScreenState extends State<DataIntegrityScreen> {
  late final DataIntegrityService _service =
      DataIntegrityService(companyId: widget.companyId);

  IntegrityIssueStatus _statusFilter = IntegrityIssueStatus.open;
  IntegritySeverity? _severityFilter;
  String? _entityFilter;
  bool _running = false;

  Future<void> _runCheck() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _running = true);
    try {
      final res = await _service.runCheck();
      if (mounted) {
        final found = res['foundIssues'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataIntegrityCheckDone(found)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _exportCsv(List<IntegrityIssue> issues) async {
    final l10n = AppLocalizations.of(context)!;
    final header =
        'severity,status,entityType,entityId,issueCode,title,description,detectedAt,lastSeenAt';
    final rows = issues.map((i) => i.toCsvRow().map(_csv).join(',')).join('\n');
    await Clipboard.setData(ClipboardData(text: '$header\n$rows'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dataIntegrityCsvCopied),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _csv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  Color _severityColor(IntegritySeverity s) {
    switch (s) {
      case IntegritySeverity.critical:
        return AppTheme.danger;
      case IntegritySeverity.high:
        return AppTheme.warning;
      case IntegritySeverity.medium:
        return AppTheme.warning;
      case IntegritySeverity.low:
        return AppTheme.muted;
      case IntegritySeverity.unknown:
        return AppTheme.muted;
    }
  }

  String _severityLabel(AppLocalizations l10n, IntegritySeverity s) {
    switch (s) {
      case IntegritySeverity.critical:
        return l10n.severityCritical;
      case IntegritySeverity.high:
        return l10n.severityHigh;
      case IntegritySeverity.medium:
        return l10n.severityMedium;
      case IntegritySeverity.low:
        return l10n.severityLow;
      case IntegritySeverity.unknown:
        return '—';
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataIntegrityTitle),
        actions: [
          IconButton(
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            tooltip: l10n.dataIntegrityRunCheck,
            onPressed: _running ? null : _runCheck,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLastCheckCard(l10n),
          _buildFilters(l10n),
          const Divider(height: 1),
          Expanded(child: _buildIssueList(l10n)),
        ],
      ),
    );
  }

  Widget _buildLastCheckCard(AppLocalizations l10n) {
    return StreamBuilder<IntegrityCheck?>(
      stream: _service.watchLastCheck(),
      builder: (context, snap) {
        final check = snap.data;
        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        check == null
                            ? l10n.dataIntegrityNever
                            : '${l10n.dataIntegrityLastCheck}: ${_fmt(check.completedAt ?? check.startedAt)} • ${check.trigger}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (check != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in IntegritySeverity.values)
                        if (s != IntegritySeverity.unknown)
                          _severityChip(l10n, s, check.severityCount(s)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _severityChip(AppLocalizations l10n, IntegritySeverity s, int count) {
    final color = _severityColor(s);
    return Chip(
      label: Text('${_severityLabel(l10n, s)}: $count',
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final st in [
                IntegrityIssueStatus.open,
                IntegrityIssueStatus.ignored,
                IntegrityIssueStatus.resolved,
              ])
                ChoiceChip(
                  label: Text(_statusLabel(l10n, st)),
                  selected: _statusFilter == st,
                  onSelected: (_) => setState(() => _statusFilter = st),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.dataIntegrityFilterAll),
                selected: _severityFilter == null,
                onSelected: (_) => setState(() => _severityFilter = null),
              ),
              for (final s in IntegritySeverity.values)
                if (s != IntegritySeverity.unknown)
                  ChoiceChip(
                    label: Text(_severityLabel(l10n, s)),
                    selected: _severityFilter == s,
                    selectedColor: _severityColor(s).withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _severityFilter = s),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, IntegrityIssueStatus s) {
    switch (s) {
      case IntegrityIssueStatus.open:
        return l10n.dataIntegrityStatusOpen;
      case IntegrityIssueStatus.ignored:
        return l10n.dataIntegrityStatusIgnored;
      case IntegrityIssueStatus.resolved:
        return l10n.dataIntegrityStatusResolved;
      case IntegrityIssueStatus.unknown:
        return '—';
    }
  }

  Widget _buildIssueList(AppLocalizations l10n) {
    return StreamBuilder<List<IntegrityIssue>>(
      stream: _service.watchIssues(status: _statusFilter),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var issues = snap.data!;
        final entityTypes = issues.map((i) => i.entityType).toSet().toList()
          ..sort();
        if (_severityFilter != null) {
          issues = issues.where((i) => i.severity == _severityFilter).toList();
        }
        if (_entityFilter != null) {
          issues = issues.where((i) => i.entityType == _entityFilter).toList();
        }
        if (issues.isEmpty) {
          return Center(
            child: Text(l10n.dataIntegrityNoIssues,
                style: const TextStyle(color: Colors.green)),
          );
        }
        return Column(
          children: [
            if (entityTypes.length > 1)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: ChoiceChip(
                        label: Text(l10n.dataIntegrityFilterAll),
                        selected: _entityFilter == null,
                        onSelected: (_) => setState(() => _entityFilter = null),
                      ),
                    ),
                    for (final e in entityTypes)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 6),
                        child: ChoiceChip(
                          label: Text(e),
                          selected: _entityFilter == e,
                          onSelected: (_) => setState(() => _entityFilter = e),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(l10n.dataIntegrityIssuesCount(issues.length)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _exportCsv(issues),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.dataIntegrityExportCsv),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: issues.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _issueTile(l10n, issues[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _issueTile(AppLocalizations l10n, IntegrityIssue issue) {
    final color = _severityColor(issue.severity);
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 14),
      title: Text(issue.title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        '${_severityLabel(l10n, issue.severity)} • ${issue.entityType} • ${issue.entityId}\n'
        '${issue.description}',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
      onTap: () => _showDetails(l10n, issue),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _handleIssueAction(v, issue),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'open', child: Text(l10n.dataIntegrityOpenEntity)),
          if (issue.status != IntegrityIssueStatus.ignored)
            PopupMenuItem(
                value: 'ignore', child: Text(l10n.dataIntegrityMarkIgnored)),
          if (issue.status != IntegrityIssueStatus.resolved)
            PopupMenuItem(
                value: 'resolve', child: Text(l10n.dataIntegrityMarkResolved)),
          if (issue.status != IntegrityIssueStatus.open)
            PopupMenuItem(
                value: 'reopen', child: Text(l10n.dataIntegrityReopen)),
        ],
      ),
    );
  }

  Future<void> _handleIssueAction(String action, IntegrityIssue issue) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    try {
      switch (action) {
        case 'open':
          if (mounted) _showDetails(AppLocalizations.of(context)!, issue);
        case 'ignore':
          await _service.markIgnored(issue, uid);
        case 'resolve':
          await _service.markResolved(issue, uid);
        case 'reopen':
          await _service.reopen(issue);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDetails(AppLocalizations l10n, IntegrityIssue issue) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(issue.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(issue.description),
              const SizedBox(height: 12),
              _detailRow('severity', _severityLabel(l10n, issue.severity)),
              _detailRow('entityType', issue.entityType),
              _detailRow('entityId', issue.entityId),
              _detailRow('issueCode', issue.issueCode),
              _detailRow('detectedAt', _fmt(issue.detectedAt)),
              _detailRow('lastSeenAt', _fmt(issue.lastSeenAt)),
              if (issue.metadata.isNotEmpty)
                _detailRow('metadata', issue.metadata.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: issue.entityId));
              Navigator.pop(ctx);
            },
            child: Text(l10n.dataIntegrityCopyId),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Read-only блок для Support Console: последняя проверка + critical/high.
class DataIntegrityReadonlyBlock extends StatelessWidget {
  const DataIntegrityReadonlyBlock({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = DataIntegrityService(companyId: companyId);
    return StreamBuilder<IntegrityCheck?>(
      stream: service.watchLastCheck(),
      builder: (context, snap) {
        final check = snap.data;
        final critical = check?.severityCount(IntegritySeverity.critical) ?? 0;
        final high = check?.severityCount(IntegritySeverity.high) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(check == null
                ? l10n.dataIntegrityNever
                : '${l10n.dataIntegrityLastCheck}: '
                    '${check.completedAt != null ? check.completedAt!.toLocal().toString().substring(0, 16) : '—'}'),
            const SizedBox(height: 4),
            Text('${l10n.severityCritical}: $critical • ${l10n.severityHigh}: $high',
                style: TextStyle(
                  color: critical > 0
                      ? Colors.red
                      : (high > 0 ? Colors.orange : Colors.green),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DataIntegrityScreen(companyId: companyId),
                  ),
                ),
                icon: const Icon(Icons.rule, size: 18),
                label: Text(l10n.dataIntegrityOpen),
              ),
            ),
          ],
        );
      },
    );
  }
}
