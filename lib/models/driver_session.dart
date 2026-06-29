import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSession {
  final String driverId;
  final String userId;
  final String deviceId;
  final String deviceLabel;
  final bool active;
  final DateTime? lastSeenAt;
  final DateTime? startedAt;
  final DateTime? takeoverAt;
  final String? takeoverByDeviceId;

  const DriverSession({
    required this.driverId,
    required this.userId,
    required this.deviceId,
    this.deviceLabel = '',
    this.active = true,
    this.lastSeenAt,
    this.startedAt,
    this.takeoverAt,
    this.takeoverByDeviceId,
  });

  factory DriverSession.fromMap(Map<String, dynamic> map) {
    return DriverSession(
      driverId: map['driverId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
      deviceLabel: map['deviceLabel']?.toString() ?? '',
      active: map['active'] == true,
      lastSeenAt: _readTs(map['lastSeenAt']),
      startedAt: _readTs(map['startedAt']),
      takeoverAt: _readTs(map['takeoverAt']),
      takeoverByDeviceId: map['takeoverByDeviceId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'userId': userId,
        'deviceId': deviceId,
        'deviceLabel': deviceLabel,
        'active': active,
        if (lastSeenAt != null)
          'lastSeenAt': Timestamp.fromDate(lastSeenAt!),
        if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
        if (takeoverAt != null) 'takeoverAt': Timestamp.fromDate(takeoverAt!),
        if (takeoverByDeviceId != null)
          'takeoverByDeviceId': takeoverByDeviceId,
      };

  static DateTime? _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
