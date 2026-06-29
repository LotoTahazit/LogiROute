import 'company_setup_wizard.dart';

/// 11 карточек Launch Center (UI поверх wizard steps + сигналов).
enum OnboardingSectionId {
  companyDetails,
  firstOwnerAdmin,
  drivers,
  clients,
  products,
  warehouse,
  accounting,
  gps,
  firstRoute,
  testDelivery,
  goLive;

  static const ordered = OnboardingSectionId.values;

  String get storageKey => name;

  List<SetupWizardStepId> get wizardSteps {
    switch (this) {
      case OnboardingSectionId.companyDetails:
        return [SetupWizardStepId.companyInfo];
      case OnboardingSectionId.firstOwnerAdmin:
        return const [];
      case OnboardingSectionId.clients:
        return [SetupWizardStepId.importClients];
      case OnboardingSectionId.products:
        return [SetupWizardStepId.importProducts];
      case OnboardingSectionId.drivers:
        return [SetupWizardStepId.addDrivers];
      case OnboardingSectionId.warehouse:
        return [SetupWizardStepId.warehouseSetup];
      case OnboardingSectionId.accounting:
        return [SetupWizardStepId.accountingSetup];
      case OnboardingSectionId.gps:
        return [SetupWizardStepId.gpsCheck];
      case OnboardingSectionId.firstRoute:
        return [SetupWizardStepId.firstRoute];
      case OnboardingSectionId.testDelivery:
        return [SetupWizardStepId.testDelivery];
      case OnboardingSectionId.goLive:
        return [SetupWizardStepId.ready];
    }
  }

  /// Карточка завершается только по сигналу Firestore (без wizard step).
  bool get isSignalOnly => this == OnboardingSectionId.firstOwnerAdmin;

  int get estimatedMinutes {
    switch (this) {
      case OnboardingSectionId.companyDetails:
        return 10;
      case OnboardingSectionId.firstOwnerAdmin:
        return 5;
      case OnboardingSectionId.clients:
      case OnboardingSectionId.products:
        return 10;
      case OnboardingSectionId.drivers:
        return 10;
      case OnboardingSectionId.warehouse:
        return 15;
      case OnboardingSectionId.accounting:
        return 20;
      case OnboardingSectionId.gps:
        return 5;
      case OnboardingSectionId.firstRoute:
        return 15;
      case OnboardingSectionId.testDelivery:
        return 20;
      case OnboardingSectionId.goLive:
        return 5;
    }
  }

  bool get isRequired {
    switch (this) {
      case OnboardingSectionId.companyDetails:
      case OnboardingSectionId.firstOwnerAdmin:
      case OnboardingSectionId.drivers:
      case OnboardingSectionId.gps:
      case OnboardingSectionId.firstRoute:
      case OnboardingSectionId.testDelivery:
        return true;
      default:
        return false;
    }
  }

  /// Роли, которым можно делегировать карточку.
  static const assignableRoles = [
    'owner',
    'dispatcher',
    'warehouse_keeper',
    'accountant',
  ];
}

enum OnboardingSectionStatus {
  notStarted,
  inProgress,
  completed,
  skipped,
}
