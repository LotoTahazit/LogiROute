/// Результат анализа sample-данных колонки.
class SampleColumnGuess {
  final String fieldKey;
  final int confidence;

  const SampleColumnGuess({required this.fieldKey, required this.confidence});
}

/// Распознавание типа колонки по первым N строкам (без заголовка).
class ImportSampleRecognizer {
  static const maxSampleRows = 20;

  static final _phoneRe = RegExp(r'^(\+972|0)(5\d{8}|[23489]\d{7})$');
  static final _vatRe = RegExp(r'^\d{8,9}$');
  static final _skuRe = RegExp(r'^[A-Za-z0-9\-]{3,20}$');
  static final _dateRe = RegExp(r'^\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}$');
  static final _coordRe = RegExp(r'^-?\d{1,3}(\.\d+)?$');
  static final _addressRe = RegExp(
    r'(רח|רחוב|שדר|כתובת|ул\.?|street|st\.?|avenue|ave|пр\.?|пер\.?)',
    caseSensitive: false,
  );
  static final _companyRe = RegExp(
    r'(בע"מ|בע״מ|ltd|llc|ooo|ооо|зао|ип|inc|corp|חברה|компания)',
    caseSensitive: false,
  );
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Оценки fieldKey → confidence (0..100) для одной колонки.
  static Map<String, int> scoreColumn(List<String> cells) {
    final samples = cells
        .where((c) => c.trim().isNotEmpty)
        .take(maxSampleRows)
        .map((c) => c.trim())
        .toList();
    if (samples.isEmpty) return const {};

    final n = samples.length;
    final scores = <String, int>{};

    int ratio(bool Function(String) test) =>
        (samples.where(test).length * 100 / n).round();

    final phoneR = ratio((s) => _phoneRe.hasMatch(s.replaceAll(RegExp(r'[\s\-]'), '')));
    if (phoneR >= 50) scores['phone'] = phoneR;

    final vatR = ratio(_vatRe.hasMatch);
    if (vatR >= 40) scores['vatId'] = vatR;

    final skuR = ratio((s) => _skuRe.hasMatch(s) && !_vatRe.hasMatch(s));
    if (skuR >= 40) {
      scores['productCode'] = skuR;
      scores['clientNumber'] = (skuR * 0.7).round();
    }

    final addrR = ratio((s) => _addressRe.hasMatch(s) && s.length > 6);
    if (addrR >= 30) scores['address'] = addrR;

    final nameR = ratio((s) => _companyRe.hasMatch(s) || (s.length > 8 && !_skuRe.hasMatch(s)));
    if (nameR >= 30) {
      scores['clientName'] = nameR;
      scores['name'] = nameR;
      scores['productName'] = (nameR * 0.6).round();
    }

    final dateR = ratio(_dateRe.hasMatch);
    if (dateR >= 40) scores['requestedDate'] = dateR;

    final qtyR = ratio((s) => RegExp(r'^\d+([.,]\d+)?$').hasMatch(s));
    if (qtyR >= 60) {
      scores['quantity'] = qtyR;
      scores['boxes'] = (qtyR * 0.5).round();
    }

    final emailR = ratio(_emailRe.hasMatch);
    if (emailR >= 50) scores['contactName'] = (emailR * 0.5).round();

    final latR = ratio((s) => _coordRe.hasMatch(s) && double.tryParse(s) != null);
    if (latR >= 50) {
      scores['deliveryAddressOverrideLat'] = latR;
      scores['deliveryAddressOverrideLng'] = latR;
    }

    return scores;
  }

  /// Все колонки: colIndex → {fieldKey: confidence}.
  static Map<int, Map<String, int>> scoreAllColumns(List<List<String>> rows) {
    if (rows.isEmpty) return {};
    final colCount = rows.fold<int>(
      0,
      (m, r) => r.length > m ? r.length : m,
    );
    final out = <int, Map<String, int>>{};
    for (var c = 0; c < colCount; c++) {
      final cells = rows.map((r) => c < r.length ? r[c] : '').toList();
      final scores = scoreColumn(cells);
      if (scores.isNotEmpty) out[c] = scores;
    }
    return out;
  }
}
