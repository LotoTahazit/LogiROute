import '../models/delivery_point.dart';
import '../utils/delivery_point_address_resolver.dart';

/// Цель навигации для точки доставки.
class DriverNavigationTarget {
  final double? lat;
  final double? lng;
  final String address;
  final String clientAddress;
  final DeliveryAddressSource addressSource;
  final bool hasOverride;

  const DriverNavigationTarget({
    this.lat,
    this.lng,
    required this.address,
    required this.clientAddress,
    required this.addressSource,
    this.hasOverride = false,
  });

  bool get hasValidCoordinates =>
      lat != null &&
      lng != null &&
      DeliveryPoint.isValidCoordinates(lat!, lng!);
}

/// Кандидат URL для запуска внешней навигации.
class NavigationLaunchCandidate {
  final String provider;
  final Uri uri;

  const NavigationLaunchCandidate(this.provider, this.uri);
}

DriverNavigationTarget navigationTargetFromDeliveryPoint(DeliveryPoint point) {
  final resolved = resolveDeliveryPointAddress(point);
  return DriverNavigationTarget(
    lat: resolved.navLat,
    lng: resolved.navLng,
    address: resolved.displayAddress,
    clientAddress: resolved.clientAddress,
    addressSource: resolved.source,
    hasOverride: resolved.hasOverride,
  );
}

String _formatCoord(double v) => v.toStringAsFixed(6);

/// Waze: координаты (приоритет).
Uri buildWazeCoordinateUri(
  double lat,
  double lng, {
  bool https = false,
}) {
  final ll = '${_formatCoord(lat)},${_formatCoord(lng)}';
  if (https) {
    return Uri.parse('https://waze.com/ul?ll=$ll&navigate=yes');
  }
  return Uri.parse('waze://?ll=$ll&navigate=yes');
}

/// Waze: поиск по адресу (fallback).
Uri buildWazeAddressUri(String address, {bool https = true}) {
  final q = Uri.encodeComponent(address.trim());
  if (https) {
    return Uri.parse('https://waze.com/ul?q=$q&navigate=yes');
  }
  return Uri.parse('waze://?q=$q&navigate=yes');
}

Uri buildGoogleMapsCoordinateUri(double lat, double lng) {
  final ll = '${_formatCoord(lat)},${_formatCoord(lng)}';
  return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$ll');
}

Uri buildGoogleMapsAddressUri(String address) {
  final q = Uri.encodeComponent(address.trim());
  return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
}

/// Waze или Google Maps (если [preferWaze] == false).
List<NavigationLaunchCandidate> buildNavigationLaunchCandidates(
  DriverNavigationTarget target, {
  bool preferWaze = true,
}) {
  if (!preferWaze) {
    final out = <NavigationLaunchCandidate>[];
    if (target.hasValidCoordinates) {
      final lat = target.lat!;
      final lng = target.lng!;
      out.add(NavigationLaunchCandidate(
        'google_maps_coords',
        buildGoogleMapsCoordinateUri(lat, lng),
      ));
    }
    if (target.address.isNotEmpty) {
      out.add(NavigationLaunchCandidate(
        'google_maps_address',
        buildGoogleMapsAddressUri(target.address),
      ));
    }
    if (out.isNotEmpty) return out;
  }

  final out = <NavigationLaunchCandidate>[];

  if (target.hasValidCoordinates) {
    final lat = target.lat!;
    final lng = target.lng!;
    out.add(NavigationLaunchCandidate(
      'waze_coords',
      buildWazeCoordinateUri(lat, lng),
    ));
    out.add(NavigationLaunchCandidate(
      'waze_https_coords',
      buildWazeCoordinateUri(lat, lng, https: true),
    ));
  }

  if (target.address.isNotEmpty) {
    out.add(NavigationLaunchCandidate(
      'waze_address',
      buildWazeAddressUri(target.address),
    ));
    out.add(NavigationLaunchCandidate(
      'waze_https_address',
      buildWazeAddressUri(target.address, https: true),
    ));
  }

  return out;
}
