import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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

  const ColumnMappingDialog({
    super.key,
    required this.sourceHeaders,
    required this.targetFields,
    required this.title,
    this.showDuplicateMode = true,
    this.sampleRows = const [],
  });

  @override
  State<ColumnMappingDialog> createState() => _ColumnMappingDialogState();
}

class _ColumnMappingDialogState extends State<ColumnMappingDialog> {
  late Map<String, int> _mapping;
  DuplicateMode _duplicateMode = DuplicateMode.skip;

  @override
  void initState() {
    super.initState();
    _mapping = {};
    _autoMap();
  }

  /// Auto-map by matching aliases to source headers
  void _autoMap() {
    final lowerHeaders = widget.sourceHeaders
        .map((h) => h.toLowerCase().replaceAll(RegExp(r'[\s*]'), ''))
        .toList();

    for (final field in widget.targetFields) {
      int bestIdx = -1;
      for (final alias in field.aliases) {
        final lowerAlias = alias.toLowerCase().replaceAll(RegExp(r'[\s*]'), '');
        for (int i = 0; i < lowerHeaders.length; i++) {
          if (lowerHeaders[i] == lowerAlias ||
              lowerHeaders[i].contains(lowerAlias) ||
              lowerAlias.contains(lowerHeaders[i])) {
            bestIdx = i;
            break;
          }
        }
        if (bestIdx >= 0) break;
      }
      _mapping[field.key] = bestIdx;
    }
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 12),
              // Mapping table
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                    },
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: [
                          _headerCell(l10n.targetField),
                          _headerCell(l10n.sourceColumn),
                          _headerCell(l10n.sampleValue),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  TableRow _buildFieldRow(TargetField field) {
    final idx = _mapping[field.key] ?? -1;
    final sampleValue = (idx >= 0 && widget.sampleRows.isNotEmpty)
        ? (idx < widget.sampleRows.first.length
            ? widget.sampleRows.first[idx]
            : '')
        : '';

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${field.label}${field.required ? " *" : ""}',
            style: TextStyle(
              color: field.required && idx < 0 ? Colors.red : null,
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
                child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
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
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateOptions(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.duplicateSkip),
          selected: _duplicateMode == DuplicateMode.skip,
          onSelected: (_) =>
              setState(() => _duplicateMode = DuplicateMode.skip),
        ),
        ChoiceChip(
          label: Text(l10n.duplicateUpdate),
          selected: _duplicateMode == DuplicateMode.update,
          onSelected: (_) =>
              setState(() => _duplicateMode = DuplicateMode.update),
        ),
        ChoiceChip(
          label: Text(l10n.duplicateAdd),
          selected: _duplicateMode == DuplicateMode.addAnyway,
          onSelected: (_) =>
              setState(() => _duplicateMode = DuplicateMode.addAnyway),
        ),
      ],
    );
  }
}
