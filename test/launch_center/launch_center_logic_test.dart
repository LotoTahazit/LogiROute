import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_setup_wizard.dart';
import 'package:logiroute/models/launch_card_meta.dart';
import 'package:logiroute/models/launch_center_logic.dart';
import 'package:logiroute/models/onboarding_section.dart';

void main() {
  group('LaunchCenterLogic', () {
    test('owner and super_admin see Launch Center; driver does not', () {
      expect(LaunchCenterLogic.canSeeLaunchCenter('owner'), isTrue);
      expect(LaunchCenterLogic.canSeeLaunchCenter('admin'), isTrue);
      expect(LaunchCenterLogic.canSeeLaunchCenter('super_admin'), isTrue);
      expect(LaunchCenterLogic.canSeeLaunchCenter('driver'), isFalse);
      expect(LaunchCenterLogic.canSeeLaunchCenter('dispatcher'), isFalse);
    });

    test('auto-signal completes clients card', () {
      final state = CompanySetupWizardState.initial();
      final stepSignals = {
        SetupWizardStepId.importClients: true,
      };
      final cardSignals = {
        OnboardingSectionId.clients: true,
      };
      expect(
        LaunchCenterLogic.cardStatus(
          OnboardingSectionId.clients,
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        ),
        OnboardingSectionStatus.completed,
      );
    });

    test('required cards done => company ready', () {
      final steps = {
        for (final s in SetupWizardStepId.ordered)
          s: SetupWizardStepStatus.notStarted,
      };
      steps[SetupWizardStepId.companyInfo] = SetupWizardStepStatus.completed;
      steps[SetupWizardStepId.addDrivers] = SetupWizardStepStatus.completed;
      steps[SetupWizardStepId.gpsCheck] = SetupWizardStepStatus.completed;
      steps[SetupWizardStepId.firstRoute] = SetupWizardStepStatus.completed;
      steps[SetupWizardStepId.testDelivery] = SetupWizardStepStatus.completed;

      final state = CompanySetupWizardState.initial().copyWith(steps: steps);
      final stepSignals = {
        for (final s in SetupWizardStepId.ordered) s: true,
      };
      final cardSignals = {
        for (final c in OnboardingSectionId.ordered) c: true,
      };

      expect(
        LaunchCenterLogic.isCompanyReady(
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        ),
        isTrue,
      );
    });

    test('skipped optional card counts as done for progress', () {
      final state = CompanySetupWizardState.initial().copyWith(
        steps: {
          SetupWizardStepId.importClients: SetupWizardStepStatus.skipped,
        },
      );
      expect(
        LaunchCenterLogic.isCardDone(
          OnboardingSectionId.clients,
          state,
          stepSignals: const {},
          cardSignals: const {},
        ),
        isTrue,
      );
    });
  });

  group('LaunchCardMeta persistence', () {
    test('assignment role persists in setup_wizard map', () {
      final state = CompanySetupWizardState.initial().copyWith(
        cardMeta: {
          OnboardingSectionId.clients: const LaunchCardMeta(
            assignedRole: 'dispatcher',
            notes: 'Import CSV',
          ),
        },
      );
      final restored = CompanySetupWizardState.fromMap(state.toMap());
      expect(
        restored.metaOf(OnboardingSectionId.clients).assignedRole,
        'dispatcher',
      );
      expect(restored.metaOf(OnboardingSectionId.clients).notes, 'Import CSV');
    });
  });
}
