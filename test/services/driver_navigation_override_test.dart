import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/delivery_point.dart';
import 'package:logiroute/services/driver_navigation_urls.dart';
import 'package:logiroute/utils/delivery_point_address_resolver.dart';

void main() {
  test('override coordinates — Waze ll из override', () {
    final point = DeliveryPoint(
      id: 'p1',
      companyId: 'c1',
      address: 'Client addr',
      latitude: 32.08,
      longitude: 34.78,
      clientName: 'C',
      urgency: 'n',
      pallets: 0,
      boxes: 0,
      deliveryAddressOverride: 'Branch',
      deliveryAddressOverrideLat: 32.09001,
      deliveryAddressOverrideLng: 34.79001,
    );
    final target = navigationTargetFromDeliveryPoint(point);
    final resolved = resolveDeliveryPointAddress(point);
    expect(resolved.source,
        DeliveryAddressSource.deliveryAddressOverrideCoordinates);
    final uri = buildWazeCoordinateUri(
      resolved.navLat!,
      resolved.navLng!,
    );
    expect(uri.queryParameters['ll'], contains('32.090010'));
  });

  test('override text fallback — Waze q', () {
    const addr = 'Разовый склад';
    final point = DeliveryPoint(
      id: 'p1',
      companyId: 'c1',
      address: 'Client',
      latitude: 0,
      longitude: 0,
      clientName: 'C',
      urgency: 'n',
      pallets: 0,
      boxes: 0,
      deliveryAddressOverride: addr,
    );
    final candidates = buildNavigationLaunchCandidates(
      navigationTargetFromDeliveryPoint(point),
    );
    expect(candidates.any((c) => c.uri.queryParameters.containsKey('q')), isTrue);
  });
}
