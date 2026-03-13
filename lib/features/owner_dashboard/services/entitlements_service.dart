import '../../../models/company_settings.dart';

/// Сервис определения доступных модулей и лимитов на основе тарифного плана.
///
/// Чистая бизнес-логика без зависимости от Firestore.
/// Данные передаются через [CompanySettings].
///
/// Источник данных: документ `/companies/{companyId}` — поля `modules`, `limits`, `plan`, `billingStatus`.
class EntitlementsService {
  final CompanySettings companySettings;

  const EntitlementsService({required this.companySettings});

  /// Модули, включённые в план.
  static const _planModules = <String, Set<String>>{
    'warehouse_only': {'warehouse'},
    'ops': {'warehouse', 'logistics', 'dispatcher', 'reports'},
    'full': {'warehouse', 'logistics', 'dispatcher', 'accounting', 'reports'},
  };

  /// Возвращает текущие модули компании.
  ModuleEntitlements getModules() => companySettings.modules;

  /// Возвращает лимиты текущего плана.
  PlanLimits getLimits() => companySettings.limits;

  /// Возвращает отчёт об использовании на основе переданных значений.
  PlanUsageReport getUsage({
    required int currentUsers,
    required int currentDocsThisMonth,
  }) {
    final limits = companySettings.limits;
    return PlanUsageReport(
      plan: companySettings.plan,
      limits: limits,
      currentUsers: currentUsers,
      currentDocsThisMonth: currentDocsThisMonth,
    );
  }

  /// Проверяет, доступен ли модуль по текущему плану.
  bool isModuleAvailable(String moduleKey) {
    return companySettings.modules[moduleKey];
  }

  /// Проверяет, является ли модуль addon (включён, но не входит в базовый план).
  bool isAddon(String moduleKey) {
    if (!isModuleAvailable(moduleKey)) return false;
    final basePlanModules = _planModules[companySettings.plan] ?? {};
    return !basePlanModules.contains(moduleKey);
  }

  /// Возвращает уровень алерта для использования ресурса.
  ///
  /// - `'critical'` если usage >= limit (100%)
  /// - `'warning'` если usage >= 80% от limit
  /// - `null` если usage < 80% от limit
  ///
  /// Для limit <= 0 всегда возвращает null.
  static String? getAlertLevel(int usage, int limit) {
    if (limit <= 0) return null;
    if (usage >= limit) return 'critical';
    if (usage >= (limit * 0.8)) return 'warning';
    return null;
  }

  /// Возвращает количество оставшихся дней триала.
  ///
  /// Результат всегда >= 0. Если trialEndsAt в прошлом, возвращает 0.
  /// Неполный день считается за целый (ceil).
  static int getTrialDaysRemaining(DateTime trialEndsAt, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final difference = trialEndsAt.difference(currentTime);
    if (difference.isNegative || difference == Duration.zero) return 0;
    // ceil: any partial day counts as a full day
    return (difference.inSeconds / 86400).ceil();
  }

  /// Возвращает список видимых секций на основе billingStatus.
  ///
  /// При `suspended` или `cancelled` — только Биллинг и Настройки.
  /// Иначе — все секции (включая accounting и reports).
  static List<String> getVisibleSections(String billingStatus) {
    if (billingStatus == 'suspended' || billingStatus == 'cancelled') {
      return const ['billing', 'settings'];
    }
    return const [
      'overview',
      'users_roles',
      'billing',
      'settings',
      'audit',
      'ops_health',
      'accounting',
      'reports',
    ];
  }

  /// Проверяет, можно ли создать приглашение.
  ///
  /// Возвращает `false` если activeUsers >= usersLimit.
  static bool canCreateInvite(int activeUsers, int usersLimit) {
    return activeUsers < usersLimit;
  }
}

/// Отчёт об использовании лимитов (pure data class).
class PlanUsageReport {
  final String plan;
  final PlanLimits limits;
  final int currentUsers;
  final int currentDocsThisMonth;

  const PlanUsageReport({
    required this.plan,
    required this.limits,
    required this.currentUsers,
    required this.currentDocsThisMonth,
  });

  bool get usersAtLimit => currentUsers >= limits.maxUsers;
  bool get docsAtLimit => currentDocsThisMonth >= limits.maxDocsPerMonth;

  String? get usersAlertLevel =>
      EntitlementsService.getAlertLevel(currentUsers, limits.maxUsers);
  String? get docsAlertLevel => EntitlementsService.getAlertLevel(
      currentDocsThisMonth, limits.maxDocsPerMonth);
}
