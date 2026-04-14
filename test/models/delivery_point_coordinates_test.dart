import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/delivery_point.dart';

/// Regression tests for coordinate validation.
///
/// BUG: Points with coordinates outside Israel (0,0 or wrong country)
/// caused the map to "fly to space" — camera zoomed out to show the whole world.
///
/// FIX: DeliveryPoint.isValidCoordinates is the SINGLE SOURCE OF TRUTH
/// for coordinate validation, used at every level:
///   1) Model: DeliveryPoint.isValidCoordinates / hasValidCoordinates
///   2) Geocoding: Google API, Web JS API, native geocoding — all reject outside Israel
///   3) Route creation: createOptimizedRoute filters invalid points
///   4) Map markers: _buildPointMarkers skips invalid coords
///   5) Camera bounds: _moveToBoundsSafe rejects bounds outside Israel
///   6) Manual input: edit_client_dialog validates before save

void main() {
  group('DeliveryPoint.isValidCoordinates', () {
    // Valid Israel coordinates
    test('Tel Aviv center is valid', () {
      expect(DeliveryPoint.isValidCoordinates(32.0853, 34.7818), true);
    });

    test('Haifa is valid', () {
      expect(DeliveryPoint.isValidCoordinates(32.7940, 34.9896), true);
    });

    test('Beer Sheva is valid', () {
      expect(DeliveryPoint.isValidCoordinates(31.2530, 34.7915), true);
    });

    test('Eilat (southern tip) is valid', () {
      expect(DeliveryPoint.isValidCoordinates(29.5577, 34.9519), true);
    });

    test('Metula (northern tip) is valid', () {
      expect(DeliveryPoint.isValidCoordinates(33.2778, 35.5730), true);
    });

    // Invalid coordinates
    test('(0, 0) is invalid — null island', () {
      expect(DeliveryPoint.isValidCoordinates(0, 0), false);
    });

    test('(0, 34.78) is invalid — lat zero', () {
      expect(DeliveryPoint.isValidCoordinates(0, 34.78), false);
    });

    test('(32.08, 0) is invalid — lng zero', () {
      expect(DeliveryPoint.isValidCoordinates(32.08, 0), false);
    });

    test('London is invalid', () {
      expect(DeliveryPoint.isValidCoordinates(51.5074, -0.1278), false);
    });

    test('New York is invalid', () {
      expect(DeliveryPoint.isValidCoordinates(40.7128, -74.0060), false);
    });

    test('Moscow is invalid', () {
      expect(DeliveryPoint.isValidCoordinates(55.7558, 37.6173), false);
    });

    test('Cairo is invalid (south of Israel bounds)', () {
      expect(DeliveryPoint.isValidCoordinates(30.0444, 31.2357), false);
    });

    test('Istanbul is invalid', () {
      expect(DeliveryPoint.isValidCoordinates(41.0082, 28.9784), false);
    });

    test('Negative coordinates are invalid', () {
      expect(DeliveryPoint.isValidCoordinates(-32.0, 34.0), false);
    });
  });

  group('DeliveryPoint.hasValidCoordinates', () {
    DeliveryPoint _point(double lat, double lng) {
      return DeliveryPoint(
        id: 'test',
        companyId: 'test_company',
        address: 'Test',
        latitude: lat,
        longitude: lng,
        clientName: 'Test',
        urgency: 'normal',
        pallets: 1,
        boxes: 0,
      );
    }

    test('Valid point returns true', () {
      expect(_point(32.0853, 34.7818).hasValidCoordinates, true);
    });

    test('Zero coords returns false', () {
      expect(_point(0, 0).hasValidCoordinates, false);
    });

    test('Outside Israel returns false', () {
      expect(_point(51.5074, -0.1278).hasValidCoordinates, false);
    });

    test('Partial zero lat returns false', () {
      expect(_point(0, 34.78).hasValidCoordinates, false);
    });

    test('Partial zero lng returns false', () {
      expect(_point(32.08, 0).hasValidCoordinates, false);
    });
  });
}
