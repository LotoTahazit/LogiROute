import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/services/entitlements_service.dart';
import 'package:logiroute/models/company_settings.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _allBillingStatuses = [
  'active',
  'trial',
  'grace',
  'suspended',
  'cancelled',
];

const _allSections = [
  'overview',
  'users_roles',
  'billing',
  'settings',
  'audit',
  'ops_health',
  'accounting',
  'reports',
];

const _suspendedOnlySections = ['billing', 'settings'];

const _moduleKeys = [
  'warehouse',
  'logistics',
  'dispatcher',
  'accounting',
  'reports',
];

String _randomStatus(Random rng) =>
    _allBillingStatuses[rng.nextInt(_allBillingStatuses.length)];

/// Generate a random positive limit (1..1000).
int _randomLimit(Random rng) => 1 + rng.nextInt(1000);

/// Generate a random usage value (0..1500) to cover below, at, and above limit.
int _randomUsage(Random rng) => rng.nextInt(1501);

/// Generate a random future DateTime (1 to 365 days from [base]).
DateTime _randomFutureDate(Random rng, DateTime base) {
  final daysAhead = 1 + rng.nextInt(365);
  final extraSeconds = rng.nextInt(86400);
  return base.add(Duration(days: daysAhead, seconds: extraSeconds));
}

/// Generate a random past DateTime (1 to 365 days before [base]).
DateTime _randomPastDate(Random rng, DateTime base) {
  final daysBehind = 1 + rng.nextInt(365);
  final extraSeconds = rng.nextInt(86400);
  return base.subtract(Duration(days: daysBehind, seconds: extraSeconds));
}

/// Build a [ModuleEntitlements] with random on/off per module.
ModuleEntitlements _randomModules(Random rng) {
  return ModuleEntitlements(
    warehouse: rng.nextBool(),
    logistics: rng.nextBool(),
    dispatcher: rng.nextBool(),
    accounting: rng.nextBool(),
    reports: rng.nextBool(),
  );
}

// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 8: Пороговые алерты использования
  //
  // usage >= limit → critical (красный)
  // usage >= 0.8*limit && usage < limit → warning (жёлтый)
  // usage < 0.8*limit → null (нет алерта)
  // limit <= 0 → null
  // **Validates: Requirements 4.3, 4.4**
  // -------------------------------------------------------------------------

  group('Property 8: Пороговые алерты использования', () {
    test(
      'Property 8a: usage >= limit always returns critical (150 iterations)',
      () {
        final rng = Random(800);

        for (var i = 0; i < 150; i++) {
          final limit = _randomLimit(rng);
          // usage in [limit, limit + 500]
          final usage = limit + rng.nextInt(501);

          final alert = EntitlementsService.getAlertLevel(usage, limit);

          expect(alert, equals('critical'),
              reason:
                  'Iteration $i: usage=$usage >= limit=$limit should be critical');
        }
      },
    );

    test(
      'Property 8b: usage >= 80% limit and < limit returns warning (150 iterations)',
      () {
        final rng = Random(801);

        for (var i = 0; i < 150; i++) {
          final limit = 10 + rng.nextInt(991); // at least 10 for meaningful 80%
          // Use ceil to ensure usage is truly >= 0.8*limit (the service compares as double)
          final threshold80 = (limit * 0.8).ceil();
          if (threshold80 >= limit) continue; // skip degenerate cases

          // usage in [threshold80, limit - 1]
          final range = limit - threshold80;
          if (range <= 0) continue;
          final usage = threshold80 + rng.nextInt(range);

          final alert = EntitlementsService.getAlertLevel(usage, limit);

          expect(alert, equals('warning'),
              reason:
                  'Iteration $i: usage=$usage in [$threshold80, ${limit - 1}] should be warning');
        }
      },
    );

    test(
      'Property 8c: usage < 80% limit returns null (150 iterations)',
      () {
        final rng = Random(802);

        for (var i = 0; i < 150; i++) {
          final limit = 10 + rng.nextInt(991);
          // Use floor to ensure usage is truly < 0.8*limit (the service compares as double)
          final threshold80 = (limit * 0.8).floor();
          if (threshold80 <= 0) continue;

          final usage = rng.nextInt(threshold80);

          final alert = EntitlementsService.getAlertLevel(usage, limit);

          expect(alert, isNull,
              reason:
                  'Iteration $i: usage=$usage < 80% of limit=$limit should be null');
        }
      },
    );

    test(
      'Property 8d: limit <= 0 always returns null (150 iterations)',
      () {
        final rng = Random(803);

        for (var i = 0; i < 150; i++) {
          final limit = -rng.nextInt(100); // 0 or negative
          final usage = rng.nextInt(1000);

          final alert = EntitlementsService.getAlertLevel(usage, limit);

          expect(alert, isNull,
              reason:
                  'Iteration $i: limit=$limit <= 0 should always return null');
        }
      },
    );

    test(
      'Property 8e: alert levels are mutually exclusive and exhaustive (150 iterations)',
      () {
        final rng = Random(804);

        for (var i = 0; i < 150; i++) {
          final limit = _randomLimit(rng);
          final usage = _randomUsage(rng);

          final alert = EntitlementsService.getAlertLevel(usage, limit);

          if (usage >= limit) {
            expect(alert, equals('critical'), reason: 'Iteration $i');
          } else if (usage >= (limit * 0.8)) {
            expect(alert, equals('warning'), reason: 'Iteration $i');
          } else {
            expect(alert, isNull, reason: 'Iteration $i');
          }
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 12: Лимит пользователей блокирует приглашения
  //
  // Если активных пользователей >= usersLimit, создание приглашения отклоняется.
  // **Validates: Requirements 5.9**
  // -------------------------------------------------------------------------

  group('Property 12: Лимит пользователей блокирует приглашения', () {
    test(
      'Property 12a: activeUsers >= usersLimit blocks invite creation (150 iterations)',
      () {
        final rng = Random(1200);

        for (var i = 0; i < 150; i++) {
          final usersLimit = 1 + rng.nextInt(100);
          // activeUsers in [usersLimit, usersLimit + 50]
          final activeUsers = usersLimit + rng.nextInt(51);

          final canInvite =
              EntitlementsService.canCreateInvite(activeUsers, usersLimit);

          expect(canInvite, isFalse,
              reason:
                  'Iteration $i: activeUsers=$activeUsers >= limit=$usersLimit should block invites');
        }
      },
    );

    test(
      'Property 12b: activeUsers < usersLimit allows invite creation (150 iterations)',
      () {
        final rng = Random(1201);

        for (var i = 0; i < 150; i++) {
          final usersLimit = 2 + rng.nextInt(100);
          final activeUsers = rng.nextInt(usersLimit);

          final canInvite =
              EntitlementsService.canCreateInvite(activeUsers, usersLimit);

          expect(canInvite, isTrue,
              reason:
                  'Iteration $i: activeUsers=$activeUsers < limit=$usersLimit should allow invites');
        }
      },
    );

    test(
      'Property 12c: exactly at limit blocks invite (boundary)',
      () {
        for (var limit = 1; limit <= 20; limit++) {
          expect(EntitlementsService.canCreateInvite(limit, limit), isFalse,
              reason: 'activeUsers=$limit == limit=$limit should block');
        }
      },
    );

    test(
      'Property 12d: one below limit allows invite (boundary)',
      () {
        for (var limit = 1; limit <= 20; limit++) {
          expect(EntitlementsService.canCreateInvite(limit - 1, limit), isTrue,
              reason: 'activeUsers=${limit - 1} < limit=$limit should allow');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 13: Расчёт оставшихся дней триала
  //
  // Для billingStatus == "trial" и trialEndsAt в будущем:
  // дни = ceil((trialEndsAt - now).inDays) >= 0
  // Для trialEndsAt в прошлом: 0
  // **Validates: Requirements 6.5**
  // -------------------------------------------------------------------------

  group('Property 13: Расчёт оставшихся дней триала', () {
    test(
      'Property 13a: future trialEndsAt returns positive days (150 iterations)',
      () {
        final rng = Random(1300);
        final now = DateTime(2026, 2, 28, 12, 0, 0);

        for (var i = 0; i < 150; i++) {
          final trialEnd = _randomFutureDate(rng, now);
          final days =
              EntitlementsService.getTrialDaysRemaining(trialEnd, now: now);

          expect(days, greaterThan(0),
              reason:
                  'Iteration $i: trialEnd=$trialEnd is in the future, days should be > 0');
        }
      },
    );

    test(
      'Property 13b: past trialEndsAt returns 0 (150 iterations)',
      () {
        final rng = Random(1301);
        final now = DateTime(2026, 2, 28, 12, 0, 0);

        for (var i = 0; i < 150; i++) {
          final trialEnd = _randomPastDate(rng, now);
          final days =
              EntitlementsService.getTrialDaysRemaining(trialEnd, now: now);

          expect(days, equals(0),
              reason:
                  'Iteration $i: trialEnd=$trialEnd is in the past, days should be 0');
        }
      },
    );

    test(
      'Property 13c: result is always >= 0 (150 iterations)',
      () {
        final rng = Random(1302);
        final now = DateTime(2026, 2, 28, 12, 0, 0);

        for (var i = 0; i < 150; i++) {
          // Mix of past and future dates
          final trialEnd = rng.nextBool()
              ? _randomFutureDate(rng, now)
              : _randomPastDate(rng, now);
          final days =
              EntitlementsService.getTrialDaysRemaining(trialEnd, now: now);

          expect(days, greaterThanOrEqualTo(0),
              reason: 'Iteration $i: days should never be negative');
        }
      },
    );

    test(
      'Property 13d: ceil behavior — partial day counts as full day',
      () {
        final now = DateTime(2026, 2, 28, 12, 0, 0);

        // 1 second in the future → 1 day
        final oneSecond = now.add(const Duration(seconds: 1));
        expect(EntitlementsService.getTrialDaysRemaining(oneSecond, now: now),
            equals(1));

        // 23 hours 59 minutes → 1 day
        final almostDay =
            now.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        expect(EntitlementsService.getTrialDaysRemaining(almostDay, now: now),
            equals(1));

        // Exactly 1 day → 1 day
        final exactDay = now.add(const Duration(days: 1));
        expect(EntitlementsService.getTrialDaysRemaining(exactDay, now: now),
            equals(1));

        // 1 day + 1 second → 2 days
        final dayPlusOne = now.add(const Duration(days: 1, seconds: 1));
        expect(EntitlementsService.getTrialDaysRemaining(dayPlusOne, now: now),
            equals(2));
      },
    );

    test(
      'Property 13e: exactly now returns 0',
      () {
        final now = DateTime(2026, 2, 28, 12, 0, 0);
        expect(EntitlementsService.getTrialDaysRemaining(now, now: now),
            equals(0));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 14: Видимость секций при suspended/cancelled
  //
  // При suspended/cancelled видимы только Биллинг и Настройки.
  // При других статусах — все 6 секций.
  // **Validates: Requirements 12.5**
  // -------------------------------------------------------------------------

  group('Property 14: Видимость секций при suspended/cancelled', () {
    test(
      'Property 14a: suspended shows only billing and settings',
      () {
        final sections = EntitlementsService.getVisibleSections('suspended');

        expect(sections, containsAll(_suspendedOnlySections));
        expect(sections, hasLength(2));
        expect(sections, isNot(contains('overview')));
        expect(sections, isNot(contains('users_roles')));
        expect(sections, isNot(contains('audit')));
        expect(sections, isNot(contains('ops_health')));
      },
    );

    test(
      'Property 14b: cancelled shows only billing and settings',
      () {
        final sections = EntitlementsService.getVisibleSections('cancelled');

        expect(sections, containsAll(_suspendedOnlySections));
        expect(sections, hasLength(2));
        expect(sections, isNot(contains('overview')));
        expect(sections, isNot(contains('users_roles')));
        expect(sections, isNot(contains('audit')));
        expect(sections, isNot(contains('ops_health')));
      },
    );

    test(
      'Property 14c: active/trial/grace show all 8 sections',
      () {
        for (final status in ['active', 'trial', 'grace']) {
          final sections = EntitlementsService.getVisibleSections(status);

          expect(sections, hasLength(8),
              reason: 'Status "$status" should show all 8 sections');
          expect(sections, containsAll(_allSections),
              reason: 'Status "$status" should contain all sections');
        }
      },
    );

    test(
      'Property 14d: suspended/cancelled sections are strict subset of full sections (150 iterations)',
      () {
        final rng = Random(1400);

        for (var i = 0; i < 150; i++) {
          final status = _randomStatus(rng);
          final sections = EntitlementsService.getVisibleSections(status);

          // All returned sections must be valid section names
          for (final s in sections) {
            expect(_allSections, contains(s),
                reason:
                    'Iteration $i: "$s" is not a valid section for status "$status"');
          }

          if (status == 'suspended' || status == 'cancelled') {
            expect(sections, hasLength(2), reason: 'Iteration $i');
            expect(sections, contains('billing'), reason: 'Iteration $i');
            expect(sections, contains('settings'), reason: 'Iteration $i');
          } else {
            expect(sections, hasLength(8), reason: 'Iteration $i');
          }
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 23: Отключённые модули скрывают UI-элементы
  //
  // Если ModuleEntitlements[moduleKey] == false, модуль недоступен.
  // isModuleAvailable должен возвращать false для отключённых модулей.
  // **Validates: Requirements 12.2**
  // -------------------------------------------------------------------------

  group('Property 23: Отключённые модули скрывают UI-элементы', () {
    test(
      'Property 23a: disabled modules return false from isModuleAvailable (150 iterations)',
      () {
        final rng = Random(2300);

        for (var i = 0; i < 150; i++) {
          final modules = _randomModules(rng);
          final settings = CompanySettings(
            id: 'test_company',
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

          for (final key in _moduleKeys) {
            final expected = modules[key];
            expect(service.isModuleAvailable(key), equals(expected),
                reason:
                    'Iteration $i: module "$key" available=${modules[key]}, isModuleAvailable should match');
          }
        }
      },
    );

    test(
      'Property 23b: all modules disabled means none available',
      () {
        const modules = ModuleEntitlements(
          warehouse: false,
          logistics: false,
          dispatcher: false,
          accounting: false,
          reports: false,
        );
        final settings = CompanySettings(
          id: 'test',
          nameHebrew: 'חברה',
          nameEnglish: 'Co',
          taxId: '123456789',
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
          departureTime: '7:00',
          modules: modules,
        );
        final service = EntitlementsService(companySettings: settings);

        for (final key in _moduleKeys) {
          expect(service.isModuleAvailable(key), isFalse,
              reason: 'All modules disabled, "$key" should be unavailable');
        }
      },
    );

    test(
      'Property 23c: all modules enabled means all available',
      () {
        const modules = ModuleEntitlements(
          warehouse: true,
          logistics: true,
          dispatcher: true,
          accounting: true,
          reports: true,
        );
        final settings = CompanySettings(
          id: 'test',
          nameHebrew: 'חברה',
          nameEnglish: 'Co',
          taxId: '123456789',
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
          departureTime: '7:00',
          modules: modules,
        );
        final service = EntitlementsService(companySettings: settings);

        for (final key in _moduleKeys) {
          expect(service.isModuleAvailable(key), isTrue,
              reason: 'All modules enabled, "$key" should be available');
        }
      },
    );

    test(
      'Property 23d: unknown module key returns false',
      () {
        final settings = CompanySettings(
          id: 'test',
          nameHebrew: 'חברה',
          nameEnglish: 'Co',
          taxId: '123456789',
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
          departureTime: '7:00',
        );
        final service = EntitlementsService(companySettings: settings);

        expect(service.isModuleAvailable('nonexistent'), isFalse);
        expect(service.isModuleAvailable(''), isFalse);
        expect(service.isModuleAvailable('random_module'), isFalse);
      },
    );

    test(
      'Property 23e: isAddon returns true only for enabled modules not in base plan (150 iterations)',
      () {
        final rng = Random(2301);
        const plans = ['logistics', 'warehouse_only', 'ops', 'full'];
        const planBaseModules = <String, Set<String>>{
          'logistics': {'logistics', 'dispatcher', 'reports'},
          'warehouse_only': {'warehouse'},
          'ops': {'warehouse', 'logistics', 'dispatcher', 'reports'},
          'full': {
            'warehouse',
            'logistics',
            'dispatcher',
            'accounting',
            'reports'
          },
        };

        for (var i = 0; i < 150; i++) {
          final plan = plans[rng.nextInt(plans.length)];
          final modules = _randomModules(rng);
          final settings = CompanySettings(
            id: 'test',
            nameHebrew: 'חברה',
            nameEnglish: 'Co',
            taxId: '123456789',
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
            departureTime: '7:00',
            modules: modules,
            plan: plan,
          );
          final service = EntitlementsService(companySettings: settings);
          final base = planBaseModules[plan]!;

          for (final key in _moduleKeys) {
            final isEnabled = modules[key];
            final inBasePlan = base.contains(key);
            final expectedAddon = isEnabled && !inBasePlan;

            expect(service.isAddon(key), equals(expectedAddon),
                reason:
                    'Iteration $i: plan=$plan, module=$key, enabled=$isEnabled, inBase=$inBasePlan');
          }
        }
      },
    );
  });
}
