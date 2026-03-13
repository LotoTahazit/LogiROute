import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/role_hierarchy.dart';
import 'package:logiroute/features/owner_dashboard/services/entitlements_service.dart';
import 'package:logiroute/features/owner_dashboard/services/permissions_service.dart';
import 'package:logiroute/models/company_settings.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All 8 dashboard section keys (must match _allSections in OwnerDashboardShell).
const _allSectionKeys = [
  'overview',
  'users_roles',
  'billing',
  'settings',
  'audit',
  'ops_health',
  'accounting',
  'reports',
];

/// Sections that should remain visible when billing is suspended/cancelled.
const _restrictedSections = ['billing', 'settings'];

/// Sections that must be hidden when billing is suspended/cancelled.
const _hiddenWhenRestricted = [
  'overview',
  'users_roles',
  'audit',
  'ops_health',
  'accounting',
  'reports',
];

/// All known billing statuses.
const _allBillingStatuses = [
  'active',
  'trial',
  'grace',
  'suspended',
  'cancelled',
];

/// Statuses that restrict section visibility.
const _restrictedStatuses = ['suspended', 'cancelled'];

/// Statuses that allow full section visibility.
const _fullAccessStatuses = ['active', 'trial', 'grace'];

String _randomBillingStatus(Random rng) =>
    _allBillingStatuses[rng.nextInt(_allBillingStatuses.length)];

String _randomRestrictedStatus(Random rng) =>
    _restrictedStatuses[rng.nextInt(_restrictedStatuses.length)];

String _randomFullAccessStatus(Random rng) =>
    _fullAccessStatuses[rng.nextInt(_fullAccessStatuses.length)];

// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 14: Видимость секций при suspended/cancelled
  //
  // При suspended/cancelled видимы только Биллинг и Настройки.
  // Все остальные секции (Обзор, Пользователи, Аудит, Операции) скрыты.
  // **Validates: Requirements 12.5**
  // -------------------------------------------------------------------------

  group('Property 14: Видимость секций при suspended/cancelled', () {
    test(
      'Property 14: for random suspended/cancelled status, only billing and settings are visible (150 iterations)',
      () {
        final rng = Random(1414);

        for (var i = 0; i < 150; i++) {
          final status = _randomRestrictedStatus(rng);
          final sections = EntitlementsService.getVisibleSections(status);

          // Only billing and settings should be visible
          expect(sections, hasLength(2),
              reason:
                  'Iteration $i: status="$status" should show exactly 2 sections');

          expect(sections, contains('billing'),
              reason: 'Iteration $i: status="$status" must include billing');

          expect(sections, contains('settings'),
              reason: 'Iteration $i: status="$status" must include settings');

          // Hidden sections must not appear
          for (final hidden in _hiddenWhenRestricted) {
            expect(sections, isNot(contains(hidden)),
                reason:
                    'Iteration $i: status="$status" must NOT include "$hidden"');
          }
        }
      },
    );

    test(
      'Property 14: for random non-restricted status, all 8 sections are visible (150 iterations)',
      () {
        final rng = Random(1415);

        for (var i = 0; i < 150; i++) {
          final status = _randomFullAccessStatus(rng);
          final sections = EntitlementsService.getVisibleSections(status);

          expect(sections, hasLength(8),
              reason:
                  'Iteration $i: status="$status" should show all 8 sections');

          for (final key in _allSectionKeys) {
            expect(sections, contains(key),
                reason: 'Iteration $i: status="$status" must include "$key"');
          }
        }
      },
    );

    test(
      'Property 14: for any random billing status, restricted invariant holds (150 iterations)',
      () {
        final rng = Random(1416);

        for (var i = 0; i < 150; i++) {
          final status = _randomBillingStatus(rng);
          final sections = EntitlementsService.getVisibleSections(status);
          final isRestricted = _restrictedStatuses.contains(status);

          // All returned sections must be valid section keys
          for (final s in sections) {
            expect(_allSectionKeys, contains(s),
                reason: 'Iteration $i: "$s" is not a valid section key');
          }

          if (isRestricted) {
            // Only billing and settings
            expect(sections, hasLength(2),
                reason: 'Iteration $i: status="$status"');
            expect(sections, containsAll(_restrictedSections),
                reason: 'Iteration $i: status="$status"');
          } else {
            // All 8 sections
            expect(sections, hasLength(8),
                reason: 'Iteration $i: status="$status"');
            expect(sections, containsAll(_allSectionKeys),
                reason: 'Iteration $i: status="$status"');
          }
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 23: Отключённые модули скрывают UI-элементы
  //
  // Если ModuleEntitlements[moduleKey] == false, соответствующие KPI-карточки
  // и секции навигации не должны отображаться в дашборде.
  // **Validates: Requirements 12.2**
  // -------------------------------------------------------------------------

  group('Property 23: Отключённые модули скрывают UI-элементы', () {
    /// All known module keys.
    const moduleKeys = [
      'warehouse',
      'logistics',
      'dispatcher',
      'accounting',
      'reports',
    ];

    /// Mapping: KPI card key → module key that controls its visibility.
    /// Matches the moduleKey assignments in OverviewSection._buildKpiSection.
    const kpiToModule = <String, String>{
      'deliveries_today': 'logistics',
      'invoices_this_month': 'accounting',
      'warehouse_movements': 'warehouse',
      'active_drivers': 'dispatcher',
    };

    /// Generate a random ModuleEntitlements with each module randomly on/off.
    ModuleEntitlements randomModules(Random rng) {
      return ModuleEntitlements(
        warehouse: rng.nextBool(),
        logistics: rng.nextBool(),
        dispatcher: rng.nextBool(),
        accounting: rng.nextBool(),
        reports: rng.nextBool(),
      );
    }

    /// Simulate KPI card visibility: a card is visible iff its module is enabled.
    bool isKpiVisible(String kpiKey, ModuleEntitlements modules) {
      final moduleKey = kpiToModule[kpiKey];
      if (moduleKey == null) return true; // no module guard → always visible
      return modules[moduleKey];
    }

    test(
      'Property 23a: disabled modules hide corresponding KPI cards (150 iterations)',
      () {
        final rng = Random(2300);

        for (var i = 0; i < 150; i++) {
          final modules = randomModules(rng);

          for (final entry in kpiToModule.entries) {
            final kpiKey = entry.key;
            final moduleKey = entry.value;
            final moduleEnabled = modules[moduleKey];
            final visible = isKpiVisible(kpiKey, modules);

            expect(visible, equals(moduleEnabled),
                reason: 'Iteration $i: KPI "$kpiKey" (module "$moduleKey") '
                    'should be ${moduleEnabled ? "visible" : "hidden"}, '
                    'modules=${{
                  for (final k in moduleKeys) k: modules[k],
                }}');
          }
        }
      },
    );

    test(
      'Property 23b: all modules disabled hides all module-gated KPI cards (150 iterations)',
      () {
        final rng = Random(2301);

        for (var i = 0; i < 150; i++) {
          // All modules off
          const modules = ModuleEntitlements(
            warehouse: false,
            logistics: false,
            dispatcher: false,
            accounting: false,
            reports: false,
          );

          // Pick a random KPI card — it should be hidden
          final kpiKeys = kpiToModule.keys.toList();
          final kpiKey = kpiKeys[rng.nextInt(kpiKeys.length)];

          expect(isKpiVisible(kpiKey, modules), isFalse,
              reason:
                  'Iteration $i: KPI "$kpiKey" should be hidden when all modules disabled');
        }
      },
    );

    test(
      'Property 23c: all modules enabled shows all KPI cards (150 iterations)',
      () {
        final rng = Random(2302);

        for (var i = 0; i < 150; i++) {
          const modules = ModuleEntitlements(
            warehouse: true,
            logistics: true,
            dispatcher: true,
            accounting: true,
            reports: true,
          );

          final kpiKeys = kpiToModule.keys.toList();
          final kpiKey = kpiKeys[rng.nextInt(kpiKeys.length)];

          expect(isKpiVisible(kpiKey, modules), isTrue,
              reason:
                  'Iteration $i: KPI "$kpiKey" should be visible when all modules enabled');
        }
      },
    );

    test(
      'Property 23d: isModuleAvailable matches ModuleEntitlements[key] for any random config (150 iterations)',
      () {
        final rng = Random(2303);

        for (var i = 0; i < 150; i++) {
          final modules = randomModules(rng);
          final settings = CompanySettings(
            id: 'test_$i',
            nameHebrew: 'חברה',
            nameEnglish: 'Company',
            taxId: '123456789',
            addressHebrew: 'כתובת',
            addressEnglish: 'Address',
            poBox: '',
            city: 'תל אביב',
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
            modules: modules,
          );
          final service = EntitlementsService(companySettings: settings);

          for (final key in moduleKeys) {
            final entitlementValue = modules[key];
            final serviceValue = service.isModuleAvailable(key);

            expect(serviceValue, equals(entitlementValue),
                reason: 'Iteration $i: isModuleAvailable("$key") should equal '
                    'ModuleEntitlements["$key"]=$entitlementValue');

            // If module is disabled, KPI cards gated by it must be hidden
            if (!entitlementValue) {
              for (final kpiEntry in kpiToModule.entries) {
                if (kpiEntry.value == key) {
                  expect(isKpiVisible(kpiEntry.key, modules), isFalse,
                      reason:
                          'Iteration $i: KPI "${kpiEntry.key}" must be hidden '
                          'when module "$key" is disabled');
                }
              }
            }
          }
        }
      },
    );

    test(
      'Property 23e: exactly the set of KPI cards for enabled modules are visible (150 iterations)',
      () {
        final rng = Random(2304);

        for (var i = 0; i < 150; i++) {
          final modules = randomModules(rng);

          final visibleKpis = kpiToModule.keys
              .where((kpi) => isKpiVisible(kpi, modules))
              .toSet();

          final expectedVisibleKpis = kpiToModule.entries
              .where((e) => modules[e.value])
              .map((e) => e.key)
              .toSet();

          expect(visibleKpis, equals(expectedVisibleKpis),
              reason:
                  'Iteration $i: visible KPIs should match enabled modules. '
                  'modules=${{
                for (final k in moduleKeys) k: modules[k],
              }}');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 33: Навигация accountant — только разрешённые секции
  //
  // Для любого пользователя с ролью accountant: видимые секции ==
  // {Бухгалтерия, Отчёты, Аудит}; секции Обзор, Пользователи, Биллинг,
  // Настройки, Операции скрыты.
  // **Validates: Requirements 18.6**
  // -------------------------------------------------------------------------

  group('Property 33: Навигация accountant — только разрешённые секции', () {
    /// All 8 section moduleKeys (matching _allSections in OwnerDashboardShell).
    const allModuleKeys = [
      'overview',
      'users',
      'billing',
      'settings',
      'audit',
      'ops_health',
      'accounting',
      'reports',
    ];

    /// Modules that accountant CAN read.
    const accountantAllowed = {'accounting', 'reports', 'audit'};

    /// Modules that accountant CANNOT read.
    const accountantHidden = [
      'overview',
      'users',
      'billing',
      'settings',
      'ops_health',
    ];

    /// Generate a random companyId.
    String randomCompanyId(Random rng) =>
        'company_${rng.nextInt(1000000).toStringAsFixed(0).padLeft(6, '0')}';

    test(
      'Property 33a: for accountant with random companyId, canRead returns true ONLY for accounting/reports/audit (150 iterations)',
      () {
        final rng = Random(3300);

        for (var i = 0; i < 150; i++) {
          final companyId = randomCompanyId(rng);
          final permissions = PermissionsService(
            role: AppRole.accountant,
            userCompanyId: companyId,
          );

          // Pick a random module key to test
          final moduleKey = allModuleKeys[rng.nextInt(allModuleKeys.length)];
          final result = permissions.canRead(moduleKey);
          final expected = accountantAllowed.contains(moduleKey);

          expect(result, equals(expected),
              reason: 'Iteration $i: accountant (company=$companyId) '
                  'canRead("$moduleKey") should be $expected');
        }
      },
    );

    test(
      'Property 33b: for accountant, the set of readable modules is exactly {accounting, reports, audit} (exhaustive check, 150 iterations)',
      () {
        final rng = Random(3301);

        for (var i = 0; i < 150; i++) {
          final companyId = randomCompanyId(rng);
          final permissions = PermissionsService(
            role: AppRole.accountant,
            userCompanyId: companyId,
          );

          final readableModules =
              allModuleKeys.where((key) => permissions.canRead(key)).toSet();

          expect(readableModules, equals(accountantAllowed),
              reason: 'Iteration $i: accountant (company=$companyId) '
                  'readable modules should be exactly $accountantAllowed, '
                  'got $readableModules');
        }
      },
    );

    test(
      'Property 33c: for accountant, hidden sections are always false (150 iterations)',
      () {
        final rng = Random(3302);

        for (var i = 0; i < 150; i++) {
          final companyId = randomCompanyId(rng);
          final permissions = PermissionsService(
            role: AppRole.accountant,
            userCompanyId: companyId,
          );

          // Pick a random hidden module key
          final hiddenKey =
              accountantHidden[rng.nextInt(accountantHidden.length)];

          expect(permissions.canRead(hiddenKey), isFalse,
              reason: 'Iteration $i: accountant (company=$companyId) '
                  'canRead("$hiddenKey") must be false');
        }
      },
    );
  });
}
