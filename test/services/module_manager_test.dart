import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_settings.dart';
import 'package:logiroute/services/module_manager.dart';

CompanySettings _makeCompany({
  String billingStatus = 'active',
  DateTime? trialEndsAt,
  ModuleEntitlements? modules,
}) {
  return CompanySettings(
    id: 'test',
    nameHebrew: '',
    nameEnglish: '',
    taxId: '',
    addressHebrew: '',
    addressEnglish: '',
    poBox: '',
    city: '',
    zipCode: '',
    phone: '',
    fax: '',
    email: '',
    website: '',
    invoiceFooterText: '',
    paymentTerms: '',
    bankDetails: '',
    driverName: '',
    driverPhone: '',
    departureTime: '',
    billingStatus: billingStatus,
    trialEndsAt: trialEndsAt,
    modules: modules ?? const ModuleEntitlements(),
  );
}

void main() {
  group('ModuleManager.isBillingActive', () {
    test('active status returns true', () {
      final c = _makeCompany(billingStatus: 'active');
      expect(ModuleManager.isBillingActive(c), true);
    });

    test('grace status returns true', () {
      final c = _makeCompany(billingStatus: 'grace');
      expect(ModuleManager.isBillingActive(c), true);
    });

    test('trial with future date returns true', () {
      final c = _makeCompany(
        billingStatus: 'trial',
        trialEndsAt: DateTime.now().add(const Duration(days: 7)),
      );
      expect(ModuleManager.isBillingActive(c), true);
    });

    test('trial with past date returns false', () {
      final c = _makeCompany(
        billingStatus: 'trial',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(ModuleManager.isBillingActive(c), false);
    });

    test('trial with null date returns true', () {
      final c = _makeCompany(billingStatus: 'trial');
      expect(ModuleManager.isBillingActive(c), true);
    });

    test('suspended returns false', () {
      final c = _makeCompany(billingStatus: 'suspended');
      expect(ModuleManager.isBillingActive(c), false);
    });

    test('cancelled returns false', () {
      final c = _makeCompany(billingStatus: 'cancelled');
      expect(ModuleManager.isBillingActive(c), false);
    });
  });

  group('ModuleManager.hasModule', () {
    test('returns true for enabled module', () {
      final c = _makeCompany();
      expect(ModuleManager.hasModule(c, 'warehouse'), true);
    });

    test('returns false for disabled module', () {
      final c = _makeCompany(
        modules: const ModuleEntitlements(logistics: false),
      );
      expect(ModuleManager.hasModule(c, 'logistics'), false);
    });

    test('returns false for blocked billing', () {
      final c = _makeCompany(billingStatus: 'blocked');
      expect(ModuleManager.hasModule(c, 'warehouse'), false);
    });

    test('returns false for unknown module', () {
      final c = _makeCompany();
      expect(ModuleManager.hasModule(c, 'nonexistent'), false);
    });
  });

  group('ModuleManager.availableModules', () {
    test('returns all modules when active and all enabled', () {
      final c = _makeCompany();
      final modules = ModuleManager.availableModules(c);
      expect(modules, contains('warehouse'));
      expect(modules, contains('logistics'));
      expect(modules, contains('dispatcher'));
      expect(modules, contains('accounting'));
      expect(modules, contains('reports'));
    });

    test('returns empty when suspended', () {
      final c = _makeCompany(billingStatus: 'suspended');
      expect(ModuleManager.availableModules(c), isEmpty);
    });

    test('excludes disabled modules', () {
      final c = _makeCompany(
        modules: const ModuleEntitlements(accounting: false, reports: false),
      );
      final modules = ModuleManager.availableModules(c);
      expect(modules, isNot(contains('accounting')));
      expect(modules, isNot(contains('reports')));
      expect(modules, contains('warehouse'));
    });
  });

  group('ModuleManager.checkDependencies', () {
    test('dispatcher requires logistics', () {
      final withLogistics = _makeCompany();
      expect(
          ModuleManager.checkDependencies(withLogistics, 'dispatcher'), true);

      final withoutLogistics = _makeCompany(
        modules: const ModuleEntitlements(logistics: false),
      );
      expect(ModuleManager.checkDependencies(withoutLogistics, 'dispatcher'),
          false);
    });

    test('warehouse has no dependencies', () {
      final c = _makeCompany();
      expect(ModuleManager.checkDependencies(c, 'warehouse'), true);
    });
  });
}
