import 'package:flutter/material.dart';

import '../models/accounting_doc.dart';
import '../models/credit_note_data.dart';
import '../repositories/accounting_docs_repository.dart';

/// Диалог создания Credit Note (תעודת זיכוי).
///
/// Получает оригинальный документ как контекст, предзаполняет поля,
/// позволяет выбрать тип коррекции (full/partial) и отправляет данные
/// через [AccountingDocsRepository.createCreditNote].
///
/// Аудит-событие записывается внутри репозитория (transaction).
///
/// Requirements: 16.1, 16.2, 16.3, 16.4, 16.5
class CreditNoteFormDialog extends StatefulWidget {
  final AccountingDoc originalDoc;
  final AccountingDocsRepository docsRepo;

  const CreditNoteFormDialog({
    super.key,
    required this.originalDoc,
    required this.docsRepo,
  });

  @override
  State<CreditNoteFormDialog> createState() => _CreditNoteFormDialogState();
}

class _CreditNoteFormDialogState extends State<CreditNoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  /// 'full' or 'partial'
  String _correctionType = 'full';

  /// Editable line items for the credit note.
  late List<_CreditLineData> _lines;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.originalDoc.lines
        .map((l) => _CreditLineData.fromLine(l))
        .toList();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Computed totals from current line items
  // ---------------------------------------------------------------------------

  AccountingDocTotals get _computedTotals {
    double net = 0;
    double vat = 0;
    for (final line in _lines) {
      final qty = double.tryParse(line.quantityCtrl.text) ?? 0;
      final price = double.tryParse(line.unitPriceCtrl.text) ?? 0;
      final vatRate = double.tryParse(line.vatRateCtrl.text) ?? 0.18;
      final lineNet = qty * price;
      final lineVat = lineNet * vatRate;
      net += lineNet;
      vat += lineVat;
    }
    return AccountingDocTotals(net: net, vat: vat, gross: net + vat);
  }

  List<AccountingDocLine> get _buildLines {
    return _lines.map((l) {
      final qty = double.tryParse(l.quantityCtrl.text) ?? 0;
      final price = double.tryParse(l.unitPriceCtrl.text) ?? 0;
      final vatRate = double.tryParse(l.vatRateCtrl.text) ?? 0.18;
      final lineNet = qty * price;
      final lineVat = lineNet * vatRate;
      return AccountingDocLine(
        description: l.descriptionCtrl.text,
        quantity: qty,
        unitPrice: price,
        totalBeforeVat: lineNet,
        vatRate: vatRate,
        vatAmount: lineVat,
        totalWithVat: lineNet + lineVat,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Correction type change handler
  // ---------------------------------------------------------------------------

  void _onCorrectionTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _correctionType = value;
      // Re-populate lines from original when switching to full
      if (value == 'full') {
        for (final line in _lines) {
          line.dispose();
        }
        _lines = widget.originalDoc.lines
            .map((l) => _CreditLineData.fromLine(l))
            .toList();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final originalStatus = widget.originalDoc.status;
    if (originalStatus != AccountingDocStatus.issued &&
        originalStatus != AccountingDocStatus.locked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ניתן ליצור תעודת זיכוי רק עבור מסמך בסטטוס "הונפק" או "נעול"',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final totals = _computedTotals;
      final data = CreditNoteData(
        originalDocId: widget.originalDoc.id!,
        originalDocNumber: widget.originalDoc.docNumber ?? 0,
        reason: _reasonCtrl.text.trim(),
        correctionType: _correctionType,
        customerId: widget.originalDoc.customerId,
        lines: _buildLines,
        totals: totals,
      );

      await widget.docsRepo.createCreditNote(data);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('תעודת זיכוי נוצרה בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה ביצירת תעודת זיכוי: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _computedTotals;
    final docNum = widget.originalDoc.docNumber?.toString() ?? '—';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Icon(Icons.note_add_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'תעודת זיכוי — מסמך מקור #$docNum',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                // Scrollable form body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOriginalDocInfo(theme),
                        const SizedBox(height: 16),
                        _buildReasonField(),
                        const SizedBox(height: 16),
                        _buildCorrectionTypeSelector(theme),
                        const SizedBox(height: 16),
                        _buildLinesSection(theme),
                        const SizedBox(height: 16),
                        _buildTotalsCard(theme, totals),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('ביטול'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('צור תעודת זיכוי'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Original document info (auto-filled, read-only)
  // ---------------------------------------------------------------------------

  Widget _buildOriginalDocInfo(ThemeData theme) {
    final doc = widget.originalDoc;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('מסמך מקורי', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ReadOnlyField(
                    label: 'מספר מסמך',
                    value: '#${doc.docNumber ?? "—"}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReadOnlyField(
                    label: 'לקוח',
                    value: doc.customerName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReadOnlyField(
                    label: 'סכום מקורי',
                    value: '₪${doc.totals.gross.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reason field (required)
  // ---------------------------------------------------------------------------

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonCtrl,
      decoration: const InputDecoration(
        labelText: 'סיבת תיקון *',
        hintText: 'נא לציין את סיבת הזיכוי',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'יש להזין סיבת תיקון' : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Correction type selector (full / partial)
  // ---------------------------------------------------------------------------

  Widget _buildCorrectionTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('סוג תיקון', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _correctionType,
          onChanged: _onCorrectionTypeChanged,
          child: Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Radio<String>(value: 'full'),
                  title: const Text('תיקון מלא'),
                  subtitle: const Text('כל השורות מהמסמך המקורי'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => _onCorrectionTypeChanged('full'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  leading: const Radio<String>(value: 'partial'),
                  title: const Text('תיקון חלקי'),
                  subtitle: const Text('עריכה/הסרה של שורות'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => _onCorrectionTypeChanged('partial'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Line items section
  // ---------------------------------------------------------------------------

  Widget _buildLinesSection(ThemeData theme) {
    final isPartial = _correctionType == 'partial';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('שורות זיכוי', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(_lines.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CreditLineRow(
              data: _lines[i],
              index: i,
              editable: isPartial,
              canRemove: isPartial && _lines.length > 1,
              onRemove: () {
                setState(() {
                  _lines[i].dispose();
                  _lines.removeAt(i);
                });
              },
              onChanged: () => setState(() {}),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Totals card (auto-calculated)
  // ---------------------------------------------------------------------------

  Widget _buildTotalsCard(ThemeData theme, AccountingDocTotals totals) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('סיכום זיכוי', style: theme.textTheme.titleMedium),
            const Divider(),
            _TotalRow(label: 'סה״כ לפני מע״מ (Net)', value: totals.net),
            _TotalRow(label: 'מע״מ (VAT)', value: totals.vat),
            const Divider(),
            _TotalRow(
              label: 'סה״כ כולל מע״מ (Gross)',
              value: totals.gross,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

/// Read-only field displaying original document info.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Mutable data holder for a credit note line item.
class _CreditLineData {
  final descriptionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final unitPriceCtrl = TextEditingController();
  final vatRateCtrl = TextEditingController();

  _CreditLineData();

  factory _CreditLineData.fromLine(AccountingDocLine line) {
    final data = _CreditLineData();
    data.descriptionCtrl.text = line.description;
    data.quantityCtrl.text = line.quantity.toString();
    data.unitPriceCtrl.text = line.unitPrice.toString();
    data.vatRateCtrl.text = line.vatRate.toString();
    return data;
  }

  void dispose() {
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    vatRateCtrl.dispose();
  }
}

/// A single line item row in the credit note form.
class _CreditLineRow extends StatelessWidget {
  final _CreditLineData data;
  final int index;
  final bool editable;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _CreditLineRow({
    required this.data,
    required this.index,
    required this.editable,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: data.descriptionCtrl,
            decoration: InputDecoration(
              labelText: 'תיאור ${index + 1}',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            readOnly: !editable,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: data.quantityCtrl,
            decoration: const InputDecoration(
              labelText: 'כמות',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            readOnly: !editable,
            onChanged: (_) => onChanged(),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val == null || val <= 0) return 'לא תקין';
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: data.unitPriceCtrl,
            decoration: const InputDecoration(
              labelText: 'מחיר יח׳',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            readOnly: !editable,
            onChanged: (_) => onChanged(),
            validator: (v) {
              if (double.tryParse(v ?? '') == null) return 'לא תקין';
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: data.vatRateCtrl,
            decoration: const InputDecoration(
              labelText: 'מע״מ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            readOnly: !editable,
            onChanged: (_) => onChanged(),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val == null || val < 0) return 'לא תקין';
              return null;
            },
          ),
        ),
        if (canRemove)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: onRemove,
            tooltip: 'הסר שורה',
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

/// Row displaying a total value.
class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₪${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
