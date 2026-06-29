import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/company_onboarding_mode.dart';
import '../../services/auth_service.dart';
import '../../services/create_company_flow_service.dart';
import '../setup/onboarding_center_screen.dart';
import 'support_console_screen.dart';

class CreateCompanySuccessScreen extends StatelessWidget {
  final CreateCompanyFlowResult result;

  const CreateCompanySuccessScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final companyName = result.companyId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCompanyFlowSuccessTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 56),
          const SizedBox(height: 12),
          Text(
            l10n.createCompanyFlowSuccessBody,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (result.emailDeliveryFailed) ...[
            const SizedBox(height: 16),
            MaterialBanner(
              content: Text(l10n.createCompanyFlowEmailFailed),
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              actions: [
                TextButton(
                  onPressed: () => auth.sendPasswordResetEmail(result.ownerEmail),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (result.onboardingMode == CompanyOnboardingMode.doneForYou)
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingCenterScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch),
              label: Text(l10n.launchCenterOpen),
            ),
          OutlinedButton.icon(
            onPressed: () {
              auth.setVirtualCompanyId(result.companyId);
              auth.setViewAsRole('owner');
            },
            icon: const Icon(Icons.person),
            label: Text(l10n.createCompanyFlowOpenAsOwner),
          ),
          if (result.onboardingMode == CompanyOnboardingMode.doneForYou)
            OutlinedButton.icon(
              onPressed: () {
                auth.setVirtualCompanyId(result.companyId);
                auth.setViewAsRole('dispatcher');
              },
              icon: const Icon(Icons.local_shipping),
              label: Text(l10n.createCompanyFlowOpenAsDispatcher),
            ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportConsoleScreen()),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: Text(l10n.supportConsoleTitle),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final text = CreateCompanyFlowService.invitationText(
                companyName: companyName,
                ownerEmail: result.ownerEmail,
                mode: result.onboardingMode,
              );
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.createCompanyFlowInviteCopied)),
              );
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.createCompanyFlowCopyInvite),
          ),
          const SizedBox(height: 16),
          Text(
            'cid: ${result.correlationId}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
