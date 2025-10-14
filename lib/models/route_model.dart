import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String driverId;
  final String driverName;
  final List<String> pointIds;
  final DateTime createdAt;
  final String status;
  final String? currentPointId;
  final double? totalDurationHours; // рассчитанное общее время маршрута

  RouteModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.pointIds,
    required this.createdAt,
    this.status = 'active',
    this.currentPointId,
    this.totalDurationHours,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      pointIds: List<String>.from(map['pointIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'active',
      currentPointId: map['currentPointId'],
      totalDurationHours: (map['totalDurationHours'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'pointIds': pointIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (currentPointId != null) 'currentPointId': currentPointId,
      if (totalDurationHours != null) 'totalDurationHours': totalDurationHours,
    };
  }

  RouteModel copyWith({
    List<String>? pointIds,
    String? status,
    String? currentPointId,
    double? totalDurationHours,
  }) {
    return RouteModel(
      id: id,
      driverId: driverId,
      driverName: driverName,
      pointIds: pointIds ?? this.pointIds,
      createdAt: createdAt,
      status: status ?? this.status,
      currentPointId: currentPointId ?? this.currentPointId,
      totalDurationHours: totalDurationHours ?? this.totalDurationHours,
    );
  }
}

