import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/role_hierarchy.dart';
import 'package:logiroute/features/owner_dashboard/services/permissions_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _allRoles = AppRole.values;

const _lowerRoles = [
  AppRole.dispatcher,
  AppRole.driver,
  AppRole.warehouseKeeper,
  AppRole.accountant,
  AppRole.viewer,
];

const _allModules = [
  'members',
  'invites',
  'company_profile',
  'settings',
  'invoices',
  'inventory',
  'routes',
  'delivery_points',
  'integrations',
  'audit',
  'billing',
  'metrics',
];

const _ownerWritable = ['members', 'invites', 'company_profile'];

const _ownerNotWritable = [
  'settings',
  'invoices',
  'inventory',
  'routes',
  'delivery_points',
  'integrations',
];

const _actions = ['create', 'update', 'delete', 'read'];

AppRole _randomRole(Random rng) => _allRoles[rng.nextInt(_allRoles.length)];

String _randomModule(Random rng) =>
    _allModules[rng.nextInt(_allModules.length)];

String _randomAction(Random rng) => _actions[rng.nextInt(_actions.length)];

String _randomCompanyId(Random rng) {
  final len = 5 + rng.nextInt(10);
  return 'company_${String.fromCharCodes(List.generate(len, (_) => 97 + rng.nextInt(26)))}';
}

PermissionsService _service(AppRole role, String companyId) {
  return PermissionsService(role: role, userCompanyId: companyId);
}

// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 2: Owner — чтение всех коллекций компании
  //
  // Для любой коллекции и пользователя с ролью owner, чей companyId
  // совпадает, canRead(module) должен возвращать true.
  // **Validates: Requirements 1.2, 11.2**
  // -------------------------------------------------------------------------

  test(
    'Property 2a: owner canRead returns true for any random module (150 iterations)',
    () {
      final rng = Random(300);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final module = _randomModule(rng);
        final svc = _service(AppRole.owner, companyId);

        expect(svc.canRead(module), isTrue,
            reason:
                'Iteration $i: owner should canRead("$module") for own company');
      }
    },
  );

  test(
    'Property 2b: owner canRead is true for all known modules (exhaustive)',
    () {
      final svc = _service(AppRole.owner, 'company_test');
      for (final module in _allModules) {
        expect(svc.canRead(module), isTrue,
            reason: 'owner should canRead("$module")');
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 3: Изоляция тенанта для non-super_admin ролей
  //
  // Для любого пользователя с ролью owner или admin и для любого companyId,
  // отличающегося от companyId пользователя, canAccessCompany должен
  // возвращать false.
  // **Validates: Requirements 1.3, 1.7, 11.8**
  // -------------------------------------------------------------------------

  test(
    'Property 3a: owner/admin canAccessCompany returns false for different companyId (150 iterations)',
    () {
      final rng = Random(301);

      for (var i = 0; i < 150; i++) {
        final userCompany = _randomCompanyId(rng);
        String targetCompany;
        do {
          targetCompany = _randomCompanyId(rng);
        } while (targetCompany == userCompany);

        final role = rng.nextBool() ? AppRole.owner : AppRole.admin;
        final svc = _service(role, userCompany);

        expect(svc.canAccessCompany(targetCompany), isFalse,
            reason:
                'Iteration $i: ${role.value} with company "$userCompany" should NOT access "$targetCompany"');
      }
    },
  );

  test(
    'Property 3b: all non-super_admin roles reject foreign companyId (150 iterations)',
    () {
      final rng = Random(302);
      final nonSuperRoles =
          _allRoles.where((r) => r != AppRole.superAdmin).toList();

      for (var i = 0; i < 150; i++) {
        final role = nonSuperRoles[rng.nextInt(nonSuperRoles.length)];
        final userCompany = _randomCompanyId(rng);
        String targetCompany;
        do {
          targetCompany = _randomCompanyId(rng);
        } while (targetCompany == userCompany);

        final svc = _service(role, userCompany);

        expect(svc.canAccessCompany(targetCompany), isFalse,
            reason:
                'Iteration $i: ${role.value} should NOT access foreign company');
      }
    },
  );

  test(
    'Property 3c: non-super_admin roles CAN access own companyId (150 iterations)',
    () {
      final rng = Random(303);
      final nonSuperRoles =
          _allRoles.where((r) => r != AppRole.superAdmin).toList();

      for (var i = 0; i < 150; i++) {
        final role = nonSuperRoles[rng.nextInt(nonSuperRoles.length)];
        final companyId = _randomCompanyId(rng);
        final svc = _service(role, companyId);

        expect(svc.canAccessCompany(companyId), isTrue,
            reason: 'Iteration $i: ${role.value} should access own company');
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 4: Owner — запись ограничена invites, members, company profile
  //
  // Для любой коллекции и пользователя с ролью owner, canWrite возвращает
  // true только для members, invites, company_profile, и false для остальных.
  // **Validates: Requirements 1.4, 1.5, 11.3, 11.4**
  // -------------------------------------------------------------------------

  test(
    'Property 4a: owner canWrite returns true only for writable collections (150 iterations)',
    () {
      final rng = Random(304);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final module = _randomModule(rng);
        final action = _randomAction(rng);
        final svc = _service(AppRole.owner, companyId);

        final expected = _ownerWritable.contains(module);
        expect(svc.canWrite(module, action), equals(expected),
            reason:
                'Iteration $i: owner canWrite("$module", "$action") should be $expected');
      }
    },
  );

  test(
    'Property 4b: owner canWrite is false for all non-writable collections (exhaustive)',
    () {
      final svc = _service(AppRole.owner, 'company_test');
      for (final module in _ownerNotWritable) {
        for (final action in _actions) {
          expect(svc.canWrite(module, action), isFalse,
              reason: 'owner should NOT canWrite("$module", "$action")');
        }
      }
    },
  );

  test(
    'Property 4c: owner canWrite is true for all writable collections (exhaustive)',
    () {
      final svc = _service(AppRole.owner, 'company_test');
      for (final module in _ownerWritable) {
        for (final action in _actions) {
          expect(svc.canWrite(module, action), isTrue,
              reason: 'owner should canWrite("$module", "$action")');
        }
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 5: Admin — полный доступ на чтение и запись
  //
  // Для любой коллекции и пользователя с ролью admin, чей companyId
  // совпадает, canRead и canWrite должны возвращать true.
  // **Validates: Requirements 1.6, 11.5**
  // -------------------------------------------------------------------------

  test(
    'Property 5a: admin canRead and canWrite return true for any module (150 iterations)',
    () {
      final rng = Random(305);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final module = _randomModule(rng);
        final action = _randomAction(rng);
        final svc = _service(AppRole.admin, companyId);

        expect(svc.canRead(module), isTrue,
            reason: 'Iteration $i: admin should canRead("$module")');
        expect(svc.canWrite(module, action), isTrue,
            reason:
                'Iteration $i: admin should canWrite("$module", "$action")');
      }
    },
  );

  test(
    'Property 5b: admin has full read+write for all known modules (exhaustive)',
    () {
      final svc = _service(AppRole.admin, 'company_test');
      for (final module in _allModules) {
        expect(svc.canRead(module), isTrue,
            reason: 'admin should canRead("$module")');
        for (final action in _actions) {
          expect(svc.canWrite(module, action), isTrue,
              reason: 'admin should canWrite("$module", "$action")');
        }
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 6: Чувствительные поля биллинга скрыты от owner/admin
  //
  // Для любых данных биллинга, возвращаемых пользователю с ролью owner
  // или admin, canViewSensitiveBilling() должен возвращать false.
  // **Validates: Requirements 1.8, 6.8, 11.7**
  // -------------------------------------------------------------------------

  test(
    'Property 6a: owner and admin canViewSensitiveBilling is always false (150 iterations)',
    () {
      final rng = Random(306);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final role = rng.nextBool() ? AppRole.owner : AppRole.admin;
        final svc = _service(role, companyId);

        expect(svc.canViewSensitiveBilling(), isFalse,
            reason:
                'Iteration $i: ${role.value} should NOT view sensitive billing');
      }
    },
  );

  test(
    'Property 6b: all non-super_admin roles cannot view sensitive billing (exhaustive)',
    () {
      for (final role in _allRoles.where((r) => r != AppRole.superAdmin)) {
        final svc = _service(role, 'company_test');
        expect(svc.canViewSensitiveBilling(), isFalse,
            reason: '${role.value} should NOT view sensitive billing');
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 11: Разрешения на назначение ролей
  //
  // Owner: canAssignRole = true для {admin, dispatcher, driver,
  //   warehouse_keeper, accountant, viewer}; false для {owner, super_admin}
  // Admin: canAssignRole = true для {admin, dispatcher, driver,
  //   warehouse_keeper, accountant, viewer}; false для {owner, super_admin}
  // Super_admin: canAssignRole = true для всех ролей
  // **Validates: Requirements 5.5, 5.6, 5.7, 5.8, 11.6**
  // -------------------------------------------------------------------------

  test(
    'Property 11a: owner canAssignRole matches expected set (150 iterations)',
    () {
      final rng = Random(307);
      const assignable = {
        AppRole.admin,
        AppRole.dispatcher,
        AppRole.driver,
        AppRole.warehouseKeeper,
        AppRole.accountant,
        AppRole.viewer,
      };

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final targetRole = _randomRole(rng);
        final svc = _service(AppRole.owner, companyId);

        final expected = assignable.contains(targetRole);
        expect(svc.canAssignRole(targetRole), equals(expected),
            reason:
                'Iteration $i: owner canAssignRole(${targetRole.value}) should be $expected');
      }
    },
  );

  test(
    'Property 11b: admin canAssignRole matches expected set (150 iterations)',
    () {
      final rng = Random(308);
      const assignable = {
        AppRole.admin,
        AppRole.dispatcher,
        AppRole.driver,
        AppRole.warehouseKeeper,
        AppRole.accountant,
        AppRole.viewer,
      };

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final targetRole = _randomRole(rng);
        final svc = _service(AppRole.admin, companyId);

        final expected = assignable.contains(targetRole);
        expect(svc.canAssignRole(targetRole), equals(expected),
            reason:
                'Iteration $i: admin canAssignRole(${targetRole.value}) should be $expected');
      }
    },
  );

  test(
    'Property 11c: owner and admin CANNOT assign owner or super_admin (exhaustive)',
    () {
      for (final assignerRole in [AppRole.owner, AppRole.admin]) {
        final svc = _service(assignerRole, 'company_test');
        expect(svc.canAssignRole(AppRole.owner), isFalse,
            reason: '${assignerRole.value} should NOT assign owner');
        expect(svc.canAssignRole(AppRole.superAdmin), isFalse,
            reason: '${assignerRole.value} should NOT assign super_admin');
      }
    },
  );

  test(
    'Property 11d: lower roles cannot assign any role (150 iterations)',
    () {
      final rng = Random(309);

      for (var i = 0; i < 150; i++) {
        final role = _lowerRoles[rng.nextInt(_lowerRoles.length)];
        final targetRole = _randomRole(rng);
        final companyId = _randomCompanyId(rng);
        final svc = _service(role, companyId);

        expect(svc.canAssignRole(targetRole), isFalse,
            reason:
                'Iteration $i: ${role.value} should NOT assign ${targetRole.value}');
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 24: Super_admin — полный кросс-тенантный доступ
  //
  // Для любого companyId и пользователя с ролью super_admin, canRead,
  // canWrite, canAccessCompany и canViewSensitiveBilling должны возвращать
  // true.
  // **Validates: Requirements 13.1, 13.2, 13.3**
  // -------------------------------------------------------------------------

  test(
    'Property 24a: super_admin has full access for any companyId and module (150 iterations)',
    () {
      final rng = Random(310);

      for (var i = 0; i < 150; i++) {
        final userCompany = _randomCompanyId(rng);
        final targetCompany = _randomCompanyId(rng);
        final module = _randomModule(rng);
        final action = _randomAction(rng);
        final svc = _service(AppRole.superAdmin, userCompany);

        expect(svc.canAccessCompany(targetCompany), isTrue,
            reason: 'Iteration $i: super_admin should access any company');
        expect(svc.canRead(module), isTrue,
            reason: 'Iteration $i: super_admin should canRead("$module")');
        expect(svc.canWrite(module, action), isTrue,
            reason:
                'Iteration $i: super_admin should canWrite("$module", "$action")');
      }
    },
  );

  test(
    'Property 24b: super_admin canViewSensitiveBilling is always true (150 iterations)',
    () {
      final rng = Random(311);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.superAdmin, companyId);

        expect(svc.canViewSensitiveBilling(), isTrue,
            reason: 'Iteration $i: super_admin should view sensitive billing');
      }
    },
  );

  test(
    'Property 24c: super_admin canAssignRole is true for all roles (exhaustive)',
    () {
      final svc = _service(AppRole.superAdmin, 'company_test');
      for (final target in _allRoles) {
        expect(svc.canAssignRole(target), isTrue,
            reason: 'super_admin should assign ${target.value}');
      }
    },
  );

  test(
    'Property 24d: super_admin has all auxiliary permissions (exhaustive)',
    () {
      final svc = _service(AppRole.superAdmin, 'company_test');
      expect(svc.canEditCompanyProfile(), isTrue);
      expect(svc.canEditSettings(), isTrue);
      expect(svc.canManageIntegrations(), isTrue);
      expect(svc.canViewSensitiveBilling(), isTrue);
    },
  );

  // -------------------------------------------------------------------------
  // Property 25: Accountant scopes — разрешённые операции
  //
  // Для любого пользователя с ролью accountant:
  //   canRead(accounting/reports/audit) = true,
  //   canWrite(accounting, create/update) = true;
  //   canRead(overview/users/billing/settings/ops_health) = false
  // **Validates: Requirements 14.1, 14.2, 14.3, 14.4, 14.5, 19.1, 19.4**
  // -------------------------------------------------------------------------

  test(
    'Property 25a: accountant canRead returns true for accounting/reports/audit (150 iterations)',
    () {
      final rng = Random(312);
      const allowedModules = ['accounting', 'reports', 'audit'];
      const deniedModules = [
        'overview',
        'users',
        'billing',
        'settings',
        'ops_health',
        'members',
        'invites',
        'company_profile',
        'invoices',
        'inventory',
        'routes',
        'delivery_points',
        'integrations',
        'metrics',
      ];

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);

        // Pick a random allowed module — should be true
        final allowed = allowedModules[rng.nextInt(allowedModules.length)];
        expect(svc.canRead(allowed), isTrue,
            reason: 'Iteration $i: accountant should canRead("$allowed")');

        // Pick a random denied module — should be false
        final denied = deniedModules[rng.nextInt(deniedModules.length)];
        expect(svc.canRead(denied), isFalse,
            reason: 'Iteration $i: accountant should NOT canRead("$denied")');
      }
    },
  );

  test(
    'Property 25b: accountant canWrite(accounting, create/update) returns true (150 iterations)',
    () {
      final rng = Random(313);
      const allowedActions = ['create', 'update'];
      const deniedActions = ['delete', 'read'];
      const deniedModules = [
        'members',
        'invites',
        'company_profile',
        'settings',
        'invoices',
        'inventory',
        'routes',
        'delivery_points',
        'integrations',
      ];

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);

        // Allowed: accounting + create/update
        final allowedAction =
            allowedActions[rng.nextInt(allowedActions.length)];
        expect(svc.canWrite('accounting', allowedAction), isTrue,
            reason:
                'Iteration $i: accountant should canWrite("accounting", "$allowedAction")');

        // Denied: accounting + delete
        final deniedAction = deniedActions[rng.nextInt(deniedActions.length)];
        expect(svc.canWrite('accounting', deniedAction), isFalse,
            reason:
                'Iteration $i: accountant should NOT canWrite("accounting", "$deniedAction")');

        // Denied: any other module
        final deniedModule = deniedModules[rng.nextInt(deniedModules.length)];
        final anyAction = _randomAction(rng);
        expect(svc.canWrite(deniedModule, anyAction), isFalse,
            reason:
                'Iteration $i: accountant should NOT canWrite("$deniedModule", "$anyAction")');
      }
    },
  );

  test(
    'Property 25c: accountant canCreateAccountingDoc, canEditAccountingDoc, canDeleteAccountingDoc (150 iterations)',
    () {
      final rng = Random(314);
      const validDocTypes = [
        'tax_invoice',
        'receipt',
        'tax_invoice_receipt',
        'credit_note',
      ];
      const invalidDocTypes = ['unknown', 'invoice', 'report', ''];
      const nonDraftStatuses = [
        'issued',
        'locked',
        'credited',
        'voided_before_delivery'
      ];

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);

        // canCreateAccountingDoc — true for valid types
        final validType = validDocTypes[rng.nextInt(validDocTypes.length)];
        expect(svc.canCreateAccountingDoc(validType), isTrue,
            reason:
                'Iteration $i: accountant should canCreateAccountingDoc("$validType")');

        // canCreateAccountingDoc — false for invalid types
        final invalidType =
            invalidDocTypes[rng.nextInt(invalidDocTypes.length)];
        expect(svc.canCreateAccountingDoc(invalidType), isFalse,
            reason:
                'Iteration $i: accountant should NOT canCreateAccountingDoc("$invalidType")');

        // canEditAccountingDoc('draft') — true
        expect(svc.canEditAccountingDoc('draft'), isTrue,
            reason:
                'Iteration $i: accountant should canEditAccountingDoc("draft")');

        // canEditAccountingDoc(non-draft) — false
        final nonDraft = nonDraftStatuses[rng.nextInt(nonDraftStatuses.length)];
        expect(svc.canEditAccountingDoc(nonDraft), isFalse,
            reason:
                'Iteration $i: accountant should NOT canEditAccountingDoc("$nonDraft")');

        // canDeleteAccountingDoc — always false
        expect(svc.canDeleteAccountingDoc(), isFalse,
            reason:
                'Iteration $i: accountant should NOT canDeleteAccountingDoc');
      }
    },
  );

  test(
    'Property 25d: accountant writableCollections returns [invoices] (150 iterations)',
    () {
      final rng = Random(315);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);

        final collections = svc.writableCollections();
        expect(collections, equals(['invoices']),
            reason:
                'Iteration $i: accountant writableCollections should be [invoices]');
      }
    },
  );

  // -------------------------------------------------------------------------
  // Property 26: Accountant — запрещённые операции
  //
  // Для любого пользователя с ролью accountant и любого модуля из
  // {members, settings, billing, invites}: canWrite(module, action) = false
  // для любого action.
  // accountant canAssignRole = false для любой роли.
  // accountant canEditCompanyProfile, canEditSettings, canManageIntegrations
  // все возвращают false.
  // **Validates: Requirements 14.6, 14.7, 14.8, 19.5**
  // -------------------------------------------------------------------------

  test(
    'Property 26a: accountant canWrite returns false for members/settings/billing/invites with any action (150 iterations)',
    () {
      final rng = Random(316);
      const forbiddenModules = ['members', 'settings', 'billing', 'invites'];

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);
        final module = forbiddenModules[rng.nextInt(forbiddenModules.length)];
        final action = _randomAction(rng);

        expect(svc.canWrite(module, action), isFalse,
            reason:
                'Iteration $i: accountant should NOT canWrite("$module", "$action")');
      }
    },
  );

  test(
    'Property 26b: accountant canAssignRole returns false for any role (150 iterations)',
    () {
      final rng = Random(317);

      for (var i = 0; i < 150; i++) {
        final companyId = _randomCompanyId(rng);
        final svc = _service(AppRole.accountant, companyId);
        final targetRole = _randomRole(rng);

        expect(svc.canAssignRole(targetRole), isFalse,
            reason:
                'Iteration $i: accountant should NOT canAssignRole(${targetRole.value})');
      }
    },
  );

  test(
    'Property 26c: accountant canEditCompanyProfile, canEditSettings, canManageIntegrations all return false (exhaustive)',
    () {
      for (final companyId in ['company_a', 'company_b', 'company_xyz']) {
        final svc = _service(AppRole.accountant, companyId);

        expect(svc.canEditCompanyProfile(), isFalse,
            reason: 'accountant ($companyId) should NOT canEditCompanyProfile');
        expect(svc.canEditSettings(), isFalse,
            reason: 'accountant ($companyId) should NOT canEditSettings');
        expect(svc.canManageIntegrations(), isFalse,
            reason: 'accountant ($companyId) should NOT canManageIntegrations');
      }
    },
  );
}
