import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_onboarding_mode.dart';
import 'package:logiroute/services/company_modules_service.dart';
import 'package:logiroute/services/company_provision_service.dart';
import 'package:logiroute/services/company_setup_wizard_service.dart';
import 'package:logiroute/services/create_company_flow_service.dart';
import 'package:logiroute/services/cross_module_audit_service.dart';
import 'package:logiroute/services/demo_company_service.dart';

void main() {
  const validInput = CreateCompanyFlowInput(
    companyId: 'acme-logistics',
    nameHebrew: 'אקמי',
    nameEnglish: 'Acme',
    taxId: '514567890',
    plan: 'logistics',
    ownerName: 'Owner One',
    ownerEmail: 'owner@acme.test',
    initialRole: 'owner',
    onboardingMode: CompanyOnboardingMode.selfSetup,
    createdByUid: 'super-1',
  );

  group('CreateCompanyFlowService.validateInput', () {
    test('accepts valid self_setup input', () {
      expect(CreateCompanyFlowService.validateInput(validInput), isNull);
    });

    test('blocks missing owner name', () {
      expect(
        CreateCompanyFlowService.validateInput(
          CreateCompanyFlowInput(
            companyId: 'acme-logistics',
            nameHebrew: 'אקמי',
            nameEnglish: 'Acme',
            taxId: '514567890',
            plan: 'full',
            ownerName: '',
            ownerEmail: 'o@x.test',
            initialRole: 'owner',
            onboardingMode: CompanyOnboardingMode.selfSetup,
            createdByUid: 'super-1',
          ),
        ),
        'missing_owner_name',
      );
    });

    test('blocks missing owner email', () {
      expect(
        CreateCompanyFlowService.validateInput(
          CreateCompanyFlowInput(
            companyId: 'acme-logistics',
            nameHebrew: 'אקמי',
            nameEnglish: 'Acme',
            taxId: '514567890',
            plan: 'full',
            ownerName: 'O',
            ownerEmail: '  ',
            initialRole: 'owner',
            onboardingMode: CompanyOnboardingMode.selfSetup,
            createdByUid: 'super-1',
          ),
        ),
        'missing_owner_email',
      );
    });

    test('blocks invalid plan', () {
      expect(
        CreateCompanyFlowService.validateInput(
          CreateCompanyFlowInput(
            companyId: 'acme-logistics',
            nameHebrew: 'אקמי',
            nameEnglish: 'Acme',
            taxId: '514567890',
            plan: 'enterprise',
            ownerName: 'O',
            ownerEmail: 'o@x.test',
            initialRole: 'owner',
            onboardingMode: CompanyOnboardingMode.selfSetup,
            createdByUid: 'super-1',
          ),
        ),
        'invalid_plan',
      );
    });

    test('blocks invalid initial role', () {
      expect(
        CreateCompanyFlowService.validateInput(
          CreateCompanyFlowInput(
            companyId: 'acme-logistics',
            nameHebrew: 'אקמי',
            nameEnglish: 'Acme',
            taxId: '514567890',
            plan: 'full',
            ownerName: 'O',
            ownerEmail: 'o@x.test',
            initialRole: 'dispatcher',
            onboardingMode: CompanyOnboardingMode.selfSetup,
            createdByUid: 'super-1',
          ),
        ),
        'invalid_initial_role',
      );
    });
  });

  group('CompanyOnboardingMode', () {
    test('fromValue maps done_for_you', () {
      expect(
        CompanyOnboardingMode.fromValue('done_for_you'),
        CompanyOnboardingMode.doneForYou,
      );
    });

    test('fromValue defaults to self_setup', () {
      expect(
        CompanyOnboardingMode.fromValue(null),
        CompanyOnboardingMode.selfSetup,
      );
    });
  });

  group('provision + plan (create company)', () {
    test('applyPlan after root doc matches create flow plan/modules', () async {
      final db = FakeFirebaseFirestore();
      const id = 'new-co-self';
      await db.collection('companies').doc(id).set({
        'nameHebrew': 'חברה',
        'country': 'Israel',
        'defaultLanguage': 'he',
        'timezone': 'Asia/Jerusalem',
        'onboardingMode': CompanyOnboardingMode.selfSetup.value,
        'billingStatus': 'trial',
      });

      await CompanyModulesService(companyId: id, firestore: db).applyPlan('logistics');

      final root = await db.collection('companies').doc(id).get();
      expect(root.data()?['plan'], 'logistics');
      expect(root.data()?['modules'], isA<Map>());
      expect(root.data()?['limits'], isA<Map>());
      expect((root.data()?['limits'] as Map)['maxUsers'], isA<int>());
    });

    test('done_for_you onboardingMode on root doc', () async {
      final db = FakeFirebaseFirestore();
      const id = 'new-co-dfy';
      await db.collection('companies').doc(id).set({
        'onboardingMode': CompanyOnboardingMode.doneForYou.value,
      });
      final root = await db.collection('companies').doc(id).get();
      expect(root.data()?['onboardingMode'], 'done_for_you');
    });
  });

  test('initialFirestorePayload records onboardingMode', () {
    final payload = CompanySetupWizardService.initialFirestorePayload(
      updatedBy: 'super-1',
      onboardingMode: CompanyOnboardingMode.doneForYou.value,
    );
    expect(payload['onboardingMode'], 'done_for_you');
    expect(payload['wizardCompleted'], isFalse);
    expect(payload['steps'], isA<Map>());
  });

  test('audit types for create company flow are defined', () {
    expect(CrossModuleAuditService.typeCompanyCreated, 'company_created');
    expect(CrossModuleAuditService.typeInitialOwnerCreated, 'initial_owner_created');
    expect(
      CrossModuleAuditService.typeOnboardingModeSelected,
      'onboarding_mode_selected',
    );
  });

  test('invitationText differs by onboarding mode', () {
    final self = CreateCompanyFlowService.invitationText(
      companyName: 'Acme',
      ownerEmail: 'o@acme.test',
      mode: CompanyOnboardingMode.selfSetup,
    );
    final dfy = CreateCompanyFlowService.invitationText(
      companyName: 'Acme',
      ownerEmail: 'o@acme.test',
      mode: CompanyOnboardingMode.doneForYou,
    );
    expect(self, contains('Launch Center'));
    expect(dfy, contains('Done-for-you'));
  });

  test('demo company id is separate from provision slug validation', () {
    expect(DemoCompanyService.companyId, 'demo-foods-israel');
    expect(
      CompanyProvisionService.isValidCompanyId(DemoCompanyService.companyId),
      isTrue,
    );
    expect(CompanyModulesService.planModules.containsKey('full'), isTrue);
  });
}
