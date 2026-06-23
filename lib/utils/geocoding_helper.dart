import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../models/delivery_point.dart';
import '../services/address_geocoding_service.dart';
import '../services/web_geocoding_service.dart';

class GeocodingHelper {
  static String applyStreetAbbreviations(String address) =>
      AddressGeocodingService.applyStreetAbbreviations(address);

  static List<String> generateAddressVariants(String originalAddress) =>
      AddressGeocodingService.generateAddressVariants(originalAddress);

  static Future<Map<String, double>?> geocodeAddress(String address) async {
    final variants = generateAddressVariants(address);

    if (kIsWeb) {
      for (final variant in variants) {
        final result = await WebGeocodingService.geocode(variant);
        if (result != null &&
            DeliveryPoint.isValidCoordinates(
                result.latitude, result.longitude)) {
          return {'latitude': result.latitude, 'longitude': result.longitude};
        }
      }
      for (final variant in variants) {
        final result = await AddressGeocodingService.geocodeViaGoogleAPI(variant);
        if (result != null) return result;
      }
    } else {
      for (final variant in variants) {
        final result = await AddressGeocodingService.geocodeViaGoogleAPI(variant);
        if (result != null) return result;
      }
      for (final variant in variants) {
        try {
          final locations = await geocoding.locationFromAddress(variant);
          if (locations.isNotEmpty) {
            final lat = locations.first.latitude;
            final lng = locations.first.longitude;
            if (!DeliveryPoint.isValidCoordinates(lat, lng)) {
              debugPrint(
                  '⚠️ [GeoHelper] REJECTED — outside Israel: ($lat, $lng) for "$variant"');
              continue;
            }
            return {'latitude': lat, 'longitude': lng};
          }
        } catch (_) {
          continue;
        }
      }
    }

    debugPrint('❌ [Geocoding] All variants failed for: $address');
    return null;
  }
}
