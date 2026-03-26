import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/client_model.dart';
import '../../../../screens/shared/dialogs/create_client_dialog.dart';
import '../../../../services/client_service.dart';
import '../../models/accounting_doc.dart';
import '../../repositories/accounting_docs_repository.dart';
import 'accounting_helpers.dart';

// =============================================================================
// Type selection dialog
// =============================================================================

/// Dialog for choosing the type of accounting document to create.
class CreateDocTypeDialog extends StatelessWidget {
  final ValueChanged<AccountingDocType> onTypeSelected;

  const CreateDocTypeDialog({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 16 : 40,
        vertical: 24,
      ),
      title: Text(l10n.selectDocType),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeOption(
              icon: Icons.receipt_long,
              label: l10n.taxInvoice,
              subtitle: 'Tax Invoice',
              onTap: () => onTypeSelected(AccountingDocType.taxInvoice),
            ),
            _TypeOption(
              icon: Icons.receipt,
              label: l10n.receipt,
              subtitle: 'Receipt',
              onTap: () => onTypeSelected(AccountingDocType.receipt),
            ),
            _TypeOption(
              icon: Icons.description,
              label: l10n.taxInvoiceReceipt,
              subtitle: 'Tax Invoice Receipt',
              onTap: () => onTypeSelected(AccountingDocType.taxInvoiceReceipt),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// =============================================================================
// Create / edit document form dialog
// =============================================================================

/// Full form dialog for creating a new accounting document.
class CreateDocFormDialog extends StatefulWidget {
  final AccountingDocType docType;
  final String companyId;
  final AccountingDocsRepository docsRepo;

  const CreateDocFormDialog({
    super.key,
    required this.docType,
    required this.companyId,
    required this.docsRepo,
  });

  @override
  State<CreateDocFormDialog> createState() => _CreateDocFormDialogState();
}

class _CreateDocFormDialogState extends State<CreateDocFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerTaxIdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<_LineItemData> _lines = [_LineItemData()];
  bool _saving = false;

  List<ClientModel> _clientSearchResults = [];
  ClientModel? _selectedClient;

  Future<void> _searchClients(String query) async {
    if (query.length < 2) {
      if (mounted) setState(() => _clientSearchResults = []);
      return;
    }
    final results =
        await ClientService(companyId: widget.companyId).searchClients(query);
    if (mounted) setState(() => _clientSearchResults = results);
  }

  void _selectClient(ClientModel client) {
    _customerNameCtrl.text = client.name;
    if (client.vatId != null && client.vatId!.isNotEmpty) {
      _customerTaxIdCtrl.text = client.vatId!;
    }
    setState(() {
      _selectedClient = client;
      _clientSearchResults = [];
    });
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerTaxIdCtrl.dispose();
    _notesCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final totals = _computedTotals;
      final doc = AccountingDoc(
        type: widget.docType,
        status: AccountingDocStatus.draft,
        customerId: _selectedClient?.id ?? '',
        customerName: _customerNameCtrl.text.trim(),
        customerTaxId: _customerTaxIdCtrl.text.trim().isNotEmpty
            ? _customerTaxIdCtrl.text.trim()
            : null,
        lines: _buildLines,
        totals: totals,
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        companyId: widget.companyId,
        notes:
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      await widget.docsRepo.createDoc(doc);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.documentCreatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorCreatingDoc(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _computedTotals;
    final l10n = AppLocalizations.of(context)!;
    final typeLbl = docTypeLabel(context, widget.docType);
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
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: theme.colorScheme.primary),
                          Text(
                            l10n.newDocumentTitle(typeLbl),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCustomerSection(theme),
                        const SizedBox(height: 16),
                        _buildLinesSection(theme),
                        const SizedBox(height: 16),
                        _buildTotalsCard(theme, totals),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.notesLabel,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          : Text(l10n.saveDraft),
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

  Widget _buildCustomerSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.customerDetails, style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: () async {
                final created = await showDialog<ClientModel>(
                  context: context,
                  builder: (_) =>
                      CreateClientDialog(companyId: widget.companyId),
                );
                if (created != null) _selectClient(created);
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(l10n.createClient),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (narrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerNameField(theme, l10n),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerTaxIdCtrl,
                decoration: InputDecoration(
                  labelText: l10n.taxIdLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCustomerNameField(theme, l10n)),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _customerTaxIdCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.taxIdLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCustomerNameField(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _customerNameCtrl,
          decoration: InputDecoration(
            labelText: l10n.customerNameRequired,
            border: const OutlineInputBorder(),
            suffixIcon: _customerNameCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _customerNameCtrl.clear();
                      setState(() {
                        _selectedClient = null;
                        _clientSearchResults = [];
                      });
                    },
                  )
                : null,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
          onChanged: (v) => _searchClients(v),
        ),
        if (_clientSearchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4)),
              color: theme.colorScheme.surface,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _clientSearchResults.length,
              itemBuilder: (context, i) {
                final c = _clientSearchResults[i];
                return ListTile(
                  dense: true,
                  title: Text(c.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${c.clientNumber} · ${c.address}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () => _selectClient(c),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLinesSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.documentLines, style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_LineItemData())),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addLine),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_lines.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LineItemRow(
              data: _lines[i],
              index: i,
              canRemove: _lines.length > 1,
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

  Widget _buildTotalsCard(ThemeData theme, AccountingDocTotals totals) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.summaryTitle, style: theme.textTheme.titleMedium),
            const Divider(),
            _TotalRow(label: l10n.netBeforeVat, value: totals.net),
            _TotalRow(label: l10n.vatLabelCalc, value: totals.vat),
            const Divider(),
            _TotalRow(
              label: l10n.grossWithVat,
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
// Private helper widgets
// =============================================================================

class _LineItemData {
  final descriptionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final unitPriceCtrl = TextEditingController(text: '0');
  final vatRateCtrl = TextEditingController(text: '0.18');

  void dispose() {
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    vatRateCtrl.dispose();
  }
}

class _LineItemRow extends StatelessWidget {
  final _LineItemData data;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineItemRow({
    required this.data,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: data.descriptionCtrl,
          decoration: InputDecoration(
            labelText: l10n.descriptionN(index + 1),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
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
                  label: l10n.quantityShort,
                  onChanged: onChanged,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return l10n.invalidValue;
                    return null;
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: _numberField(
                  controller: data.unitPriceCtrl,
                  label: l10n.unitPriceLabel,
                  onChanged: onChanged,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? l10n.invalidValue : null,
                ),
              ),
              SizedBox(
                width: 110,
                child: _numberField(
                  controller: data.vatRateCtrl,
                  label: l10n.vatRateLabel,
                  onChanged: onChanged,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val < 0) return l10n.invalidValue;
                    return null;
                  },
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: AppLocalizations.of(context)!.removeLine,
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
                  label: l10n.quantityShort,
                  onChanged: onChanged,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return l10n.invalidValue;
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: _numberField(
                  controller: data.unitPriceCtrl,
                  label: l10n.unitPriceLabel,
                  onChanged: onChanged,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? l10n.invalidValue : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: _numberField(
                  controller: data.vatRateCtrl,
                  label: l10n.vatRateLabel,
                  onChanged: onChanged,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val < 0) return l10n.invalidValue;
                    return null;
                  },
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: AppLocalizations.of(context)!.removeLine,
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
      onChanged: (_) => onChanged(),
      validator: validator,
    );
  }
}

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
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(label, style: style),
          Text('₪${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
