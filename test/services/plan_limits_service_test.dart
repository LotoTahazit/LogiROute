import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_settings.dart';
import 'package:logiroute/services/plan_limits_service.dart';

void main() {
  group('PlanLimitsService (H5)', () {
    test('defaultLimitsForPlan matches plan matrix', () {
      expect(
        PlanLimitsService.defaultLimitsForPlan('warehouse_only').maxUsers,
        5,
      );
      expect(
        PlanLimitsService.defaultLimitsForPlan('full').maxDocsPerMonth,
        10000,
      );
    });

    test('resolveLimits uses plan fallback when limits missing', () {
      final limits = PlanLimitsService.resolveLimits(
        limitsMap: null,
        plan: 'ops',
      );
      expect(limits.maxUsers, 15);
      expect(limits.maxDocsPerMonth, 2000);
    });

    test('resolveLimits merges partial root limits with plan defaults', () {
      final limits = PlanLimitsService.resolveLimits(
        limitsMap: {'maxUsers': 20},
        plan: 'full',
      );
      expect(limits.maxUsers, 20);
      expect(limits.maxDocsPerMonth, 10000);
    });

    test('fromMap null uses full plan defaults not magic 999', () {
      final limits = PlanLimits.fromMap(null, plan: 'full');
      expect(limits.maxUsers, 50);
      expect(limits.maxDocsPerMonth, 10000);
      expect(limits.maxUsers, isNot(999));
    });
  });
}
