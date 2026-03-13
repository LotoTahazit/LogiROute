import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_point.dart';
import 'smart_navigation_service.dart';

class FullRouteLauncher {
  final SmartNavigationService _smartNav = SmartNavigationService();

  /// 📍 Открывает маршрут целиком:
  /// - если точек ≤3 → открывает Google Maps
  /// - если >3 → строит OSRM маршрут внутри приложения
  Future<void> openFullRoute(List<DeliveryPoint> points) async {
    if (points.isEmpty) {
      print('⚠️ [FullRouteLauncher] No points to navigate');
      return;
    }

    print('🧭 [FullRouteLauncher] Opening route with ${points.length} points');

    if (points.length <= 3) {
      // ✅ Google Maps для коротких маршрутов
      final start = '${points.first.latitude},${points.first.longitude}';
      final end = '${points.last.latitude},${points.last.longitude}';
      final waypoints = points.length > 2
          ? points
              .sublist(1, points.length - 1)
              .map((p) => '${p.latitude},${p.longitude}')
              .join('|')
          : '';

      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$start'
        '&destination=$end'
        '&travelmode=driving'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}',
      );

      print('🗺️ [FullRouteLauncher] Opening Google Maps: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('✅ [FullRouteLauncher] Google Maps opened successfully');
      } else {
        print('❌ [FullRouteLauncher] Failed to open Google Maps: $url');
        throw Exception('Не удалось открыть Google Maps: $url');
      }
    } else {
      // 🚀 OSRM для длинных маршрутов (строится внутри приложения)
      print('🚀 [FullRouteLauncher] Using OSRM for ${points.length} points');
      
      final startLat = points.first.latitude;
      final startLng = points.first.longitude;
      final endLat = points.last.latitude;
      final endLng = points.last.longitude;

      final osrmRoute = await _smartNav.getMultiPointRoute(
        startLat: startLat,
        startLng: startLng,
        waypoints: points.sublist(1, points.length - 1),
        endLat: endLat,
        endLng: endLng,
      );

      if (osrmRoute != null) {
        print('✅ [FullRouteLauncher] OSRM route calculated: '
            '${osrmRoute.distance}, ${osrmRoute.duration}');
      } else {
        print('❌ [FullRouteLauncher] Failed to build OSRM route');
        throw Exception('Не удалось построить маршрут через OSRM');
      }
    }
  }
}

