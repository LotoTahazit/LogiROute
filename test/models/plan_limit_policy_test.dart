import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/plan_limit_policy.dart';

void main() {
  group('PlanLimitPolicy (H5)', () {
    test('maxUsers and maxDocs are soft on pilot', () {
      expect(
        PlanLimitPolicy.enforcement(PlanLimitKey.maxUsers),
        LimitEnforcement.soft,
      );
      expect(
        PlanLimitPolicy.enforcement(PlanLimitKey.maxDocsPerMonth),
        LimitEnforcement.soft,
      );
      expect(PlanLimitPolicy.blocks(PlanLimitKey.maxUsers), isFalse);
    });

    test('maxRoutesPerDay is not enforced', () {
      expect(
        PlanLimitPolicy.enforcement(PlanLimitKey.maxRoutesPerDay),
        LimitEnforcement.notEnforced,
      );
    });

    test('isOverLimit and isNearLimit thresholds', () {
      expect(PlanLimitPolicy.isOverLimit(10, 10), isTrue);
      expect(PlanLimitPolicy.isOverLimit(9, 10), isFalse);
      expect(PlanLimitPolicy.isNearLimit(8, 10), isTrue);
      expect(PlanLimitPolicy.isNearLimit(10, 10), isFalse);
    });
  });
}
