import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/import/import_column_matcher.dart';
import '../services/import/import_confidence_engine.dart';
import '../theme/app_theme.dart';
import 'logi_route_tab_bar.dart';

/// Result of column mapping
class ColumnMapping {
  /// Map of targetField → sourceColumnIndex (-1 = not mapped)
  final Map<String, int> mapping;

  /// Duplicate handling mode
  final DuplicateMode duplicateMode;

  ColumnMapping({required this.mapping, required this.duplicateMode});
}

enum DuplicateMode { skip, update, addAnyway }

/// Target field definition
class TargetField {
  final String key;
  final String label;
  final bool required;

  /// Known aliases for auto-mapping (Hebrew, English, Priority field names)
  final List<String> aliases;

  const TargetField({
    required this.key,
    required this.label,
    this.required = false,
    this.aliases = const [],
  });
}

/// Dialog for mapping source columns to target fields
class ColumnMappingDialog extends StatefulWidget {
  final List<String> sourceHeaders;
  final List<TargetField> targetFields;
  final String title;
  final bool showDuplicateMode;

  /// First few rows for preview
  final List<List<String>> sampleRows;

  /// Show confidence % column (import wizard)
  final bool showConfidence;

  /// Pre-computed confidence per field key
  final Map<String, int>? confidenceByField;

  const ColumnMappingDialog({
    super.key,
    required this.sourceHeaders,
    required this.targetFields,
    required this.title,
    this.showDuplicateMode = true,
    this.sampleRows = const [],
    this.showConfidence = false,
    this.confidenceByField,
  });

  @override
  State<ColumnMappingDialog> createState() => _ColumnMappingDialogState();
}

class _ColumnMappingDialogState extends State<ColumnMappingDialog> {
  late Map<String, int> _mapping;
  late Map<String, int> _confidence;
  List<int> _unusedColumns = [];
  DuplicateMode _duplicateMode = DuplicateMode.skip;

  @override
  void initState() {
    super.initState();
    _mapping = {};
    _confidence = {};
    _autoMap();
  }

  /// Auto-map via ImportColumnMatcher (exact → synonym → fuzzy).
  void _autoMap() {
    final suggestion = ImportColumnMatcher.suggestMapping(
      sourceHeaders: widget.sourceHeaders,
      targetFields: widget.targetFields,
      sampleRows: widget.sampleRows,
    );
    _mapping = suggestion.mapping;
    _confidence = widget.confidenceByField ?? suggestion.confidenceByField;
    _unusedColumns = suggestion.unusedColumnIndexes;
  }

  bool get _isValid {
    for (final field in widget.targetFields) {
      if (field.required && (_mapping[field.key] ?? -1) < 0) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.columnMappingHint,
                  style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              const SizedBox(height: 12),
              // Mapping table
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(3),
                      2: const FlexColumnWidth(2),
                      if (widget.showConfidence) 3: const FlexColumnWidth(1),
                    },
                    border: TableBorder.all(
                        color: AppTheme.muted.withValues(alpha: 0.22)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.surfaceHi),
                        children: [
                          _headerCell(l10n.targetField),
                          _headerCell(l10n.sourceColumn),
                          _headerCell(l10n.sampleValue),
                          if (widget.showConfidence) _headerCell('%'),
                        ],
                      ),
                      ...widget.targetFields.map(_buildFieldRow),
                    ],
                  ),
                ),
              ),
              if (widget.showDuplicateMode) ...[
                const SizedBox(height: 16),
                Text(l10n.duplicateHandling,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDuplicateOptions(l10n),
              ],
              if (_unusedColumns.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.importWizardUnusedColumns,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _unusedColumns
                      .map((i) => Chip(
                            label: Text(widget.sourceHeaders[i],
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _isValid
                ? () => Navigator.pop(
                    context,
                    ColumnMapping(
                      mapping: Map.from(_mapping),
                      duplicateMode: _duplicateMode,
                    ))
                : null,
            child: Text(l10n.continueImport),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.text)),
    );
  }

  TableRow _buildFieldRow(TargetField field) {
    final idx = _mapping[field.key] ?? -1;
    final sampleValue = (idx >= 0 && widget.sampleRows.isNotEmpty)
        ? (idx < widget.sampleRows.first.length
            ? widget.sampleRows.first[idx]
            : '')
        : '';
    final conf = _confidence[field.key] ?? 0;
    final level = ImportConfidenceEngine.levelFor(
      field: field,
      columnIndex: idx,
      confidence: conf,
    );
    final confColor = _importConfLevelColor(level);

    return TableRow(
      decoration: widget.showConfidence
          ? _importConfRowDecoration(level, idx)
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${field.label}${field.required ? " *" : ""}',
            style: TextStyle(
              color: level == ImportConfidenceLevel.missing
                  ? AppTheme.danger
                  : AppTheme.text,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: DropdownButton<int>(
            value: idx,
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: -1,
                child: Text('—', style: TextStyle(color: AppTheme.muted)),
              ),
              ...widget.sourceHeaders.asMap().entries.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
            ],
            onChanged: (v) => setState(() => _mapping[field.key] = v ?? -1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            sampleValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ),
        if (widget.showConfidence)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '$conf',
              style: TextStyle(
                color: confColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDuplicateOptions(AppLocalizations l10n) {
    return LogiRoutePillSelector(
      labels: [l10n.duplicateSkip, l10n.duplicateUpdate, l10n.duplicateAdd],
      selectedIndex: DuplicateMode.values.indexOf(_duplicateMode),
      onSelected: (i) =>
          setState(() => _duplicateMode = DuplicateMode.values[i]),
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
