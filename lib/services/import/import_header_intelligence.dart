/// Нормализация заголовков Excel/CSV (ru/en/he) для сопоставления колонок.
class ImportHeaderIntelligence {
  /// Убирает регистр, пробелы, `_`, `-`, `*`, `.`, `:`, кавычки; разворачивает сокращения.
  static String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp('[\\s_\\-*\\.:\"\'`׳״]+'), '');
    s = s.replaceAll('מק״ט', 'מקט');
    s = s.replaceAll('ח״פ', 'חפ');
    s = s.replaceAll('ע״מ', 'עמ');
    return _expandAbbreviations(s);
  }

  static String _expandAbbreviations(String s) {
    return _abbrevTokens[s] ?? s;
  }

  /// Распространённые сокращения (en/ru/he translit).
  static const _abbrevTokens = <String, String>{
    'cust': 'customer',
    'custname': 'customername',
    'custcode': 'customernumber',
    'addr': 'address',
    'desc': 'description',
    'descr': 'description',
    'tel': 'phone',
    'mob': 'phone',
    'mobile': 'phone',
    'qty': 'quantity',
    'qnt': 'quantity',
    'num': 'number',
    'no': 'number',
    'sku': 'productcode',
    'part': 'productcode',
    'item': 'productcode',
    'vat': 'vatid',
    'hp': 'vatid',
    'inn': 'vatid',
    'sn': 'productcode',
    'wt': 'weight',
    'vol': 'volume',
    'cat': 'category',
    'dt': 'date',
    'deliv': 'delivery',
    'ship': 'shipping',
    'klient': 'customer',
    'naim': 'name',
    'nazv': 'name',
    'adres': 'address',
    'telefon': 'phone',
    'tovar': 'productname',
    'artikul': 'productcode',
    'kod': 'code',
  };

  /// Похожесть двух нормализованных заголовков (0..100).
  static int headerSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 100;
    if (a.contains(b) || b.contains(a)) return 95;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final ratio = 1.0 - dist / maxLen;
    if (ratio >= 0.92) return 90;
    if (ratio >= 0.82) return 80;
    if (ratio >= 0.72) return 70;
    return 0;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = a.length;
    final n = b.length;
    var prev = List<int>.generate(n + 1, (j) => j);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      final swap = prev;
      prev = curr;
      curr = swap;
    }
    return prev[n];
  }

  /// Похожесть двух наборов заголовков (0..1).
  static double headersSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final na = a.map(normalize).toList();
    final nb = b.map(normalize).toList();
    var matches = 0;
    var total = 0;
    for (final h in na) {
      if (h.isEmpty) continue;
      total++;
      if (nb.any((x) => x == h || headerSimilarity(x, h) >= 70)) {
        matches++;
      }
    }
    if (total == 0) return 0;
    return matches / total;
  }
}
