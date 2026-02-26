import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../services/web_geocoding_service.dart';

class GeocodingHelper {
  static String applyStreetAbbreviations(String address) {
    String result = address;

    final knownAbbreviations = {
      'בעל שם טוב': 'בעלש"ט',
      'הבעל שם טוב': 'הבעלש"ט',
      'בן גוריון': 'בן גוריון',
      'דוד המלך': 'דוד המלך',
    };

    for (final entry in knownAbbreviations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    final patterns = [
      RegExp(r'רבי\s+(\S)(\S+)'),
      RegExp(r'משה\s+(\S)(\S+)'),
      RegExp(r'אליהו\s+(\S)(\S+)'),
      RegExp(r'דוד\s+(\S)(\S+)'),
      RegExp(r'שלמה\s+(\S)(\S+)'),
      RegExp(r'יהודה\s+(\S)(\S+)'),
    ];

    for (final pattern in patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final prefix = match.group(0)!.split(' ')[0];
        final firstLetter = match.group(1)!;
        return '$prefix $firstLetter';
      });
    }

    return result;
  }

  static List<String> generateAddressVariants(String originalAddress) {
    List<String> variants = [originalAddress];

    String abbreviated = applyStreetAbbreviations(originalAddress);
    if (abbreviated != originalAddress) variants.add(abbreviated);

    variants.add('$originalAddress, ישראל');
    if (abbreviated != originalAddress) variants.add('$abbreviated, ישראל');

    String withoutPrefix = originalAddress
        .replaceAll('רחוב ', '')
        .replaceAll('רח\' ', '')
        .replaceAll('שדרות ', '')
        .replaceAll('שד\' ', '')
        .trim();

    if (withoutPrefix != originalAddress) {
      variants.add(withoutPrefix);
      variants.add('$withoutPrefix, ישראל');

      String withoutPrefixAbbr = applyStreetAbbreviations(withoutPrefix);
      if (withoutPrefixAbbr != withoutPrefix) {
        variants.add(withoutPrefixAbbr);
        variants.add('$withoutPrefixAbbr, ישראל');
      }
    }

    return variants.toSet().toList();
  }

  static Future<Map<String, double>?> geocodeAddress(String address) async {
    final variants = generateAddressVariants(address);

    if (kIsWeb) {
      for (String variant in variants) {
        final result = await WebGeocodingService.geocode(variant);
        if (result != null) {
          return {'latitude': result.latitude, 'longitude': result.longitude};
        }
      }
    } else {
      for (String variant in variants) {
        try {
          final locations = await geocoding.locationFromAddress(variant);
          if (locations.isNotEmpty) {
            return {
              'latitude': locations.first.latitude,
              'longitude': locations.first.longitude,
            };
          }
        } catch (e) {
          continue;
        }
      }
    }

    debugPrint('❌ [Geocoding] All variants failed for: $address');
    return null;
  }
}
