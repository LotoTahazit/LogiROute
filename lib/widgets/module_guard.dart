import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/company_settings.dart';
import '../services/company_settings_service.dart';
import '../services/module_manager.dart';
import 'module_access_denied.dart';

/// Обёртка для проверки доступа к модулю.
/// Entitlements читаются через [CompanySettingsService] (root modules + rules).
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

  Widget _errorScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (companyId.isEmpty) {
      return _errorScreen(context, l10n.noCompanySelected);
    }

    return FutureBuilder<CompanySettings?>(
      future: CompanySettingsService(companyId: companyId).getSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _errorScreen(context, l10n.companyDataNotFound);
        }

        final settings = snapshot.data;
        if (settings == null) {
          return _errorScreen(context, l10n.companyDataNotFound);
        }

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
