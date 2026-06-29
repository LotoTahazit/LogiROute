import '../../widgets/column_mapping_dialog.dart';
import 'import_alias_packs.dart';
import 'import_confidence_engine.dart';
import 'import_header_intelligence.dart';
import 'import_sample_recognizer.dart';

/// Результат сопоставления одной колонки файла с полем LogiRoute.
class FieldColumnMatch {
  final int columnIndex;
  final int confidence;

  const FieldColumnMatch({required this.columnIndex, required this.confidence});

  bool get isAutoMapped => columnIndex >= 0 && confidence >= 70;
}

/// Результат auto-map для всех полей (Universal Import Engine v2).
class ImportMappingSuggestion {
  final Map<String, int> mapping;
  final Map<String, int> confidenceByField;
  final Map<String, ConfidenceBreakdown> breakdownByField;
  final List<int> unusedColumnIndexes;
  final ImportAliasPack detectedPack;

  const ImportMappingSuggestion({
    required this.mapping,
    required this.confidenceByField,
    this.breakdownByField = const {},
    this.unusedColumnIndexes = const [],
    this.detectedPack = ImportAliasPack.excelGeneric,
  });
}

/// Сопоставление заголовков Excel/CSV с полями LogiRoute.
class ImportColumnMatcher {
  /// @deprecated Используйте [ImportHeaderIntelligence.normalize].
  static String normalize(String raw) => ImportHeaderIntelligence.normalize(raw);

  static ImportMappingSuggestion suggestMapping({
    required List<String> sourceHeaders,
    required List<TargetField> targetFields,
    List<List<String>> sampleRows = const [],
    ImportAliasPack? aliasPack,
    Map<String, String> learnedHeaders = const {},
  }) {
    final pack = aliasPack ?? ImportAliasPacks.detectPack(sourceHeaders);
    final fields = ImportConfidenceEngine.enrichFields(targetFields, pack);
    final normalizedHeaders =
        sourceHeaders.map(ImportHeaderIntelligence.normalize).toList();
    final sampleScores = ImportSampleRecognizer.scoreAllColumns(
      sampleRows.take(ImportSampleRecognizer.maxSampleRows).toList(),
    );
    final usedColumns = <int>{};
    final mapping = <String, int>{};
    final confidence = <String, int>{};
    final breakdown = <String, ConfidenceBreakdown>{};

    final fieldsSorted = [...fields]
      ..sort((a, b) {
        if (a.required == b.required) return 0;
        return a.required ? -1 : 1;
      });

    for (final field in fieldsSorted) {
      final best = _bestMatchForField(
        field: field,
        sourceHeaders: sourceHeaders,
        normalizedHeaders: normalizedHeaders,
        sampleScores: sampleScores,
        pack: pack,
        learnedHeaders: learnedHeaders,
        usedColumns: usedColumns,
      );
      mapping[field.key] = best.columnIndex;
      confidence[field.key] = best.confidence;
      if (best.breakdown != null) {
        breakdown[field.key] = best.breakdown!;
      }
      if (best.columnIndex >= 0 && best.confidence >= 70) {
        usedColumns.add(best.columnIndex);
      }
    }

    final unused = <int>[];
    for (var i = 0; i < sourceHeaders.length; i++) {
      if (!usedColumns.contains(i)) unused.add(i);
    }

    return ImportMappingSuggestion(
      mapping: mapping,
      confidenceByField: confidence,
      breakdownByField: breakdown,
      unusedColumnIndexes: unused,
      detectedPack: pack,
    );
  }

  static _MatchResult _bestMatchForField({
    required TargetField field,
    required List<String> sourceHeaders,
    required List<String> normalizedHeaders,
    required Map<int, Map<String, int>> sampleScores,
    required ImportAliasPack pack,
    required Map<String, String> learnedHeaders,
    required Set<int> usedColumns,
  }) {
    _MatchResult? best;

    for (var col = 0; col < normalizedHeaders.length; col++) {
      if (usedColumns.contains(col)) continue;
      final header = normalizedHeaders[col];
      if (header.isEmpty) continue;

      final bd = ImportConfidenceEngine.scoreCell(
        header: header,
        col: col,
        field: field,
        sampleScores: sampleScores,
        pack: pack,
        learnedHeaders: learnedHeaders,
      );
      if (bd.total <= 0) continue;

      final candidate = _MatchResult(
        columnIndex: col,
        confidence: bd.total,
        breakdown: bd,
      );
      if (best == null || candidate.confidence > best.confidence) {
        best = candidate;
      }
    }

    return best ??
        const _MatchResult(columnIndex: -1, confidence: 0, breakdown: null);
  }

  /// Похожесть двух наборов заголовков (0..1) для сохранённого mapping.
  static double headersSimilarity(List<String> a, List<String> b) =>
      ImportHeaderIntelligence.headersSimilarity(a, b);
}

class _MatchResult {
  final int columnIndex;
  final int confidence;
  final ConfidenceBreakdown? breakdown;

  const _MatchResult({
    required this.columnIndex,
    required this.confidence,
    required this.breakdown,
  });
}
