import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_system_error.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/platform_error_service.dart';
import 'customer_health_dashboard_screen.dart';
import 'support_console_screen.dart';

class PlatformErrorDetailScreen extends StatefulWidget {
  final PlatformSystemError error;

  const PlatformErrorDetailScreen({super.key, required this.error});

  @override
  State<PlatformErrorDetailScreen> createState() =>
      _PlatformErrorDetailScreenState();
}

class _PlatformErrorDetailScreenState extends State<PlatformErrorDetailScreen> {
  final _service = PlatformErrorService();
  String? _stack;
  bool _loadingStack = true;

  PlatformSystemError get e => widget.error;

  @override
  void initState() {
    super.initState();
    _loadStack();
  }

  Future<void> _loadStack() async {
    final s = await _service.loadStackTrace(e.errorId);
    if (mounted) setState(() {
      _stack = s;
      _loadingStack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final cids = {
      if (e.correlationId != null) e.correlationId!,
      ...e.recentCorrelationIds,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.platformErrorDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (e.incidentSuggested)
            MaterialBanner(
              content: Text(l10n.platformErrorIncidentSuggested),
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              actions: [const SizedBox.shrink()],
            ),
          Text(e.errorMessage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${l10n.platformErrorColSeverity}: ${severityToString(e.severity)}'),
          Text('${l10n.platformErrorColCount}: ${e.occurrences}'),
          Text('${l10n.companyDetails}: ${e.companyName ?? e.companyId ?? '—'}'),
          Text('${l10n.platformErrorColOperation}: ${e.operation ?? '—'}'),
          const SizedBox(height: 12),
          Text(l10n.platformErrorCorrelationIds, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...cids.map((c) => SelectableText(c)),
          const SizedBox(height: 12),
          Text(l10n.platformErrorStackTrace, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_loadingStack)
            const LinearProgressIndicator()
          else
            SelectableText(_stack ?? l10n.platformErrorNoStack),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.companyId != null)
                OutlinedButton.icon(
                  onPressed: () {
                    CompanyContext.activateCompany(context, e.companyId!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportConsoleScreen(
                          initialCompanyId: e.companyId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: Text(l10n.supportConsoleTitle),
                ),
              if (e.companyId != null)
                OutlinedButton.icon(
                  onPressed: () {
                    CompanyContext.activateCompany(context, e.companyId!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerHealthDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.monitor_heart),
                  label: Text(l10n.customerHealthDashboardTitle),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: e.errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.platformErrorCopied)),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.platformErrorCopy),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: jsonEncode(e.toJson())),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.platformErrorCopied)),
                  );
                },
                icon: const Icon(Icons.data_object),
                label: Text(l10n.platformErrorCopyJson),
              ),
              if (!e.resolved)
                FilledButton.icon(
                  onPressed: () async {
                    final uid = auth.currentUser?.uid ?? '';
                    await _service.markResolved(errorId: e.errorId, uid: uid);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.platformErrorMarkResolved),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    await _service.reopen(e.errorId);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.platformErrorReopen),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
