import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_setup_wizard.dart';
import 'package:logiroute/models/company_terminology.dart';
import 'package:logiroute/services/firestore_paths.dart';
import 'package:logiroute/services/onboarding_step_signals.dart';

const _companyId = 'c1';

OnboardingStepSignals _gpsSignals(FakeFirebaseFirestore db) =>
    OnboardingStepSignals(
      companyId: _companyId,
      firestore: db,
      terminologyLoader: (_) async => CompanyTerminology(companyId: _companyId),
    );

void main() {
  test('onboarding gpsCheck false when driver_locations empty', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('companies').doc(_companyId).set({'nameHebrew': 'X'});

    final all = await _gpsSignals(db).checkAll();
    expect(all[SetupWizardStepId.gpsCheck], false);
  });

  test('onboarding gpsCheck true with fresh valid fix in driver_locations',
      () async {
    final db = FakeFirebaseFirestore();
    await db.collection('companies').doc(_companyId).set({'nameHebrew': 'X'});
    final paths = FirestorePaths(firestore: db);
    await paths.driverLocations(_companyId).doc('d1').set({
      'isOnShift': true,
      'latitude': 32.08,
      'longitude': 34.78,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
    });

    final all = await _gpsSignals(db).checkAll();
    expect(all[SetupWizardStepId.gpsCheck], true);
  });
}