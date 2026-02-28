import '../services/accounting_export_service.dart';
import '../models/invoice.dart';

/// Сохранённый пресет экспорта.
/// Хранится в companies/{companyId}/export_presets/{presetId}
class ExportPreset {
  final String id;
  final String name; // "חשבשבת ישן", "Priority CSV", "Excel אוניברסלי"
  final AccountingExportFormat format;
  final ExportEncoding encoding;
  final CsvSeparator separator;
  final InvoiceDocumentType? docTypeFilter;
  final bool isDefault;

  ExportPreset({
    required this.id,
    required this.name,
    required this.format,
    this.encoding = ExportEncoding.utf8bom,
    this.separator = CsvSeparator.comma,
    this.docTypeFilter,
    this.isDefault = false,
  });

  factory ExportPreset.fromMap(Map<String, dynamic> map, String id) {
    return ExportPreset(
      id: id,
      name: map['name'] ?? '',
      format: AccountingExportFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => AccountingExportFormat.csv,
      ),
      encoding: ExportEncoding.values.firstWhere(
        (e) => e.name == map['encoding'],
        orElse: () => ExportEncoding.utf8bom,
      ),
      separator: CsvSeparator.values.firstWhere(
        (e) => e.name == map['separator'],
        orElse: () => CsvSeparator.comma,
      ),
      docTypeFilter: map['docTypeFilter'] != null
          ? InvoiceDocumentType.values.firstWhere(
              (e) => e.name == map['docTypeFilter'],
              orElse: () => InvoiceDocumentType.invoice,
            )
          : null,
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'format': format.name,
        'encoding': encoding.name,
        'separator': separator.name,
        if (docTypeFilter != null) 'docTypeFilter': docTypeFilter!.name,
        'isDefault': isDefault,
      };

  /// Built-in presets (не сохраняются в Firestore)
  static List<ExportPreset> builtInPresets() => [
        ExportPreset(
          id: '_hashavshevet_old',
          name: 'חשבשבת ישן (1255 + TAB)',
          format: AccountingExportFormat.hashavshevet,
          encoding: ExportEncoding.windows1255,
          separator: CsvSeparator.tab,
        ),
        ExportPreset(
          id: '_hashavshevet_new',
          name: 'חשבשבת חדש (UTF-8 + TAB)',
          format: AccountingExportFormat.hashavshevet,
          encoding: ExportEncoding.utf8bom,
          separator: CsvSeparator.tab,
        ),
        ExportPreset(
          id: '_priority',
          name: 'Priority ERP',
          format: AccountingExportFormat.priority,
          encoding: ExportEncoding.utf8bom,
          separator: CsvSeparator.comma,
        ),
        ExportPreset(
          id: '_excel',
          name: 'Excel אוניברסלי',
          format: AccountingExportFormat.csv,
          encoding: ExportEncoding.utf8bom,
          separator: CsvSeparator.comma,
        ),
        ExportPreset(
          id: '_excel_semicolon',
          name: 'Excel (נקודה-פסיק)',
          format: AccountingExportFormat.csv,
          encoding: ExportEncoding.utf8bom,
          separator: CsvSeparator.semicolon,
        ),
      ];
}
