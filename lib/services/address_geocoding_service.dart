import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_config_service.dart';

/// Address geocoding helpers: variant generation, abbreviations,
/// transliteration, and Google Geocoding API calls.
class AddressGeocodingService {
  /// Replaces full street names with abbreviations (like Google Maps)
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

  /// Generates multiple address variants for geocoding (Waze-like approach)
  static List<String> generateAddressVariants(String originalAddress) {
    List<String> variants = [];

    variants.add(originalAddress);

    String abbreviated = applyStreetAbbreviations(originalAddress);
    if (abbreviated != originalAddress) {
      variants.add(abbreviated);
    }

    variants.add('$originalAddress, ישראל');
    if (abbreviated != originalAddress) {
      variants.add('$abbreviated, ישראל');
    }

    variants.add('$originalAddress, Israel');
    if (abbreviated != originalAddress) {
      variants.add('$abbreviated, Israel');
    }

    String standardizedFormat = _standardizeAddressFormat(originalAddress);
    if (standardizedFormat != originalAddress) {
      variants.add(standardizedFormat);
      variants.add('$standardizedFormat, ישראל');

      String standardizedAbbreviated =
          applyStreetAbbreviations(standardizedFormat);
      if (standardizedAbbreviated != standardizedFormat) {
        variants.add(standardizedAbbreviated);
        variants.add('$standardizedAbbreviated, ישראל');
      }
    }

    // City variants
    final cities = {
      'חולון': 'Holon',
      'ראשון לציון': 'Rishon',
      'תל אביב': 'Tel Aviv',
      'פתח תקווה': 'Petah Tikva',
      'ירושלים': 'Jerusalem',
      'חיפה': 'Haifa',
      'באר שבע': 'Beer Sheva',
    };

    for (final entry in cities.entries) {
      if (!originalAddress.contains(entry.key) &&
          !originalAddress.contains(entry.value)) {
        variants.add('$originalAddress, ${entry.key}, ישראל');
        if (abbreviated != originalAddress) {
          variants.add('$abbreviated, ${entry.key}, ישראל');
        }
      }
    }

    String simplified = _simplifyAddress(originalAddress);
    if (simplified != originalAddress) {
      variants.add(simplified);
      variants.add('$simplified, תל אביב, ישראל');

      String simplifiedAbbreviated = applyStreetAbbreviations(simplified);
      if (simplifiedAbbreviated != simplified) {
        variants.add(simplifiedAbbreviated);
        variants.add('$simplifiedAbbreviated, תל אביב, ישראל');
      }
    }

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

    List<String> transliteratedVariants =
        _getTransliteratedVariants(originalAddress);
    variants.addAll(transliteratedVariants);

    debugPrint(
        '🔍 [Address Variants] Generated ${variants.length} variants for "$originalAddress"');

    return variants.toSet().toList();
  }

  static String _standardizeAddressFormat(String address) {
    RegExp houseNumberRegex = RegExp(r'^(\d+)\s*(.+)$');
    Match? match = houseNumberRegex.firstMatch(address);

    if (match != null) {
      String number = match.group(1)!;
      String rest = match.group(2)!.trim();
      return '$number $rest';
    }

    return address;
  }

  static String _simplifyAddress(String address) {
    String simplified = address
        .replaceAll(RegExp(r'\s*,\s*'), ' ')
        .replaceAll('רחוב', '')
        .replaceAll('שדרות', '')
        .replaceAll('רח', '')
        .replaceAll('שד', '')
        .trim();

    return simplified;
  }

  static List<String> _getTransliteratedVariants(String address) {
    List<String> variants = [];

    Map<String, String> streetTranslations = {
      'רחוב החלוצים': 'HaHalutzim Street',
      'רחוב הכרמל': 'Carmel Street',
      'רחוב דיזנגוף': 'Dizengoff Street',
      'רחוב הרצל': 'Herzl Street',
      'שדרות בן גוריון': 'Ben Gurion Boulevard',
      'רחוב אלנבי': 'Allenby Street',
      'רחוב רוטשילד': 'Rothschild Boulevard',
      'שדרות': 'Boulevard',
    };

    for (String hebrewStreet in streetTranslations.keys) {
      if (address.contains(hebrewStreet)) {
        String translated = address.replaceAll(
          hebrewStreet,
          streetTranslations[hebrewStreet]!,
        );
        variants.add(translated);
        variants.add('$translated, Tel Aviv, Israel');
      }
    }

    return variants;
  }

  /// Geocode via Google Geocoding API with city validation
  static Future<Map<String, double>?> geocodeViaGoogleAPI(
      String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url =
        '${ApiConfigService.googleGeocodingApiUrl}?address=$encodedAddress&key=${ApiConfigService.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        AppConfig.geocodingTimeout,
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        late final Map<String, dynamic> data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          debugPrint('❌ [Google API] JSON parse error: $e');
          return null;
        }

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final formattedAddress = result['formatted_address'] as String;

          debugPrint('🗺️ [Google API] Input: "$address"');
          debugPrint('🗺️ [Google API] Result: "$formattedAddress"');
          debugPrint(
              '🗺️ [Google API] Coords: (${location['lat']}, ${location['lng']})');

          // Validate city if specified in request
          final cityChecks = {
            'חולון': ['חולון', 'Holon'],
            'Holon': ['חולון', 'Holon'],
            'ראשון לציון': ['ראשון לציון', 'Rishon'],
            'Rishon': ['ראשון לציון', 'Rishon'],
            'תל אביב': ['תל אביב', 'Tel Aviv'],
            'Tel Aviv': ['תל אביב', 'Tel Aviv'],
            'פתח תקווה': ['פתח תקווה', 'Petah Tikva'],
            'Petah Tikva': ['פתח תקווה', 'Petah Tikva'],
          };

          for (final entry in cityChecks.entries) {
            if (address.contains(entry.key)) {
              final cityFound =
                  entry.value.any((city) => formattedAddress.contains(city));
              if (!cityFound) {
                debugPrint(
                    '⚠️ [Google API] WARNING: Requested ${entry.key} but got: $formattedAddress');
                return null;
              }
            }
          }

          return {'latitude': location['lat'], 'longitude': location['lng']};
        } else {
          debugPrint('❌ [Google API] Status: ${data['status']}');
        }
      } else {
        debugPrint('❌ [Google API] HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Google API] Error: $e');
    }

    return null;
  }
}
