import '../models/role_hierarchy.dart';

/// Сервис проверки прав доступа на уровне приложения.
///
/// Чистая бизнес-логика без зависимости от Firestore.
/// - `owner`: canRead(*) для своей компании; canWrite только для members, invites, company_profile
/// - `admin`: canRead(*) + canWrite(*) для своей компании
/// - `super_admin`: всё разрешено для любой компании
/// - `accountant`: canRead(accounting/reports/audit); canWrite(accounting, create/update); no delete
class PermissionsService {
  final AppRole role;
  final String userCompanyId;
  final Map<String, String>? scopes;

  const PermissionsService({
    required this.role,
    required this.userCompanyId,
    this.scopes,
  });

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
    'accountingDocs',
  ];

  /// Модули, доступные для чтения accountant.
  static const _accountantReadableModules = {
    'accounting',
    'reports',
    'audit',
  };

  /// Роли, которые owner может назначать.
  static const _ownerAssignableRoles = {
    AppRole.admin,
    AppRole.dispatcher,
    AppRole.driver,
    AppRole.warehouseKeeper,
    AppRole.accountant,
    AppRole.viewer,
  };

  /// Роли, которые admin может назначать.
  static const _adminAssignableRoles = {
    AppRole.admin,
    AppRole.dispatcher,
    AppRole.driver,
    AppRole.warehouseKeeper,
    AppRole.accountant,
    AppRole.viewer,
  };

  /// Допустимые типы бухгалтерских документов для создания.
  static const _allowedAccountingDocTypes = {
    'tax_invoice',
    'receipt',
    'tax_invoice_receipt',
    'credit_note',
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
  /// accountant — только accounting, reports, audit.
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
  /// - owner: admin, dispatcher, driver, warehouse_keeper, accountant, viewer
  /// - admin: admin, dispatcher, driver, warehouse_keeper, accountant, viewer
  bool canAssignRole(AppRole targetRole) {
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
  /// Доступно для owner, admin, super_admin.
  bool canEditCompanyProfile() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет право на редактирование настроек счёта (подвал, тнаи тшлум, реквизиты банка).
  ///
  /// Доступно для owner, admin и super_admin — это данные компании, которыми
  /// владелец управляет самостоятельно.
  bool canEditInvoiceSettings() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.owner:
      case AppRole.admin:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет право на редактирование настроек (налоги, нумерация, шаблоны).
  ///
  /// Доступно для admin и super_admin. Owner — только чтение.
  bool canEditSettings() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет право на управление интеграциями (печать, email, WhatsApp, API-ключи).
  ///
  /// Доступно для admin и super_admin. Owner — только чтение.
  bool canManageIntegrations() {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
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
  /// Допустимые типы: tax_invoice, receipt, tax_invoice_receipt, credit_note.
  /// Для admin/super_admin/accountant — true для допустимых типов.
  bool canCreateAccountingDoc(String docType) {
    if (!_allowedAccountingDocTypes.contains(docType)) return false;
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
      case AppRole.accountant:
        return true;
      default:
        return false;
    }
  }

  /// Проверяет, может ли пользователь редактировать бухгалтерский документ
  /// с указанным статусом.
  ///
  /// Accountant/admin/super_admin могут редактировать только draft-документы.
  bool canEditAccountingDoc(String docStatus) {
    switch (role) {
      case AppRole.superAdmin:
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
