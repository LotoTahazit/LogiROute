import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/admin_billing_route_policy.dart';

void main() {
  group('AdminBillingRoutePolicy (H9)', () {
    test('platform super_admin bypasses BillingGuard', () {
      expect(
        AdminBillingRoutePolicy.bypassesBillingGuard('super_admin'),
        isTrue,
      );
    });

    test('company admin uses BillingGuard', () {
      expect(
        AdminBillingRoutePolicy.bypassesBillingGuard('admin'),
        isFalse,
      );
    });
  });
}
