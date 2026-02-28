import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/screens/admin/billing/billing_helpers.dart';

void main() {
  // -------------------------------------------------------------------------
  // planDisplayInfo
  // -------------------------------------------------------------------------
  group('planDisplayInfo', () {
    test('contains all four plans', () {
      expect(planDisplayInfo.keys,
          containsAll(['warehouse_only', 'ops', 'full', 'custom']));
    });

    test('warehouse_only has correct values', () {
      final info = planDisplayInfo['warehouse_only']!;
      expect(info.name, 'מחסן בלבד');
      expect(info.price, '₪149');
      expect(info.modules, ['warehouse']);
    });

    test('ops has correct values', () {
      final info = planDisplayInfo['ops']!;
      expect(info.name, 'תפעול');
      expect(info.price, '₪299');
      expect(info.modules, ['warehouse', 'logistics', 'dispatcher']);
    });

    test('full has correct values', () {
      final info = planDisplayInfo['full']!;
      expect(info.name, 'מלא');
      expect(info.price, '₪499');
      expect(info.modules,
          ['warehouse', 'logistics', 'dispatcher', 'accounting', 'reports']);
    });

    test('custom has dash price and empty modules', () {
      final info = planDisplayInfo['custom']!;
      expect(info.name, 'מותאם אישית');
      expect(info.price, '—');
      expect(info.modules, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // statusColors
  // -------------------------------------------------------------------------
  group('statusColors', () {
    test('maps all five statuses to correct colors', () {
      expect(statusColors['active'], Colors.green);
      expect(statusColors['trial'], Colors.blue);
      expect(statusColors['grace'], Colors.orange);
      expect(statusColors['suspended'], Colors.red);
      expect(statusColors['cancelled'], Colors.grey);
    });
  });

  // -------------------------------------------------------------------------
  // remainingDays
  // -------------------------------------------------------------------------
  group('remainingDays', () {
    test('future date returns positive days', () {
      final now = DateTime(2024, 6, 1);
      final paidUntil = DateTime(2024, 6, 11);
      expect(remainingDays(paidUntil, now), 10);
    });

    test('past date returns negative days', () {
      final now = DateTime(2024, 6, 11);
      final paidUntil = DateTime(2024, 6, 1);
      expect(remainingDays(paidUntil, now), -10);
    });

    test('same date returns zero', () {
      final now = DateTime(2024, 6, 1);
      expect(remainingDays(now, now), 0);
    });
  });

  // -------------------------------------------------------------------------
  // usageWarningLevel
  // -------------------------------------------------------------------------
  group('usageWarningLevel', () {
    test('below 80% returns normal', () {
      expect(usageWarningLevel(79, 100), UsageWarningLevel.normal);
      expect(usageWarningLevel(0, 100), UsageWarningLevel.normal);
    });

    test('at 80% returns warning', () {
      expect(usageWarningLevel(80, 100), UsageWarningLevel.warning);
    });

    test('between 80% and 100% returns warning', () {
      expect(usageWarningLevel(99, 100), UsageWarningLevel.warning);
    });

    test('at 100% returns critical', () {
      expect(usageWarningLevel(100, 100), UsageWarningLevel.critical);
    });

    test('above 100% returns critical', () {
      expect(usageWarningLevel(150, 100), UsageWarningLevel.critical);
    });
  });

  // -------------------------------------------------------------------------
  // availablePlans
  // -------------------------------------------------------------------------
  group('availablePlans', () {
    test('excludes current plan', () {
      expect(availablePlans('ops'), isNot(contains('ops')));
      expect(availablePlans('ops'), ['warehouse_only', 'full']);
    });

    test('never includes custom', () {
      expect(availablePlans('custom'), isNot(contains('custom')));
      expect(availablePlans('custom'), ['warehouse_only', 'ops', 'full']);
    });

    test('returns two plans when current is in the standard set', () {
      expect(availablePlans('warehouse_only'), hasLength(2));
      expect(availablePlans('full'), hasLength(2));
    });
  });

  // -------------------------------------------------------------------------
  // formatUsage
  // -------------------------------------------------------------------------
  group('formatUsage', () {
    test('formats as X / Y', () {
      expect(formatUsage(5, 10), '5 / 10');
      expect(formatUsage(0, 100), '0 / 100');
      expect(formatUsage(999, 1000), '999 / 1000');
    });
  });
}
