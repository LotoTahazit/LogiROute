import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:logiroute/screens/admin/billing/billing_helpers.dart';



void main() {

  group('planDisplayInfo', () {

    test('contains all four plans', () {

      expect(

        planDisplayInfo.keys,

        containsAll(['logistics', 'warehouse_only', 'ops', 'full']),

      );

      expect(planDisplayInfo.keys, hasLength(4));

    });



    test('logistics has correct values', () {

      final info = planDisplayInfo['logistics']!;

      expect(info.promoPrice, '₪1,490');

      expect(info.price, '₪1,990');

      expect(info.setupFee, '₪2,000');

      expect(info.modules, ['logistics', 'dispatcher', 'reports']);

    });



    test('warehouse_only has correct values', () {

      final info = planDisplayInfo['warehouse_only']!;

      expect(info.promoPrice, '₪990');

      expect(info.price, '₪1,290');

      expect(info.setupFee, '₪1,500');

      expect(info.modules, ['warehouse']);

    });



    test('ops has correct values', () {

      final info = planDisplayInfo['ops']!;

      expect(info.promoPrice, '₪2,290');

      expect(info.price, '₪2,990');

      expect(info.setupFee, '₪3,000');

      expect(info.modules, ['warehouse', 'logistics', 'dispatcher', 'reports']);

    });



    test('full has correct values', () {

      final info = planDisplayInfo['full']!;

      expect(info.promoPrice, '₪2,990');

      expect(info.price, '₪3,990');

      expect(info.setupFee, '₪5,000');

      expect(info.modules,

          ['warehouse', 'logistics', 'dispatcher', 'accounting', 'reports']);

    });

  });



  group('billingAddons', () {

    test('driver and warehouse overage defaults', () {

      expect(billingAddons.includedDrivers, 5);

      expect(billingAddons.extraDriverPerMonth, 99);

      expect(billingAddons.includedWarehouseLocations, 1);

      expect(billingAddons.extraWarehousePerMonth, 199);

    });

  });



  group('availablePlans', () {

    test('excludes current plan', () {

      expect(availablePlans('ops'), isNot(contains('ops')));

      expect(availablePlans('ops'),

          ['logistics', 'warehouse_only', 'full']);

    });



    test('unknown plan returns all four', () {

      expect(availablePlans('unknown'),

          ['logistics', 'warehouse_only', 'ops', 'full']);

    });

  });



  group('remainingDays', () {

    test('future date returns positive days', () {

      final now = DateTime(2024, 6, 1);

      final paidUntil = DateTime(2024, 6, 11);

      expect(remainingDays(paidUntil, now), 10);

    });

  });



  group('usageWarningLevel', () {

    test('at 100% returns critical', () {

      expect(usageWarningLevel(100, 100), UsageWarningLevel.critical);

    });

  });



  group('formatUsage', () {

    test('formats as X / Y', () {

      expect(formatUsage(5, 10), '5 / 10');

    });

  });

}


