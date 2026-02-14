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
  final String address;
  final double latitude;
  final double longitude;
  final String clientName;
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

  DeliveryPoint({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.clientName,
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
  });

  factory DeliveryPoint.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryPoint(
      id: id,
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      clientName: map['clientName'] ?? '',
      openingTime: map['openingTime'] != null
          ? (map['openingTime'] as Timestamp).toDate()
          : null,
      urgency: map['urgency'] ?? 'normal',
      pallets: map['pallets'] ?? 0,
      boxes: map['boxes'] ??
          (map['pallets'] ?? 1) * 4, // Fallback для старых записей
      status: normalizeStatus(map['status']),
      arrivedAt: map['arrivedAt'] != null
          ? (map['arrivedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      orderInRoute: map['orderInRoute'] ?? 0,
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverCapacity: map['driverCapacity'],
      temporaryAddress: map['temporaryAddress'],
      autoCompleted: map['autoCompleted'] ?? false,
      boxTypes: map['boxTypes'] != null
          ? (map['boxTypes'] as List)
              .map((item) => BoxType.fromMap(item as Map<String, dynamic>))
              .toList()
          : null,
      eta: map['eta'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'clientName': clientName,
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
    };
  }

  DeliveryPoint copyWith({
    String? status,
    DateTime? arrivedAt,
    DateTime? completedAt,
    int? orderInRoute,
    String? eta,
  }) {
    return DeliveryPoint(
      id: id,
      address: address,
      latitude: latitude,
      longitude: longitude,
      clientName: clientName,
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
