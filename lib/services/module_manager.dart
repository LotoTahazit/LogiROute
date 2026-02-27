import '../models/company_settings.dart';

/// Менеджер модулей — проверка доступа к модулям SaaS
///
/// Использование:
/// ```dart
/// if (!ModuleManager.hasWarehouse(companySettings)) {
///   return AccessDeniedScreen(module: 'warehouse');
/// }
/// ```
class ModuleManager {
  /// Проверить доступ к модулю по ID
  static bool hasModule(CompanySettings company, String moduleId) {
    if (company.billingStatus == 'blocked') return false;
    return company.modules[moduleId];
  }

  /// Проверить что billing активен (active или trial)
  static bool isBillingActive(CompanySettings company) {
    return company.billingStatus == 'active' ||
        company.billingStatus == 'trial';
  }

  // === Convenience методы ===

  static bool hasWarehouse(CompanySettings c) => hasModule(c, 'warehouse');
  static bool hasLogistics(CompanySettings c) => hasModule(c, 'logistics');
  static bool hasDispatcher(CompanySettings c) => hasModule(c, 'dispatcher');
  static bool hasAccounting(CompanySettings c) => hasModule(c, 'accounting');
  static bool hasReports(CompanySettings c) => hasModule(c, 'reports');

  /// Получить список доступных модулей
  static List<String> availableModules(CompanySettings company) {
    if (!isBillingActive(company)) return [];
    final all = [
      'warehouse',
      'logistics',
      'dispatcher',
      'accounting',
      'reports',
    ];
    return all.where((m) => company.modules[m]).toList();
  }

  /// Проверить зависимости модуля
  /// dispatcher требует logistics
  static bool checkDependencies(CompanySettings company, String moduleId) {
    switch (moduleId) {
      case 'dispatcher':
        return hasLogistics(company);
      default:
        return true;
    }
  }
}
