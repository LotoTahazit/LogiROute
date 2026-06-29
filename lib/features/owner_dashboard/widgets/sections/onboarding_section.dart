import 'package:flutter/material.dart';

import '../../../../models/company_settings.dart';
import '../../../../screens/setup/onboarding_center_screen.dart';

class OnboardingSection extends StatelessWidget {
  const OnboardingSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  final String companyId;
  final CompanySettings companySettings;

  @override
  Widget build(BuildContext context) {
    return OnboardingCenterScreen(
      companyId: companyId,
      companySettings: companySettings,
      embedded: true,
    );
  }
}
