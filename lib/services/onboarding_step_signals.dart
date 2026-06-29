import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company_settings.dart';
import '../models/company_terminology.dart';
import '../models/delivery_point.dart';import '../models/company_setup_wizard.dart';
import '../models/onboarding_section.dart';
import 'company_terminology_service.dart';
import 'firestore_paths.dart';
import 'gps_health.dart';

/// Загрузка terminology для warehouse-сигнала (тесты подставляют fake без Firebase).
typedef TerminologyLoader = Future<CompanyTerminology> Function(String companyId);

/// Read-only проверки «шаг выполнен» через дешёвые limit(1) запросы.
class OnboardingStepSignals {
  OnboardingStepSignals({
    required this.companyId,
    CompanySettings? companySettings,
    FirebaseFirestore? firestore,
    TerminologyLoader? terminologyLoader,
  })  : _companySettings = companySettings,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _terminologyLoader = terminologyLoader;
  final String companyId;
  final CompanySettings? _companySettings;
  final FirebaseFirestore _firestore;
  final TerminologyLoader? _terminologyLoader;
  FirestorePaths get _paths => FirestorePaths(firestore: _firestore);

  Future<Map<SetupWizardStepId, bool>> checkAll() async {
    final settings = _companySettings ??
        CompanySettings.fromFirestore(
          await _firestore.collection('companies').doc(companyId).get(),
        );

    final results = await Future.wait([
      _hasDoc(_paths.clients(companyId)),
      _hasDoc(_paths.productTypes(companyId)),
      _hasDriver(),
      _hasWarehouse(),
      _hasAccounting(settings),
      _hasGps(),
      _hasDoc(_paths.routes(companyId)),
      _hasCompletedDelivery(),
    ]);

    return {
      SetupWizardStepId.companyInfo: _companyInfoDone(settings),
      SetupWizardStepId.importClients: results[0],
      SetupWizardStepId.importProducts: results[1],
      SetupWizardStepId.addDrivers: results[2],
      SetupWizardStepId.warehouseSetup: results[3],
      SetupWizardStepId.accountingSetup: results[4],
      SetupWizardStepId.gpsCheck: results[5],
      SetupWizardStepId.firstRoute: results[6],
      SetupWizardStepId.testDelivery: results[7],
    };
  }

  /// Сигналы карточек Launch Center (включая signal-only).
  Future<Map<OnboardingSectionId, bool>> checkCardSignals() async {
    final steps = await checkAll();
    final ownerAdmin = await _hasOwnerOrAdmin();
    return {
      OnboardingSectionId.companyDetails:
          steps[SetupWizardStepId.companyInfo] == true,
      OnboardingSectionId.firstOwnerAdmin: ownerAdmin,
      OnboardingSectionId.clients: steps[SetupWizardStepId.importClients] == true,
      OnboardingSectionId.products:
          steps[SetupWizardStepId.importProducts] == true,
      OnboardingSectionId.drivers: steps[SetupWizardStepId.addDrivers] == true,
      OnboardingSectionId.warehouse:
          steps[SetupWizardStepId.warehouseSetup] == true,
      OnboardingSectionId.accounting:
          steps[SetupWizardStepId.accountingSetup] == true,
      OnboardingSectionId.gps: steps[SetupWizardStepId.gpsCheck] == true,
      OnboardingSectionId.firstRoute: steps[SetupWizardStepId.firstRoute] == true,
      OnboardingSectionId.testDelivery:
          steps[SetupWizardStepId.testDelivery] == true,
      OnboardingSectionId.goLive: false,
    };
  }

  bool _companyInfoDone(CompanySettings s) {
    return s.nameHebrew.trim().isNotEmpty && s.taxId.trim().isNotEmpty;
  }

  Future<bool> _hasDoc(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> _hasDriver() async {
    final snap = await _paths
        .members(companyId)
        .where('role', isEqualTo: 'driver')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return true;
    // Fallback: createUser раньше писал только users/, без members/
    final usersSnap = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .limit(50)
        .get();
    return usersSnap.docs.any((d) => d.data()['role'] == 'driver');
  }

  Future<bool> _hasOwnerOrAdmin() async {
    for (final role in ['owner', 'admin']) {
      final snap = await _paths
          .members(companyId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return true;
    }
    final usersSnap = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .limit(50)
        .get();
    return usersSnap.docs.any((d) {
      final role = d.data()['role'] as String?;
      return role == 'owner' || role == 'admin';
    });
  }

  Future<bool> _hasWarehouse() async {
    final terminology = _terminologyLoader != null
        ? await _terminologyLoader!(companyId)
        : await CompanyTerminologyService(companyId: companyId).getTerminology();    if (terminology.warehouseStructure.configured) return true;
    if (await _hasDoc(_paths.inventory(companyId))) return true;
    return _hasDoc(_paths.productTypes(companyId));
  }

  Future<bool> _hasAccounting(CompanySettings settings) async {
    if (settings.accountingProvider != 'none' &&
        settings.accountingProvider.isNotEmpty) {
      return true;
    }
    return _hasDoc(_paths.invoices(companyId));
  }

  Future<bool> _hasGps() async {
    final snap = await _paths.driverLocations(companyId).limit(50).get();
    return GpsHealth.onboardingGpsComplete(
      snap.docs.map((d) => d.data()),
    );
  }

  Future<bool> _hasCompletedDelivery() async {
    final statuses = [
      DeliveryPoint.statusCompleted,
      DeliveryPoint.statusCompletedHe,
      DeliveryPoint.statusCompletedRu,
      DeliveryPoint.statusCompletedRuAlt,
    ];
    final snap = await _paths
        .deliveryPoints(companyId)
        .where('status', whereIn: statuses)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
