/// Конфигурация компании — загружается из Firestore: companies/{companyId}/settings/config
class CompanyConfig {
  // 🏭 Склад
  final double warehouseLat;
  final double warehouseLng;
  final String warehouseAddress;

  // ⏰ Рабочие часы
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;
  final List<int> workDays; // 1=Mon ... 7=Sun

  // 🗺️ Маршрутизация
  final double autoCompleteRadiusMeters;
  final int autoCompleteWaitMinutes;
  final int maxPointsPerRoute;

  // 📍 Геозона
  final double geofenceMinLat;
  final double geofenceMaxLat;
  final double geofenceMinLng;
  final double geofenceMaxLng;

  // 📦 Диспетчеризация
  final int defaultPalletCapacity;
  final int minBoxesPerPallet;
  final int maxBoxesPerPallet;

  const CompanyConfig({
    this.warehouseLat = 32.48698,
    this.warehouseLng = 34.982121,
    this.warehouseAddress = '',
    this.workStartHour = 6,
    this.workStartMinute = 0,
    this.workEndHour = 17,
    this.workEndMinute = 0,
    this.workDays = const [1, 2, 3, 4, 5], // Sun-Thu (Israel)
    this.autoCompleteRadiusMeters = 100.0,
    this.autoCompleteWaitMinutes = 2,
    this.maxPointsPerRoute = 50,
    this.geofenceMinLat = 29.0,
    this.geofenceMaxLat = 34.0,
    this.geofenceMinLng = 34.0,
    this.geofenceMaxLng = 36.5,
    this.defaultPalletCapacity = 26,
    this.minBoxesPerPallet = 16,
    this.maxBoxesPerPallet = 48,
  });

  factory CompanyConfig.fromMap(Map<String, dynamic> data) {
    return CompanyConfig(
      warehouseLat: (data['warehouseLat'] as num?)?.toDouble() ?? 32.48698,
      warehouseLng: (data['warehouseLng'] as num?)?.toDouble() ?? 34.982121,
      warehouseAddress: data['warehouseAddress']?.toString() ?? '',
      workStartHour: (data['workStartHour'] as num?)?.toInt() ?? 6,
      workStartMinute: (data['workStartMinute'] as num?)?.toInt() ?? 0,
      workEndHour: (data['workEndHour'] as num?)?.toInt() ?? 17,
      workEndMinute: (data['workEndMinute'] as num?)?.toInt() ?? 0,
      workDays: (data['workDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5],
      autoCompleteRadiusMeters:
          (data['autoCompleteRadiusMeters'] as num?)?.toDouble() ?? 100.0,
      autoCompleteWaitMinutes:
          (data['autoCompleteWaitMinutes'] as num?)?.toInt() ?? 2,
      maxPointsPerRoute: (data['maxPointsPerRoute'] as num?)?.toInt() ?? 50,
      geofenceMinLat: (data['geofenceMinLat'] as num?)?.toDouble() ?? 29.0,
      geofenceMaxLat: (data['geofenceMaxLat'] as num?)?.toDouble() ?? 34.0,
      geofenceMinLng: (data['geofenceMinLng'] as num?)?.toDouble() ?? 34.0,
      geofenceMaxLng: (data['geofenceMaxLng'] as num?)?.toDouble() ?? 36.5,
      defaultPalletCapacity:
          (data['defaultPalletCapacity'] as num?)?.toInt() ?? 26,
      minBoxesPerPallet: (data['minBoxesPerPallet'] as num?)?.toInt() ?? 16,
      maxBoxesPerPallet: (data['maxBoxesPerPallet'] as num?)?.toInt() ?? 48,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'warehouseLat': warehouseLat,
      'warehouseLng': warehouseLng,
      'warehouseAddress': warehouseAddress,
      'workStartHour': workStartHour,
      'workStartMinute': workStartMinute,
      'workEndHour': workEndHour,
      'workEndMinute': workEndMinute,
      'workDays': workDays,
      'autoCompleteRadiusMeters': autoCompleteRadiusMeters,
      'autoCompleteWaitMinutes': autoCompleteWaitMinutes,
      'maxPointsPerRoute': maxPointsPerRoute,
      'geofenceMinLat': geofenceMinLat,
      'geofenceMaxLat': geofenceMaxLat,
      'geofenceMinLng': geofenceMinLng,
      'geofenceMaxLng': geofenceMaxLng,
      'defaultPalletCapacity': defaultPalletCapacity,
      'minBoxesPerPallet': minBoxesPerPallet,
      'maxBoxesPerPallet': maxBoxesPerPallet,
    };
  }

  /// Дефолтная конфигурация
  static const CompanyConfig defaults = CompanyConfig();
}
