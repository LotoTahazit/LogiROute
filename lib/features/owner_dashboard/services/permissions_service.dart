import '../models/role_hierarchy.dart';

/// Сервис проверки прав доступа на уровне приложения.
///
/// Чистая бизнес-логика без зависимости от Firestore.
/// - `owner`: canRead(*) для своей компании; canWrite только для members, invites, company_profile
/// - `admin`: canRead(*) + canWrite(*) для своей компании
/// - `super_admin`: всё разрешено для любой компании
/// - `accountant`: canRead(accounting/reports/audit/settings); canWrite(accounting, create/update);
///   редактирование профиля компании, настроек счёта, интеграций и клиентов; no delete
class PermissionsService {
  final AppRole role;
  final String userCompanyId;
  final Map<String, String>? scopes;

  const PermissionsService({
    required this.role,
    required this.userCompanyId,
    this.scopes,
  });

  /// Права по effectiveRole (`viewAsRole ?? actualRole`) — только UI.
  factory PermissionsService.forUser({
    required String? actualRole,
    String? viewAsRole,
    required String userCompanyId,
  }) {
    return PermissionsService(
      role: effectiveAppRole(actualRole: actualRole, viewAsRole: viewAsRole),
      userCompanyId: userCompanyId,
    );
  }

  /// Коллекции, в которые owner может писать.
  static const _ownerWritableCollections = [
    'members',
    'invites',
    'company_profile',
  ];

  /// Все коллекции, доступные для записи admin/super_admin.
  static const _allWritableCollections = [
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

  /// Коллекции, доступные для записи accountant.
  static const _accountantWritableCollections = [
    'invoices',
  ];

  /// Модули, доступные для чтения accountant.
  static const _accountantReadableModules = {
    'accounting',
    'reports',
    'audit',
    'settings',
  };

  /// Роли, которые owner может назначать.
  static const _ownerAssignableRoles = {
    AppRole.admin,
    AppRole.dispatcher,
    AppRole.driver,
    AppRole.warehouseKeeper,
    AppRole.accountant,
  };

  /// Роли, которые admin может назначать.
  static const _adminAssignableRoles = {
    AppRole.admin,
    AppRole.dispatcher,
    AppRole.driver,
    AppRole.warehouseKeeper,
    AppRole.accountant,
  };

  /// Допустимые типы бухгалтерских документов для создания.
  static const _allowedAccountingDocTypes = {
    'tax_invoice',
    'receipt',
    'tax_invoice_receipt',
    'credit_note',
    'delivery_note',
  };

  /// Проверяет, может ли пользователь получить доступ к данным указанной компании.
  ///
  /// super_admin — кросс-тенантный доступ ко всем компаниям.
  /// Остальные роли — только к своей компании.
  bool canAccessCompany(String targetCompanyId) {
    if (role == AppRole.superAdmin) return true;
    return targetCompanyId == userCompanyId;
  }

  /// Проверяет право на чтение модуля.
  ///
  /// owner, admin, super_admin — могут читать все модули (в рамках своей компании).
  /// accountant — accounting, reports, audit, settings.
  /// Остальные роли — не имеют доступа через Owner Dashboard.
  bool canRead(String module) {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
        return true;
      case AppRole.accountant:
        return _accountantReadableModules.contains(module);
      default:
        return false;
    }
  }

  /// Проверяет право на запись в коллекцию.
  ///
  /// - super_admin: полный доступ на запись
  /// - admin: полный доступ на запись в рамках компании
  /// - owner: только members, invites, company_profile
  /// - accountant: только accounting с create/update (не delete)
  bool canWrite(String module, String action) {
    switch (role) {
      case AppRole.superAdmin:
        return true;
      case AppRole.admin:
        return true;
      case AppRole.owner:
        return _ownerWritableCollections.contains(module);
      case AppRole.accountant:
        if (module != 'accounting') return false;
        return action == 'create' || action == 'update';
      default:
        return false;
    }
  }

  /// Проверяет, может ли пользователь назначить указанную роль.
  ///
  /// - super_admin: может назначить любую роль
  /// - owner: admin, dispatcher, driver, warehouse_keeper, accountant
  /// - admin: admin, dispatcher, driver, warehouse_keeper, accountant
  /// viewer отключён до появления read-only dashboard.
  bool canAssignRole(AppRole targetRole) {
    if (targetRole == AppRole.viewer) return false;
    switch (role) {
      case AppRole.superAdmin:
        return true;
      case AppRole.owner:
        return _ownerAssignableRoles.contains(targetRole);
      case AppRole.admin:
        return _adminAssignableRoles.contains(targetRole);
      default:
        return false;
    }
  }

  /// Проверяет право на редактирование профиля компании.
  ///
  /// Доступно для owner, admin, super_admin, accountant.
  bool canEditCompanyProfile() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет право на редактирование настроек счёта (подвал, тнаи тшлум, реквизиты банка).
  ///
  /// Доступно для owner, admin, super_admin и accountant.
  bool canEditInvoiceSettings() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет право на редактирование настроек (налоги, нумерация, шаблоны).
  ///
  /// Доступно для admin, super_admin, accountant и owner (self-service pilot).
  bool canEditSettings() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
      case AppRole.accountant:
      case AppRole.owner:
        return true;
      default:
        return false;
    }
  }

  /// Интеграции — admin+ и owner на этапе первичной настройки.
  bool canManageIntegrations() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
      case AppRole.accountant:
      case AppRole.owner:
        return true;
      default:
        return false;
    }
  }

  /// Создание и редактирование клиентов (для счетов и накладных).
  bool canManageClients() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
      case AppRole.owner:
      case AppRole.dispatcher:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Политики доставки и дефолты водителя — только admin/super_admin.
  bool canEditOpsSettings() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
        return true;
      default:
        return false;
    }
  }

  /// Настройка API-ключей внешней бухгалтерии (Greeninvoice / iCount).
  bool canManageAccountingCredentials() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет доступ к чувствительным полям биллинга (subscriptionId, paymentCustomerId).
  ///
  /// Доступно только для super_admin.
  bool canViewSensitiveBilling() {
    return role == AppRole.superAdmin;
  }

  /// Возвращает список коллекций, доступных для записи текущей роли.
  List<String> writableCollections() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
        return List.unmodifiable(_allWritableCollections);
      case AppRole.owner:
        return List.unmodifiable(_ownerWritableCollections);
      case AppRole.accountant:
        return List.unmodifiable(_accountantWritableCollections);
      default:
        return const [];
    }
  }

  /// Проверяет, может ли пользователь создать бухгалтерский документ указанного типа.
  ///
  /// Допустимые типы: tax_invoice, receipt, tax_invoice_receipt, credit_note, delivery_note.
  /// Для admin/super_admin/owner/accountant — true для допустимых типов.
  bool canCreateAccountingDoc(String docType) {
    if (!_allowedAccountingDocTypes.contains(docType)) return false;
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Accountant/admin/owner/super_admin могут редактировать только draft-документы.
  bool canEditAccountingDoc(String docStatus) {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
      case AppRole.accountant:
        return docStatus == 'draft';
      default:
        return false;
    }
  }

  /// Проверяет, может ли пользователь удалить бухгалтерский документ.
  ///
  /// Удаление бухгалтерских документов запрещено для всех ролей
  /// в соответствии с требованиями ניהול ספרים.
  bool canDeleteAccountingDoc() {
    return false;
  }
}
