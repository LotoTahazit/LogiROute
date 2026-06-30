/// Состояние GPS-трекинга водителя (UI + health-check).
enum DriverGpsStatus {
  /// Свежий локальный fix и запись в Firestore проходит — зелёный.
  active,

  /// Ждём первый fix после старта трекинга — жёлтый.
  waiting,

  /// Нет разрешения на геолокацию — оранжевый.
  permissionRequired,

  /// Служба геолокации выключена — оранжевый.
  disabled,

  /// GPS-fix есть, но Firestore временно не обновился — жёлтый warning.
  uploadError,

  /// Нет свежего локального fix дольше UI-порога — красный.
  stale,
}
