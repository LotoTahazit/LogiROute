import '../../widgets/column_mapping_dialog.dart';
import 'import_alias_packs.dart';
import 'import_header_intelligence.dart';
import 'import_sample_recognizer.dart';

/// Детализация confidence для одного поля.
class ConfidenceBreakdown {
  final int headerScore;
  final int sampleScore;
  final int aliasScore;
  final int positionScore;
  final int learningBoost;
  final int total;

  const ConfidenceBreakdown({
    required this.headerScore,
    required this.sampleScore,
    required this.aliasScore,
    required this.positionScore,
    required this.learningBoost,
    required this.total,
  });
}

/// Уровень уверенности для UI (зелёный / жёлтый / красный).
enum ImportConfidenceLevel { high, review, missing }

class ImportConfidenceEngine {
  static ImportConfidenceLevel levelFor({
    required TargetField field,
    required int columnIndex,
    required int confidence,
  }) {
    if (field.required && columnIndex < 0) return ImportConfidenceLevel.missing;
    if (confidence >= 85) return ImportConfidenceLevel.high;
    if (confidence >= 50) return ImportConfidenceLevel.review;
    if (field.required) return ImportConfidenceLevel.missing;
    return ImportConfidenceLevel.review;
  }

  /// Позиционные подсказки: типичный индекс колонки для поля.
  static const _positionHints = {
    'clientNumber': [0],
    'productCode': [0],
    'name': [1],
    'clientName': [1],
    'productName': [1, 2],
    'address': [2, 3],
    'phone': [3, 4],
    'quantity': [2, 3, 4],
    'vatId': [3, 4, 5],
  };

  static int _positionScore(String fieldKey, int col) {
    final hints = _positionHints[fieldKey];
    if (hints == null) return 0;
    if (hints.contains(col)) return 80;
    if (hints.any((h) => (col - h).abs() == 1)) return 50;
    return 0;
  }

  static int _headerScore(String header, TargetField field) {
    final normalizedKey = ImportHeaderIntelligence.normalize(field.key);
    var best = ImportHeaderIntelligence.headerSimilarity(header, normalizedKey);
    for (final alias in [field.key, ...field.aliases]) {
      final na = ImportHeaderIntelligence.normalize(alias);
      if (na.isEmpty) continue;
      final s = ImportHeaderIntelligence.headerSimilarity(header, na);
      if (s > best) best = s;
    }
    return best;
  }

  static int _aliasPackScore(
    String header,
    String fieldKey,
    ImportAliasPack pack,
  ) {
    var best = 0;
    for (final alias in ImportAliasPacks.aliasesFor(pack, fieldKey)) {
      final na = ImportHeaderIntelligence.normalize(alias);
      if (na.isEmpty) continue;
      final s = ImportHeaderIntelligence.headerSimilarity(header, na);
      if (s > best) best = s;
    }
    return best;
  }

  static ConfidenceBreakdown scoreCell({
    required String header,
    required int col,
    required TargetField field,
    required Map<int, Map<String, int>> sampleScores,
    required ImportAliasPack pack,
    required Map<String, String> learnedHeaders,
  }) {
    final headerScore = _headerScore(header, field);
    final aliasScore = _aliasPackScore(header, field.key, pack);
    final sampleScore = sampleScores[col]?[field.key] ?? 0;
    final positionScore = _positionScore(field.key, col);

    var learningBoost = 0;
    final learnedField = learnedHeaders[header];
    if (learnedField == field.key) learningBoost = 15;

    if (learnedField == field.key) {
      return ConfidenceBreakdown(
        headerScore: headerScore,
        sampleScore: sampleScore,
        aliasScore: aliasScore,
        positionScore: positionScore,
        learningBoost: learningBoost,
        total: 90,
      );
    }

    final total = _combine(
      headerScore,
      aliasScore,
      sampleScore,
      positionScore,
      learningBoost,
    );

    return ConfidenceBreakdown(
      headerScore: headerScore,
      sampleScore: sampleScore,
      aliasScore: aliasScore,
      positionScore: positionScore,
      learningBoost: learningBoost,
      total: total,
    );
  }

  static int _combine(
    int header,
    int alias,
    int sample,
    int position,
    int learning,
  ) {
    final peak = [header, alias, sample, position].reduce(
      (a, b) => a > b ? a : b,
    );
    if (peak >= 95) return 100;
    final blended = (header * 0.35 +
            alias * 0.25 +
            sample * 0.25 +
            position * 0.15)
        .round();
    final base = blended > peak ? blended : peak;
    return (base + learning).clamp(0, 100);
  }

  /// Обогатить поля синонимами из alias pack.
  static List<TargetField> enrichFields(
    List<TargetField> fields,
    ImportAliasPack pack,
  ) {
    return fields.map((f) {
      final extra = ImportAliasPacks.aliasesFor(pack, f.key);
      return TargetField(
        key: f.key,
        label: f.label,
        required: f.required,
        aliases: [...f.aliases, ...extra],
      );
    }).toList();
  }
}
