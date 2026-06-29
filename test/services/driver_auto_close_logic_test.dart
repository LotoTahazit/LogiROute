import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/config/app_config.dart';
import 'package:logiroute/models/delivery_point.dart';
import 'package:logiroute/services/driver_auto_close_logic.dart';

DeliveryPoint _point({
  required String id,
  required String driverId,
  required String status,
  double lat = 32.08,
  double lng = 34.78,
  String name = 'Client',
  int order = 0,
}) {
  return DeliveryPoint(
    id: id,
    companyId: 'c1',
    address: 'addr',
    latitude: lat,
    longitude: lng,
    clientName: name,
    urgency: 'normal',
    pallets: 0,
    boxes: 0,
    status: status,
    orderInRoute: order,
    driverId: driverId,
  );
}

void main() {
  const driverId = 'drv1';
  const driverLat = 32.08000;
  const driverLng = 34.78000;

  group('selectNearestDriverAutoCloseTarget', () {
    test('две точки рядом — закрывается ближайшая, не первая по порядку', () {
      final far = _point(
        id: 'p1',
        driverId: driverId,
        status: DeliveryPoint.statusAssigned,
        lat: 32.08010,
        lng: 34.78010,
        name: 'First',
        order: 0,
      );
      final near = _point(
        id: 'p2',
        driverId: driverId,
        status: DeliveryPoint.statusAssigned,
        lat: 32.08001,
        lng: 34.78001,
        name: 'Second',
        order: 1,
      );

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: [far, near],
        driverId: driverId,
      );

      expect(target?.point.id, 'p2');
      expect(target!.distanceMeters, lessThan(5));
    });

    test('ближайшая completed — игнорируется, выбирается следующая', () {
      final completed = _point(
        id: 'done',
        driverId: driverId,
        status: DeliveryPoint.statusCompleted,
        lat: 32.08001,
        lng: 34.78001,
        name: 'Done',
      );
      final active = _point(
        id: 'active',
        driverId: driverId,
        status: DeliveryPoint.statusInProgress,
        lat: 32.08005,
        lng: 34.78005,
        name: 'Active',
      );

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: [completed, active],
        driverId: driverId,
      );

      expect(target?.point.id, 'active');
    });

    test('точка другого водителя — игнорируется', () {
      final other = _point(
        id: 'other',
        driverId: 'other-driver',
        status: DeliveryPoint.statusAssigned,
        lat: 32.08001,
        lng: 34.78001,
      );
      final mine = _point(
        id: 'mine',
        driverId: driverId,
        status: DeliveryPoint.statusAssigned,
        lat: 32.08008,
        lng: 34.78008,
      );

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: [other, mine],
        driverId: driverId,
      );

      expect(target?.point.id, 'mine');
    });

    test('без координат — игнорируется', () {
      final bad = _point(
        id: 'bad',
        driverId: driverId,
        status: DeliveryPoint.statusAssigned,
        lat: 0,
        lng: 0,
      );

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: [bad],
        driverId: driverId,
      );

      expect(target, isNull);
    });

    test('вне радиуса — null', () {
      final far = _point(
        id: 'far',
        driverId: driverId,
        status: DeliveryPoint.statusAssigned,
        lat: 32.09,
        lng: 34.79,
      );

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: [far],
        driverId: driverId,
        enterRadiusM: AppConfig.autoCompleteRadius,
      );

      expect(target, isNull);
    });

    test('порядок маршрута не влияет — ближайшая третья по order', () {
      final points = [
        _point(id: 'a', driverId: driverId, status: DeliveryPoint.statusAssigned,
            lat: 32.08020, lng: 34.78020, order: 0),
        _point(id: 'b', driverId: driverId, status: DeliveryPoint.statusAssigned,
            lat: 32.08015, lng: 34.78015, order: 1),
        _point(id: 'c', driverId: driverId, status: DeliveryPoint.statusAssigned,
            lat: 32.08002, lng: 34.78002, order: 2),
      ];

      final target = selectNearestDriverAutoCloseTarget(
        driverLat: driverLat,
        driverLng: driverLng,
        points: points,
        driverId: driverId,
      );

      expect(target?.point.id, 'c');
    });
  });

  group('shouldResetDriverAutoCloseTimer', () {
    test('внутри enter, но до reset — таймер не сбрасывается', () {
      expect(
        shouldResetDriverAutoCloseTimer(distanceMeters: 110),
        isFalse,
      );
    });

    test('за resetRadius — сброс', () {
      expect(
        shouldResetDriverAutoCloseTimer(distanceMeters: 121),
        isTrue,
      );
    });
  });

  group('driverAutoCloseWaitComplete', () {
    test('таймер завершён после waitDuration', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final now = start.add(const Duration(minutes: 3));
      expect(driverAutoCloseWaitComplete(start, now), isTrue);
    });
  });
}
