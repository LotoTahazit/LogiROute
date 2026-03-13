import 'package:cloud_firestore/cloud_firestore.dart';
import 'box_type.dart';

class DeliveryPoint {
  static const String statusPending = 'pending';
  static const String statusAssigned = 'assigned';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static const String statusPendingHe = '\u05de\u05de\u05ea\u05d9\u05df';
  static const String statusAssignedHe = '\u05d4\u05d5\u05e7\u05e6\u05d4';
  static const String statusInProgressHe =
      '\u05d1\u05d1\u05d9\u05e6\u05d5\u05e2';
  static const String statusCompletedHe = '\u05d4\u05d5\u05e9\u05dc\u05dd';
  static const String statusCancelledHe = '\u05d1\u05d5\u05d8\u05dc';

  static const String statusPendingRu =
      '\u043e\u0436\u0438\u0434\u0430\u0435\u0442';
  static const String statusAssignedRu =
      '\u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d';
  static const String statusInProgressRu =
      '\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435';
  static const String statusCompletedRu =
      '\u0437\u0430\u0432\u0435\u0440\u0448\u0451\u043d';
  static const String statusCancelledRu =
      '\u043e\u0442\u043c\u0435\u043d\u0451\u043d';

  static const String statusCompletedRuAlt =
      '\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d';
  static const String statusCancelledRuAlt =
      '\u043e\u0442\u043c\u0435\u043d\u0435\u043d';

  static List<String> get activeRouteStatuses => [
        statusAssigned,
        statusInProgress,
        statusAssignedHe,
        statusInProgressHe,
        statusAssignedRu,
        statusInProgressRu,
      ];

  static List<String> get pendingStatuses => [
        statusPending,
        statusPendingHe,
        statusPendingRu,
      ];
  final String id;
  final String companyId; // ID компании для изоляции данных
  final String address;
  final double latitude;
  final double longitude;
  final String clientName;
  final String? clientNumber; // 6-значный номер клиента
  final DateTime? openingTime;
  final String urgency;
  final int pallets;
  final int boxes; // Количество коробок
  final String status;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final int orderInRoute;
  final String? driverId;
  final String? driverName;
  final int? driverCapacity;
  final String? temporaryAddress; // Временный адрес для этой доставки
  final bool autoCompleted; // Завершено автоматически
  final List<BoxType>? boxTypes; // Типы коробок в заказе
  final String? eta; // Расчётное время прибытия (ETA)
  final double? distanceKm; // Расстояние от предыдущей точки (км)
  final String? routeId; // ID маршрута для группировки точек
  final String? routePolyline; // Кешированная полилиния маршрута (encoded)
  final String? updatedByUid; // Аудит: кто последний обновил статус
  final DateTime? updatedAt; // Аудит: когда последний раз обновлён статус

  DeliveryPoint({
    required this.id,
    required this.companyId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.clientName,
    this.clientNumber,
    this.openingTime,
    required this.urgency,
    required this.pallets,
    required this.boxes,
    this.status = statusPending,
    this.arrivedAt,
    this.completedAt,
    this.orderInRoute = 0,
    this.driverId,
    this.driverName,
    this.driverCapacity,
    this.temporaryAddress,
    this.autoCompleted = false,
    this.boxTypes,
    this.eta,
    this.distanceKm,
    this.routeId,
    this.routePolyline,
    this.updatedByUid,
    this.updatedAt,
  });

  factory DeliveryPoint.fromMap(Map<String, dynamic> map, String id) {
    try {
      return DeliveryPoint(
        id: id,
        companyId: map['companyId'] ?? '',
        address: map['address'] ?? '',
        latitude: (map['latitude'] is num)
            ? (map['latitude'] as num).toDouble()
            : double.tryParse('${map['latitude']}') ?? 0,
        longitude: (map['longitude'] is num)
            ? (map['longitude'] as num).toDouble()
            : double.tryParse('${map['longitude']}') ?? 0,
        clientName: map['clientName'] ?? '',
        clientNumber: map['clientNumber']?.toString(),
        openingTime:
            map['openingTime'] != null && map['openingTime'] is Timestamp
                ? (map['openingTime'] as Timestamp).toDate()
                : null,
        urgency: map['urgency'] ?? 'normal',
        pallets: (map['pallets'] is num)
            ? (map['pallets'] as num).toInt()
            : int.tryParse('${map['pallets']}') ?? 0,
        boxes: map['boxes'] != null
            ? (map['boxes'] is num
                ? (map['boxes'] as num).toInt()
                : int.tryParse('${map['boxes']}') ?? 0)
            : (map['pallets'] is num
                    ? (map['pallets'] as num).toInt()
                    : int.tryParse('${map['pallets']}') ?? 1) *
                4,
        status: normalizeStatus(map['status']),
        arrivedAt: map['arrivedAt'] != null && map['arrivedAt'] is Timestamp
            ? (map['arrivedAt'] as Timestamp).toDate()
            : null,
        completedAt:
            map['completedAt'] != null && map['completedAt'] is Timestamp
                ? (map['completedAt'] as Timestamp).toDate()
                : null,
        orderInRoute: (map['orderInRoute'] is num)
            ? (map['orderInRoute'] as num).toInt()
            : int.tryParse('${map['orderInRoute']}') ?? 0,
        driverId: map['driverId']?.toString(),
        driverName: map['driverName']?.toString() ?? '',
        driverCapacity: (map['driverCapacity'] is num)
            ? (map['driverCapacity'] as num).toInt()
            : null,
        temporaryAddress: map['temporaryAddress']?.toString(),
        autoCompleted: map['autoCompleted'] ?? false,
        boxTypes: map['boxTypes'] != null && map['boxTypes'] is List
            ? (map['boxTypes'] as List)
                .whereType<Map<String, dynamic>>()
                .map((item) => BoxType.fromMap(item))
                .toList()
            : null,
        eta: map['eta']?.toString() ?? '',
        distanceKm: (map['distanceKm'] is num)
            ? (map['distanceKm'] as num).toDouble()
            : double.tryParse('${map['distanceKm']}'),
        routeId: map['routeId']?.toString(),
        routePolyline: map['routePolyline']?.toString(),
        updatedByUid: map['updatedByUid']?.toString(),
        updatedAt: map['updatedAt'] != null && map['updatedAt'] is Timestamp
            ? (map['updatedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      print('❌ DeliveryPoint.fromMap error: $e');
      print('📄 Document id=$id, data=$map');
      return DeliveryPoint(
        id: id,
        companyId: map['companyId'] ?? '',
        address: map['address'] ?? '',
        latitude: 0,
        longitude: 0,
        clientName: map['clientName'] ?? 'ERROR',
        urgency: 'normal',
        pallets: 0,
        boxes: 0,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'clientName': clientName,
      if (clientNumber != null) 'clientNumber': clientNumber,
      if (openingTime != null) 'openingTime': Timestamp.fromDate(openingTime!),
      'urgency': urgency,
      'pallets': pallets,
      'boxes': boxes,
      'status': status,
      if (arrivedAt != null) 'arrivedAt': Timestamp.fromDate(arrivedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'orderInRoute': orderInRoute,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (driverCapacity != null) 'driverCapacity': driverCapacity,
      if (temporaryAddress != null) 'temporaryAddress': temporaryAddress,
      'autoCompleted': autoCompleted,
      if (boxTypes != null)
        'boxTypes': boxTypes!.map((box) => box.toMap()).toList(),
      if (eta != null) 'eta': eta,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (routeId != null) 'routeId': routeId,
      if (routePolyline != null) 'routePolyline': routePolyline,
      if (updatedByUid != null) 'updatedByUid': updatedByUid,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  DeliveryPoint copyWith({
    String? status,
    DateTime? arrivedAt,
    DateTime? completedAt,
    int? orderInRoute,
    String? eta,
    double? distanceKm,
    String? updatedByUid,
    DateTime? updatedAt,
  }) {
    return DeliveryPoint(
      id: id,
      companyId: companyId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      clientName: clientName,
      clientNumber: clientNumber,
      openingTime: openingTime,
      urgency: urgency,
      pallets: pallets,
      boxes: boxes,
      status: status ?? this.status,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      orderInRoute: orderInRoute ?? this.orderInRoute,
      driverId: driverId,
      driverName: driverName,
      driverCapacity: driverCapacity,
      temporaryAddress: temporaryAddress,
      autoCompleted: autoCompleted,
      boxTypes: boxTypes,
      eta: eta ?? this.eta,
      distanceKm: distanceKm ?? this.distanceKm,
      routeId: routeId,
      routePolyline: routePolyline,
      updatedByUid: updatedByUid ?? this.updatedByUid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String normalizeStatus(dynamic rawStatus) {
    if (rawStatus == null) return statusPending;

    final String value = rawStatus.toString().trim();
    if (value.isEmpty) return statusPending;

    final String lower = value.toLowerCase();
    switch (lower) {
      case statusPending:
        return statusPending;
      case statusAssigned:
        return statusAssigned;
      case statusInProgress:
        return statusInProgress;
      case statusCompleted:
        return statusCompleted;
      case statusCancelled:
        return statusCancelled;
    }

    if (value == statusPendingHe || value == statusPendingRu) {
      return statusPending;
    }
    if (value == statusAssignedHe || value == statusAssignedRu) {
      return statusAssigned;
    }
    if (value == statusInProgressHe || value == statusInProgressRu) {
      return statusInProgress;
    }
    if (value == statusCompletedHe ||
        value == statusCompletedRu ||
        value == statusCompletedRuAlt) {
      return statusCompleted;
    }
    if (value == statusCancelledHe ||
        value == statusCancelledRu ||
        value == statusCancelledRuAlt) {
      return statusCancelled;
    }

    return value;
  }
}
