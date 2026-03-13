import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/company_settings.dart';

void main() {
  group('ModuleEntitlements', () {
    test('default constructor enables all modules', () {
      const modules = ModuleEntitlements();
      expect(modules.warehouse, true);
      expect(modules.logistics, true);
      expect(modules.dispatcher, true);
      expect(modules.accounting, true);
      expect(modules.reports, true);
    });

    test('fromMap with null returns all enabled', () {
      final modules = ModuleEntitlements.fromMap(null);
      expect(modules.warehouse, true);
      expect(modules.logistics, true);
    });

    test('fromMap respects disabled modules', () {
      final modules = ModuleEntitlements.fromMap({
        'warehouse': true,
        'logistics': false,
        'dispatcher': false,
        'accounting': true,
        'reports': true,
      });
      expect(modules.warehouse, true);
      expect(modules.logistics, false);
      expect(modules.dispatcher, false);
    });

    test('operator [] returns correct values', () {
      final modules = ModuleEntitlements.fromMap({
        'warehouse': true,
        'logistics': false,
      });
      expect(modules['warehouse'], true);
      expect(modules['logistics'], false);
      expect(modules['unknown'], false);
    });

    test('toMap roundtrip', () {
      const original = ModuleEntitlements(
        warehouse: true,
        logistics: false,
        dispatcher: true,
        accounting: false,
        reports: true,
      );
      final map = original.toMap();
      final restored = ModuleEntitlements.fromMap(map);
      expect(restored.warehouse, original.warehouse);
      expect(restored.logistics, original.logistics);
      expect(restored.dispatcher, original.dispatcher);
      expect(restored.accounting, original.accounting);
      expect(restored.reports, original.reports);
    });
  });

  group('PlanLimits', () {
    test('default values', () {
      const limits = PlanLimits();
      expect(limits.maxUsers, 999);
      expect(limits.maxDocsPerMonth, 99999);
      expect(limits.maxRoutesPerDay, 999);
    });

    test('fromMap with null returns defaults', () {
      final limits = PlanLimits.fromMap(null);
      expect(limits.maxUsers, 999);
    });

    test('fromMap with custom values', () {
      final limits = PlanLimits.fromMap({
        'maxUsers': 5,
        'maxDocsPerMonth': 100,
        'maxRoutesPerDay': 10,
      });
      expect(limits.maxUsers, 5);
      expect(limits.maxDocsPerMonth, 100);
      expect(limits.maxRoutesPerDay, 10);
    });
  });

  group('CompanySettings', () {
    test('copyWith preserves unchanged fields', () {
      final original = CompanySettings(
        id: 'test-id',
        nameHebrew: 'חברה',
        nameEnglish: 'Company',
        taxId: '123456789',
        addressHebrew: 'כתובת',
        addressEnglish: 'Address',
        poBox: '',
        city: 'Tel Aviv',
        zipCode: '12345',
        phone: '050-1234567',
        fax: '',
        email: 'test@test.com',
        website: '',
        invoiceFooterText: '',
        paymentTerms: '',
        bankDetails: '',
        driverName: '',
        driverPhone: '',
        departureTime: '7:00',
        plan: 'full',
        billingStatus: 'active',
        gracePeriodDays: 7,
      );

      final updated = original.copyWith(billingStatus: 'grace');
      expect(updated.billingStatus, 'grace');
      expect(updated.nameHebrew, 'חברה');
      expect(updated.plan, 'full');
      expect(updated.gracePeriodDays, 7);
    });

    test('copyWith updates payment fields', () {
      final original = CompanySettings(
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
      );

      final now = DateTime.now();
      final updated = original.copyWith(
        paidUntil: now,
        paymentProvider: 'stripe',
        subscriptionId: 'sub_123',
        paymentCustomerId: 'cus_456',
      );

      expect(updated.paidUntil, now);
      expect(updated.paymentProvider, 'stripe');
      expect(updated.subscriptionId, 'sub_123');
      expect(updated.paymentCustomerId, 'cus_456');
    });
  });
}
