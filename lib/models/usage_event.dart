/// Pilot usage events — без PII, append-only.
enum UsageEventName {
  onboardingStepOpened('onboarding_step_opened'),
  onboardingStepCompleted('onboarding_step_completed'),
  importStarted('import_started'),
  importCompleted('import_completed'),
  routeCreated('route_created'),
  driverAssigned('driver_assigned'),
  deliveryCompleted('delivery_completed'),
  invoiceCreated('invoice_created'),
  checkoutStarted('checkout_started'),
  supportOpened('support_opened'),
  reportOpened('report_opened'),
  exportStarted('export_started');

  const UsageEventName(this.value);
  final String value;

  static const allValues = UsageEventName.values;

  static UsageEventName? tryParse(String raw) {
    for (final e in values) {
      if (e.value == raw) return e;
    }
    return null;
  }
}
