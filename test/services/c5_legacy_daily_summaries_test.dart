import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// C5: root daily_summaries отключён; KPI = companies/{id}/metrics/daily/days/{date}.
void main() {
  final libRoot = Directory.current.path.contains('test')
      ? Directory('${Directory.current.path}/../lib')
      : Directory('${Directory.current.path}/lib');

  test('invoice_service does not reference legacy SummaryService', () {
    final src = File('${libRoot.path}/services/invoice_service.dart')
        .readAsStringSync();
    expect(src.contains('summary_service'), isFalse);
    expect(src.contains('SummaryService'), isFalse);
    expect(src.contains("collection('daily_summaries')"), isFalse);
  });

  test('no runtime write to root daily_summaries in lib/', () {
    final hits = <String>[];
    for (final f in libRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final content = f.readAsStringSync();
      if (content.contains("collection('daily_summaries')") &&
          !f.path.endsWith('firestore_paths.dart')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: 'root daily_summaries writes: $hits');
  });

  test('Owner Overview uses MetricsService (metrics/daily/days)', () {
    final overviewSrc = File(
            '${libRoot.path}/features/owner_dashboard/widgets/sections/overview_section.dart')
        .readAsStringSync();
    expect(overviewSrc, contains('MetricsService'));
    expect(overviewSrc, contains('recalculateDailyMetrics'));

    final metricsSrc = File(
            '${libRoot.path}/features/owner_dashboard/services/metrics_service.dart')
        .readAsStringSync();
    expect(metricsSrc, contains("collection('metrics')"));
    expect(metricsSrc, contains("collection('days')"));
    expect(metricsSrc, contains('recalculateDailyMetrics'));
  });
}
