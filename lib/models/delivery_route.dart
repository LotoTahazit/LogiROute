import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_status.dart';

class DeliveryRoute {
  final String? id;
  final String companyId;
  final String driverId;
  final String driverName;
  final List<String> pointIds; // ID точек доставки (stops)
  final RouteStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? routeDate;
  final Map<String, dynamic>? metadata; // Дополнительные данные

  const DeliveryRoute({
    this.id,
    required this.companyId,
    required this.driverId,
    required this.driverName,
    required this.pointIds,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.routeDate,
    this.metadata,
  });

  /// Создать из Firestore документа
  factory DeliveryRoute.fromMap(Map<String, dynamic> map, {String? id}) {
    return DeliveryRoute(
      id: id ?? map['id'],
      companyId: map['companyId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      pointIds: List<String>.from(map['pointIds'] ?? []),
      status: RouteStatusExtension.fromString(map['status'] ?? 'draft'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      routeDate: (map['routeDate'] as Timestamp?)?.toDate(),
      metadata: map['metadata'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'driverId': driverId,
      'driverName': driverName,
      'pointIds': pointIds,
      'status': status.name,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (routeDate != null) 'routeDate': Timestamp.fromDate(routeDate!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Копия с изменениями
  DeliveryRoute copyWith({
    String? id,
    String? companyId,
    String? driverId,
    String? driverName,
    List<String>? pointIds,
    RouteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? routeDate,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryRoute(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      pointIds: pointIds ?? this.pointIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routeDate: routeDate ?? this.routeDate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'DeliveryRoute(id: $id, companyId: $companyId, driverId: $driverId, status: $status, pointIds: ${pointIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryRoute &&
        other.id == id &&
        other.companyId == companyId &&
        other.driverId == driverId &&
        other.status == status &&
        other.pointIds.length == pointIds.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        companyId.hashCode ^
        driverId.hashCode ^
        status.hashCode ^
        pointIds.length.hashCode;
  }
}
