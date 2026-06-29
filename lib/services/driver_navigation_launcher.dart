import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_point.dart';
import '../utils/delivery_point_address_resolver.dart';
import 'driver_navigation_urls.dart';

class NavigationLaunchResult {
  final bool success;
  final String? provider;
  final Uri? uri;
  final String? reason;

  const NavigationLaunchResult({
    required this.success,
    this.provider,
    this.uri,
    this.reason,
  });
}

/// Запуск навигации (Waze или Google Maps по remote config).
Future<NavigationLaunchResult> launchDriverNavigation(
  DeliveryPoint point, {
  bool preferWaze = true,
}) async {
  final target = navigationTargetFromDeliveryPoint(point);
  final candidates = buildNavigationLaunchCandidates(
    target,
    preferWaze: preferWaze,
  );

  debugPrint(
    '🧭 [Navigation] ${jsonEncode({
      'phase': 'prepare',
      'pointId': point.id,
      'clientName': point.clientName,
      'lat': target.lat,
      'lng': target.lng,
      'address': target.address,
      'clientAddress': target.clientAddress,
      'addressSource': deliveryAddressSourceKey(target.addressSource),
      'hasDeliveryAddressOverride': target.hasOverride,
      'hasValidCoordinates': target.hasValidCoordinates,
      'candidates': candidates.map((c) => c.uri.toString()).toList(),
    })}',
  );

  if (candidates.isEmpty) {
    return const NavigationLaunchResult(
      success: false,
      reason: 'no_destination',
    );
  }

  for (final candidate in candidates) {
    var launched = false;
    Object? error;
    try {
      launched = await launchUrl(
        candidate.uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      error = e;
      launched = false;
    }

    debugPrint(
      '🧭 [Navigation] ${jsonEncode({
        'phase': 'launch',
        'pointId': point.id,
        'provider': candidate.provider,
        'url': candidate.uri.toString(),
        'launched': launched,
        if (error != null) 'error': error.toString(),
      })}',
    );

    if (launched) {
      return NavigationLaunchResult(
        success: true,
        provider: candidate.provider,
        uri: candidate.uri,
      );
    }
  }

  return const NavigationLaunchResult(
    success: false,
    reason: 'all_failed',
  );
}
