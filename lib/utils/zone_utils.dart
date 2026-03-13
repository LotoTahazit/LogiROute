import 'package:flutter/material.dart';

/// Зоны доставки (אזורי חלוקה)
class DeliveryZone {
  final String id;
  final String nameHe;
  final String nameEn;
  final String nameRu;
  final Color color;

  const DeliveryZone({
    required this.id,
    required this.nameHe,
    required this.nameEn,
    required this.nameRu,
    required this.color,
  });
}

class ZoneUtils {
  static const List<DeliveryZone> allZones = [
    DeliveryZone(
      id: 'center',
      nameHe: 'מרכז',
      nameEn: 'Center',
      nameRu: 'Центр',
      color: Colors.green,
    ),
    DeliveryZone(
      id: 'south',
      nameHe: 'דרום',
      nameEn: 'South',
      nameRu: 'Юг',
      color: Colors.red,
    ),
    DeliveryZone(
      id: 'north',
      nameHe: 'צפון',
      nameEn: 'North',
      nameRu: 'Север',
      color: Colors.blue,
    ),
    DeliveryZone(
      id: 'jerusalem',
      nameHe: 'ירושלים והסביבה',
      nameEn: 'Jerusalem & Area',
      nameRu: 'Иерусалим и округа',
      color: Colors.amber,
    ),
    DeliveryZone(
      id: 'sharon',
      nameHe: 'שרון',
      nameEn: 'Sharon',
      nameRu: 'Шарон',
      color: Colors.purple,
    ),
  ];

  static DeliveryZone? getZone(String id) {
    try {
      return allZones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  static Color getZoneColor(String id) {
    return getZone(id)?.color ?? Colors.grey;
  }

  static String getZoneName(String id, String locale) {
    final zone = getZone(id);
    if (zone == null) return id;
    switch (locale) {
      case 'he':
        return zone.nameHe;
      case 'ru':
        return zone.nameRu;
      default:
        return zone.nameEn;
    }
  }

  /// Виджет с цветными точками зон клиента
  static Widget buildZoneDots(List<String> zones, {double size = 10}) {
    if (zones.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: zones.map((zoneId) {
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: getZoneColor(zoneId),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  /// Цветная полоска слева (для ListTile leading)
  static Widget buildZoneStripe(List<String> zones,
      {double width = 4, double height = 40}) {
    if (zones.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    final segmentHeight = height / zones.length;
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: zones.map((zoneId) {
          return Container(
            width: width,
            height: segmentHeight,
            color: getZoneColor(zoneId),
          );
        }).toList(),
      ),
    );
  }
}
