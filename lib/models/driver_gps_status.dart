/// Состояние GPS-трекинга водителя (UI + health-check).
enum DriverGpsStatus {
  active,
  waiting,
  error,
  disabled,
  permissionRequired,
}
