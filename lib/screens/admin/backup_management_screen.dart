import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';

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

  Future<void> _recordBackup() async {
    final auth = context.read<AuthService>();
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('רישום גיבוי'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'מיקום גיבוי',
                hintText: 'Google Drive / External HDD / etc.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'הערות (אופציונלי)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('שמור')),
        ],
      ),
    );

    if (result == true && locationController.text.isNotEmpty) {
      await _backupService.recordBackup(
        performedBy: auth.userModel?.name ?? auth.currentUser?.uid ?? '',
        backupLocation: locationController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'גיבוי נרשם בהצלחה');
        _loadData();
      }
    }
  }

  Future<void> _recordRestoreTest() async {
    final auth = context.read<AuthService>();
    final notesController = TextEditingController();
    bool success = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('רישום בדיקת שחזור'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('השחזור הצליח?'),
                value: success,
                onChanged: (v) => setDialogState(() => success = v),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'הערות'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ביטול')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('שמור')),
          ],
        ),
      ),
    );

    if (result == true) {
      await _backupService.recordRestoreTest(
        performedBy: auth.userModel?.name ?? auth.currentUser?.uid ?? '',
        success: success,
        backupId: _backups.isNotEmpty ? _backups.first['id'] ?? '' : '',
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'בדיקת שחזור נרשמה');
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ניהול גיבויים'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'גיבויים'),
              Tab(text: 'בדיקות שחזור'),
              Tab(text: 'דוח עמידה'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_backupService.isQuarterlyBackupDue())
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text('נדרש גיבוי רבעוני!')),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _recordBackup,
                icon: const Icon(Icons.backup),
                label: const Text('רשום גיבוי'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _backups.isEmpty
              ? const Center(child: Text('אין גיבויים רשומים'))
              : ListView.builder(
                  itemCount: _backups.length,
                  itemBuilder: (context, i) {
                    final b = _backups[i];
                    final ts = b['timestamp'] as Timestamp?;
                    return ListTile(
                      leading:
                          const Icon(Icons.cloud_done, color: Colors.green),
                      title: Text(b['backupLocation'] ?? ''),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: _recordRestoreTest,
                icon: const Icon(Icons.restore),
                label: const Text('רשום בדיקת שחזור'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _restoreTests.isEmpty
              ? const Center(child: Text('אין בדיקות שחזור'))
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
                      title: Text(success ? 'שחזור הצליח' : 'שחזור נכשל'),
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
    if (_complianceReport == null) {
      return const Center(child: Text('טוען...'));
    }
    final r = _complianceReport!;
    final compliant = r['compliant'] == true;

    return Padding(
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
                      compliant
                          ? 'עמידה בדרישות — תקין'
                          : 'בעיות בעמידה בדרישות',
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
          _infoRow('רבעון', '${r['currentQuarter']} ${r['year']}'),
          _infoRow('גיבוי רבעוני',
              r['isCurrentQuarterBackedUp'] == true ? '✅ בוצע' : '❌ לא בוצע'),
          _infoRow('נדרש גיבוי', r['backupsDue'] == true ? 'כן' : 'לא'),
          _infoRow('גיבויים רשומים', '${r['totalBackupsRecorded']}'),
          _infoRow(
              'בדיקת שחזור אחרונה',
              r['lastRestoreTestSuccess'] == true
                  ? '✅ הצליח'
                  : '❌ לא בוצע/נכשל'),
          _infoRow('בדיקות שחזור', '${r['totalRestoreTests']}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 180,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
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
