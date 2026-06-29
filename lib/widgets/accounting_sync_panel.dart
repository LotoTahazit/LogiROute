import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/accounting_sync_service.dart';
import '../theme/app_theme.dart';

class AccountingSyncPanel extends StatefulWidget {
  const AccountingSyncPanel({super.key, required this.companyId});

  final String companyId;

  @override
  State<AccountingSyncPanel> createState() => _AccountingSyncPanelState();
}

class _AccountingSyncPanelState extends State<AccountingSyncPanel> {
  late final AccountingSyncService _service;
  final _retrying = <String>{};
  bool _batchRunning = false;

  @override
  void initState() {
    super.initState();
    _service = AccountingSyncService(companyId: widget.companyId);
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _batch(String mode) async {
    if (_batchRunning) return;
    setState(() => _batchRunning = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final r = await _service.batchSync(mode: mode, userId: _uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountingSyncBatchResult(
              r.processed,
              r.succeeded,
              r.failed,
              r.skipped,
            )),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _batchRunning = false);
    }
  }

  Future<void> _retry(String invoiceId) async {
    setState(() => _retrying.add(invoiceId));
    try {
      await _service.retry(invoiceId, userId: _uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.accountingSyncRetried),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _retrying.remove(invoiceId));
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'synced':
        return l10n.accountingSyncStatusSynced;
      case 'failed':
        return l10n.accountingSyncStatusFailed;
      case 'processing':
        return l10n.accountingSyncStatusProcessing;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'synced':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      default:
        return AppTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountingSyncTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _batchRunning ? null : () => _batch('failed'),
                  icon: _batchRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.accountingSyncRetryAllFailed),
                ),
                OutlinedButton.icon(
                  onPressed: _batchRunning ? null : () => _batch('unsynced'),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(l10n.accountingSyncBackfillUnsynced),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AccountingSyncEntry>>(
              stream: _service.watchLedger(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.accountingSyncNoEntries,
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final busy = _retrying.contains(e.invoiceId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${l10n.invoice} #${e.externalNumber ?? e.invoiceId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.provider} · ${_statusLabel(e.status, l10n)}',
                            style: TextStyle(
                              color: _statusColor(e.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (e.distributionNumber != null)
                            Text(
                              l10n.accountingSyncDistribution(e.distributionNumber!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (e.lastError != null && e.status == 'failed')
                            Text(
                              e.lastError!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (e.pdfUrl != null)
                            IconButton(
                              tooltip: 'PDF',
                              icon: const Icon(Icons.picture_as_pdf, size: 20),
                              onPressed: () => launchUrl(
                                Uri.parse(e.pdfUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                          if (e.status == 'failed')
                            IconButton(
                              tooltip: l10n.accountingSyncRetry,
                              onPressed: busy ? null : () => _retry(e.invoiceId),
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh, size: 20),
                            ),
                        ],
                      ),
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
