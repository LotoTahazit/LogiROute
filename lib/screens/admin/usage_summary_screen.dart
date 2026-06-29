import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/usage_event.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/usage_analytics_service.dart';
import '../../theme/app_theme.dart';

/// Usage Summary — pilot analytics для owner/admin/super_admin.
class UsageSummaryScreen extends StatefulWidget {
  const UsageSummaryScreen({super.key, this.companyId});

  final String? companyId;

  @override
  State<UsageSummaryScreen> createState() => _UsageSummaryScreenState();
}

class _UsageSummaryScreenState extends State<UsageSummaryScreen> {
  final _service = UsageAnalyticsService();
  int _days = 7;
  UsageSummary? _summary;
  bool _loading = false;
  static final _timeFmt = DateFormat('dd/MM/yy HH:mm');

  String? _companyId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _companyId = widget.companyId ??
        CompanyContext.of(context).effectiveCompanyId;
    _load();
  }

  bool get _canRead {
    final auth = context.read<AuthService>();
    final role = auth.userModel?.role ?? '';
    return auth.userModel?.isSuperAdmin == true ||
        role == 'owner' ||
        role == 'admin';
  }

  Future<void> _load() async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final summary = await _service.loadSummary(companyId: companyId, days: _days);
      if (mounted) setState(() => _summary = summary);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_canRead) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.usageSummaryTitle)),
        body: Center(child: Text(l10n.usageSummaryOwnerOnly)),
      );
    }

    final summary = _summary;
    final rows = UsageEventName.allValues
        .map((e) => MapEntry(e.value, summary?.countsByEvent[e.value] ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usageSummaryTitle),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(l10n.usageSummaryDays7)),
                ButtonSegment(value: 30, label: Text(l10n.usageSummaryDays30)),
              ],
              selected: {_days},
              onSelectionChanged: (s) {
                setState(() => _days = s.first);
                _load();
              },
            ),
          ),
          if (_companyId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${l10n.customerHealthCompanyId}: $_companyId',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _statChip(
                  l10n.usageSummaryActiveUsers,
                  '${summary?.activeUsers ?? '—'}',
                ),
                _statChip(
                  l10n.usageSummaryTotalEvents,
                  '${summary?.totalEvents ?? '—'}',
                ),
                _statChip(
                  l10n.usageSummaryLastEvent,
                  summary?.lastEventAt != null
                      ? _timeFmt.format(summary!.lastEventAt!)
                      : '—',
                ),
              ],
            ),
          ),
          if (summary != null && summary.sampleSize >= 200)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.usageSummarySampleNote(summary.sampleSize),
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ),
          Expanded(
            child: _loading && summary == null
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(child: Text(l10n.usageSummaryNoEvents))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = rows[i];
                          return ListTile(
                            dense: true,
                            title: Text(e.key,
                                style: const TextStyle(fontFamily: 'monospace')),
                            trailing: Text(
                              '${e.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
