import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/delivery_point.dart';
import 'package:logiroute/models/invoice.dart';
import 'package:logiroute/utils/delivery_point_address_resolver.dart';

void main() {
  test('invoice: юридический адрес клиента отдельно от адреса доставки', () {
    final point = DeliveryPoint(
      id: 'p1',
      companyId: 'c1',
      address: 'Legal Client St',
      latitude: 32.08,
      longitude: 34.78,
      clientName: 'Client',
      urgency: 'n',
      pallets: 0,
      boxes: 0,
      deliveryAddressOverride: 'Warehouse B',
      deliveryAddressOverrideLat: 32.09,
      deliveryAddressOverrideLng: 34.79,
    );
    final resolved = resolveDeliveryPointAddress(point);
    final invoice = Invoice(
      id: 'i1',
      companyId: 'c1',
      sequentialNumber: 1,
      clientName: 'Client',
      clientNumber: '100',
      address: resolved.clientAddress,
      deliveryAddress: resolved.deliveryAddressOverride,
      driverName: 'Driver',
      truckNumber: '12',
      deliveryDate: DateTime(2026, 1, 1),
      departureTime: DateTime(2026, 1, 1, 7),
      items: const [],
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    );

    expect(invoice.address, 'Legal Client St');
    expect(invoice.deliveryAddress, 'Warehouse B');
    expect(invoice.address, isNot(equals(invoice.deliveryAddress)));

    final map = invoice.toMap();
    expect(map['address'], 'Legal Client St');
    expect(map['deliveryAddress'], 'Warehouse B');

    final restored = Invoice.fromMap(map, 'i1');
    expect(restored.address, invoice.address);
    expect(restored.deliveryAddress, invoice.deliveryAddress);
  });
}
