/// Warehouse RBAC aligned with Firestore rules (C6).
///
/// Read: dispatcher may read inventory/box_types/product_types (invoicing reference).
/// Write: admin, warehouse_keeper, super_admin only (`canWriteModule(warehouse)`).
class WarehouseAccess {
  WarehouseAccess._();

  static bool canReadWarehouse(String? role) {
    switch (role) {
      case 'super_admin':
      case 'admin':
      case 'owner':
      case 'warehouse_keeper':
      case 'dispatcher':
        return true;
      default:
        return false;
    }
  }

  static bool canWriteWarehouse(String? role) {
    switch (role) {
      case 'super_admin':
      case 'admin':
      case 'warehouse_keeper':
        return true;
      default:
        return false;
    }
  }

  /// Read without write (dispatcher default).
  static bool isReadOnlyWarehouse(String? role) =>
      canReadWarehouse(role) && !canWriteWarehouse(role);
}
