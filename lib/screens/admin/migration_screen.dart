import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/summary_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// One-time migration screen to build summaries for existing data
/// מסך מעבר חד-פעמי לבניית סיכומים לנתונים קיימים
///
/// Run this ONCE after deploying the optimization update
class MigrationScreen extends StatefulWidget {
  final String companyId;

  const MigrationScreen({super.key, required this.companyId});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  late final SummaryService _summaryService;
  bool _isRunning = false;
  final List<String> _logs = [];
  int _daysToMigrate = 30;

  @override
  void initState() {
    super.initState();
    _summaryService = SummaryService(companyId: widget.companyId);
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateFormat('HH:mm:ss').format(DateTime.now())} - $message');
    });
  }

  Future<void> _runMigration() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🚀 Starting migration...');
    _addLog('Building summaries for last $_daysToMigrate days');

    final now = DateTime.now();
    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < _daysToMigrate; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      _addLog('📅 Processing $dateStr...');

      try {
        // Build invoice summary
        await _summaryService.rebuildInvoiceSummary(date);
        _addLog('  ✅ Invoice summary built');

        // Build delivery summary
        await _summaryService.rebuildDeliverySummary(date);
        _addLog('  ✅ Delivery summary built');

        successCount++;
      } catch (e) {
        _addLog('  ❌ Error: $e');
        errorCount++;
      }

      // Small delay to avoid overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _addLog('');
    _addLog('🎉 Migration complete!');
    _addLog('✅ Success: $successCount days');
    if (errorCount > 0) {
      _addLog('❌ Errors: $errorCount days');
    }
    _addLog('');
    _addLog('💡 You can now use the optimized dashboard');

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataMigration),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.oneTimeSetup,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.migrationDescription,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.migrationInstructions,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flex(
              direction: narrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment:
                  narrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(l10n.daysToMigrate),
                SizedBox(width: narrow ? 0 : 16, height: narrow ? 8 : 0),
                DropdownButton<int>(
                  value: _daysToMigrate,
                  items: [7, 14, 30, 60, 90]
                      .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days ${l10n.days}'),
                          ))
                      .toList(),
                  onChanged: _isRunning
                      ? null
                      : (value) {
                          setState(() {
                            _daysToMigrate = value ?? 30;
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runMigration,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Running...' : 'Start Migration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Migration Log:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHi,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Click "Start Migration" to begin',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color? textColor;
                          if (log.contains('✅')) {
                            textColor = Colors.green.shade700;
                          } else if (log.contains('❌')) {
                            textColor = Colors.red.shade700;
                          } else if (log.contains('🎉')) {
                            textColor = Colors.blue.shade700;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
