import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/utils/delivery_address_audit.dart';

void main() {
  const client = 'ул. Герцль, 15';

  test('no change when override equal', () {
    expect(
      deliveryAddressOverrideChange(
        clientAddress: client,
        oldOverride: 'склад №3',
        newOverride: '  склад №3  ',
      ),
      isNull,
    );
  });

  test('set override logs client → override', () {
    final c = deliveryAddressOverrideChange(
      clientAddress: client,
      oldOverride: null,
      newOverride: 'склад №3, ул. Герцль, 22',
    );
    expect(c!.oldAddress, client);
    expect(c.newAddress, 'склад №3, ул. Герцль, 22');
  });

  test('clear override logs override → client', () {
    final c = deliveryAddressOverrideChange(
      clientAddress: client,
      oldOverride: 'склад №3, ул. Герцль, 22',
      newOverride: null,
    );
    expect(c!.oldAddress, 'склад №3, ул. Герцль, 22');
    expect(c.newAddress, client);
  });

  test('change override text', () {
    final c = deliveryAddressOverrideChange(
      clientAddress: client,
      oldOverride: 'склад №1',
      newOverride: 'склад №3',
    );
    expect(c!.oldAddress, 'склад №1');
    expect(c.newAddress, 'склад №3');
  });
}
