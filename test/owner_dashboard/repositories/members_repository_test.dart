import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/member_with_user.dart';
import 'package:logiroute/features/owner_dashboard/models/membership.dart';
import 'package:logiroute/features/owner_dashboard/models/role_hierarchy.dart';
import 'package:logiroute/models/user_model.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _allRoles = AppRole.values;
const _allStatuses = MembershipStatus.values;

String _randomString(Random rng, {int minLen = 1, int maxLen = 20}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => 97 + rng.nextInt(26)), // a-z
  );
}

AppRole _randomRole(Random rng) => _allRoles[rng.nextInt(_allRoles.length)];

MembershipStatus _randomStatus(Random rng) =>
    _allStatuses[rng.nextInt(_allStatuses.length)];

/// Generate a random user map simulating `/users/{uid}` document.
Map<String, dynamic> _randomUserMap(Random rng) {
  // Randomly choose between 'name' and 'displayName' key
  final useDisplayName = rng.nextBool();
  final nameKey = useDisplayName ? 'displayName' : 'name';
  return {
    nameKey: _randomString(rng),
    'email': '${_randomString(rng)}@test.com',
    'phone': '+${rng.nextInt(999999999)}',
  };
}

/// Generate a random [Membership].
Membership _randomMembership(Random rng) {
  return Membership(
    role: _randomRole(rng),
    status: _randomStatus(rng),
    createdAt: DateTime(
        2020 + rng.nextInt(6), 1 + rng.nextInt(12), 1 + rng.nextInt(28)),
    createdBy: 'creator-${_randomString(rng, maxLen: 8)}',
  );
}

/// Generate a random [UserModel].
UserModel _randomUserModel(Random rng) {
  final uid = 'uid-${_randomString(rng, maxLen: 10)}';
  return UserModel(
    uid: uid,
    email: '${_randomString(rng)}@test.com',
    name: _randomString(rng),
    role: _randomRole(rng).value,
  );
}

// ===========================================================================
// Property-Based Tests
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // Property 7: Объединение Global User + Membership содержит все
  // обязательные поля
  //
  // Для любой пары (Global User, Membership), результат объединения
  // MemberWithUser должен содержать поля: displayName, email, phone,
  // role, status, createdAt.
  // **Validates: Requirements 2.3**
  // -------------------------------------------------------------------------

  test(
    'Property 7a: fromUserMapAndMembership — all required fields are present and correct (150 iterations)',
    () {
      final rng = Random(200);

      for (var i = 0; i < 150; i++) {
        final uid = 'uid-${_randomString(rng, maxLen: 10)}';
        final userMap = _randomUserMap(rng);
        final membership = _randomMembership(rng);

        final result = MemberWithUser.fromUserMapAndMembership(
          uid: uid,
          userMap: userMap,
          membership: membership,
        );

        // displayName comes from 'displayName' or 'name' key
        final expectedName =
            (userMap['displayName'] ?? userMap['name'] ?? '') as String;

        expect(result.uid, equals(uid), reason: 'Iteration $i: uid mismatch');
        expect(result.displayName, equals(expectedName),
            reason: 'Iteration $i: displayName mismatch');
        expect(result.email, equals(userMap['email']),
            reason: 'Iteration $i: email mismatch');
        expect(result.phone, equals(userMap['phone']),
            reason: 'Iteration $i: phone mismatch');
        expect(result.role, equals(membership.role),
            reason: 'Iteration $i: role mismatch');
        expect(result.status, equals(membership.status),
            reason: 'Iteration $i: status mismatch');
        expect(result.createdAt, equals(membership.createdAt),
            reason: 'Iteration $i: createdAt mismatch');
      }
    },
  );

  test(
    'Property 7b: fromUserAndMembership — all required fields are present and correct (150 iterations)',
    () {
      final rng = Random(201);

      for (var i = 0; i < 150; i++) {
        final user = _randomUserModel(rng);
        final membership = _randomMembership(rng);

        final result = MemberWithUser.fromUserAndMembership(
          user: user,
          membership: membership,
        );

        expect(result.uid, equals(user.uid),
            reason: 'Iteration $i: uid mismatch');
        expect(result.displayName, equals(user.name),
            reason: 'Iteration $i: displayName mismatch');
        expect(result.email, equals(user.email),
            reason: 'Iteration $i: email mismatch');
        expect(result.phone, isA<String>(),
            reason: 'Iteration $i: phone should be a String');
        expect(result.role, equals(membership.role),
            reason: 'Iteration $i: role mismatch');
        expect(result.status, equals(membership.status),
            reason: 'Iteration $i: status mismatch');
        expect(result.createdAt, equals(membership.createdAt),
            reason: 'Iteration $i: createdAt mismatch');
      }
    },
  );

  test(
    'Property 7c: null membership defaults to viewer/suspended with all fields still present (150 iterations)',
    () {
      final rng = Random(202);

      for (var i = 0; i < 150; i++) {
        final uid = 'uid-${_randomString(rng, maxLen: 10)}';
        final userMap = _randomUserMap(rng);

        final result = MemberWithUser.fromUserMapAndMembership(
          uid: uid,
          userMap: userMap,
          membership: null,
        );

        final expectedName =
            (userMap['displayName'] ?? userMap['name'] ?? '') as String;

        expect(result.uid, equals(uid), reason: 'Iteration $i: uid mismatch');
        expect(result.displayName, equals(expectedName),
            reason: 'Iteration $i: displayName mismatch');
        expect(result.email, equals(userMap['email']),
            reason: 'Iteration $i: email mismatch');
        expect(result.phone, equals(userMap['phone']),
            reason: 'Iteration $i: phone mismatch');
        expect(result.role, equals(AppRole.viewer),
            reason: 'Iteration $i: null membership should default to viewer');
        expect(result.status, equals(MembershipStatus.suspended),
            reason:
                'Iteration $i: null membership should default to suspended');
        // createdAt is null when membership is null — that's acceptable
        expect(result.createdAt, isNull,
            reason:
                'Iteration $i: createdAt should be null without membership');
      }
    },
  );

  test(
    'Property 7d: fromUserAndMembership with null membership defaults correctly (150 iterations)',
    () {
      final rng = Random(203);

      for (var i = 0; i < 150; i++) {
        final user = _randomUserModel(rng);

        final result = MemberWithUser.fromUserAndMembership(
          user: user,
          membership: null,
        );

        expect(result.uid, equals(user.uid),
            reason: 'Iteration $i: uid mismatch');
        expect(result.displayName, equals(user.name),
            reason: 'Iteration $i: displayName mismatch');
        expect(result.email, equals(user.email),
            reason: 'Iteration $i: email mismatch');
        expect(result.phone, isA<String>(),
            reason: 'Iteration $i: phone should be a String');
        expect(result.role, equals(AppRole.viewer),
            reason: 'Iteration $i: null membership should default to viewer');
        expect(result.status, equals(MembershipStatus.suspended),
            reason:
                'Iteration $i: null membership should default to suspended');
        expect(result.createdAt, isNull,
            reason:
                'Iteration $i: createdAt should be null without membership');
      }
    },
  );
}
