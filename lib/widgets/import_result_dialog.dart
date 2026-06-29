import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/import/import_wizard_executor.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';

/// Диалог результата импорта с опцией скачать CSV ошибок.
class ImportResultDialog extends StatelessWidget {
  final ImportWizardResult result;

  const ImportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(l10n.importWizardResultTitle),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow(Icons.add_circle_outline, Colors.green,
                  l10n.importWizardImported, result.imported),
              if (result.updated > 0)
                _statRow(Icons.edit, Colors.blue, l10n.importWizardUpdated,
                    result.updated),
              if (result.skipped > 0)
                _statRow(Icons.skip_next, AppTheme.muted,
                    l10n.importWizardSkipped, result.skipped),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                _statRow(Icons.error_outline, Colors.red,
                    l10n.importWizardErrors, result.errors.length),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: result.errors.length.clamp(0, 10),
                    itemBuilder: (_, i) => Text(
                      result.errors[i],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (result.errorCsv != null)
            TextButton.icon(
              onPressed: () => downloadFile(
                result.errorCsv!,
                'import_errors.csv',
              ),
              icon: const Icon(Icons.download),
              label: Text(l10n.importWizardDownloadErrors),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text('$label: $count', style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
