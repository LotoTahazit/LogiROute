import 'dart:convert';

/// Pure utility class for generating receipts from payment event data.
/// No Flutter or Firebase dependencies — uses only dart:convert.
class ReceiptExporter {
  ReceiptExporter._(); // prevent instantiation

  static const _fields = [
    'eventId',
    'type',
    'provider',
    'amount',
    'currency',
    'processedAt',
    'paidUntil',
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generates a JSON-formatted receipt string from [eventData].
  static String toJson(Map<String, dynamic> eventData) {
    final receipt = _buildReceipt(eventData);
    return jsonEncode(receipt);
  }

  /// Generates a single-event CSV line (no header) from [eventData].
  static String toCsv(Map<String, dynamic> eventData) {
    final receipt = _buildReceipt(eventData);
    return _receiptToCsvRow(receipt);
  }

  /// Generates a CSV string with header row followed by one row per event.
  /// Returns header-only when [events] is empty.
  static String toMultiCsv(List<Map<String, dynamic>> events) {
    final buf = StringBuffer();
    buf.writeln(_fields.join(','));
    for (final event in events) {
      final receipt = _buildReceipt(event);
      buf.writeln(_receiptToCsvRow(receipt));
    }
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Builds a normalised receipt map from raw [eventData].
  static Map<String, dynamic> _buildReceipt(Map<String, dynamic> eventData) {
    return {
      'eventId': eventData['eventId'] ?? '',
      'type': eventData['type'] ?? '',
      'provider': eventData['provider'] ?? '',
      'amount': _resolveAmount(eventData['amount']),
      'currency': (eventData['currency'] as String?) ?? 'ILS',
      'processedAt': _resolveDate(eventData['processedAt']),
      'paidUntil': _resolveDate(eventData['paidUntil']),
    };
  }

  /// Returns the amount as-is when present, or "—" when null/missing.
  static dynamic _resolveAmount(dynamic value) {
    if (value == null) return '—';
    return value;
  }

  /// Converts a date value to an ISO-8601 string.
  /// Handles: String (pass-through), objects with `toDate()` (Timestamp),
  /// DateTime, and null (empty string).
  static String _resolveDate(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    // Handle Firestore Timestamp (has toDate() method) without importing Firebase
    try {
      // ignore: avoid_dynamic_calls
      final dt = value.toDate() as DateTime;
      return dt.toIso8601String();
    } catch (_) {
      return value.toString();
    }
  }

  /// Converts a receipt map to a single CSV row string.
  static String _receiptToCsvRow(Map<String, dynamic> receipt) {
    return _fields.map((f) => _escapeCsv(receipt[f].toString())).join(',');
  }

  /// Escapes a value for CSV: wraps in quotes if it contains comma, quote, or newline.
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
