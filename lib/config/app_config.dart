/// Централизованная конфигурация приложения
class AppConfig {
  // 🚛 Параметры грузовика и дорог
  static const double minBridgeHeight =
      4.0; // Минимальная высота моста в метрах
  static const double truckHeight = 3.5; // Высота грузовика с грузом в метрах
  static const double maxTruckWeight =
      4.0; // Максимальный вес грузовика в тоннах
  static const double minRoadWeightLimit =
      4.0; // Минимальное ограничение веса дороги в тоннах

  // 📍 Параметры геолокации
  static const int locationDistanceFilter =
      30; // Метров между обновлениями GPS (оптимизировано для экономии)
  static const Duration locationUpdateInterval = Duration(seconds: 3);
  static const Duration oldLocationThreshold =
      Duration(minutes: 5); // Порог устаревших данных

  // 🎯 Параметры автозакрытия точек
  static const double autoCompleteRadius = 100.0; // Радиус автозакрытия (метры)
  static const double autoCompleteResetRadius =
      120.0; // Гистерезис против GPS-дрожания
  static const Duration autoCompleteDuration =
      Duration(minutes: 3); // Время ожидания до автозакрытия
  static const Duration autoCloseUndoWindow =
      Duration(seconds: 90); // Окно отмены после автозакрытия

  // ⏱️ Таймауты
  static const Duration geocodingTimeout = Duration(seconds: 5);
  static const Duration navigationApiTimeout = Duration(seconds: 10);
  static const Duration mapUpdateDelay = Duration(milliseconds: 500);

  // 🌍 Радиус Земли для расчетов
  static const double earthRadiusKm = 6371.0;

  // 🏭 Координаты склада по умолчанию (Мишмарот)
  static const double defaultWarehouseLat = 32.48698;
  static const double defaultWarehouseLng = 34.982121;

  // 📦 Параметры паллет
  static const int minBoxesPerPallet = 16;
  static const int maxBoxesPerPallet = 48;

  // 🗺️ Параметры карты
  static const double defaultMapZoom = 11.0;
  static const double detailMapZoom = 15.0;

  // 🔌 WebSocket GPS сервер (Cloud Run)
  // IMPORTANT: Set GPS_WS_URL env variable at build time: --dart-define=GPS_WS_URL=wss://your-server.run.app
  static const String gpsWebSocketUrl = String.fromEnvironment(
    'GPS_WS_URL',
    defaultValue: '', // Empty = disabled. Must be set via --dart-define
  );

  // 🧾 Tax invoice/receipt UI gate.
  // Keep the document type in the domain model so Mas Hachnasa API can be added later.
  static const bool enableTaxInvoiceReceipt = true;
}
