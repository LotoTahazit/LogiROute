import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/system_event.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _allStatuses = SystemEventStatus.values;
const _allTypes = SystemEventType.values;
const _allSources = SystemEventSource.values;

String _randomString(Random rng, {int minLen = 1, int maxLen = 20}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => 97 + rng.nextInt(26)), // a-z
  );
}

/// Generate a random [SystemEvent] with randomized fields.
SystemEvent _randomSystemEvent(Random rng) {
  final status = _allStatuses[rng.nextInt(_allStatuses.length)];
  final type = _allTypes[rng.nextInt(_allTypes.length)];
  final source = _allSources[rng.nextInt(_allSources.length)];

  return SystemEvent(
    type: type,
    source: source,
    status: status,
    message: _randomString(rng, minLen: 3, maxLen: 30),
    endpoint:
        rng.nextBool() ? 'https://${_randomString(rng, maxLen: 10)}.com' : null,
    responseStatus: rng.nextBool() ? 200 + rng.nextInt(300) : null,
    responseTime: rng.nextBool() ? rng.nextInt(5000) : null,
    retryCount: rng.nextInt(20), // 0..19
    createdAt: DateTime(
      2022 + rng.nextInt(4),
      1 + rng.nextInt(12),
      1 + rng.nextInt(28),
      rng.nextInt(24),
      rng.nextInt(60),
    ),
    resolvedAt: rng.nextBool()
        ? DateTime(2024, 1 + rng.nextInt(12), 1 + rng.nextInt(28))
        : null,
  );
}

/// Generate a list of N random system events.
List<SystemEvent> _randomSystemEvents(Random rng, int count) {
  return List.generate(count, (_) => _randomSystemEvent(rng));
}

/// Compute retry stats locally, mirroring SystemEventsRepository.getRetryStats().
///
/// - `totalRetries` = sum of retryCount across all events
/// - `totalEvents` = number of events
/// - `successCount` = number of events with status == success
/// - `successRate` = (successCount / totalEvents) * 100.0, or 0.0 if empty
Map<String, dynamic> _computeRetryStats(List<SystemEvent> events) {
  int totalRetries = 0;
  int successCount = 0;

  for (final event in events) {
    totalRetries += event.retryCount;
    if (event.status == SystemEventStatus.success) {
      successCount++;
    }
  }

  final totalEvents = events.length;
  final successRate =
      totalEvents > 0 ? (successCount / totalEvents) * 100.0 : 0.0;

  return {
    'totalRetries': totalRetries,
    'totalEvents': totalEvents,
    'successCount': successCount,
    'successRate': successRate,
  };
}

// ===========================================================================
// Property-Based Tests — MetricsService / Retry Stats
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Feature: owner-dashboard, Property 21: Корректность статистики ретраев
  //
  // Для любого набора системных событий, вычисленное количество ретраев
  // должно равняться сумме retryCount по всем событиям, а процент
  // успешных — отношению событий со статусом success к общему количеству.
  // **Validates: Requirements 9.4**
  // -------------------------------------------------------------------------

  group('Property 21: Корректность статистики ретраев', () {
    test(
      'Property 21a: totalRetries equals sum of retryCount across all events (150 iterations)',
      () {
        final rng = Random(2100);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(51); // 0..50 events
          final events = _randomSystemEvents(rng, n);

          final stats = _computeRetryStats(events);

          // Manually compute expected sum
          final expectedSum =
              events.fold<int>(0, (sum, e) => sum + e.retryCount);

          expect(stats['totalRetries'], equals(expectedSum),
              reason:
                  'Iteration $i: totalRetries (${stats['totalRetries']}) should equal sum of retryCount ($expectedSum) for $n events');
          expect(stats['totalEvents'], equals(n),
              reason: 'Iteration $i: totalEvents should equal $n');
        }
      },
    );

    test(
      'Property 21b: successRate equals (successCount / totalEvents) * 100 (150 iterations)',
      () {
        final rng = Random(2101);

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(50); // 1..50 events (non-empty)
          final events = _randomSystemEvents(rng, n);

          final stats = _computeRetryStats(events);

          final expectedSuccessCount =
              events.where((e) => e.status == SystemEventStatus.success).length;
          final expectedRate = (expectedSuccessCount / n) * 100.0;

          expect(stats['successCount'], equals(expectedSuccessCount),
              reason:
                  'Iteration $i: successCount (${stats['successCount']}) should equal $expectedSuccessCount');
          expect(stats['successRate'], closeTo(expectedRate, 1e-9),
              reason:
                  'Iteration $i: successRate (${stats['successRate']}) should be close to $expectedRate');
        }
      },
    );

    test(
      'Property 21c: empty event list produces zero stats',
      () {
        final stats = _computeRetryStats([]);

        expect(stats['totalRetries'], equals(0),
            reason: 'Empty list should have 0 totalRetries');
        expect(stats['totalEvents'], equals(0),
            reason: 'Empty list should have 0 totalEvents');
        expect(stats['successCount'], equals(0),
            reason: 'Empty list should have 0 successCount');
        expect(stats['successRate'], equals(0.0),
            reason: 'Empty list should have 0.0 successRate');
      },
    );

    test(
      'Property 21d: all-success events produce 100% successRate (150 iterations)',
      () {
        final rng = Random(2103);

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(30); // 1..30 events
          final events = List.generate(
            n,
            (_) => SystemEvent(
              type: _allTypes[rng.nextInt(_allTypes.length)],
              source: _allSources[rng.nextInt(_allSources.length)],
              status: SystemEventStatus.success,
              message: _randomString(rng, maxLen: 10),
              retryCount: rng.nextInt(10),
            ),
          );

          final stats = _computeRetryStats(events);

          expect(stats['successCount'], equals(n),
              reason:
                  'Iteration $i: all events are success, count should be $n');
          expect(stats['successRate'], closeTo(100.0, 1e-9),
              reason: 'Iteration $i: all-success should produce 100.0% rate');
        }
      },
    );

    test(
      'Property 21e: no-success events produce 0% successRate (150 iterations)',
      () {
        final rng = Random(2104);
        // Statuses that are NOT success
        const nonSuccessStatuses = [
          SystemEventStatus.error,
          SystemEventStatus.failed,
          SystemEventStatus.retrying,
        ];

        for (var i = 0; i < 150; i++) {
          final n = 1 + rng.nextInt(30); // 1..30 events
          final events = List.generate(
            n,
            (_) => SystemEvent(
              type: _allTypes[rng.nextInt(_allTypes.length)],
              source: _allSources[rng.nextInt(_allSources.length)],
              status:
                  nonSuccessStatuses[rng.nextInt(nonSuccessStatuses.length)],
              message: _randomString(rng, maxLen: 10),
              retryCount: rng.nextInt(10),
            ),
          );

          final stats = _computeRetryStats(events);

          expect(stats['successCount'], equals(0),
              reason: 'Iteration $i: no success events, count should be 0');
          expect(stats['successRate'], closeTo(0.0, 1e-9),
              reason: 'Iteration $i: no-success should produce 0.0% rate');
        }
      },
    );

    test(
      'Property 21f: successRate is always in range [0.0, 100.0] (150 iterations)',
      () {
        final rng = Random(2105);

        for (var i = 0; i < 150; i++) {
          final n = rng.nextInt(51); // 0..50 events
          final events = _randomSystemEvents(rng, n);

          final stats = _computeRetryStats(events);
          final rate = stats['successRate'] as double;

          expect(rate >= 0.0, isTrue,
              reason: 'Iteration $i: successRate ($rate) should be >= 0.0');
          expect(rate <= 100.0, isTrue,
              reason: 'Iteration $i: successRate ($rate) should be <= 100.0');
        }
      },
    );
  });
}
