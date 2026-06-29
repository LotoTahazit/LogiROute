import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/company_modules_service.dart';

void main() {
  group('CompanyModulesService', () {
    test('normalizePlan falls back to full', () {
      expect(CompanyModulesService.normalizePlan(null), 'full');
      expect(CompanyModulesService.normalizePlan('unknown'), 'full');
      expect(CompanyModulesService.normalizePlan('logistics'), 'logistics');
    });

    test('entitlementsForPlan matches plan matrix', () {
      final logistics = CompanyModulesService.entitlementsForPlan('logistics');
      expect(logistics.warehouse, false);
      expect(logistics.logistics, true);
      expect(logistics.dispatcher, true);
      expect(logistics.accounting, false);
      expect(logistics.reports, true);

      final warehouseOnly =
          CompanyModulesService.entitlementsForPlan('warehouse_only');
      expect(warehouseOnly.warehouse, true);
      expect(warehouseOnly.logistics, false);
    });

    test('rootEntitlementsPatch includes plan modules and limits', () {
      final patch = CompanyModulesService.rootEntitlementsPatch('ops');
      expect(patch['plan'], 'ops');
      expect(patch['modules'], isA<Map>());
      expect((patch['modules'] as Map)['accounting'], false);
      expect(patch['limits'], isA<Map>());
      expect((patch['limits'] as Map)['maxUsers'], isA<int>());
    });

    test('entitlementsFromRootData uses root modules when present', () {
      final ent = CompanyModulesService.entitlementsFromRootData({
        'plan': 'full',
        'modules': {'warehouse': false, 'logistics': true},
      });
      expect(ent.warehouse, false);
      expect(ent.logistics, true);
    });

    test('entitlementsFromRootData falls back to plan when modules missing', () {
      final ent = CompanyModulesService.entitlementsFromRootData({
        'plan': 'warehouse_only',
      });
      expect(ent.warehouse, true);
      expect(ent.logistics, false);
    });

    group('applyPlan (H4)', () {
      const companyId = 'h4-co';

      test('create company — full plan syncs root + settings mirror', () async {
        final db = FakeFirebaseFirestore();
        await db.collection('companies').doc(companyId).set({'name': 'X'});

        await CompanyModulesService(companyId: companyId, firestore: db)
            .applyPlan('full');

        final root = await db.collection('companies').doc(companyId).get();
        final settings = await db
            .collection('companies')
            .doc(companyId)
            .collection('settings')
            .doc('settings')
            .get();

        expect(root.data()?['plan'], 'full');
        expect(root.data()?['modules'], isA<Map>());
        expect((root.data()?['modules'] as Map)['accounting'], true);
        expect(root.data()?['limits'], isA<Map>());
        expect(settings.data()?['plan'], 'full');
        expect(settings.data()?['modules'], isA<Map>());
      });

      test('upgrade logistics → full', () async {
        final db = FakeFirebaseFirestore();
        final svc = CompanyModulesService(companyId: companyId, firestore: db);
        await svc.applyPlan('logistics');
        await svc.applyPlan('full');

        final root = await db.collection('companies').doc(companyId).get();
        expect(root.data()?['plan'], 'full');
        expect((root.data()?['modules'] as Map)['accounting'], true);
        expect((root.data()?['limits'] as Map)['maxUsers'], 50);
      });

      test('downgrade full → warehouse_only', () async {
        final db = FakeFirebaseFirestore();
        final svc = CompanyModulesService(companyId: companyId, firestore: db);
        await svc.applyPlan('full');
        await svc.applyPlan('warehouse_only');

        final root = await db.collection('companies').doc(companyId).get();
        expect(root.data()?['plan'], 'warehouse_only');
        expect((root.data()?['modules'] as Map)['logistics'], false);
        expect((root.data()?['limits'] as Map)['maxUsers'], 5);
      });

      test('billing cancel does not use applyPlan — plan unchanged', () async {
        final db = FakeFirebaseFirestore();
        await db.collection('companies').doc(companyId).set({
          'plan': 'ops',
          ...CompanyModulesService.rootEntitlementsPatch('ops'),
        });

        await db.collection('companies').doc(companyId).update({
          'billingStatus': 'cancelled',
        });

        final root = await db.collection('companies').doc(companyId).get();
        expect(root.data()?['plan'], 'ops');
        expect((root.data()?['modules'] as Map)['warehouse'], true);
      });
    });
  });
}
