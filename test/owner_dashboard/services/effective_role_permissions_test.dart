import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/features/owner_dashboard/models/role_hierarchy.dart';
import 'package:logiroute/features/owner_dashboard/services/permissions_service.dart';

void main() {
  const companyId = 'co-1';

  PermissionsService perms({
    required String? actualRole,
    String? viewAsRole,
  }) {
    return PermissionsService.forUser(
      actualRole: actualRole,
      viewAsRole: viewAsRole,
      userCompanyId: companyId,
    );
  }

  group('effectiveRole view-as (H1)', () {
    test('super_admin view-as owner uses owner permissions', () {
      final p = perms(actualRole: 'super_admin', viewAsRole: 'owner');
      expect(p.canRead('billing'), isTrue);
      expect(p.canRead('users'), isTrue);
      expect(p.canViewSensitiveBilling(), isFalse);
      expect(p.canAssignRole(AppRole.admin), isTrue);
    });

    test('super_admin view-as accountant hides owner/admin sections', () {
      final p = perms(actualRole: 'super_admin', viewAsRole: 'accountant');
      expect(p.canRead('accounting'), isTrue);
      expect(p.canRead('reports'), isTrue);
      expect(p.canRead('audit'), isTrue);
      expect(p.canRead('settings'), isTrue);
      expect(p.canRead('billing'), isFalse);
      expect(p.canRead('users'), isFalse);
      expect(p.canRead('overview'), isFalse);
      expect(p.canRead('ops_health'), isFalse);
      expect(p.canViewSensitiveBilling(), isFalse);
      expect(p.canWrite('settings', 'update'), isFalse);
      expect(p.canWrite('accounting', 'create'), isTrue);
    });

    test('normal owner without view-as unchanged', () {
      final p = perms(actualRole: 'owner', viewAsRole: null);
      expect(p.canRead('billing'), isTrue);
      expect(p.canRead('users'), isTrue);
      expect(p.canViewSensitiveBilling(), isFalse);
      expect(p.canWrite('members', 'update'), isTrue);
      expect(p.canWrite('settings', 'update'), isFalse);
    });

    test('accountant without view-as unchanged', () {
      final p = perms(actualRole: 'accountant', viewAsRole: null);
      expect(p.canRead('accounting'), isTrue);
      expect(p.canRead('billing'), isFalse);
      expect(p.canEditSettings(), isTrue);
      expect(p.canEditOpsSettings(), isFalse);
    });

    test('effectiveAppRole prefers viewAsRole over actualRole', () {
      expect(
        effectiveAppRole(actualRole: 'super_admin', viewAsRole: 'accountant'),
        AppRole.accountant,
      );
      expect(
        effectiveAppRole(actualRole: 'owner', viewAsRole: null),
        AppRole.owner,
      );
    });
  });
}
