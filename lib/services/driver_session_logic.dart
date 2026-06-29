import '../config/app_config.dart';
import '../models/driver_session.dart';
enum DriverSessionAccess {
  active,
  blocked,
  stale,
  none,
}

DriverSessionAccess evaluateDriverSessionAccess({
  required String localDeviceId,
  DriverSession? session,
  DateTime? now,
  Duration staleThreshold = AppConfig.driverSessionStaleThreshold,
}) {
  if (session == null || !session.active) return DriverSessionAccess.none;
  if (session.deviceId == localDeviceId) return DriverSessionAccess.active;
  final lastSeen = session.lastSeenAt;
  final t = now ?? DateTime.now();
  if (lastSeen == null || t.difference(lastSeen) > staleThreshold) {
    return DriverSessionAccess.stale;
  }
  return DriverSessionAccess.blocked;
}

bool isDriverSessionStale(
  DateTime? lastSeenAt, {
  DateTime? now,
  Duration staleThreshold = AppConfig.driverSessionStaleThreshold,
}) {
  if (lastSeenAt == null) return true;
  final t = now ?? DateTime.now();
  return t.difference(lastSeenAt) > staleThreshold;
}

bool driverSessionOwnedByDevice(DriverSession? session, String deviceId) =>
    session != null &&
    session.active &&
    session.deviceId == deviceId;
