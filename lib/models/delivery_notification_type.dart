/// Типы push-уведомлений для водителей
/// Соответствуют типам в Cloud Function onPointAssigned.js
class DeliveryNotificationType {
  static const String newStop = 'NEW_STOP';
  static const String routeChanged = 'ROUTE_CHANGED';
  static const String stopCancelled = 'STOP_CANCELLED';
  static const String urgentStop = 'URGENT_STOP';

  /// Все типы для фильтрации
  static const List<String> all = [
    newStop,
    routeChanged,
    stopCancelled,
    urgentStop,
  ];

  /// Иконка по типу
  static String icon(String type) {
    switch (type) {
      case newStop:
        return '📦';
      case routeChanged:
        return '🔄';
      case stopCancelled:
        return '❌';
      case urgentStop:
        return '🚨';
      default:
        return '📋';
    }
  }
}
