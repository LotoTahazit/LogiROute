import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/company_selection_service.dart';
import '../services/auth_service.dart';

/// Виджет выбора компании для super_admin
class CompanySelectorWidget extends StatelessWidget {
  const CompanySelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final companyService = context.watch<CompanySelectionService>();

    // Показываем только для super_admin
    if (authService.userModel?.isSuperAdmin != true) {
      return const SizedBox.shrink();
    }

    if (companyService.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (companyService.availableCompanies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: companyService.selectedCompanyId,
              dropdownColor: Colors.blue.shade700,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: companyService.availableCompanies.map((company) {
                return DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  companyService.selectCompany(value);
                  // ✅ Устанавливаем виртуальный companyId в AuthService
                  authService.setVirtualCompanyId(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
