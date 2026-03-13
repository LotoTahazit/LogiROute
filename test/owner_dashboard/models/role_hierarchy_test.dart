import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/role_hierarchy.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All roles in the enum.
const _allRoles = AppRole.values;

/// Roles at the "base" level (level 0) — they are all equal.
const _baseRoles = [
  AppRole.dispatcher,
  AppRole.driver,
  AppRole.warehouseKeeper,
  AppRole.accountant,
  AppRole.viewer,
];

/// Pick a random role.
AppRole _randomRole(Random rng) => _allRoles[rng.nextInt(_allRoles.length)];

// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 1: Иерархия ролей — порядок
  //
  // Для любых двух ролей функция сравнения согласована с порядком:
  //   super_admin > owner > admin > {dispatcher, driver, warehouse_keeper,
  //                                   accountant, viewer}
  // **Validates: Requirements 1.1**
  // -------------------------------------------------------------------------

  test(
    'Property 1a: compareRoles is consistent with level ordering (150 iterations)',
    () {
      final rng = Random(100);

      for (var i = 0; i < 150; i++) {
        final a = _randomRole(rng);
        final b = _randomRole(rng);
        final cmp = compareRoles(a, b);

        if (a.level > b.level) {
          expect(cmp > 0, isTrue,
              reason:
                  'Iteration $i: compareRoles(${a.name}, ${b.name}) should be positive');
        } else if (a.level < b.level) {
          expect(cmp < 0, isTrue,
              reason:
                  'Iteration $i: compareRoles(${a.name}, ${b.name}) should be negative');
        } else {
          expect(cmp, equals(0),
              reason:
                  'Iteration $i: compareRoles(${a.name}, ${b.name}) should be 0');
        }
      }
    },
  );

  test(
    'Property 1b: isAbove is consistent with strict level ordering (150 iterations)',
    () {
      final rng = Random(101);

      for (var i = 0; i < 150; i++) {
        final a = _randomRole(rng);
        final b = _randomRole(rng);

        expect(isAbove(a, b), equals(a.level > b.level),
            reason:
                'Iteration $i: isAbove(${a.name}, ${b.name}) inconsistent with levels');
      }
    },
  );

  test(
    'Property 1c: super_admin > owner > admin > all base roles (exhaustive)',
    () {
      // super_admin is above everyone except itself
      for (final role in _allRoles) {
        if (role == AppRole.superAdmin) {
          expect(isAbove(AppRole.superAdmin, role), isFalse,
              reason: 'super_admin should not be above itself');
        } else {
          expect(isAbove(AppRole.superAdmin, role), isTrue,
              reason: 'super_admin should be above ${role.name}');
        }
      }

      // owner is above admin and all base roles, not above super_admin or itself
      expect(isAbove(AppRole.owner, AppRole.superAdmin), isFalse);
      expect(isAbove(AppRole.owner, AppRole.owner), isFalse);
      expect(isAbove(AppRole.owner, AppRole.admin), isTrue);
      for (final base in _baseRoles) {
        expect(isAbove(AppRole.owner, base), isTrue,
            reason: 'owner should be above ${base.name}');
      }

      // admin is above all base roles, not above super_admin, owner, or itself
      expect(isAbove(AppRole.admin, AppRole.superAdmin), isFalse);
      expect(isAbove(AppRole.admin, AppRole.owner), isFalse);
      expect(isAbove(AppRole.admin, AppRole.admin), isFalse);
      for (final base in _baseRoles) {
        expect(isAbove(AppRole.admin, base), isTrue,
            reason: 'admin should be above ${base.name}');
      }

      // base roles are all at the same level — none is above another
      for (final a in _baseRoles) {
        for (final b in _baseRoles) {
          expect(isAbove(a, b), isFalse,
              reason: '${a.name} should not be above ${b.name}');
        }
      }
    },
  );

  test(
    'Property 1d: compareRoles antisymmetry — compareRoles(a,b) == -compareRoles(b,a) (150 iterations)',
    () {
      final rng = Random(102);

      for (var i = 0; i < 150; i++) {
        final a = _randomRole(rng);
        final b = _randomRole(rng);

        expect(compareRoles(a, b), equals(-compareRoles(b, a)),
            reason:
                'Iteration $i: compareRoles(${a.name}, ${b.name}) should be antisymmetric');
      }
    },
  );

  test(
    'Property 1e: compareRoles transitivity (150 iterations)',
    () {
      final rng = Random(103);

      for (var i = 0; i < 150; i++) {
        final a = _randomRole(rng);
        final b = _randomRole(rng);
        final c = _randomRole(rng);

        if (compareRoles(a, b) > 0 && compareRoles(b, c) > 0) {
          expect(compareRoles(a, c) > 0, isTrue,
              reason:
                  'Iteration $i: transitivity violated for ${a.name} > ${b.name} > ${c.name}');
        }
      }
    },
  );
}
