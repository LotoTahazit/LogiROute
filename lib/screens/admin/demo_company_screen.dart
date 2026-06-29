import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/company_selection_service.dart';
import '../../services/demo_company_service.dart';

/// Super admin: создание / сброс демо-компании Demo Foods Israel.
class DemoCompanyScreen extends StatefulWidget {
  const DemoCompanyScreen({super.key});

  @override
  State<DemoCompanyScreen> createState() => _DemoCompanyScreenState();
}

class _DemoCompanyScreenState extends State<DemoCompanyScreen> {
  final _service = DemoCompanyService();
  bool _busy = false;
  Map<String, dynamic>? _lastResult;

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _lastResult = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.demoCompanySuccess)),
      );
      final auth = context.read<AuthService>();
      final selection = context.read<CompanySelectionService>();
      await selection.loadCompanies();
      selection.selectCompany(DemoCompanyService.companyId);
      auth.setVirtualCompanyId(DemoCompanyService.companyId);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() => _busy = true);
    Map<String, dynamic> preview;
    try {
      preview = await _service.previewResetDemoCompany();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.message}')),
        );
      }
      if (mounted) setState(() => _busy = false);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    final deletable = preview['deletableTotal'] ?? 0;
    final blocked = preview['blockedTotal'] ?? 0;
    final safe = preview['safeToPurge'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.demoCompanyResetPreviewTitle),
        content: SingleChildScrollView(
          child: Text(
            safe
                ? l10n.demoCompanyResetPreviewBody(deletable, blocked)
                : l10n.demoCompanyResetBlocked(blocked),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          if (safe)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.demoCompanyResetAction),
            ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _service.resetDemoCompany(confirm: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();
    if (auth.userModel?.isSuperAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.demoCompanyTitle)),
        body: Center(child: Text(l10n.demoCompanySuperAdminOnly)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.demoCompanyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.demoCompanyDesc),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(_service.createDemoCompany),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.storefront),
            label: Text(l10n.demoCompanyCreate),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _confirmReset,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.demoCompanyResetAction),
          ),
          const SizedBox(height: 24),
          Text(l10n.demoCompanyCredentialsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _credTile(l10n.demoCompanyCredOwner, DemoCompanyService.demoEmail('demo.owner')),
          _credTile(l10n.demoCompanyCredDispatcher, DemoCompanyService.demoEmail('demo.dispatcher')),
          _credTile(l10n.demoCompanyCredDriver, DemoCompanyService.demoEmail('demo.driver01')),
          Text(l10n.demoCompanyPasswordHint, style: Theme.of(context).textTheme.bodySmall),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.demoCompanyLastSeed(_lastResult!['clients'] ?? 0, _lastResult!['products'] ?? 0),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _credTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: SelectableText(value, style: const TextStyle(fontFamily: 'monospace')),
    );
  }
}
