import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/accounting_doc.dart';

/// Утилита вычисления immutableSnapshotHash для бухгалтерских документов.
///
/// SHA-256 от ключевых полей: docNumber, issuedAt, customerId, lines, totals.
/// Используется при переходе draft → issued для фиксации целостности
/// в соответствии с требованиями ניהול ספרים.
class SnapshotHash {
  /// Вычисляет SHA-256 хеш от ключевых полей документа.
  ///
  /// Возвращает hex-строку SHA-256 хеша.
  static String compute(AccountingDoc doc) {
    final payload = _buildPayload(doc);
    final jsonString = jsonEncode(payload);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Собирает каноническое представление ключевых полей для хеширования.
  static Map<String, dynamic> _buildPayload(AccountingDoc doc) {
    return {
      'docNumber': doc.docNumber,
      'issuedAt': doc.issuedAt?.toIso8601String(),
      'customerId': doc.customerId,
      'lines': doc.lines.map((line) => line.toMap()).toList(),
      'totals': doc.totals.toMap(),
    };
  }
}
