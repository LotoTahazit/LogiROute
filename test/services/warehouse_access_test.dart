import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/warehouse_access.dart';

void main() {
  group('WarehouseAccess', () {
    test('dispatcher read-only', () {
      expect(WarehouseAccess.canReadWarehouse('dispatcher'), true);
      expect(WarehouseAccess.canWriteWarehouse('dispatcher'), false);
      expect(WarehouseAccess.isReadOnlyWarehouse('dispatcher'), true);
    });

    test('warehouse_keeper write', () {
      expect(WarehouseAccess.canWriteWarehouse('warehouse_keeper'), true);
      expect(WarehouseAccess.isReadOnlyWarehouse('warehouse_keeper'), false);
    });

    test('admin write', () {
      expect(WarehouseAccess.canWriteWarehouse('admin'), true);
    });

    test('driver no warehouse access', () {
      expect(WarehouseAccess.canReadWarehouse('driver'), false);
      expect(WarehouseAccess.canWriteWarehouse('driver'), false);
    });
  });
}
