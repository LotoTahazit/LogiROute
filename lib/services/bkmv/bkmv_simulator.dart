import 'package:archive/archive.dart';

import 'bkmv_codec.dart';
import 'bkmv_exporter.dart';
import 'bkmv_records.dart';

/// Результат «симулятора» רשות המסים — структурные проверки horaot 1.31.
class BkmvSimulatorResult {
  final bool ok;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, int> recordCounts;

  const BkmvSimulatorResult({
    required this.ok,
    required this.errors,
    required this.warnings,
    required this.recordCounts,
  });
}

/// Локальная проверка ZIP / OPENFRMT до загрузки в портал רשות המסים.
class BkmvSimulator {
  BkmvSimulator._();

  static const _lengths = {
    'A100': BkmvRecords.lenA100,
    'C100': BkmvRecords.lenC100,
    'D110': BkmvRecords.lenD110,
    'D120': BkmvRecords.lenD120,
    'Z900': BkmvRecords.lenZ900,
    'A000': BkmvRecords.lenA000,
  };

  static BkmvSimulatorResult validateExport(BkmvExportResult export) =>
      _validate(export.iniText, export.bkmvText);

  static BkmvSimulatorResult validateZip(List<int> zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final ini = archive.findFile('INI.TXT');
      final data = archive.findFile('BKMVDATA.TXT');
      if (ini == null) {
        return const BkmvSimulatorResult(
          ok: false,
          errors: ['ZIP: missing INI.TXT'],
          warnings: [],
          recordCounts: {},
        );
      }
      if (data == null) {
        return const BkmvSimulatorResult(
          ok: false,
          errors: ['ZIP: missing BKMVDATA.TXT'],
          warnings: [],
          recordCounts: {},
        );
      }
      final iniText = String.fromCharCodes(ini.content);
      final bkmvText = String.fromCharCodes(data.content);
      return _validate(iniText, bkmvText);
    } catch (e) {
      return BkmvSimulatorResult(
        ok: false,
        errors: ['ZIP decode: $e'],
        warnings: [],
        recordCounts: {},
      );
    }
  }

  static BkmvSimulatorResult _validate(String iniText, String bkmvText) {
    final errors = <String>[];
    final warnings = <String>[];
    final counts = <String, int>{};

    if (!iniText.contains(BkmvCodec.crlf)) {
      warnings.add('INI.TXT: expected CRLF line endings');
    }
    if (!bkmvText.contains(BkmvCodec.crlf)) {
      warnings.add('BKMVDATA.TXT: expected CRLF line endings');
    }

    final iniLines = _splitLines(iniText);
    final dataLines = _splitLines(bkmvText);
    final summaries = <String, int>{};

    if (iniLines.isEmpty) errors.add('INI.TXT is empty');
    if (dataLines.isEmpty) errors.add('BKMVDATA.TXT is empty');

    if (iniLines.isNotEmpty) {
      final a000 = iniLines.first;
      if (!a000.startsWith('A000')) {
        errors.add('INI: first record must be A000');
      } else {
        _checkLen(a000, 'A000', errors);
        if (!a000.contains(BkmvCodec.ofVersion)) {
          errors.add('A000: missing ${BkmvCodec.ofVersion}');
        }
      }
      for (var i = 1; i < iniLines.length; i++) {
        final line = iniLines[i];
        if (line.length != BkmvRecords.lenIniSummary) {
          errors.add('INI summary line ${i + 1}: bad length ${line.length}');
          continue;
        }
        final code = line.substring(0, 4);
        summaries[code] = int.tryParse(line.substring(4).trim()) ?? -1;
      }
      if ((summaries['A100'] ?? 0) != 1) {
        errors.add('INI: A100 count must be 1');
      }
      if ((summaries['Z900'] ?? 0) != 1) {
        errors.add('INI: Z900 count must be 1');
      }

      if (a000.startsWith('A000') && a000.length == BkmvRecords.lenA000) {
        final declaredTotal = int.tryParse(a000.substring(9, 24)) ?? -1;
        if (declaredTotal != dataLines.length) {
          errors.add(
              'A000 total $declaredTotal != BKMVDATA lines ${dataLines.length}');
        }
      }
    }

    String? vatId;
    String? primaryFromA100;

    for (var i = 0; i < dataLines.length; i++) {
      final line = dataLines[i];
      final code = line.length >= 4 ? line.substring(0, 4) : '????';
      counts[code] = (counts[code] ?? 0) + 1;
      final expectedLen = _lengths[code];
      if (expectedLen != null) {
        if (line.length != expectedLen) {
          errors.add('$code line ${i + 1}: length ${line.length} != $expectedLen');
        }
      } else {
        errors.add('Line ${i + 1}: unknown record $code');
      }

      if (line.length >= 22) {
        final lineVat = line.substring(13, 22);
        vatId ??= lineVat;
        if (lineVat != vatId) {
          errors.add('$code line ${i + 1}: VAT mismatch');
        }
      }

      final recNo = int.tryParse(line.substring(4, 13)) ?? -1;
      if (recNo != i + 1) {
        errors.add('$code line ${i + 1}: record number $recNo expected ${i + 1}');
      }

      if (code == 'A100') {
        primaryFromA100 = line.substring(22, 37).trim();
        if (!line.contains(BkmvCodec.ofVersion)) {
          errors.add('A100: missing ${BkmvCodec.ofVersion}');
        }
      }
      if (code == 'Z900') {
        final zPrimary = line.substring(22, 37).trim();
        if (primaryFromA100 != null && zPrimary != primaryFromA100) {
          errors.add('Z900: primary ID mismatch with A100');
        }
        final zTotal = int.tryParse(line.substring(45, 60)) ?? -1;
        if (zTotal != dataLines.length) {
          errors.add('Z900 total $zTotal != lines ${dataLines.length}');
        }
      }
    }

    if (dataLines.isNotEmpty) {
      if (!dataLines.first.startsWith('A100')) {
        errors.add('BKMVDATA must start with A100');
      }
      if (!dataLines.last.startsWith('Z900')) {
        errors.add('BKMVDATA must end with Z900');
      }
    }

    if ((counts['C100'] ?? 0) > 0 && (counts['D110'] ?? 0) == 0) {
      warnings.add('C100 without D110 lines');
    }

    _compareSummary('C100', summaries, counts, errors);
    _compareSummary('D110', summaries, counts, errors);
    _compareSummary('D120', summaries, counts, errors);

    return BkmvSimulatorResult(
      ok: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      recordCounts: counts,
    );
  }

  static List<String> _splitLines(String text) {
    return text
        .split(BkmvCodec.crlf)
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static void _checkLen(String line, String code, List<String> errors) {
    final expected = _lengths[code];
    if (expected != null && line.length != expected) {
      errors.add('$code: length ${line.length} != $expected');
    }
  }

  static void _compareSummary(
    String code,
    Map<String, int> summaries,
    Map<String, int> actual,
    List<String> errors,
  ) {
    final actualCount = actual[code] ?? 0;
    if (actualCount == 0) return;
    final iniCount = summaries[code];
    if (iniCount == null) {
      errors.add('INI: missing summary for $code ($actualCount in file)');
    } else if (iniCount != actualCount) {
      errors.add('INI $code count $iniCount != BKMVDATA $actualCount');
    }
  }
}
