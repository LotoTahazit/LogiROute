import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/integrity_verify_service.dart';
import '../../services/company_context.dart';

/// Admin UI: проверка целостности криптоцепочки
class IntegrityCheckScreen extends StatefulWidget {
  const IntegrityCheckScreen({super.key});

  @override
  State<IntegrityCheckScreen> createState() => _IntegrityCheckScreenState();
}

class _IntegrityCheckScreenState extends State<IntegrityCheckScreen> {
  String _counterKey = 'invoice';
  int _rangeSize = 500;
  bool _isChecking = false;
  IntegrityVerifyResult? _result;
  String? _error;

  // Счётчики для определения максимального диапазона
  final Map<String, int> _counterValues = {};
  bool _loadingCounters = true;

  static const _counterKeys = [
    ('invoice', 'חשבוניות מס'),
    ('receipt', 'קבלות'),
    ('creditNote', 'זיכויים'),
    ('delivery', 'תעודות משלוח'),
    ('taxInvoiceReceipt', 'חשבוניות מס/קבלה'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCounters());
  }

  Future<void> _loadCounters() async {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    setState(() => _loadingCounters = true);
    try {
      for (final (key, _) in _counterKeys) {
        final snap = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('accounting')
            .doc('_root')
            .collection('counters')
            .doc(key)
            .get();
        if (snap.exists) {
          _counterValues[key] =
              (snap.data()?['lastNumber'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCounters = false);
  }

  Future<void> _runCheck() async {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final maxDoc = _counterValues[_counterKey] ?? 0;
    if (maxDoc == 0) {
      setState(() => _error = 'אין מסמכים מסוג זה');
      return;
    }

    final from = (maxDoc - _rangeSize + 1).clamp(1, maxDoc);
    final to = maxDoc;

    setState(() {
      _isChecking = true;
      _result = null;
      _error = null;
    });

    try {
      final result = await IntegrityVerifyService().verify(
        companyId: companyId,
        counterKey: _counterKey,
        from: from,
        to: to,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('בדיקת שלמות שרשרת')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Counter key selector
              const Text('סוג מסמך:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _counterKeys.map((entry) {
                  final (key, label) = entry;
                  final count = _counterValues[key] ?? 0;
                  return ChoiceChip(
                    label: Text('$label ($count)'),
                    selected: _counterKey == key,
                    onSelected: (_) => setState(() {
                      _counterKey = key;
                      _result = null;
                      _error = null;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Range size
              const Text('טווח בדיקה:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [100, 500, 1000, 2000].map((size) {
                  return ChoiceChip(
                    label: Text('אחרונים $size'),
                    selected: _rangeSize == size,
                    onSelected: (_) => setState(() => _rangeSize = size),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Run button
              ElevatedButton.icon(
                onPressed: _isChecking || _loadingCounters ? null : _runCheck,
                icon: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user),
                label: Text(_isChecking ? 'בודק...' : 'בדוק שלמות'),
              ),
              const SizedBox(height: 24),

              // Result
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ),

              if (_result != null)
                Card(
                  color:
                      _result!.ok ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _result!.ok ? Icons.check_circle : Icons.cancel,
                              color: _result!.ok ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _result!.summary,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _result!.ok
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('טווח: ${_result!.from}..${_result!.to}'),
                        Text('נבדקו: ${_result!.checked}'),
                        if (_result!.lastHash != null)
                          Text(
                            'Hash אחרון: ${_result!.lastHash!.substring(0, 16)}...',
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                          ),
                        if (_result!.firstBrokenAt != null)
                          Text(
                            'שבירה במסמך: #${_result!.firstBrokenAt}',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        if (_result!.reason != null)
                          Text('סיבה: ${_result!.reason}'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
