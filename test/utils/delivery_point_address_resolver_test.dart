import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/delivery_point.dart';
import 'package:logiroute/utils/delivery_point_address_resolver.dart';

DeliveryPoint _point({
  String address = 'Client St 1',
  double lat = 32.08,
  double lng = 34.78,
  String? override,
  double? overrideLat,
  double? overrideLng,
}) {
  return DeliveryPoint(
    id: 'p1',
    companyId: 'c1',
    address: address,
    latitude: lat,
    longitude: lng,
    clientName: 'Client',
    urgency: 'n',
    pallets: 0,
    boxes: 0,
    deliveryAddressOverride: override,
    deliveryAddressOverrideLat: overrideLat,
    deliveryAddressOverrideLng: overrideLng,
  );
}

void main() {
  test('без override — обычный адрес и координаты точки', () {
    final r = resolveDeliveryPointAddress(_point());
    expect(r.hasOverride, isFalse);
    expect(r.displayAddress, 'Client St 1');
    expect(r.source, DeliveryAddressSource.pointCoordinates);
    expect(r.navLat, 32.08);
  });

  test('override coordinates — приоритет для навигации', () {
    final r = resolveDeliveryPointAddress(_point(
      override: 'Branch 5',
      overrideLat: 32.09,
      overrideLng: 34.79,
    ));
    expect(r.source, DeliveryAddressSource.deliveryAddressOverrideCoordinates);
    expect(r.navLat, 32.09);
    expect(r.displayAddress, 'Branch 5');
    expect(r.clientAddress, 'Client St 1');
  });

  test('override text — fallback без координат', () {
    final r = resolveDeliveryPointAddress(_point(
      override: 'Warehouse B',
      lat: 0,
      lng: 0,
    ));
    expect(r.source, DeliveryAddressSource.deliveryAddressOverrideText);
    expect(r.overrideMissingCoordinates, isTrue);
    expect(r.navLat, isNull);
  });

  test('legacy temporaryAddress в fromMap', () {
    final p = DeliveryPoint.fromMap({
      'address': 'Main',
      'temporaryAddress': 'Once',
      'latitude': 32.08,
      'longitude': 34.78,
    }, 'id');
    expect(p.hasDeliveryAddressOverride, isTrue);
    expect(p.deliveryAddressOverride, 'Once');
  });

  test('импорт: другой адрес → override, client не меняется', () {
    final r = resolveImportPointAddresses(
      importedAddress: 'Branch 9',
      clientAddress: 'Main St 1',
    );
    expect(r.pointAddress, 'Main St 1');
    expect(r.deliveryAddressOverride, 'Branch 9');
  });

  test('импорт: тот же адрес — без override', () {
    final r = resolveImportPointAddresses(
      importedAddress: 'Main St 1',
      clientAddress: 'Main St 1',
    );
    expect(r.pointAddress, 'Main St 1');
    expect(r.deliveryAddressOverride, isNull);
  });
}
