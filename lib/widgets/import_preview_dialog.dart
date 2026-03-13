import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Generic import preview dialog that shows parsed rows with errors
/// Returns true if user confirms import, false/null otherwise
class ImportPreviewDialog extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<ImportPreviewRow> rows;

  const ImportPreviewDialog({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
  });

  int get validCount => rows.where((r) => r.isValid).length;
  int get errorCount => rows.where((r) => !r.isValid).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorCount > 0
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      errorCount > 0 ? Icons.warning : Icons.check_circle,
                      color: errorCount > 0 ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.importPreviewTotal(
                          rows.length, validCount, errorCount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Table
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.grey.shade100),
                      columnSpacing: 16,
                      columns: [
                        const DataColumn(label: Text('#')),
                        ...columns.map((c) => DataColumn(label: Text(c))),
                        DataColumn(label: Text(l10n.importPreviewStatus)),
                      ],
                      rows: rows.map((row) {
                        return DataRow(
                          color: row.isValid
                              ? null
                              : WidgetStateProperty.all(Colors.red.shade50),
                          cells: [
                            DataCell(Text('${row.rowIndex}')),
                            ...row.values.map((v) => DataCell(Text(v,
                                maxLines: 1, overflow: TextOverflow.ellipsis))),
                            DataCell(
                              row.isValid
                                  ? const Icon(Icons.check,
                                      color: Colors.green, size: 18)
                                  : Tooltip(
                                      message: row.errors.join('\n'),
                                      child: const Icon(Icons.error,
                                          color: Colors.red, size: 18),
                                    ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          if (validCount > 0)
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.upload),
              label: Text(l10n.importRowsButton(validCount)),
            ),
        ],
      ),
    );
  }
}

/// A single row in the import preview
class ImportPreviewRow {
  final int rowIndex;
  final List<String> values;
  final List<String> errors;
  bool get isValid => errors.isEmpty;

  ImportPreviewRow({
    required this.rowIndex,
    required this.values,
    this.errors = const [],
  });
}
