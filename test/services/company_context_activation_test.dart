import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/company_selection_service.dart';

/// H2: Support Console должен синхронизировать tenant через selectCompany + virtualCompanyId.
void main() {
  group('CompanyContext tenant activation (H2)', () {
    test('resolveAdminTenant prefers selectedCompanyId over virtual and user', () {
      expect(
        CompanySelectionService.resolveAdminTenant(
          selectedCompanyId: 'tenant-a',
          virtualCompanyId: 'tenant-old',
          userCompanyId: 'tenant-user',
        ),
        'tenant-a',
      );
    });

    test('resolveAdminTenant falls back to virtual then user companyId', () {
      expect(
        CompanySelectionService.resolveAdminTenant(
          selectedCompanyId: null,
          virtualCompanyId: 'tenant-virtual',
          userCompanyId: 'tenant-user',
        ),
        'tenant-virtual',
      );
      expect(
        CompanySelectionService.resolveAdminTenant(
          selectedCompanyId: null,
          virtualCompanyId: null,
          userCompanyId: 'tenant-user',
        ),
        'tenant-user',
      );
    });
  });
}
