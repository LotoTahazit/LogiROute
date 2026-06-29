/// Режим внедрения после создания компании super_admin.
enum CompanyOnboardingMode {
  selfSetup('self_setup'),
  doneForYou('done_for_you');

  final String value;
  const CompanyOnboardingMode(this.value);

  static CompanyOnboardingMode fromValue(String? raw) {
    switch (raw) {
      case 'done_for_you':
        return CompanyOnboardingMode.doneForYou;
      case 'self_setup':
      default:
        return CompanyOnboardingMode.selfSetup;
    }
  }
}
