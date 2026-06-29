import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/firestore_paths.dart';
import 'package:logiroute/services/gps_health.dart';

void main() {
  const companyId = 'acme-co';

  group('FirestorePaths driver_locations', () {
    test('driverLocations returns companies/{id}/driver_locations', () {
      final paths = FirestorePaths(firestore: FakeFirebaseFirestore());
      expect(
        paths.driverLocations(companyId).path,
        'companies/$companyId/driver_locations',
      );
    });
  });

  group('GpsHealth onboarding', () {
    final now = DateTime(2026, 6, 21, 12);

    test('false when driver_locations empty', () {
      expect(GpsHealth.onboardingGpsComplete([]), false);
    });

    test('true with fresh valid fix', () {
      final doc = {
        'isOnShift': true,
        'latitude': 32.08,
        'longitude': 34.78,
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      };
      expect(GpsHealth.onboardingGpsComplete([doc]), true);
    });

    test('false when fix older than 48h', () {
      expect(
        GpsHealth.hasFreshValidFix({
          'latitude': 32.08,
          'longitude': 34.78,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 72))),
        }, now: now),
        false,
      );
    });

    test('stale counts on-shift without fresh fix', () {
      final counts = GpsHealth.summarizeDocs([
        {
          'isOnShift': true,
          'latitude': 32.08,
          'longitude': 34.78,
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 72))),
        },
        {'isOnShift': false, 'latitude': 32.0, 'longitude': 34.0},
      ], now: now);
      expect(counts.stale, 1);
      expect(counts.offline, 1);
      expect(counts.active, 0);
    });
  });
}
