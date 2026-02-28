import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/accounting_export_service.dart';
import '../../services/export_preset_service.dart';
import '../../models/invoice.dart';
import '../../models/export_preset.dart';

/// מסך ייצוא לתוכנות הנהלת חשבונות
/// תומך: חשבשבת, Priority, CSV אוניברסלי
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

  Future<void> _saveCurrentAsPreset() async {
    final ctx = CompanyContext.of(context);
    final companyId = ctx.effectiveCompanyId;
    if (companyId == null || companyId.isEmpty) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('שמור פרופיל'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'שם הפרופיל',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('שמור'),
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
            content: Text('פרופיל "$name" נשמר'),
            backgroundColor: Colors.green),
      );
    }
  }

  static const _formatLabels = {
    AccountingExportFormat.hashavshevet: 'חשבשבת',
    AccountingExportFormat.priority: 'Priority ERP',
    AccountingExportFormat.csv: 'CSV אוניברסלי',
  };

  static const _formatDescriptions = {
    AccountingExportFormat.hashavshevet:
        'קובץ טקסט עם טאבים — תואם לייבוא חשבשבת',
    AccountingExportFormat.priority: 'קובץ CSV תואם לייבוא Priority',
    AccountingExportFormat.csv: 'קובץ CSV אוניברסלי — מתאים לכל תוכנה',
  };

  static const _encodingLabels = {
    ExportEncoding.utf8bom: 'UTF-8 + BOM (מומלץ לאקסל)',
    ExportEncoding.utf8: 'UTF-8 (ללא BOM)',
    ExportEncoding.windows1255: 'Windows-1255 (חשבשבת ישן)',
  };

  static const _separatorLabels = {
    CsvSeparator.comma: 'פסיק (,)',
    CsvSeparator.semicolon: 'נקודה-פסיק (;)',
    CsvSeparator.tab: 'טאב',
  };

  static const _docTypeLabels = {
    null: 'הכל',
    InvoiceDocumentType.invoice: 'חשבונית מס',
    InvoiceDocumentType.taxInvoiceReceipt: 'חשבונית מס/קבלה',
    InvoiceDocumentType.receipt: 'קבלה',
    InvoiceDocumentType.delivery: 'תעודת משלוח',
    InvoiceDocumentType.creditNote: 'זיכוי',
  };

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('he'),
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

      setState(() {
        _lastResult = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ייצוא הושלם — ${result.recordCount} רשומות (${result.fileName})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה בייצוא: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ייצוא להנהלת חשבונות'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'שמור פרופיל',
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
              // Preset quick-select
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

              // Format selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('תוכנת יעד',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ..._formatLabels.entries
                          .map((e) => RadioListTile<AccountingExportFormat>(
                                title: Text(e.value),
                                subtitle:
                                    Text(_formatDescriptions[e.key] ?? ''),
                                value: e.key,
                                groupValue: _format,
                                onChanged: (v) => setState(() => _format = v!),
                              )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Period selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('תקופה',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(true),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                  '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('עד'),
                          ),
                          Expanded(
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

              // Document type filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('סוג מסמך',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<InvoiceDocumentType?>(
                        value: _docTypeFilter,
                        items: _docTypeLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
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

              // Encoding & Separator (only for CSV/Priority)
              if (_format != AccountingExportFormat.hashavshevet) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('הגדרות קובץ',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        // Separator
                        DropdownButtonFormField<CsvSeparator>(
                          value: _separator,
                          items: _separatorLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _separator = v ?? CsvSeparator.comma),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'מפריד',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Encoding
                        DropdownButtonFormField<ExportEncoding>(
                          value: _encoding,
                          items: _encodingLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _encoding = v ?? ExportEncoding.utf8bom),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'קידוד',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Encoding for Hashavshevet
              if (_format == AccountingExportFormat.hashavshevet) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('קידוד',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ExportEncoding>(
                          value: _encoding,
                          items: _encodingLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
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
                          'לגרסאות ישנות של חשבשבת — בחר Windows-1255',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Export button
              FilledButton.icon(
                onPressed: _isExporting ? null : _doExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'מייצא...' : 'ייצוא'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              // Result preview
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
                            Text('ייצוא הושלם',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.green.shade800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('קובץ: ${_lastResult!.fileName}'),
                        Text('רשומות: ${_lastResult!.recordCount}'),
                        Text('פורמט: ${_formatLabels[_lastResult!.format]}'),
                        const SizedBox(height: 12),
                        // Preview first lines
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
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
