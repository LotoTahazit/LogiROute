import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/data_retention_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';

/// Data retention policy screen — run checks, view history, compliance status.
/// [infoOnly] — только информационные карточки (диспетчер).
/// [podOnly] — только PoD (водитель).
class DataRetentionScreen extends StatefulWidget {
  const DataRetentionScreen({super.key, this.infoOnly = false, this.podOnly = false});

  final bool infoOnly;
  final bool podOnly;

  bool get _readOnly => infoOnly || podOnly;

  @override
  State<DataRetentionScreen> createState() => _DataRetentionScreenState();
}

class _DataRetentionScreenState extends State<DataRetentionScreen> {
  late DataRetentionService _service;
  bool _isLoading = false;
  bool _isRunning = false;
  RetentionCheckResult? _lastResult;
  List<Map<String, dynamic>> _history = [];
  String? _companyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget._readOnly) return;
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId == _companyId) return;
    _companyId = companyId;
    _service = DataRetentionService(companyId: companyId);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _service.getCheckHistory();
      setState(() => _history = history);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runCheck() async {
    final auth = context.read<AuthService>();
    setState(() => _isRunning = true);
    try {
      final result = await _service.runRetentionCheck(
        auth.userModel?.name ?? auth.currentUser?.uid ?? '',
      );
      setState(() => _lastResult = result);
      _loadHistory();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showSuccess(context, l10n.eventRetentionChecked);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.podOnly ? l10n.podTitle : l10n.dataRetention),
          actions: [
            if (!widget._readOnly)
              IconButton(
                onPressed: _isRunning ? null : _runCheck,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow),
                tooltip: l10n.runCheck,
              ),
          ],
        ),
        body: !widget._readOnly && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.podOnly) ...[
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: narrow ? 260 : 520),
                                child: Text(
                                  l10n.retentionPolicyInfo,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                color: Colors.orange.shade800),
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: narrow ? 260 : 520),
                              child: Text(
                                l10n.podRetentionInfo,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget._readOnly) ...[
                      const SizedBox(height: 16),
                      if (_lastResult != null) ...[
                      Text(l10n.lastCheckResult,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        color: _lastResult!.isCompliant
                            ? Colors.green.shade50
                            : Colors.red.shade50,
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
                                  Icon(
                                    _lastResult!.isCompliant
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _lastResult!.isCompliant
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth: narrow ? 250 : 520),
                                    child: Text(_lastResult!.summary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(l10n.retentionDocumentsCount(
                                  _lastResult!.totalDocuments)),
                              if (_lastResult!.oldestDocumentDate != null)
                                Text(l10n.oldestDocumentDate(_lastResult!
                                    .oldestDocumentDate
                                    .toString()
                                    .substring(0, 10))),
                              Text(l10n.retentionCutoffDate(_lastResult!
                                  .retentionCutoffDate
                                  .toString()
                                  .substring(0, 10))),
                              if (_lastResult!.hasSequentialGaps)
                                Text(
                                  l10n.retentionGapsCount(
                                      _lastResult!.totalDocuments,
                                      _lastResult!.expectedCount),
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(l10n.retentionHistory,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(l10n.noPreviousChecks),
                        ),
                      )
                    else
                      ..._history.map((h) {
                        final compliant = h['isCompliant'] == true;
                        final ts = h['checkedAt'] as Timestamp?;
                        final entry = l10n.retentionHistoryEntry(
                          h['checkedBy'] as String? ?? '',
                          h['totalDocuments'] as int? ?? 0,
                        );
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              compliant ? Icons.check_circle : Icons.error,
                              color: compliant ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              compliant ? l10n.compliant : l10n.issuesFound,
                            ),
                            subtitle: Text(
                              '$entry${ts != null ? ' • ${ts.toDate().toString().substring(0, 16)}' : ''}',
                            ),
                            trailing: h['hasSequentialGaps'] == true
                                ? Chip(
                                    label: Text(l10n.gapsLabel,
                                        style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.orange,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
