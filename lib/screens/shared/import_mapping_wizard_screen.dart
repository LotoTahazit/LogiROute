import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/import_wizard_type.dart';
import '../../models/saved_import_mapping.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/import/import_column_matcher.dart';
import '../../services/import/import_confidence_engine.dart';
import '../../services/import/import_alias_packs.dart';
import '../../services/import/import_mapping_learning.dart';
import '../../services/import/import_header_intelligence.dart';
import '../../services/import/import_field_registry.dart';
import '../../services/import/import_mapping_repository.dart';
import '../../services/import/import_row_parser.dart';
import '../../services/import/import_wizard_executor.dart';
import '../../services/import_file_parser.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_download.dart';
import '../../widgets/column_mapping_dialog.dart';
import '../../widgets/logi_route_tab_bar.dart';
import '../../services/company_remote_config_service.dart';
import '../../models/company_remote_config.dart';

/// 7-шаговый мастер импорта с mapping и сохранением шаблонов.
class ImportMappingWizardScreen extends StatefulWidget {
  final ImportWizardType? initialType;

  const ImportMappingWizardScreen({super.key, this.initialType});

  @override
  State<ImportMappingWizardScreen> createState() =>
      _ImportMappingWizardScreenState();
}

class _ImportMappingWizardScreenState extends State<ImportMappingWizardScreen> {
  int _step = 0;
  ImportWizardType? _type;
  ParsedFileData? _fileData;
  Map<String, int> _mapping = {};
  Map<String, int> _confidence = {};
  Map<String, ConfidenceBreakdown> _breakdown = {};
  List<int> _unusedColumns = [];
  ImportAliasPack _detectedPack = ImportAliasPack.excelGeneric;
  Map<String, String> _learnedHeaders = {};
  DuplicateMode _duplicateMode = DuplicateMode.skip;
  SavedImportMapping? _savedMatch;
  bool _importing = false;
  ImportWizardResult? _result;
  String? _fileError;
  int _previewRows = CompanyRemoteConfig.defaults.importPreviewRows;

  bool _previewRowsLoaded = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_type != null) _step = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_previewRowsLoaded) {
      _previewRowsLoaded = true;
      _loadPreviewRows();
    }
  }

  Future<void> _loadPreviewRows() async {
    final cid = _companyId;
    if (cid.isEmpty) return;
    final rc = await CompanyRemoteConfigService().get(cid);
    if (mounted) setState(() => _previewRows = rc.importPreviewRows);
  }

  String get _companyId =>
      CompanyContext.of(context).effectiveCompanyId ?? '';

  List<TargetField> _fields(AppLocalizations l10n) =>
      ImportFieldRegistry.fieldsFor(_type!, l10n);

  bool get _mappingValid {
    if (_type == null) return false;
    for (final f in _fields(AppLocalizations.of(context)!)) {
      if (!f.required) continue;
      if ((_mapping[f.key] ?? -1) < 0) return false;
    }
    if (_type == ImportWizardType.deliveryPoints) {
      final hasClient = (_mapping['clientName'] ?? -1) >= 0 ||
          (_mapping['clientNumber'] ?? -1) >= 0;
      final hasAddr = (_mapping['address'] ?? -1) >= 0 ||
          (_mapping['deliveryAddressOverride'] ?? -1) >= 0;
      return hasClient && hasAddr;
    }
    return true;
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    final pick = await ImportFileParser.pickSpreadsheet();
    if (!mounted) return;
    if (pick.error == 'cancelled') return;
    if (pick.error != null || pick.data == null) {
      setState(() {
        _fileError = pick.error == 'read_failed'
            ? l10n.importFileReadFailed
            : l10n.importFileParseFailed;
      });
      return;
    }
    setState(() {
      _fileData = pick.data;
      _fileError = null;
      _step = 2;
    });
    await _loadLearnedHeaders();
    await _suggestSavedMapping();
  }

  Future<void> _suggestSavedMapping() async {
    if (_type == null || _fileData == null || _companyId.isEmpty) return;
    final repo = ImportMappingRepository(companyId: _companyId);
    final match =
        await repo.findBestMatch(_fileData!.headers, _type!);
    if (!mounted || match == null) return;
  setState(() => _savedMatch = match);
  }

  void _applyAutoMapping() {
    if (_fileData == null || _type == null) return;
    final l10n = AppLocalizations.of(context)!;
    final suggestion = ImportColumnMatcher.suggestMapping(
      sourceHeaders: _fileData!.headers,
      targetFields: _fields(l10n),
      sampleRows: _fileData!.rows,
      learnedHeaders: _learnedHeaders,
    );
    setState(() {
      _mapping = suggestion.mapping;
      _confidence = suggestion.confidenceByField;
      _breakdown = suggestion.breakdownByField;
      _unusedColumns = suggestion.unusedColumnIndexes;
      _detectedPack = suggestion.detectedPack;
    });
  }

  Future<void> _loadLearnedHeaders() async {
    if (_companyId.isEmpty || _type == null) return;
    final learned = await ImportMappingLearning(companyId: _companyId)
        .loadLearnedHeaders(_type!);
    if (mounted) setState(() => _learnedHeaders = learned);
  }

  Future<void> _onMappingChanged(TargetField field, int? col) async {
    final prev = _mapping[field.key] ?? -1;
    setState(() => _mapping[field.key] = col ?? -1);
    if (col == null || col < 0 || _type == null || _fileData == null) return;
    if (col == prev) return;
    final header = _fileData!.headers[col];
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ImportMappingLearning(companyId: _companyId).recordCorrection(
      importType: _type!,
      originalHeader: header,
      fieldKey: field.key,
      uid: uid,
    );
    _learnedHeaders[ImportHeaderIntelligence.normalize(header)] = field.key;
  }

  void _applySavedMapping() {
    if (_savedMatch == null || _fileData == null) return;
    final headers = _fileData!.headers;
    final remapped = <String, int>{};
    for (final entry in _savedMatch!.mapping.entries) {
      final col = entry.value;
      if (col >= 0 && col < headers.length) {
        remapped[entry.key] = col;
      } else {
        remapped[entry.key] = -1;
      }
    }
    setState(() {
      _mapping = remapped;
      _confidence = {};
    });
  }

  List<dynamic> _parsedRows() {
    if (_fileData == null || _type == null) return [];
    return ImportRowParser.parseRows(
      type: _type!,
      rows: _fileData!.rows,
      mapping: _mapping,
    );
  }

  Future<void> _runImport() async {
    if (_fileData == null || _type == null || _companyId.isEmpty) return;
    setState(() {
      _importing = true;
      _step = 5;
    });
    final auth = context.read<AuthService>();
    final result = await ImportWizardExecutor.execute(
      type: _type!,
      rows: _fileData!.rows,
      mapping: _mapping,
      companyId: _companyId,
      duplicateMode: _duplicateMode,
      userId: FirebaseAuth.instance.currentUser?.uid,
      role: auth.userModel?.role,
    );
    if (!mounted) return;
    setState(() {
      _importing = false;
      _result = result;
      _step = 6;
    });
    if (_savedMatch != null) {
      await ImportMappingRepository(companyId: _companyId)
          .markUsed(_savedMatch!.id);
    }
    await _offerSaveTemplate();
  }

  Future<void> _offerSaveTemplate() async {
    if (_result == null || _result!.imported == 0 && _result!.updated == 0) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importWizardSaveTemplate),
        content: Text(l10n.importWizardSaveTemplateHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
    final nameCtrl = TextEditingController(
      text: _fileData?.fileName ?? l10n.importWizardTemplateDefaultName,
    );
    final named = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importWizardTemplateName),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l10n.importWizardTemplateName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (named == null || named.isEmpty || _type == null || _fileData == null) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    await ImportMappingRepository(companyId: _companyId).save(
      SavedImportMapping(
        id: '',
        companyId: _companyId,
        importType: _type!,
        name: named,
        sourceHeaders: _fileData!.headers,
        mapping: _mapping,
        createdAt: now,
        updatedAt: now,
        createdBy: uid,
      ),
    );
  }

  void _next() {
    if (_step == 2) {
      _applyAutoMapping();
      setState(() => _step = 3);
    } else if (_step == 3 && _mappingValid) {
      setState(() => _step = 4);
    } else if (_step == 4) {
      _runImport();
    } else if (_step == 0 && _type != null) {
      setState(() => _step = 1);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.importWizardTitle)),
        body: Stepper(
          currentStep: _step.clamp(0, 6),
          onStepContinue: _canContinue() ? _next : null,
          onStepCancel: _step > 0 ? _back : null,
          controlsBuilder: (ctx, details) {
            if (_step >= 5) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_step > 0 && _step < 5)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.importWizardBack),
                    ),
                  const SizedBox(width: 8),
                  if (_step < 5)
                    FilledButton(
                      onPressed: _canContinue() ? details.onStepContinue : null,
                      child: Text(_step == 4 ? l10n.importWizardRun : l10n.next),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(l10n.importWizardStepType),
              isActive: _step == 0,
              state: _step > 0 ? StepState.complete : StepState.indexed,
              content: _buildTypeStep(l10n),
            ),
            Step(
              title: Text(l10n.importWizardStepFile),
              isActive: _step == 1,
              state: _step > 1 ? StepState.complete : StepState.indexed,
              content: _buildFileStep(l10n),
            ),
            Step(
              title: Text(l10n.importWizardStepHeaders),
              isActive: _step == 2,
              state: _step > 2 ? StepState.complete : StepState.indexed,
              content: _buildHeadersStep(l10n),
            ),
            Step(
              title: Text(l10n.importWizardStepMapping),
              isActive: _step == 3,
              state: _step > 3 ? StepState.complete : StepState.indexed,
              content: _buildMappingStep(l10n),
            ),
            Step(
              title: Text(l10n.importWizardStepPreview),
              isActive: _step == 4,
              state: _step > 4 ? StepState.complete : StepState.indexed,
              content: _buildPreviewStep(l10n),
            ),
            Step(
              title: Text(l10n.importWizardStepImport),
              isActive: _step == 5,
              state: _step > 5 ? StepState.complete : StepState.indexed,
              content: _importing
                  ? const Center(child: CircularProgressIndicator())
                  : Text(l10n.importWizardImporting),
            ),
            Step(
              title: Text(l10n.importWizardStepResult),
              isActive: _step == 6,
              state: _step == 6 ? StepState.complete : StepState.indexed,
              content: _result == null
                  ? const SizedBox.shrink()
                  : _buildResultStep(l10n),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _type != null;
      case 1:
        return _fileData != null;
      case 2:
        return true;
      case 3:
        return _mappingValid;
      case 4:
        return _parsedRows().any(ImportRowParser.rowIsValid);
      default:
        return false;
    }
  }

  Widget _buildTypeStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ImportWizardType.values.map((t) {
        return RadioListTile<ImportWizardType>(
          value: t,
          groupValue: _type,
          title: Text(_typeLabel(l10n, t)),
          onChanged: (v) => setState(() {
            _type = v;
            _step = 1;
          }),
        );
      }).toList(),
    );
  }

  String _typeLabel(AppLocalizations l10n, ImportWizardType t) =>
      switch (t) {
        ImportWizardType.clients => l10n.importWizardTypeClients,
        ImportWizardType.products => l10n.importWizardTypeProducts,
        ImportWizardType.deliveryPoints => l10n.importWizardTypeDeliveryPoints,
      };

  Widget _buildFileStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.importWizardFileHint),
        const SizedBox(height: 12),
        if (_fileError != null)
          Text(_fileError!, style: const TextStyle(color: Colors.red)),
        if (_fileData != null)
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(_fileData!.fileName),
            subtitle: Text(
              l10n.importWizardFileSummary(
                _fileData!.headers.length,
                _fileData!.rows.length,
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(l10n.importWizardPickFile),
        ),
      ],
    );
  }

  Widget _buildHeadersStep(AppLocalizations l10n) {
    if (_fileData == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.importWizardHeadersFound(_fileData!.headers.length)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _fileData!.headers
              .map((h) => Chip(label: Text(h, style: const TextStyle(fontSize: 12))))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMappingStep(AppLocalizations l10n) {
    if (_fileData == null || _type == null) return const SizedBox.shrink();
    final fields = _fields(l10n);
    final packLabel = ImportAliasPacks.packLabels[_detectedPack] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_detectedPack != ImportAliasPack.excelGeneric)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.importWizardDetectedPack(packLabel),
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
        if (_savedMatch != null)
          Card(
            color: AppTheme.surfaceHi,
            child: ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(l10n.importWizardUseSavedMapping),
              subtitle: Text(_savedMatch!.name),
              trailing: TextButton(
                onPressed: _applySavedMapping,
                child: Text(l10n.importWizardApply),
              ),
            ),
          ),
        Text(l10n.columnMappingHint,
            style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1),
              },
              border: TableBorder.all(
                  color: AppTheme.muted.withValues(alpha: 0.22)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.surfaceHi),
                  children: [
                    _cell(l10n.targetField, bold: true),
                    _cell(l10n.sourceColumn, bold: true),
                    _cell(l10n.sampleValue, bold: true),
                    _cell(l10n.importWizardConfidence, bold: true),
                  ],
                ),
                ...fields.map((f) => _mappingRow(f, l10n)),
              ],
            ),
          ),
        ),
        if (_unusedColumns.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.importWizardUnusedColumns,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _unusedColumns
                .map((i) => Chip(
                      label: Text(
                        _fileData!.headers[i],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ))
                .toList(),
          ),
        ],
        if (_type == ImportWizardType.clients) ...[
          const SizedBox(height: 12),
          Text(l10n.duplicateHandling,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          LogiRoutePillSelector(
            labels: [l10n.duplicateSkip, l10n.duplicateUpdate, l10n.duplicateAdd],
            selectedIndex: DuplicateMode.values.indexOf(_duplicateMode),
            onSelected: (i) =>
                setState(() => _duplicateMode = DuplicateMode.values[i]),
          ),
        ],
      ],
    );
  }

  TableRow _mappingRow(TargetField field, AppLocalizations l10n) {
    final idx = _mapping[field.key] ?? -1;
    final sample = (idx >= 0 && _fileData!.rows.isNotEmpty)
        ? (idx < _fileData!.rows.first.length ? _fileData!.rows.first[idx] : '')
        : '';
    final conf = _confidence[field.key] ?? 0;
    final level = ImportConfidenceEngine.levelFor(
      field: field,
      columnIndex: idx,
      confidence: conf,
    );
    final levelColor = _importConfLevelColor(level);
    return TableRow(
      decoration: _importConfRowDecoration(level, idx),
      children: [
        _cell(
          '${field.label}${field.required ? " *" : ""}',
          color: level == ImportConfidenceLevel.missing ? AppTheme.danger : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: DropdownButton<int>(
            value: idx,
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: -1, child: Text('—')),
              ..._fileData!.headers.asMap().entries.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
            ],
            onChanged: (v) => _onMappingChanged(field, v),
          ),
        ),
        _cell(sample),
        _cell('$conf', color: levelColor),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : null,
          color: color ?? (bold ? AppTheme.text : null),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPreviewStep(AppLocalizations l10n) {
    final rows = _parsedRows().take(_previewRows).toList();
    final valid = rows.where(ImportRowParser.rowIsValid).length;
    final err = rows.length - valid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.importPreviewTotal(rows.length, valid, err),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];
              final ok = ImportRowParser.rowIsValid(r);
              final errs = ImportRowParser.rowErrors(r);
              final hasWarnings = !ok && errs.any((e) => !e.contains('*'));
              final iconColor = ok
                  ? Colors.green
                  : hasWarnings
                      ? Colors.orange
                      : Colors.red;
              return ListTile(
                dense: true,
                tileColor: ok
                    ? Colors.green.withValues(alpha: 0.05)
                    : hasWarnings
                        ? Colors.orange.withValues(alpha: 0.05)
                        : Colors.red.withValues(alpha: 0.05),
                leading: Icon(
                  ok ? Icons.check_circle : Icons.warning,
                  color: iconColor,
                  size: 18,
                ),
                title: Text('№ ${ImportRowParser.rowIndex(r)}'),
                subtitle: errs.isNotEmpty ? Text(errs.join('; ')) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep(AppLocalizations l10n) {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.importWizardImported}: ${r.imported}'),
        if (r.updated > 0) Text('${l10n.importWizardUpdated}: ${r.updated}'),
        if (r.skipped > 0) Text('${l10n.importWizardSkipped}: ${r.skipped}'),
        if (r.errors.isNotEmpty) ...[
          Text('${l10n.importWizardErrors}: ${r.errors.length}'),
          const SizedBox(height: 8),
          if (r.errorCsv != null)
            TextButton.icon(
              onPressed: () => downloadFile(r.errorCsv!, 'import_errors.csv'),
              icon: const Icon(Icons.download),
              label: Text(l10n.importWizardDownloadErrors),
            ),
        ],
      ],
    );
  }
}

Color _importConfLevelColor(ImportConfidenceLevel level) => switch (level) {
      ImportConfidenceLevel.high => AppTheme.green,
      ImportConfidenceLevel.review => AppTheme.warning,
      ImportConfidenceLevel.missing => AppTheme.danger,
    };

BoxDecoration? _importConfRowDecoration(ImportConfidenceLevel level, int idx) {
  if (level == ImportConfidenceLevel.missing) {
    return BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.10));
  }
  if (idx >= 0 && level == ImportConfidenceLevel.high) {
    return BoxDecoration(color: AppTheme.green.withValues(alpha: 0.10));
  }
  if (level == ImportConfidenceLevel.review) {
    return BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.10));
  }
  if (idx < 0) {
    return BoxDecoration(color: AppTheme.muted.withValues(alpha: 0.08));
  }
  return null;
}
