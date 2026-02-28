import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/data_retention_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';

/// Data retention policy screen — run checks, view history, compliance status.
class DataRetentionScreen extends StatefulWidget {
  const DataRetentionScreen({super.key});

  @override
  State<DataRetentionScreen> createState() => _DataRetentionScreenState();
}

class _DataRetentionScreenState extends State<DataRetentionScreen> {
  late DataRetentionService _service;
  bool _isLoading = false;
  bool _isRunning = false;
  RetentionCheckResult? _lastResult;
  List<Map<String, dynamic>> _history = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _service = DataRetentionService(companyId: companyId);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _service.getCheckHistory();
      setState(() => _history = history);
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Error: $e');
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
        SnackbarHelper.showSuccess(context, 'בדיקה הושלמה');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מדיניות שמירת נתונים'),
          actions: [
            IconButton(
              onPressed: _isRunning ? null : _runCheck,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              tooltip: 'הפעל בדיקה',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'לפי חוק ניהול ספרים, יש לשמור מסמכים לפחות 7 שנים.\n'
                                'הבדיקה מוודאת שלא נמחקו מסמכים ושאין פערים במספור.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Last result
                    if (_lastResult != null) ...[
                      const Text('תוצאת בדיקה אחרונה',
                          style: TextStyle(
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
                              Row(
                                children: [
                                  Icon(
                                    _lastResult!.isCompliant
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _lastResult!.isCompliant
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_lastResult!.summary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('מסמכים: ${_lastResult!.totalDocuments}'),
                              if (_lastResult!.oldestDocumentDate != null)
                                Text(
                                    'מסמך ישן ביותר: ${_lastResult!.oldestDocumentDate.toString().substring(0, 10)}'),
                              Text(
                                  'תאריך חיתוך: ${_lastResult!.retentionCutoffDate.toString().substring(0, 10)}'),
                              if (_lastResult!.hasSequentialGaps)
                                Text(
                                  'פערים: ${_lastResult!.totalDocuments} מתוך ${_lastResult!.expectedCount} צפויים',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // History
                    const Text('היסטוריית בדיקות',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('אין בדיקות קודמות. לחץ ▶ להפעלת בדיקה.'),
                        ),
                      )
                    else
                      ..._history.map((h) {
                        final compliant = h['isCompliant'] == true;
                        final ts = h['checkedAt'] as Timestamp?;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              compliant ? Icons.check_circle : Icons.error,
                              color: compliant ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              compliant ? 'תקין' : 'בעיות נמצאו',
                            ),
                            subtitle: Text(
                              '${h['checkedBy']} • ${h['totalDocuments']} מסמכים'
                              '${ts != null ? ' • ${ts.toDate().toString().substring(0, 16)}' : ''}',
                            ),
                            trailing: h['hasSequentialGaps'] == true
                                ? const Chip(
                                    label: Text('פערים',
                                        style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.orange,
                                  )
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
