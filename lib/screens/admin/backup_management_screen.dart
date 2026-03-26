import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';

/// Backup management screen — quarterly backup records, restore tests, compliance report.
class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BackupService _backupService;
  bool _isLoading = false;

  List<Map<String, dynamic>> _backups = [];
  List<Map<String, dynamic>> _restoreTests = [];
  Map<String, dynamic>? _complianceReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _backupService = BackupService(companyId: companyId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.getBackupHistory();
      final tests = await _backupService.getRestoreTestHistory();
      final report = await _backupService.getBackupComplianceReport();
      setState(() {
        _backups = backups;
        _restoreTests = tests;
        _complianceReport = report;
      });
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<(String, String, IconData, String)> _storageTypes(
          AppLocalizations l10n) =>
      [
        (
          'google_drive',
          l10n.storageGoogleDrive,
          Icons.cloud,
          l10n.hintGoogleDrive
        ),
        (
          'onedrive',
          l10n.storageOneDrive,
          Icons.cloud_outlined,
          l10n.hintOneDrive
        ),
        ('dropbox', l10n.storageDropbox, Icons.cloud_queue, l10n.hintDropbox),
        ('aws_s3', l10n.storageAwsS3, Icons.storage, l10n.hintAwsS3),
        (
          'external_hdd',
          l10n.storageExternalHdd,
          Icons.sd_storage,
          l10n.hintExternalHdd
        ),
        ('nas', l10n.storageNas, Icons.dns, l10n.hintNas),
        ('usb', l10n.storageUsb, Icons.usb, l10n.hintUsb),
        ('firebase', l10n.storageFirebase, Icons.backup, l10n.hintFirebase),
        (
          'local_server',
          l10n.storageLocalServer,
          Icons.computer,
          l10n.hintLocalServer
        ),
        ('ftp', l10n.storageFtp, Icons.folder_shared, l10n.hintFtp),
        ('other', l10n.storageOther, Icons.edit, l10n.hintOther),
      ];

  Future<void> _recordBackup() async {
    final auth = context.read<AuthService>();
    final l10n = AppLocalizations.of(context)!;
    final storageTypes = _storageTypes(l10n);
    String selectedType = '';
    final pathController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogWidth =
              MediaQuery.sizeOf(ctx).width < 500 ? 320.0 : 400.0;
          final hint = storageTypes
                  .where((t) => t.$1 == selectedType)
                  .map((t) => t.$4)
                  .firstOrNull ??
              '';
          final canSave =
              selectedType.isNotEmpty && pathController.text.trim().isNotEmpty;

          return AlertDialog(
            title: Text(l10n.registerBackupTitle),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: l10n.storageType),
                    initialValue: selectedType.isEmpty ? null : selectedType,
                    items: storageTypes.map((t) {
                      final (key, label, icon, _) = t;
                      return DropdownMenuItem(
                        value: key,
                        child: Row(children: [
                          Icon(icon, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedType = v ?? '';
                      pathController.clear();
                    }),
                  ),
                  if (selectedType.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: pathController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.exactLocation,
                        hintText: hint,
                        hintStyle: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: l10n.notesOptional),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel)),
              FilledButton(
                  onPressed: canSave ? () => Navigator.pop(ctx, true) : null,
                  child: Text(l10n.save)),
            ],
          );
        },
      ),
    );

    if (result == true &&
        selectedType.isNotEmpty &&
        pathController.text.trim().isNotEmpty) {
      final typeLabel = storageTypes
          .firstWhere((t) => t.$1 == selectedType,
              orElse: () => ('', selectedType, Icons.help, ''))
          .$2;
      final fullLocation = '$typeLabel: ${pathController.text.trim()}';

      await _backupService.recordBackup(
        performedBy: auth.userModel?.name ?? auth.currentUser?.uid ?? '',
        backupLocation: fullLocation,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.backupRecorded);
        _loadData();
      }
    }
  }

  Future<void> _recordRestoreTest() async {
    final auth = context.read<AuthService>();
    final l10n = AppLocalizations.of(context)!;
    final notesController = TextEditingController();
    bool success = true;
    String? selectedBackupId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogWidth =
              MediaQuery.sizeOf(ctx).width < 500 ? 320.0 : 400.0;
          return AlertDialog(
          title: Text(l10n.registerRestoreTestTitle),
          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_backups.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration:
                        InputDecoration(labelText: l10n.restoreFromBackup),
                    initialValue: selectedBackupId,
                    items: _backups.map((b) {
                      final id = b['id'] as String? ?? '';
                      final loc = b['backupLocation'] as String? ?? '—';
                      final ts = b['timestamp'] as Timestamp?;
                      final date = ts != null
                          ? '${ts.toDate().day}.${ts.toDate().month}.${ts.toDate().year}'
                          : '';
                      return DropdownMenuItem(
                        value: id,
                        child: Text('$loc ($date)',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedBackupId = v),
                  )
                else
                  Text(l10n.noBackupsYetRegisterFirst,
                      style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(l10n.restoreSuccess),
                  value: success,
                  onChanged: (v) => setDialogState(() => success = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.notesLabel),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            FilledButton(
                onPressed: selectedBackupId != null
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(l10n.save)),
          ],
        );
        },
      ),
    );

    if (result == true && selectedBackupId != null) {
      await _backupService.recordRestoreTest(
        performedBy: auth.userModel?.name ?? auth.currentUser?.uid ?? '',
        success: success,
        backupId: selectedBackupId!,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.restoreTestRecorded);
        _loadData();
      }
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
          title: Text(l10n.backupManagementTitle),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: narrow,
            tabs: [
              Tab(text: l10n.tabBackups),
              Tab(text: l10n.tabRestoreTests),
              Tab(text: l10n.tabComplianceReport),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBackupsTab(),
                  _buildRestoreTestsTab(),
                  _buildComplianceTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildBackupsTab() {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_backupService.isQuarterlyBackupDue())
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l10n.quarterlyBackupRequired)),
                            ],
                          ),
                        ),
                      ),
                    if (_backupService.isQuarterlyBackupDue())
                      const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _recordBackup,
                      icon: const Icon(Icons.backup),
                      label: Text(l10n.registerBackup),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (_backupService.isQuarterlyBackupDue())
                      Expanded(
                        child: Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(l10n.quarterlyBackupRequired)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _recordBackup,
                      icon: const Icon(Icons.backup),
                      label: Text(l10n.registerBackup),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _backups.isEmpty
              ? Center(child: Text(l10n.noBackupsRecorded))
              : ListView.builder(
                  itemCount: _backups.length,
                  itemBuilder: (context, i) {
                    final b = _backups[i];
                    final ts = b['timestamp'] as Timestamp?;
                    return ListTile(
                      leading:
                          const Icon(Icons.cloud_done, color: Colors.green),
                      title: Text(
                        b['backupLocation'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: narrow,
                      subtitle: Text(
                        '${b['performedBy']} • ${b['quarter']} ${b['year']}'
                        '${ts != null ? ' • ${ts.toDate().toString().substring(0, 16)}' : ''}',
                      ),
                      trailing: b['notes'] != null
                          ? Tooltip(
                              message: b['notes'],
                              child: const Icon(Icons.note))
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRestoreTestsTab() {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: narrow
              ? SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _recordRestoreTest,
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.registerRestoreTest),
                  ),
                )
              : Row(
                  children: [
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _recordRestoreTest,
                      icon: const Icon(Icons.restore),
                      label: Text(l10n.registerRestoreTest),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _restoreTests.isEmpty
              ? Center(child: Text(l10n.noRestoreTests))
              : ListView.builder(
                  itemCount: _restoreTests.length,
                  itemBuilder: (context, i) {
                    final t = _restoreTests[i];
                    final success = t['success'] == true;
                    final ts = t['timestamp'] as Timestamp?;
                    return ListTile(
                      leading: Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: success ? Colors.green : Colors.red,
                      ),
                      title: Text(
                          success ? l10n.restoreSucceeded : l10n.restoreFailed),
                      subtitle: Text(
                        '${t['performedBy']} • ${t['quarter']} ${t['year']}'
                        '${ts != null ? ' • ${ts.toDate().toString().substring(0, 16)}' : ''}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComplianceTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_complianceReport == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final r = _complianceReport!;
    final compliant = r['compliant'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: compliant ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    compliant ? Icons.verified : Icons.warning,
                    color: compliant ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      compliant ? l10n.complianceOk : l10n.complianceIssues,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: compliant
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoRow(l10n.labelQuarter, '${r['currentQuarter']} ${r['year']}'),
          _infoRow(
              l10n.labelQuarterlyBackup,
              r['isCurrentQuarterBackedUp'] == true
                  ? l10n.statusDone
                  : l10n.statusNotDone),
          _infoRow(l10n.labelBackupDue,
              r['backupsDue'] == true ? l10n.yes : l10n.no),
          _infoRow(l10n.labelBackupsRecorded, '${r['totalBackupsRecorded']}'),
          _infoRow(
              l10n.labelLastRestoreTest,
              r['lastRestoreTestSuccess'] == true
                  ? l10n.statusSucceeded
                  : l10n.statusNotDoneOrFailed),
          _infoRow(l10n.labelRestoreTests, '${r['totalRestoreTests']}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value),
              ],
            )
          : Row(
              children: [
                SizedBox(
                    width: 180,
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Text(value)),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
