enum RouteStatus {
  draft,      // Черновик
  planned,    // Запланирован
  active,     // Активен (водитель в пути)
  completed,  // Завершён
  cancelled,  // Отменён
}

extension RouteStatusExtension on RouteStatus {
  String get name {
    switch (this) {
      case RouteStatus.draft:
        return 'draft';
      case RouteStatus.planned:
        return 'planned';
      case RouteStatus.active:
        return 'active';
      case RouteStatus.completed:
        return 'completed';
      case RouteStatus.cancelled:
        return 'cancelled';
    }
  }

  static RouteStatus fromString(String status) {
    switch (status) {
      case 'draft':
        return RouteStatus.draft;
      case 'planned':
        return RouteStatus.planned;
      case 'active':
        return RouteStatus.active;
      case 'completed':
        return RouteStatus.completed;
      case 'cancelled':
        return RouteStatus.cancelled;
      default:
        throw ArgumentError('Invalid RouteStatus: $status');
    }
  }
}
