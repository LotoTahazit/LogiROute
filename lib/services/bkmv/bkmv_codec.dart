import 'dart:math';

/// Кодирование полей OPENFRMT / horaot 1.31 (fixed-width, CRLF).
class BkmvCodec {
  BkmvCodec._();

  static const String ofVersion = '&OF1.31&';
  static const String crlf = '\r\n';

  /// 15-значный מזהה ראשי (поля 1004 / 1103 / 1153).
  static String newPrimaryId([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(15, (_) => r.nextInt(10)).join();
  }

  /// אלפאנומרי — пробелы справа (מיושר לשמאל).
  static String alpha(String? value, int length) {
    final s = (value ?? '').replaceAll('\n', ' ').trim();
    if (s.length > length) return s.substring(0, length);
    return s.padRight(length, ' ');
  }

  /// נומרי — нули слева (מיושר לימין).
  static String numeric(String? value, int length) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final s = digits.isEmpty ? '0' : digits;
    if (s.length > length) return s.substring(s.length - length);
    return s.padLeft(length, '0');
  }

  static String numericInt(int value, int length) =>
      numeric(value.toString(), length);

  static String dateYmd(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  static String timeHm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}';

  /// סכום 9(12)v99 ב־15 תווים: סימן + 14 ספרות (אגורות).
  /// כמות 9999v12 — 17 תווים.
  static String quantity17(double value) {
    final neg = value < 0;
    final scaled = (value.abs() * 1e12).round();
    final body = scaled.toString().padLeft(16, '0');
    if (body.length > 16) {
      throw ArgumentError('Quantity too large for BKMV field: $value');
    }
    return '${neg ? '-' : '+'}$body';
  }

  static String amount15(double value) {
    final neg = value < 0;
    final cents = (value.abs() * 100).round();
    final body = cents.toString().padLeft(14, '0');
    if (body.length > 14) {
      throw ArgumentError('Amount too large for BKMV field: $value');
    }
    return '${neg ? '-' : '+'}$body';
  }

  /// סכום 9(9)v99 ב־12 תווים (שדה 1224).
  static String amount12(double value) {
    final neg = value < 0;
    final cents = (value.abs() * 100).round();
    final body = cents.toString().padLeft(11, '0');
    if (body.length > 11) {
      throw ArgumentError('Amount too large for BKMV 12-char field: $value');
    }
    return '${neg ? '-' : '+'}$body';
  }

  /// שיעור מע"מ 99v99 ב־4 ספרות. Вход — ДОЛЯ (0.18), как `Invoice.vatRate`:
  /// 0.18 → "1800", 0.17 → "1700", 0 → "0000".
  /// (×100 — доля→процент, ×100 — два знака после запятой формата 99V99.)
  static String vatRate4(double rate) {
    final scaled = (rate * 10000).round();
    return numericInt(scaled, 4);
  }

  static String vatId9(String? raw) => numeric(raw, 9);

  static String line(String body) {
    if (body.contains('\r') || body.contains('\n')) {
      throw ArgumentError('BKMV record must not contain line breaks');
    }
    return '$body$crlf';
  }

  /// ISO-8859-8 (subset) — как в accounting_export_service.
  static List<int> encodeIso88598(String text) {
    final bytes = <int>[];
    for (final codeUnit in text.codeUnits) {
      if (codeUnit < 0x80) {
        bytes.add(codeUnit);
      } else if (codeUnit >= 0x05D0 && codeUnit <= 0x05EA) {
        bytes.add(codeUnit - 0x05D0 + 0xE0);
      } else if (codeUnit == 0x20AA) {
        bytes.add(0xA4);
      } else {
        bytes.add(0x3F);
      }
    }
    return bytes;
  }

  static List<int> encodeFile(String content) => encodeIso88598(content);

  static void assertLength(String record, int expected, String label) {
    if (record.length != expected) {
      throw StateError(
          '$label: expected $expected chars, got ${record.length}');
    }
  }
}
