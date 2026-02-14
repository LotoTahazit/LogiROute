import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Separate status document for delivery points
/// ⚡ OPTIMIZATION: Small document for realtime updates
///
/// This allows listening to delivery status without reading full point data
/// Typical size: ~300 bytes vs ~3KB for full delivery point
class DeliveryStatus {
  final String pointId;
  final String status; // pending, assigned, in_progress, completed, cancelled
  final LatLng? currentLocation; // Driver's current location
  final DateTime? eta; // Estimated time of arrival
  final DateTime? completedAt;
  final String? completionNotes;
  final DateTime lastUpdated;

  DeliveryStatus({
    required this.pointId,
    required this.status,
    this.currentLocation,
    this.eta,
    this.completedAt,
    this.completionNotes,
    required this.lastUpdated,
  });

  bool get isActive => status == 'assigned' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  Map<String, dynamic> toMap() {
    return {
      'pointId': pointId,
      'status': status,
      if (currentLocation != null)
        'currentLocation': {
          'lat': currentLocation!.latitude,
          'lng': currentLocation!.longitude,
        },
      if (eta != null) 'eta': Timestamp.fromDate(eta!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (completionNotes != null) 'completionNotes': completionNotes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory DeliveryStatus.fromMap(Map<String, dynamic> map, String id) {
    LatLng? location;
    if (map['currentLocation'] != null) {
      final loc = map['currentLocation'] as Map<String, dynamic>;
      location = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    }

    return DeliveryStatus(
      pointId: id,
      status: map['status'] ?? 'pending',
      currentLocation: location,
      eta: map['eta'] != null ? (map['eta'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completionNotes: map['completionNotes'],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  DeliveryStatus copyWith({
    String? status,
    LatLng? currentLocation,
    DateTime? eta,
    DateTime? completedAt,
    String? completionNotes,
    DateTime? lastUpdated,
  }) {
    return DeliveryStatus(
      pointId: pointId,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      eta: eta ?? this.eta,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
