import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.creditNoteOnlyForIssued)),
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
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.creditNoteCreatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.creditNoteCreateError(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totals = _computedTotals;
    final docNum = widget.originalDoc.docNumber?.toString() ?? '—';
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: narrow ? MediaQuery.sizeOf(context).height * 0.92 : 700,
        ),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.note_add_outlined,
                              color: theme.colorScheme.primary),
                          Text(
                            '${l10n.creditNoteCreateTitle} — ${l10n.originalDocumentLabel} #$docNum',
                            style: narrow
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge,
                          ),
                        ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createCreditNoteButton),
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
    final l10n = AppLocalizations.of(context)!;
    final doc = widget.originalDoc;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.originalDocumentLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (narrow) ...[
              _ReadOnlyField(
                label: 'מספר מסמך',
                value: '#${doc.docNumber ?? "—"}',
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(
                label: 'לקוח',
                value: doc.customerName,
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(
                label: 'סכום מקורי',
                value: '₪${doc.totals.gross.toStringAsFixed(2)}',
              ),
            ] else
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _reasonCtrl,
      decoration: InputDecoration(
        labelText: l10n.correctionReasonLabel,
        hintText: l10n.creditNoteReasonHint,
        border: const OutlineInputBorder(),
      ),
      maxLines: 2,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? l10n.creditNoteReasonRequired : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Correction type selector (full / partial)
  // ---------------------------------------------------------------------------

  Widget _buildCorrectionTypeSelector(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.correctionTypeLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _correctionType,
          onChanged: _onCorrectionTypeChanged,
          child: narrow
              ? Column(
                  children: [
                    ListTile(
                      leading: const Radio<String>(value: 'full'),
                      title: Text(l10n.fullCorrectionTitle),
                      subtitle: Text(l10n.fullCorrectionSubtitle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => _onCorrectionTypeChanged('full'),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Radio<String>(value: 'partial'),
                      title: Text(l10n.partialCorrectionTitle),
                      subtitle: Text(l10n.partialCorrectionSubtitle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => _onCorrectionTypeChanged('partial'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: const Radio<String>(value: 'full'),
                        title: Text(l10n.fullCorrectionTitle),
                        subtitle: Text(l10n.fullCorrectionSubtitle),
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
                        title: Text(l10n.partialCorrectionTitle),
                        subtitle: Text(l10n.partialCorrectionSubtitle),
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
        Text(AppLocalizations.of(context)!.correctionLinesTitle,
            style: theme.textTheme.titleMedium),
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
            Text(AppLocalizations.of(context)!.correctionSummaryTitle,
                style: theme.textTheme.titleMedium),
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: data.descriptionCtrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.descriptionIndex(index + 1),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          readOnly: !editable,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
        ),
        const SizedBox(height: 8),
        if (narrow)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 110,
                child: _numberField(
                  controller: data.quantityCtrl,
                  label: 'כמות',
                  editable: editable,
                  onChanged: onChanged,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'לא תקין';
                    return null;
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: _numberField(
                  controller: data.unitPriceCtrl,
                  label: 'מחיר יח׳',
                  editable: editable,
                  onChanged: onChanged,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'לא תקין' : null,
                ),
              ),
              SizedBox(
                width: 110,
                child: _numberField(
                  controller: data.vatRateCtrl,
                  label: 'מע״מ',
                  editable: editable,
                  onChanged: onChanged,
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
                ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: _numberField(
                  controller: data.quantityCtrl,
                  label: 'כמות',
                  editable: editable,
                  onChanged: onChanged,
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
                child: _numberField(
                  controller: data.unitPriceCtrl,
                  label: 'מחיר יח׳',
                  editable: editable,
                  onChanged: onChanged,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'לא תקין' : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: _numberField(
                  controller: data.vatRateCtrl,
                  label: 'מע״מ',
                  editable: editable,
                  onChanged: onChanged,
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
          ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required bool editable,
    required VoidCallback onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      readOnly: !editable,
      onChanged: (_) => onChanged(),
      validator: validator,
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
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₪${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
