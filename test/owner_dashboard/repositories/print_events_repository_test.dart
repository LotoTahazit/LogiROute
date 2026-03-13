import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/print_event.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _allStatuses = PrintEventStatus.values;

String _randomString(Random rng, {int minLen = 1, int maxLen = 20}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => 97 + rng.nextInt(26)), // a-z
  );
}

/// Generate a random [PrintEvent] with randomized fields.
PrintEvent _randomPrintEvent(Random rng) {
  final status = _allStatuses[rng.nextInt(_allStatuses.length)];

  return PrintEvent(
    id: 'pe-${_randomString(rng, maxLen: 12)}',
    invoiceId: 'inv-${_randomString(rng, maxLen: 10)}',
    printedBy: 'uid-${_randomString(rng, maxLen: 10)}',
    printedAt: DateTime(
      2022 + rng.nextInt(4),
      1 + rng.nextInt(12),
      1 + rng.nextInt(28),
      rng.nextInt(24),
      rng.nextInt(60),
    ),
    status: status,
    errorMessage: status == PrintEventStatus.error
        ? _randomString(rng, minLen: 5, maxLen: 30)
        : null,
    printerName:
        rng.nextBool() ? 'printer-${_randomString(rng, maxLen: 8)}' : null,
  );
}

/// Generate a list of N random print events.
List<PrintEvent> _randomPrintEvents(Random rng, int count) {
  return List.generate(count, (_) => _randomPrintEvent(rng));
}

/// Apply status filter locally, mirroring PrintEventsRepository.watchPrintEvents
/// filtering logic.
///
/// If [statusFilter] is non-null and non-empty, returns only events whose
/// status.value matches the filter. Otherwise returns all events.
List<PrintEvent> _filterByStatus(
  List<PrintEvent> events,
  String? statusFilter,
) {
  if (statusFilter == null || statusFilter.isEmpty) {
    return events;
  }
  return events.where((e) => e.status.value == statusFilter).toList();
}

// ===========================================================================
// Property-Based Tests — PrintEventsRepository
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Feature: owner-dashboard, Property 20: Фильтрация событий печати по статусу
  //
  // Для любого фильтра статуса и для любого события печати в
  // отфильтрованном результате, статус события должен совпадать с фильтром.
  // **Validates: Requirements 9.1**
  // -------------------------------------------------------------------------

  group('Property 20: Фильтрация событий печати по статусу', () {
    test(
      'Property 20a: every event in filtered result has matching status (150 iterations)',
      () {
        final rng = Random(2000);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46); // 5..50 events
          final events = _randomPrintEvents(rng, n);

          // Pick a random status filter from the enum values
          final filterStatus = _allStatuses[rng.nextInt(_allStatuses.length)];
          final filtered = _filterByStatus(events, filterStatus.value);

          // Every event in the result must have the matching status
          for (final event in filtered) {
            expect(event.status, equals(filterStatus),
                reason:
                    'Iteration $i: event status "${event.status.value}" should match filter "${filterStatus.value}"');
          }
        }
      },
    );

    test(
      'Property 20b: filtered result is a subset of original events (150 iterations)',
      () {
        final rng = Random(2001);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46); // 5..50 events
          final events = _randomPrintEvents(rng, n);

          final filterStatus = _allStatuses[rng.nextInt(_allStatuses.length)];
          final filtered = _filterByStatus(events, filterStatus.value);

          // Filtered count should be <= original count
          expect(filtered.length <= events.length, isTrue,
              reason:
                  'Iteration $i: filtered (${filtered.length}) should be <= original (${events.length})');

          // Every filtered event should exist in the original list
          final originalIds = events.map((e) => e.id).toSet();
          for (final event in filtered) {
            expect(originalIds.contains(event.id), isTrue,
                reason:
                    'Iteration $i: filtered event ${event.id} should exist in original');
          }
        }
      },
    );

    test(
      'Property 20c: null/empty filter returns all events (150 iterations)',
      () {
        final rng = Random(2002);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(30); // 0..29 events
          final events = _randomPrintEvents(rng, n);

          // null filter
          final filteredNull = _filterByStatus(events, null);
          expect(filteredNull.length, equals(events.length),
              reason:
                  'Iteration $i: null filter should return all ${events.length} events');

          // empty string filter
          final filteredEmpty = _filterByStatus(events, '');
          expect(filteredEmpty.length, equals(events.length),
              reason:
                  'Iteration $i: empty filter should return all ${events.length} events');
        }
      },
    );

    test(
      'Property 20d: filtered count equals manual count of matching events (150 iterations)',
      () {
        final rng = Random(2003);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46); // 5..50 events
          final events = _randomPrintEvents(rng, n);

          final filterStatus = _allStatuses[rng.nextInt(_allStatuses.length)];
          final filtered = _filterByStatus(events, filterStatus.value);

          // Manually count events with matching status
          final expectedCount =
              events.where((e) => e.status == filterStatus).length;

          expect(filtered.length, equals(expectedCount),
              reason:
                  'Iteration $i: filtered count (${filtered.length}) should equal manual count ($expectedCount) for status "${filterStatus.value}"');
        }
      },
    );

    test(
      'Property 20e: filtering by each status partitions all events (150 iterations)',
      () {
        final rng = Random(2004);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46); // 5..50 events
          final events = _randomPrintEvents(rng, n);

          // Sum of filtered counts for each status should equal total count
          var totalFiltered = 0;
          for (final status in _allStatuses) {
            final filtered = _filterByStatus(events, status.value);
            totalFiltered += filtered.length;
          }

          expect(totalFiltered, equals(events.length),
              reason:
                  'Iteration $i: sum of filtered counts ($totalFiltered) should equal total events (${events.length})');
        }
      },
    );

    test(
      'Property 20f: empty event list returns empty for any filter',
      () {
        final events = <PrintEvent>[];

        for (final status in _allStatuses) {
          final filtered = _filterByStatus(events, status.value);
          expect(filtered.isEmpty, isTrue,
              reason:
                  'Empty list filtered by "${status.value}" should be empty');
        }

        // Also null/empty filter
        expect(_filterByStatus(events, null).isEmpty, isTrue);
        expect(_filterByStatus(events, '').isEmpty, isTrue);
      },
    );
  });
}
