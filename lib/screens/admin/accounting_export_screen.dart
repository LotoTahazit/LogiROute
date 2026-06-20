import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/accounting_export_service.dart';
import '../../services/export_preset_service.dart';
import '../../models/invoice.dart';
import '../../models/export_preset.dart';
import '../../utils/file_download_stub.dart'
    if (dart.library.html) '../../utils/file_download_web.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/document_type_labels.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accounting_sync_panel.dart';

/// Accounting export screen — Hashavshevet, Priority, universal CSV.
class AccountingExportScreen extends StatefulWidget {
  const AccountingExportScreen({super.key});

  @override
  State<AccountingExportScreen> createState() => _AccountingExportScreenState();
}

class _AccountingExportScreenState extends State<AccountingExportScreen> {
  AccountingExportFormat _format = AccountingExportFormat.hashavshevet;
  ExportEncoding _encoding = ExportEncoding.utf8bom;
  CsvSeparator _separator = CsvSeparator.comma;
  InvoiceDocumentType? _docTypeFilter;
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _isExporting = false;
  AccountingExportResult? _lastResult;

  List<ExportPreset> _presets = ExportPreset.builtInPresets();
  ExportPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPresets());
  }

  Future<void> _loadPresets() async {
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId;
    if (companyId == null || companyId.isEmpty) return;
    final service = ExportPresetService(companyId: companyId);
    final presets = await service.getAll();
    if (mounted) setState(() => _presets = presets);
  }

  void _applyPreset(ExportPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _format = preset.format;
      _encoding = preset.encoding;
      _separator = preset.separator;
      _docTypeFilter = preset.docTypeFilter;
    });
  }

  String _formatLabel(AppLocalizations l10n, AccountingExportFormat f) {
    switch (f) {
      case AccountingExportFormat.hashavshevet:
        return l10n.exportFormatHashavshevet;
      case AccountingExportFormat.priority:
        return l10n.exportFormatPriority;
      case AccountingExportFormat.csv:
        return l10n.exportFormatCsv;
    }
  }

  String _formatDesc(AppLocalizations l10n, AccountingExportFormat f) {
    switch (f) {
      case AccountingExportFormat.hashavshevet:
        return l10n.exportFormatHashavshevetDesc;
      case AccountingExportFormat.priority:
        return l10n.exportFormatPriorityDesc;
      case AccountingExportFormat.csv:
        return l10n.exportFormatCsvDesc;
    }
  }

  String _encodingLabel(AppLocalizations l10n, ExportEncoding e) {
    switch (e) {
      case ExportEncoding.utf8bom:
        return l10n.encodingUtf8Bom;
      case ExportEncoding.utf8:
        return l10n.encodingUtf8;
      case ExportEncoding.windows1255:
        return l10n.encodingWindows1255;
    }
  }

  String _separatorLabel(AppLocalizations l10n, CsvSeparator s) {
    switch (s) {
      case CsvSeparator.comma:
        return l10n.separatorComma;
      case CsvSeparator.semicolon:
        return l10n.separatorSemicolon;
      case CsvSeparator.tab:
        return l10n.separatorTab;
    }
  }

  Future<void> _saveCurrentAsPreset() async {
    final l10n = AppLocalizations.of(context)!;
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId;
    if (companyId == null || companyId.isEmpty) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveProfileTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.profileNameLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelAction2)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: Text(l10n.savePlan),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final preset = ExportPreset(
      id: '',
      name: name,
      format: _format,
      encoding: _encoding,
      separator: _separator,
      docTypeFilter: _docTypeFilter,
    );

    final service = ExportPresetService(companyId: companyId);
    await service.save(preset);
    await _loadPresets();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.profileSaved(name)),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _doExport() async {
    final l10n = AppLocalizations.of(context)!;
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId;
    if (companyId == null || companyId.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? 'unknown';

    setState(() {
      _isExporting = true;
      _lastResult = null;
    });

    try {
      final service = AccountingExportService(companyId: companyId);
      final result = await service.export(
        fromDate: _fromDate,
        toDate: _toDate,
        exportedBy: uid,
        format: _format,
        filterDocType: _docTypeFilter,
        separator: _format == AccountingExportFormat.hashavshevet
            ? CsvSeparator.tab
            : _separator,
      );

      setState(() => _lastResult = result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportRecordsCount(
                result.recordCount, result.fileName)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.exportErrorWithDetail(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    final formats = AccountingExportFormat.values;
    final encodings = ExportEncoding.values;
    final separators = CsvSeparator.values;
    final docTypes = <InvoiceDocumentType?>[null, ...InvoiceDocumentType.values];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountingExportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: l10n.settingsSaveProfile,
            onPressed: _saveCurrentAsPreset,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (companyId.isNotEmpty) ...[
                AccountingSyncPanel(companyId: companyId),
                const SizedBox(height: 16),
              ],
              if (_presets.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      final isSelected = _selectedPreset?.id == preset.id;
                      return FilterChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onSelected: (_) => _applyPreset(preset),
                        selectedColor: Colors.deepPurple.shade100,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.targetSoftwareLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      RadioGroup<AccountingExportFormat>(
                        groupValue: _format,
                        onChanged: (AccountingExportFormat? value) {
                          if (value != null) setState(() => _format = value);
                        },
                        child: Column(
                          children: formats
                              .map((f) => ListTile(
                                    title: Text(_formatLabel(l10n, f)),
                                    subtitle: Text(_formatDesc(l10n, f)),
                                    leading: Radio<AccountingExportFormat>(
                                      value: f,
                                    ),
                                    onTap: () => setState(() => _format = f),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.periodSection,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Flex(
                        direction: narrow ? Axis.vertical : Axis.horizontal,
                        children: [
                          Expanded(
                            flex: narrow ? 0 : 1,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(true),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                  '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: narrow ? 0 : 8,
                              vertical: narrow ? 8 : 0,
                            ),
                            child: Text(l10n.untilLabel),
                          ),
                          Expanded(
                            flex: narrow ? 0 : 1,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(false),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                  '${_toDate.day}/${_toDate.month}/${_toDate.year}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.documentTypeSection,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<InvoiceDocumentType?>(
                        initialValue: _docTypeFilter,
                        items: docTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(invoiceDocTypeLabelOptional(l10n, t)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _docTypeFilter = v),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_format != AccountingExportFormat.hashavshevet) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fileSettingsSection,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CsvSeparator>(
                          initialValue: _separator,
                          items: separators
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(_separatorLabel(l10n, s)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _separator = v ?? CsvSeparator.comma),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.separatorLabel,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ExportEncoding>(
                          initialValue: _encoding,
                          items: encodings
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_encodingLabel(l10n, e)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _encoding = v ?? ExportEncoding.utf8bom),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.encodingSection,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_format == AccountingExportFormat.hashavshevet) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.encodingSection,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ExportEncoding>(
                          initialValue: _encoding,
                          items: encodings
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_encodingLabel(l10n, e)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _encoding = v ?? ExportEncoding.utf8bom),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.hashavshevetEncodingHint,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _isExporting ? null : _doExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_isExporting ? l10n.exporting : l10n.exportAction),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(l10n.exportCompleteTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.green.shade800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.fileLabel(_lastResult!.fileName)),
                        Text(l10n.recordsLabel(_lastResult!.recordCount)),
                        Text(l10n.formatLabel(
                            _formatLabel(l10n, _lastResult!.format))),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            final bytes = [
                              0xEF,
                              0xBB,
                              0xBF,
                              ...utf8.encode(_lastResult!.content)
                            ];
                            downloadFile(bytes, _lastResult!.fileName);
                          },
                          icon: const Icon(Icons.download),
                          label: Text(l10n.downloadFileBtn),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHi,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _lastResult!.content.length > 2000
                                    ? '${_lastResult!.content.substring(0, 2000)}\n...'
                                    : _lastResult!.content,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
