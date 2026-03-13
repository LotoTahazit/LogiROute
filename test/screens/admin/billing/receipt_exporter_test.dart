import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/screens/admin/billing/receipt_exporter.dart';

void main() {
  // -------------------------------------------------------------------------
  // Sample data
  // -------------------------------------------------------------------------
  final fullEvent = <String, dynamic>{
    'eventId': 'evt_001',
    'type': 'payment_success',
    'provider': 'stripe',
    'amount': 299,
    'currency': 'ILS',
    'processedAt': '2024-06-01T12:00:00.000Z',
    'paidUntil': '2024-07-01T12:00:00.000Z',
  };

  final missingAmountEvent = <String, dynamic>{
    'eventId': 'evt_002',
    'type': 'subscription_created',
    'provider': 'tranzila',
    // amount intentionally omitted
    'currency': 'USD',
    'processedAt': '2024-05-15T09:30:00.000Z',
    'paidUntil': '2024-06-15T09:30:00.000Z',
  };

  final nullAmountEvent = <String, dynamic>{
    'eventId': 'evt_003',
    'type': 'payment_failed',
    'provider': 'payplus',
    'amount': null,
    'currency': null, // should default to ILS
    'processedAt': null, // should become empty string
    'paidUntil': null,
  };

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------
  group('toJson', () {
    test('round-trip with full data', () {
      final jsonStr = ReceiptExporter.toJson(fullEvent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['eventId'], 'evt_001');
      expect(parsed['type'], 'payment_success');
      expect(parsed['provider'], 'stripe');
      expect(parsed['amount'], 299);
      expect(parsed['currency'], 'ILS');
      expect(parsed['processedAt'], '2024-06-01T12:00:00.000Z');
      expect(parsed['paidUntil'], '2024-07-01T12:00:00.000Z');
    });

    test('missing amount produces dash', () {
      final jsonStr = ReceiptExporter.toJson(missingAmountEvent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['amount'], '—');
    });

    test('null amount produces dash', () {
      final jsonStr = ReceiptExporter.toJson(nullAmountEvent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['amount'], '—');
    });

    test('null currency defaults to ILS', () {
      final jsonStr = ReceiptExporter.toJson(nullAmountEvent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['currency'], 'ILS');
    });

    test('null dates become empty strings', () {
      final jsonStr = ReceiptExporter.toJson(nullAmountEvent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['processedAt'], '');
      expect(parsed['paidUntil'], '');
    });
  });

  // -------------------------------------------------------------------------
  // toCsv
  // -------------------------------------------------------------------------
  group('toCsv', () {
    test('single event CSV contains all fields', () {
      final csv = ReceiptExporter.toCsv(fullEvent);

      expect(csv, contains('evt_001'));
      expect(csv, contains('payment_success'));
      expect(csv, contains('stripe'));
      expect(csv, contains('299'));
      expect(csv, contains('ILS'));
      expect(csv, contains('2024-06-01T12:00:00.000Z'));
      expect(csv, contains('2024-07-01T12:00:00.000Z'));

      // Should have exactly 6 commas (7 fields)
      expect(','.allMatches(csv).length, 6);
    });

    test('missing amount shows dash in CSV', () {
      final csv = ReceiptExporter.toCsv(missingAmountEvent);
      final parts = csv.split(',');

      // amount is the 4th field (index 3)
      expect(parts[3], '—');
    });

    test('escapes values containing commas', () {
      final eventWithComma = <String, dynamic>{
        ...fullEvent,
        'provider': 'stripe,inc',
      };
      final csv = ReceiptExporter.toCsv(eventWithComma);
      expect(csv, contains('"stripe,inc"'));
    });

    test('escapes values containing quotes', () {
      final eventWithQuote = <String, dynamic>{
        ...fullEvent,
        'provider': 'pay"plus',
      };
      final csv = ReceiptExporter.toCsv(eventWithQuote);
      expect(csv, contains('"pay""plus"'));
    });
  });

  // -------------------------------------------------------------------------
  // toMultiCsv
  // -------------------------------------------------------------------------
  group('toMultiCsv', () {
    test('header and multiple events', () {
      final csv = ReceiptExporter.toMultiCsv([fullEvent, missingAmountEvent]);
      final lines = csv.trim().split('\n');

      // Header + 2 data rows
      expect(lines.length, 3);
      expect(lines[0].trim(),
          'eventId,type,provider,amount,currency,processedAt,paidUntil');
      expect(lines[1], contains('evt_001'));
      expect(lines[2], contains('evt_002'));
    });

    test('empty list produces header only', () {
      final csv = ReceiptExporter.toMultiCsv([]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 1);
      expect(lines[0].trim(),
          'eventId,type,provider,amount,currency,processedAt,paidUntil');
    });

    test('missing amount in multi CSV shows dash', () {
      final csv = ReceiptExporter.toMultiCsv([missingAmountEvent]);
      final lines = csv.trim().split('\n');
      final dataParts = lines[1].split(',');

      // amount is the 4th field (index 3)
      expect(dataParts[3], '—');
    });
  });

  // -------------------------------------------------------------------------
  // DateTime handling
  // -------------------------------------------------------------------------
  group('DateTime handling', () {
    test('handles DateTime objects in processedAt', () {
      final eventWithDateTime = <String, dynamic>{
        ...fullEvent,
        'processedAt': DateTime.utc(2024, 6, 1, 12, 0, 0),
      };
      final jsonStr = ReceiptExporter.toJson(eventWithDateTime);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(parsed['processedAt'], contains('2024-06-01'));
    });
  });
}
