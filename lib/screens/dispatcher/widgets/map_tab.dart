import 'package:flutter/material.dart';
import '../../../models/delivery_point.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/delivery_map_widget.dart';

/// Вкладка с картой
class MapTab extends StatelessWidget {
  final List<DeliveryPoint> routes;
  final List<DeliveryPoint> lastNonEmptyRoutes;
  final List<UserModel> drivers;
  final String? selectedDriverId;
  final Function(String? driverId) onDriverFilterChanged;

  const MapTab({
    super.key,
    required this.routes,
    required this.lastNonEmptyRoutes,
    required this.drivers,
    required this.selectedDriverId,
    required this.onDriverFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final allPoints = routes.isNotEmpty ? routes : lastNonEmptyRoutes;

    // Получаем список водителей с активными маршрутами
    final activeDriverIds = allPoints
        .where((p) => p.driverId != null)
        .map((p) => p.driverId!)
        .toSet()
        .toList();

    // Подсчитываем количество точек для каждого водителя
    final driverPointCounts = <String, int>{};
    for (final point in allPoints) {
      if (point.driverId != null) {
        driverPointCounts[point.driverId!] =
            (driverPointCounts[point.driverId!] ?? 0) + 1;
      }
    }

    // Фильтруем точки по выбранному водителю
    var filteredPoints = allPoints;
    if (selectedDriverId != null) {
      filteredPoints =
          allPoints.where((p) => p.driverId == selectedDriverId).toList();
    }

    return Column(
      children: [
        // Фильтр по водителям
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                l10n.filterByDriver,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedDriverId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('${l10n.allDrivers} (${allPoints.length})'),
                    ),
                    ...drivers.map((driver) {
                      final isActive = activeDriverIds.contains(driver.uid);
                      final pointCount = driverPointCounts[driver.uid] ?? 0;

                      return DropdownMenuItem<String?>(
                        value: driver.uid,
                        enabled: isActive,
                        child: Text(
                          isActive
                              ? '${driver.name} ($pointCount)'
                              : '${driver.name} (0)',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: onDriverFilterChanged,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DeliveryMapWidget(points: filteredPoints),
        ),
      ],
    );
  }
}
