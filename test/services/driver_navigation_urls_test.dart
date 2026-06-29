import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/driver_navigation_urls.dart';
import 'package:logiroute/utils/delivery_point_address_resolver.dart';

void main() {
  group('buildWazeCoordinateUri', () {
    test('валидные координаты — waze:// с ll и navigate=yes', () {
      final uri = buildWazeCoordinateUri(32.085300, 34.781768);
      expect(uri.scheme, 'waze');
      expect(uri.queryParameters['navigate'], 'yes');
      expect(uri.queryParameters['ll'], '32.085300,34.781768');
    });

    test('https fallback для координат', () {
      final uri = buildWazeCoordinateUri(32.08, 34.78, https: true);
      expect(uri.scheme, 'https');
      expect(uri.host, 'waze.com');
      expect(uri.path, '/ul');
      expect(uri.queryParameters['ll'], isNotNull);
      expect(uri.queryParameters['navigate'], 'yes');
    });
  });

  group('buildWazeAddressUri', () {
    test('адрес с пробелами и ивритом — encodeComponent', () {
      const addr = 'רחוב הרצל 10 תל אביב';
      final uri = buildWazeAddressUri(addr);
      expect(uri.queryParameters['navigate'], 'yes');
      expect(uri.toString(), contains(Uri.encodeComponent(addr)));
    });
  });

  group('buildNavigationLaunchCandidates', () {
    test('валидные координаты — сначала Waze coords, не address', () {
      final target = DriverNavigationTarget(
        lat: 32.0853,
        lng: 34.7818,
        address: 'Some Street 1',
        clientAddress: 'Some Street 1',
        addressSource: DeliveryAddressSource.pointCoordinates,
      );
      final list = buildNavigationLaunchCandidates(target);
      expect(list.first.provider, 'waze_coords');
      expect(list.first.uri.queryParameters.containsKey('ll'), isTrue);
      expect(list.first.uri.queryParameters.containsKey('q'), isFalse);
    });

    test('координаты 0,0 — только Waze по адресу', () {
      final target = DriverNavigationTarget(
        lat: 0,
        lng: 0,
        address: 'Tel Aviv',
        clientAddress: 'Tel Aviv',
        addressSource: DeliveryAddressSource.clientAddress,
      );
      final list = buildNavigationLaunchCandidates(target);
      expect(list.any((c) => c.provider.startsWith('waze')), isTrue);
      expect(list.every((c) => c.provider.startsWith('waze')), isTrue);
    });

    test('без координат и без адреса — пусто', () {
      const target = DriverNavigationTarget(
        lat: 0,
        lng: 0,
        address: '',
        clientAddress: '',
        addressSource: DeliveryAddressSource.clientAddress,
      );
      expect(buildNavigationLaunchCandidates(target), isEmpty);
    });

    test('только Waze-кандидаты при coords и адресе', () {
      final target = DriverNavigationTarget(
        lat: 32.08,
        lng: 34.78,
        address: 'Addr',
        clientAddress: 'Addr',
        addressSource: DeliveryAddressSource.pointCoordinates,
      );
      final list = buildNavigationLaunchCandidates(target);
      expect(list.every((c) => c.provider.startsWith('waze')), isTrue);
      expect(list.first.provider, 'waze_coords');
    });
  });
}
