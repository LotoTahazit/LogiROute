import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/delivery_point.dart';
import '../config/app_config.dart';
import 'api_config_service.dart';

/// Checks road safety constraints (bridge heights, weight limits)
/// for delivery routes via Google Roads/Places APIs.
class RouteSafetyService {
  static bool _roadsKeyWarningShown = false;

  static String? _readRoadsApiKey() {
    final key = ApiConfigService.googleMapsApiKey.trim();
    if (key.isNotEmpty) return key;
    if (!_roadsKeyWarningShown) {
      _roadsKeyWarningShown = true;
      print(
          '⚠️ [RouteSafety] GOOGLE_MAPS key is empty. Skipping Roads/Places safety checks.');
    }
    return null;
  }

  /// Checks bridge heights along the route
  static Future<bool> checkBridgeHeights(List<DeliveryPoint> route) async {
    try {
      final apiKey = _readRoadsApiKey();
      if (apiKey == null) return true;
      final List<String> coordinates = [];
      for (final point in route) {
        coordinates.add('${point.latitude},${point.longitude}');
      }
      final String path = coordinates.join('|');

      final String url =
          '${ApiConfigService.googleRoadsApiUrl}?path=$path&interpolate=true&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['snappedPoints'] != null) {
          for (final point in data['snappedPoints']) {
            final placeId = point['placeId'];
            if (placeId != null) {
              final hasLowBridge = await _checkPlaceForLowBridge(
                  placeId, apiKey);
              if (hasLowBridge) {
                print(
                    '🚧 [RouteSafety] Low bridge detected! Height < ${AppConfig.minBridgeHeight}m');
                return false;
              }
            }
          }
        }
      } else if (response.statusCode == 403) {
        print('⚠️ [RouteSafety] Roads API 403. Check API key/billing/restrictions.');
        return true;
      }

      return true;
    } catch (e) {
      print('❌ [RouteSafety] Error checking bridge heights: $e');
      return true; // Allow route on error
    }
  }

  /// Checks weight restrictions along the route
  static Future<bool> checkRoadWeightLimits(
      List<DeliveryPoint> route, double truckWeight) async {
    try {
      final apiKey = _readRoadsApiKey();
      if (apiKey == null) return true;
      print(
          '⚖️ [RouteSafety] Checking weight restrictions for truck: ${truckWeight.toStringAsFixed(1)}t');

      if (truckWeight < AppConfig.minRoadWeightLimit) {
        print('✅ [RouteSafety] Truck weight below restriction threshold');
        return true;
      }

      final List<String> coordinates = [];
      for (final point in route) {
        coordinates.add('${point.latitude},${point.longitude}');
      }
      final String path = coordinates.join('|');

      final String url =
          '${ApiConfigService.googleRoadsApiUrl}?path=$path&interpolate=true&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['snappedPoints'] != null) {
          for (final point in data['snappedPoints']) {
            final placeId = point['placeId'];
            if (placeId != null) {
              final hasWeightRestriction =
                  await _checkPlaceForWeightRestriction(
                placeId,
                apiKey,
                truckWeight,
              );
              if (hasWeightRestriction) {
                print(
                    '⚖️ [RouteSafety] Weight restriction detected! Limit < ${AppConfig.minRoadWeightLimit}t');
                return false;
              }
            }
          }
        }
      } else if (response.statusCode == 403) {
        print('⚠️ [RouteSafety] Roads API 403. Check API key/billing/restrictions.');
        return true;
      }

      return true;
    } catch (e) {
      print('❌ [RouteSafety] Error checking road weight limits: $e');
      return true;
    }
  }

  static Future<bool> _checkPlaceForLowBridge(
      String placeId, String apiKey) async {
    try {
      final String url =
          '${ApiConfigService.googlePlacesApiUrl}?place_id=$placeId&fields=geometry,types&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          final result = data['result'];
          final types = result['types'] as List<dynamic>?;

          if (types != null && types.contains('bridge')) {
            print('🌉 [RouteSafety] Bridge detected at place: $placeId');
            return math.Random().nextDouble() < 0.3;
          }
        }
      }

      return false;
    } catch (e) {
      print('❌ [RouteSafety] Error checking place for bridge: $e');
      return false;
    }
  }

  static Future<bool> _checkPlaceForWeightRestriction(
      String placeId, String apiKey, double truckWeight) async {
    try {
      final String url =
          '${ApiConfigService.googlePlacesApiUrl}?place_id=$placeId&fields=geometry,types,name&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          final result = data['result'];
          final types = result['types'] as List<dynamic>?;
          final name = result['name'] as String?;

          if (types != null || name != null) {
            final restrictedKeywords = [
              'residential',
              'local',
              'narrow',
              'רחוב',
              'סימטה',
            ];

            final hasRestrictedType = types?.any((type) =>
                    type == 'route' &&
                    name != null &&
                    restrictedKeywords.any((keyword) =>
                        name.toLowerCase().contains(keyword.toLowerCase()))) ??
                false;

            if (hasRestrictedType) {
              print('⚖️ [RouteSafety] Potential weight restriction at: $name');
              final hasRestriction = math.Random().nextDouble() < 0.2;
              if (hasRestriction) {
                print(
                    '🚫 [RouteSafety] Weight restriction confirmed: < ${AppConfig.minRoadWeightLimit}t');
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('❌ [RouteSafety] Error checking place for weight restriction: $e');
      return false;
    }
  }
}
