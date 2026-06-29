/// H9: политика BillingGuard для AdminDashboard.
class AdminBillingRoutePolicy {
  AdminBillingRoutePolicy._();

  /// Только platform super_admin обходит billing gate для AdminDashboard.
  /// super_admin view-as admin → effectiveRole `admin` → guard включён.
  static bool bypassesBillingGuard(String effectiveRole) =>
      effectiveRole == 'super_admin';
}
