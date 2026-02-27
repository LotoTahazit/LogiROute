import 'package:flutter/material.dart';
import '../models/company_settings.dart';
import '../services/company_settings_service.dart';
import '../services/module_manager.dart';
import 'module_access_denied.dart';

/// Обёртка для проверки доступа к модулю
/// Загружает CompanySettings и проверяет entitlement
class ModuleGuard extends StatelessWidget {
  final String companyId;
  final String requiredModule;
  final Widget child;

  const ModuleGuard({
    super.key,
    required this.companyId,
    required this.requiredModule,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (companyId.isEmpty)
      return child; // fallback: пропускаем если нет companyId

    return FutureBuilder<CompanySettings?>(
      future: CompanySettingsService(companyId: companyId).getSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = snapshot.data;
        if (settings == null) return child; // нет настроек — пропускаем

        if (!ModuleManager.isBillingActive(settings)) {
          return Scaffold(
            body: ModuleAccessDenied(
              moduleName: requiredModule,
              description: 'החשבון שלך אינו פעיל. אנא צור קשר עם התמיכה.',
            ),
          );
        }

        if (!ModuleManager.hasModule(settings, requiredModule)) {
          return Scaffold(
            body: ModuleAccessDenied(moduleName: requiredModule),
          );
        }

        if (!ModuleManager.checkDependencies(settings, requiredModule)) {
          return Scaffold(
            body: ModuleAccessDenied(
              moduleName: requiredModule,
              description: 'מודול זה דורש מודולים נוספים שאינם פעילים',
            ),
          );
        }

        return child;
      },
    );
  }
}
