/// Централизованная конфигурация приложения
class AppConfig {
  // 🚛 Параметры грузовика и дорог
  static const double minBridgeHeight = 4.0; // Минимальная высота моста в метрах
  static const double truckHeight = 3.5; // Высота грузовика с грузом в метрах
  
  // 📍 Параметры геолокации
  static const int locationDistanceFilter = 5; // Метров между обновлениями GPS
  static const Duration locationUpdateInterval = Duration(seconds: 3);
  static const Duration oldLocationThreshold = Duration(minutes: 5); // Порог устаревших данных
  
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
}

