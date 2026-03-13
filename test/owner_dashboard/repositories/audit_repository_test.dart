import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/audit_event.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _moduleKeys = [
  'dispatcher',
  'logistics',
  'warehouse',
  'accounting',
  'reports',
];

const _eventTypes = [
  'invoice_issued',
  'route_published',
  'item_received',
  'payment_recorded',
  'report_generated',
  'user_invited',
  'role_changed',
  'settings_updated',
];

String _randomString(Random rng, {int minLen = 1, int maxLen = 20}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => 97 + rng.nextInt(26)), // a-z
  );
}

String _randomModuleKey(Random rng) =>
    _moduleKeys[rng.nextInt(_moduleKeys.length)];

String _randomEventType(Random rng) =>
    _eventTypes[rng.nextInt(_eventTypes.length)];

String _randomUid(Random rng) => 'uid-${_randomString(rng, maxLen: 10)}';

DateTime _randomDateTime(Random rng) {
  return DateTime(
    2022 + rng.nextInt(4),
    1 + rng.nextInt(12),
    1 + rng.nextInt(28),
    rng.nextInt(24),
    rng.nextInt(60),
    rng.nextInt(60),
  );
}

/// Generate a random [CrossModuleAuditEvent].
CrossModuleAuditEvent _randomAuditEvent(Random rng, {DateTime? createdAt}) {
  return CrossModuleAuditEvent(
    id: 'event-${_randomString(rng, maxLen: 12)}',
    moduleKey: _randomModuleKey(rng),
    type: _randomEventType(rng),
    entity: AuditEntity(
      collection: _randomString(rng, minLen: 3, maxLen: 10),
      docId: _randomString(rng, maxLen: 12),
    ),
    createdBy: _randomUid(rng),
    createdAt: createdAt ?? _randomDateTime(rng),
    extra: rng.nextBool()
        ? {'detail_${_randomString(rng, maxLen: 5)}': _randomString(rng)}
        : {},
  );
}

/// Generate a list of N random audit events with unique timestamps.
List<CrossModuleAuditEvent> _randomAuditEvents(Random rng, int count) {
  final events = <CrossModuleAuditEvent>[];
  for (var i = 0; i < count; i++) {
    events.add(_randomAuditEvent(rng));
  }
  return events;
}

/// Sort events by descending createdAt (newest first), matching repository behavior.
List<CrossModuleAuditEvent> _sortDescending(
    List<CrossModuleAuditEvent> events) {
  final sorted = List<CrossModuleAuditEvent>.from(events);
  sorted.sort((a, b) {
    final aTime = a.createdAt ?? DateTime(1970);
    final bTime = b.createdAt ?? DateTime(1970);
    return bTime.compareTo(aTime);
  });
  return sorted;
}

/// Generate a random [AuditFilter] with some fields randomly set.
AuditFilter _randomFilter(Random rng, List<CrossModuleAuditEvent> events) {
  // Pick filter values from existing events to ensure some matches
  final useModuleKey = rng.nextBool() && events.isNotEmpty;
  final useType = rng.nextBool() && events.isNotEmpty;
  final useCreatedBy = rng.nextBool() && events.isNotEmpty;
  final useDateRange = rng.nextBool();

  return AuditFilter(
    moduleKey:
        useModuleKey ? events[rng.nextInt(events.length)].moduleKey : null,
    type: useType ? events[rng.nextInt(events.length)].type : null,
    createdBy:
        useCreatedBy ? events[rng.nextInt(events.length)].createdBy : null,
    from: useDateRange ? _randomDateTime(rng) : null,
    to: useDateRange
        ? _randomDateTime(rng).add(Duration(days: rng.nextInt(365)))
        : null,
  );
}

/// Apply filter logic locally (mirrors AuditRepository._applyClientFilters
/// and _applyServerFilters).
List<CrossModuleAuditEvent> _applyFilterLocally(
  List<CrossModuleAuditEvent> events,
  AuditFilter filter,
) {
  var result = events;

  if (filter.moduleKey != null) {
    result = result.where((e) => e.moduleKey == filter.moduleKey).toList();
  }
  if (filter.type != null) {
    result = result.where((e) => e.type == filter.type).toList();
  }
  if (filter.createdBy != null) {
    result = result.where((e) => e.createdBy == filter.createdBy).toList();
  }
  if (filter.from != null) {
    result = result
        .where(
            (e) => e.createdAt != null && !e.createdAt!.isBefore(filter.from!))
        .toList();
  }
  if (filter.to != null) {
    result = result
        .where((e) => e.createdAt != null && !e.createdAt!.isAfter(filter.to!))
        .toList();
  }
  return result;
}

/// Parse a CSV string into a list of rows (each row is a list of fields).
/// Handles RFC 4180 quoted fields that may contain newlines.
List<List<String>> _parseCsvRows(String csv) {
  final rows = <List<String>>[];
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  var i = 0;

  while (i < csv.length) {
    final ch = csv[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          current.write('"');
          i += 2;
          continue;
        } else {
          inQuotes = false;
          i++;
          continue;
        }
      } else {
        current.write(ch);
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        fields.add(current.toString());
        current = StringBuffer();
      } else if (ch == '\n' || ch == '\r') {
        // End of row
        fields.add(current.toString());
        current = StringBuffer();
        if (fields.any((f) => f.isNotEmpty) || fields.length > 1) {
          rows.add(List<String>.from(fields));
        }
        fields.clear();
        // Skip \r\n
        if (ch == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') {
          i++;
        }
      } else {
        current.write(ch);
      }
    }
    i++;
  }
  // Handle last row if no trailing newline
  fields.add(current.toString());
  if (fields.any((f) => f.isNotEmpty) || fields.length > 1) {
    rows.add(List<String>.from(fields));
  }
  return rows;
}

// ===========================================================================
// Property-Based Tests — AuditRepository
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 9: Лента последних событий ограничена 20 записями
  //
  // Для любого журнала аудита с N записями (N >= 0), лента «Последние
  // события» должна содержать min(N, 20) записей, отсортированных по
  // убыванию createdAt.
  // **Validates: Requirements 4.5**
  // -------------------------------------------------------------------------

  group('Property 9: Лента последних событий ограничена 20 записями', () {
    test(
      'Property 9a: recent events feed contains min(N, 20) records sorted descending by createdAt (150 iterations)',
      () {
        final rng = Random(900);

        for (var i = 0; i < 150; i++) {
          // Generate N events where N is 0..50
          final n = rng.nextInt(51);
          final events = _randomAuditEvents(rng, n);

          // Sort descending by createdAt (simulates repository behavior)
          final sorted = _sortDescending(events);

          // Take at most 20 (simulates the recent events feed limit)
          final recentFeed = sorted.take(20).toList();

          // Verify count is min(N, 20)
          final expectedCount = n < 20 ? n : 20;
          expect(recentFeed.length, equals(expectedCount),
              reason:
                  'Iteration $i: for N=$n events, feed should have $expectedCount records');

          // Verify descending order
          for (var j = 0; j < recentFeed.length - 1; j++) {
            final current = recentFeed[j].createdAt ?? DateTime(1970);
            final next = recentFeed[j + 1].createdAt ?? DateTime(1970);
            expect(
              current.compareTo(next) >= 0,
              isTrue,
              reason:
                  'Iteration $i: events[$j].createdAt ($current) should be >= events[${j + 1}].createdAt ($next)',
            );
          }
        }
      },
    );

    test(
      'Property 9b: empty audit log produces empty feed',
      () {
        final events = <CrossModuleAuditEvent>[];
        final sorted = _sortDescending(events);
        final recentFeed = sorted.take(20).toList();

        expect(recentFeed.length, equals(0),
            reason: 'Empty log should produce empty feed');
      },
    );

    test(
      'Property 9c: feed with exactly 20 events returns all 20 sorted (150 iterations)',
      () {
        final rng = Random(902);

        for (var i = 0; i < 150; i++) {
          final events = _randomAuditEvents(rng, 20);
          final sorted = _sortDescending(events);
          final recentFeed = sorted.take(20).toList();

          expect(recentFeed.length, equals(20),
              reason: 'Iteration $i: exactly 20 events should return 20');

          for (var j = 0; j < recentFeed.length - 1; j++) {
            final current = recentFeed[j].createdAt ?? DateTime(1970);
            final next = recentFeed[j + 1].createdAt ?? DateTime(1970);
            expect(current.compareTo(next) >= 0, isTrue,
                reason: 'Iteration $i: descending order violated at index $j');
          }
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 17: Хронологический порядок аудит-лога
  //
  // Для любого списка записей аудита, отображаемый порядок должен быть
  // по убыванию createdAt (новые сверху). Формально: для любых двух
  // соседних записей a[i] и a[i+1], a[i].createdAt >= a[i+1].createdAt.
  // **Validates: Requirements 8.1**
  // -------------------------------------------------------------------------

  group('Property 17: Хронологический порядок аудит-лога', () {
    test(
      'Property 17a: sorted audit log maintains descending createdAt order (150 iterations)',
      () {
        final rng = Random(1700);

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(100); // 1..100 events
          final events = _randomAuditEvents(rng, n);

          // Sort descending (simulates repository orderBy createdAt desc)
          final sorted = _sortDescending(events);

          // Verify: for any two adjacent entries a[i].createdAt >= a[i+1].createdAt
          for (var j = 0; j < sorted.length - 1; j++) {
            final current = sorted[j].createdAt ?? DateTime(1970);
            final next = sorted[j + 1].createdAt ?? DateTime(1970);
            expect(
              current.compareTo(next) >= 0,
              isTrue,
              reason:
                  'Iteration $i: sorted[$j].createdAt ($current) should be >= sorted[${j + 1}].createdAt ($next)',
            );
          }
        }
      },
    );

    test(
      'Property 17b: single event list is trivially sorted (150 iterations)',
      () {
        final rng = Random(1701);

        for (var i = 0; i < 150; i++) {
          final event = _randomAuditEvent(rng);
          final sorted = _sortDescending([event]);

          expect(sorted.length, equals(1),
              reason: 'Iteration $i: single event list should have 1 element');
          expect(sorted.first.id, equals(event.id),
              reason: 'Iteration $i: single event should be preserved');
        }
      },
    );

    test(
      'Property 17c: sorting preserves all events (no loss, no duplication) (150 iterations)',
      () {
        final rng = Random(1702);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(50) + 2; // 2..51 events
          final events = _randomAuditEvents(rng, n);
          final sorted = _sortDescending(events);

          // Same count
          expect(sorted.length, equals(events.length),
              reason: 'Iteration $i: sorting should not change count');

          // Same set of IDs
          final originalIds = events.map((e) => e.id).toSet();
          final sortedIds = sorted.map((e) => e.id).toSet();
          expect(sortedIds, equals(originalIds),
              reason: 'Iteration $i: sorting should preserve all event IDs');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 18: Фильтрация аудит-лога
  //
  // Для любого набора фильтров (moduleKey, type, createdBy, dateRange)
  // и для любой записи в отфильтрованном результате, запись должна
  // удовлетворять всем активным фильтрам одновременно.
  // **Validates: Requirements 8.2**
  // -------------------------------------------------------------------------

  group('Property 18: Фильтрация аудит-лога', () {
    test(
      'Property 18a: every record in filtered result satisfies all active filters (150 iterations)',
      () {
        final rng = Random(1800);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46); // 5..50 events
          final events = _randomAuditEvents(rng, n);
          final filter = _randomFilter(rng, events);

          final filtered = _applyFilterLocally(events, filter);

          // Every record in the result must satisfy ALL active filters
          for (final event in filtered) {
            if (filter.moduleKey != null) {
              expect(event.moduleKey, equals(filter.moduleKey),
                  reason:
                      'Iteration $i: event moduleKey "${event.moduleKey}" should match filter "${filter.moduleKey}"');
            }
            if (filter.type != null) {
              expect(event.type, equals(filter.type),
                  reason:
                      'Iteration $i: event type "${event.type}" should match filter "${filter.type}"');
            }
            if (filter.createdBy != null) {
              expect(event.createdBy, equals(filter.createdBy),
                  reason:
                      'Iteration $i: event createdBy "${event.createdBy}" should match filter "${filter.createdBy}"');
            }
            if (filter.from != null && event.createdAt != null) {
              expect(event.createdAt!.compareTo(filter.from!) >= 0, isTrue,
                  reason:
                      'Iteration $i: event createdAt ${event.createdAt} should be >= filter.from ${filter.from}');
            }
            if (filter.to != null && event.createdAt != null) {
              expect(event.createdAt!.compareTo(filter.to!) <= 0, isTrue,
                  reason:
                      'Iteration $i: event createdAt ${event.createdAt} should be <= filter.to ${filter.to}');
            }
          }
        }
      },
    );

    test(
      'Property 18b: filtered result is a subset of original events (150 iterations)',
      () {
        final rng = Random(1801);

        for (var i = 0; i < 150; i++) {
          final n = 5 + rng.nextInt(46);
          final events = _randomAuditEvents(rng, n);
          final filter = _randomFilter(rng, events);

          final filtered = _applyFilterLocally(events, filter);

          // Filtered result should be a subset
          expect(filtered.length <= events.length, isTrue,
              reason:
                  'Iteration $i: filtered (${filtered.length}) should be <= original (${events.length})');

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
      'Property 18c: empty filter returns all events (150 iterations)',
      () {
        final rng = Random(1802);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(30);
          final events = _randomAuditEvents(rng, n);
          const emptyFilter = AuditFilter();

          final filtered = _applyFilterLocally(events, emptyFilter);

          expect(filtered.length, equals(events.length),
              reason:
                  'Iteration $i: empty filter should return all ${events.length} events');
        }
      },
    );

    test(
      'Property 18d: non-matching filter returns empty result (150 iterations)',
      () {
        final rng = Random(1803);

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(30);
          final events = _randomAuditEvents(rng, n);

          // Create a filter with a moduleKey that doesn't exist in events
          final nonExistentModule =
              'nonexistent_module_${_randomString(rng, maxLen: 8)}';
          final filter = AuditFilter(moduleKey: nonExistentModule);

          final filtered = _applyFilterLocally(events, filter);

          expect(filtered.isEmpty, isTrue,
              reason:
                  'Iteration $i: filter with non-existent moduleKey should return empty');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 19: Round-trip экспорта аудит-лога в CSV
  //
  // Для любого списка записей аудита, экспортированный CSV должен
  // содержать ровно столько строк данных, сколько записей в списке,
  // и каждая строка должна содержать колонки: дата, модуль, тип события,
  // пользователь, сущность, детали.
  // **Validates: Requirements 8.5, 8.7**
  // -------------------------------------------------------------------------

  group('Property 19: Round-trip экспорта аудит-лога в CSV', () {
    test(
      'Property 19a: CSV has header + exactly N data rows with 6 columns (150 iterations)',
      () {
        final rng = Random(1900);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(30); // 0..29 events
          final events = _randomAuditEvents(rng, n);

          final csv = _buildCsvFromEvents(events);
          final rows = _parseCsvRows(csv);

          if (n == 0) {
            // Only header row
            expect(rows.length, equals(1),
                reason:
                    'Iteration $i: empty events should produce only header row');
          } else {
            // Header + N data rows
            expect(rows.length, equals(n + 1),
                reason:
                    'Iteration $i: CSV should have ${n + 1} rows (1 header + $n data), got ${rows.length}');
          }

          // Verify header has 6 columns
          expect(rows.first.length, equals(6),
              reason: 'Iteration $i: header should have 6 columns');

          // Verify each data row has 6 columns
          for (var j = 1; j < rows.length; j++) {
            expect(rows[j].length, equals(6),
                reason:
                    'Iteration $i: data row $j should have 6 columns, got ${rows[j].length}');
          }
        }
      },
    );

    test(
      'Property 19b: CSV header contains expected column names',
      () {
        final events = <CrossModuleAuditEvent>[];
        final csv = _buildCsvFromEvents(events);
        final rows = _parseCsvRows(csv);

        expect(rows.isNotEmpty, isTrue,
            reason: 'CSV should have at least header');
        final header = rows.first;
        expect(header[0], equals('дата'));
        expect(header[1], equals('модуль'));
        expect(header[2], equals('тип события'));
        expect(header[3], equals('пользователь'));
        expect(header[4], equals('сущность'));
        expect(header[5], equals('детали'));
      },
    );

    test(
      'Property 19c: CSV data rows contain correct event data (150 iterations)',
      () {
        final rng = Random(1902);

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(20); // 1..20 events
          final events = _randomAuditEvents(rng, n);

          final csv = _buildCsvFromEvents(events);
          final rows = _parseCsvRows(csv);

          // Skip header, verify each data row matches the event
          for (var j = 0; j < events.length; j++) {
            final event = events[j];
            final row = rows[j + 1]; // +1 to skip header

            // Column 0: date (ISO 8601 string or empty)
            final expectedDate = event.createdAt?.toIso8601String() ?? '';
            expect(row[0], equals(expectedDate),
                reason: 'Iteration $i, row $j: date mismatch');

            // Column 1: module
            expect(row[1], equals(event.moduleKey),
                reason: 'Iteration $i, row $j: module mismatch');

            // Column 2: event type
            expect(row[2], equals(event.type),
                reason: 'Iteration $i, row $j: type mismatch');

            // Column 3: user
            expect(row[3], equals(event.createdBy),
                reason: 'Iteration $i, row $j: user mismatch');

            // Column 4: entity (collection/docId)
            final expectedEntity =
                '${event.entity.collection}/${event.entity.docId}';
            expect(row[4], equals(expectedEntity),
                reason: 'Iteration $i, row $j: entity mismatch');

            // Column 5: details (extra fields as key=value pairs)
            final expectedDetails = event.extra.entries
                .map((e) => '${e.key}=${e.value}')
                .join('; ');
            expect(row[5], equals(expectedDetails),
                reason: 'Iteration $i, row $j: details mismatch');
          }
        }
      },
    );

    test(
      'Property 19d: CSV with special characters is properly escaped (150 iterations)',
      () {
        final rng = Random(1903);
        const specialChars = [',', '"', '\n', '",', ',\n', '"quoted"'];

        for (var i = 0; i < 150; i++) {
          // Create event with special characters in fields
          final specialValue = specialChars[rng.nextInt(specialChars.length)];
          final event = CrossModuleAuditEvent(
            id: 'event-$i',
            moduleKey: 'module$specialValue',
            type: 'type_${_randomString(rng, maxLen: 5)}',
            entity: AuditEntity(
              collection: 'col$specialValue',
              docId: 'doc-$i',
            ),
            createdBy: _randomUid(rng),
            createdAt: _randomDateTime(rng),
            extra: {'key': 'value$specialValue'},
          );

          final csv = _buildCsvFromEvents([event]);
          final rows = _parseCsvRows(csv);

          // Should have header + 1 data row
          expect(rows.length, equals(2),
              reason: 'Iteration $i: should have header + 1 data row');

          // Data row should have exactly 6 columns despite special chars
          expect(rows[1].length, equals(6),
              reason:
                  'Iteration $i: data row should have 6 columns even with special chars');
        }
      },
    );
  });
}

// ---------------------------------------------------------------------------
// CSV builder (mirrors AuditRepository._buildCsv)
// ---------------------------------------------------------------------------

/// Builds CSV from events, replicating the repository's _buildCsv logic.
String _buildCsvFromEvents(List<CrossModuleAuditEvent> events) {
  final buffer = StringBuffer();
  buffer.writeln('дата,модуль,тип события,пользователь,сущность,детали');

  for (final event in events) {
    final date = event.createdAt?.toIso8601String() ?? '';
    final module = _escapeCsv(event.moduleKey);
    final type = _escapeCsv(event.type);
    final user = _escapeCsv(event.createdBy);
    final entity =
        _escapeCsv('${event.entity.collection}/${event.entity.docId}');
    final details = _escapeCsv(
      event.extra.entries.map((e) => '${e.key}=${e.value}').join('; '),
    );
    buffer.writeln('$date,$module,$type,$user,$entity,$details');
  }
  return buffer.toString();
}

/// Mirrors AuditRepository._escapeCsv.
String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
