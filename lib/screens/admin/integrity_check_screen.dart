import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/integrity_verify_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';

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

  static const _counterKeyIds = [
    'invoice',
    'receipt',
    'creditNote',
    'delivery',
    'taxInvoiceReceipt',
  ];

  List<(String, String)> _getCounterKeys(AppLocalizations l10n) => [
        ('invoice', l10n.counterInvoices),
        ('receipt', l10n.counterReceipts),
        ('creditNote', l10n.counterCreditNotes),
        ('delivery', l10n.counterDeliveryNotes),
        ('taxInvoiceReceipt', l10n.counterTaxInvoiceReceipts),
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
      for (final key in _counterKeyIds) {
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
    } catch (e) {
      debugPrint('⚠️ [IntegrityCheck] Error loading counters: $e');
    }
    if (mounted) setState(() => _loadingCounters = false);
  }

  Future<void> _runCheck() async {
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final maxDoc = _counterValues[_counterKey] ?? 0;
    if (maxDoc == 0) {
      setState(() => _error = AppLocalizations.of(context)!.noDocumentsOfType);
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

  String _reasonText(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'MISSING_ENTRY':
        return l10n.integrityReasonMissingEntry;
      case 'MISSING_PREV_FOR_RANGE':
        return l10n.integrityReasonMissingPrevForRange;
      case 'SCHEMA_INVALID':
        return l10n.integrityReasonSchemaInvalid;
      case 'PREV_HASH_MISMATCH':
        return l10n.integrityReasonPrevHashMismatch;
      case 'HASH_MISMATCH':
        return l10n.integrityReasonHashMismatch;
      default:
        return code ?? '';
    }
  }

  String _resultSummary(AppLocalizations l10n, IntegrityVerifyResult r) {
    if (r.ok && r.legacyOnly) return l10n.integrityLegacyOnly;
    if (r.ok) return l10n.integrityOkSummary(r.checked);
    return l10n.integrityFailedSummary(r.firstBrokenAt ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counterKeys = _getCounterKeys(l10n);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.integrityCheckTitle)),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.integrityCheckExplain,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Counter key selector
              Text(l10n.documentTypeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: counterKeys.map((entry) {
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
              Text(l10n.checkRangeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [100, 500, 1000, 2000].map((size) {
                  return ChoiceChip(
                    label: Text(l10n.lastNItems(size)),
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
                label: Text(_isChecking ? l10n.checking : l10n.checkIntegrity),
              ),
              const SizedBox(height: 24),

              // Result
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: narrow ? 250 : 560),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_result != null)
                Card(
                  color: _result!.ok
                      ? (_result!.legacyOnly
                          ? Colors.orange.shade50
                          : Colors.green.shade50)
                      : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              _result!.ok ? Icons.check_circle : Icons.cancel,
                              color: _result!.ok ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: narrow ? 240 : 520),
                              child: Text(
                                _resultSummary(l10n, _result!),
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
                        Text(l10n.rangeLabel(_result!.from, _result!.to)),
                        if (_result!.checkedFrom != null &&
                            _result!.checkedFrom! > _result!.from)
                          Text(l10n.integrityCheckedFrom(
                              _result!.checkedFrom!, _result!.to)),
                        if (_result!.legacySkippedFrom != null &&
                            _result!.legacySkippedTo != null)
                          Text(
                            l10n.integrityLegacySkipped(
                              _result!.legacySkippedFrom!,
                              _result!.legacySkippedTo!,
                            ),
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        Text(l10n.checkedCount(_result!.checked)),
                        if (_result!.lastHash != null)
                          Text(
                            l10n.lastHashLabel(
                                _result!.lastHash!.substring(0, 16)),
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                          ),
                        if (_result!.firstBrokenAt != null)
                          Text(
                            l10n.breakAtDocument(_result!.firstBrokenAt!),
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        if (_result!.reason != null)
                          Text(l10n.reasonLabel(
                              _reasonText(l10n, _result!.reason))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
    );
  }
}
