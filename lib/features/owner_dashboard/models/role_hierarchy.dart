/// Иерархия ролей приложения LogiRoute.
///
/// Порядок: super_admin > owner > admin > dispatcher | driver | warehouse_keeper | accountant | viewer
/// Роли dispatcher, driver, warehouse_keeper, accountant, viewer находятся на одном уровне.
enum AppRole {
  superAdmin,
  owner,
  admin,
  dispatcher,
  driver,
  warehouseKeeper,
  accountant,
  viewer;

  /// Строковое представление роли для Firestore.
  String get value {
    switch (this) {
      case AppRole.superAdmin:
        return 'super_admin';
      case AppRole.owner:
        return 'owner';
      case AppRole.admin:
        return 'admin';
      case AppRole.dispatcher:
        return 'dispatcher';
      case AppRole.driver:
        return 'driver';
      case AppRole.warehouseKeeper:
        return 'warehouse_keeper';
      case AppRole.accountant:
        return 'accountant';
      case AppRole.viewer:
        return 'viewer';
    }
  }

  /// Числовой уровень иерархии (больше = выше).
  ///
  /// super_admin = 3, owner = 2, admin = 1,
  /// dispatcher | driver | warehouse_keeper | accountant | viewer = 0
  int get level {
    switch (this) {
      case AppRole.superAdmin:
        return 3;
      case AppRole.owner:
        return 2;
      case AppRole.admin:
        return 1;
      case AppRole.dispatcher:
      case AppRole.driver:
      case AppRole.warehouseKeeper:
      case AppRole.accountant:
      case AppRole.viewer:
        return 0;
    }
  }

  /// Создать AppRole из строки Firestore.
  ///
  /// Бросает [ArgumentError] если строка не соответствует ни одной роли.
  static AppRole fromString(String role) {
    switch (role) {
      case 'super_admin':
        return AppRole.superAdmin;
      case 'owner':
        return AppRole.owner;
      case 'admin':
        return AppRole.admin;
      case 'dispatcher':
        return AppRole.dispatcher;
      case 'driver':
        return AppRole.driver;
      case 'warehouse_keeper':
        return AppRole.warehouseKeeper;
      case 'accountant':
        return AppRole.accountant;
      case 'viewer':
        return AppRole.viewer;
      default:
        // Неизвестная роль из Firestore (легаси/новые значения, напр. 'pending')
        // НЕ должна ронять экран — least privilege (минимальные права).
        return AppRole.viewer;
    }
  }
}

/// Сравнивает две роли по иерархии.
///
/// Возвращает:
/// - положительное число, если [a] выше [b]
/// - отрицательное число, если [a] ниже [b]
/// - 0, если роли на одном уровне
int compareRoles(AppRole a, AppRole b) {
  return a.level - b.level;
}

/// Проверяет, что роль [a] строго выше роли [b] в иерархии.
bool isAbove(AppRole a, AppRole b) {
  return a.level > b.level;
}
