import 'package:url_launcher/url_launcher.dart';

class NavigationLauncherService {
  /// Открывает внешнюю навигацию (Google Maps или Waze) для указанной точки
  static Future<void> openExternalNavigation({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    try {
      final destination = '$latitude,$longitude';
      
      // Сначала пробуем Google Maps с правильным форматом URL
      final googleUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
      );
      
      print('🧭 [Navigation] Trying to open Google Maps: $googleUrl');
      
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
        print('✅ [Navigation] Opened Google Maps for: $destination');
        return;
      }
      
      // Если Google Maps не доступен, пробуем Waze
      print('🧭 [Navigation] Google Maps not available, trying Waze...');
      final wazeUrl = Uri.parse('waze://?ll=$destination&navigate=yes');
      
      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl, mode: LaunchMode.externalApplication);
        print('✅ [Navigation] Opened Waze for: $destination');
        return;
      }
      
      // Если ни один не доступен, пробуем общий URL для карт
      print('🧭 [Navigation] Waze not available, trying fallback maps...');
      final fallbackUrl = Uri.parse('https://maps.google.com/maps?q=$destination');
      
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        print('✅ [Navigation] Opened fallback maps for: $destination');
        return;
      }
      
      print('❌ [Navigation] No navigation app available');
      throw Exception('No navigation app available');
      
    } catch (e) {
      print('❌ [Navigation] Failed to open external navigation: $e');
      rethrow;
    }
  }
  
  /// Открывает маршрут с несколькими точками в Google Maps
  static Future<void> openMultiPointRoute({
    required List<Map<String, dynamic>> waypoints,
  }) async {
    try {
      if (waypoints.isEmpty) return;
      
      // Строим URL для маршрута с несколькими точками
      final waypointString = waypoints
          .map((point) => '${point['lat']},${point['lng']}')
          .join('|');
      
      final googleUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&waypoints=$waypointString&travelmode=driving',
      );
      
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
        print('🧭 [Navigation] Opened multi-point route with ${waypoints.length} waypoints');
        return;
      }
      
      throw Exception('Google Maps not available for multi-point route');
      
    } catch (e) {
      print('❌ [Navigation] Failed to open multi-point route: $e');
      rethrow;
    }
  }
}
