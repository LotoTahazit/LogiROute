import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPoint {
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
    this.status = 'pending',
    this.arrivedAt,
    this.completedAt,
    this.orderInRoute = 0,
    this.driverId,
    this.driverName,
    this.driverCapacity,
    this.temporaryAddress,
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
      boxes: map['boxes'] ?? (map['pallets'] ?? 1) * 4, // Fallback для старых записей
      status: map['status'] ?? 'pending',
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
    };
  }

  DeliveryPoint copyWith({
    String? status,
    DateTime? arrivedAt,
    DateTime? completedAt,
    int? orderInRoute,
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
    );
  }
}

