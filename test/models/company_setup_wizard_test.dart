import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_setup_wizard.dart';

void main() {
  test('required steps cannot be skipped', () {
    expect(SetupWizardStepId.companyInfo.canSkip, isFalse);
    expect(SetupWizardStepId.importClients.canSkip, isTrue);
    expect(SetupWizardStepId.testDelivery.canSkip, isFalse);
  });

  test('allRequiredDone when required steps completed', () {
    final state = CompanySetupWizardState.initial().copyWith(
      steps: {
        SetupWizardStepId.companyInfo: SetupWizardStepStatus.completed,
        SetupWizardStepId.importClients: SetupWizardStepStatus.skipped,
        SetupWizardStepId.importProducts: SetupWizardStepStatus.skipped,
        SetupWizardStepId.addDrivers: SetupWizardStepStatus.completed,
        SetupWizardStepId.warehouseSetup: SetupWizardStepStatus.skipped,
        SetupWizardStepId.accountingSetup: SetupWizardStepStatus.skipped,
        SetupWizardStepId.gpsCheck: SetupWizardStepStatus.completed,
        SetupWizardStepId.firstRoute: SetupWizardStepStatus.completed,
        SetupWizardStepId.testDelivery: SetupWizardStepStatus.completed,
        SetupWizardStepId.ready: SetupWizardStepStatus.notStarted,
      },
    );
    expect(state.allRequiredDone, isTrue);
  });

  test('applySignalUpgrades upgrades notStarted/inProgress only', () {
    final base = {
      SetupWizardStepId.companyInfo: SetupWizardStepStatus.notStarted,
      SetupWizardStepId.gpsCheck: SetupWizardStepStatus.inProgress,
      SetupWizardStepId.addDrivers: SetupWizardStepStatus.completed,
      SetupWizardStepId.importClients: SetupWizardStepStatus.skipped,
    };
    final signals = {
      SetupWizardStepId.companyInfo: true,
      SetupWizardStepId.gpsCheck: true,
      SetupWizardStepId.addDrivers: false,
      SetupWizardStepId.importClients: true,
    };
    final out = CompanySetupWizardState.applySignalUpgrades(base, signals)!;
    expect(out[SetupWizardStepId.companyInfo], SetupWizardStepStatus.completed);
    expect(out[SetupWizardStepId.gpsCheck], SetupWizardStepStatus.completed);
    expect(out[SetupWizardStepId.addDrivers], SetupWizardStepStatus.completed);
    expect(out[SetupWizardStepId.importClients], SetupWizardStepStatus.skipped);
  });

  test('applySignalUpgrades never downgrades when signal is false', () {
    final base = {
      SetupWizardStepId.gpsCheck: SetupWizardStepStatus.completed,
    };
    final out = CompanySetupWizardState.applySignalUpgrades(base, {
      SetupWizardStepId.gpsCheck: false,
    });
    expect(out, isNull);
    expect(base[SetupWizardStepId.gpsCheck], SetupWizardStepStatus.completed);
  });
}
